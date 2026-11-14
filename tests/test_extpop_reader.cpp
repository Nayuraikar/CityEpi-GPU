// CEPOP v1 reader tests: golden fixture (written by scripts/synthpop/cepop.py), C++ serializer byte-equality with the
// Python writer, every format-level rejection, semantic rejection via validate_input, and V0-V3 execution.
#include <cstdio>
#include <cstring>
#include <functional>
#include "external_input_common.hpp"
#include "external_population.hpp"
#include "v1_simulation.hpp"
#include "v2_simulation.hpp"
#include "v3_simulation.hpp"

#ifndef CEPOP_FIXTURE
#error "CEPOP_FIXTURE must point at tests/fixtures/tiny.cepop"
#endif

static int fails = 0;
#define CHECK(c) do { if (!(c)) { printf("FAIL %s:%d %s\n", __FILE__, __LINE__, #c); ++fails; } } while (0)
using Bytes = std::vector<uint8_t>;

static Bytes read_file(const char* path) {
    Bytes b; FILE* f = fopen(path, "rb"); if (!f) return b;
    uint8_t c[4096]; size_t r; while ((r = fread(c, 1, sizeof c, f)) > 0) b.insert(b.end(), c, c + r);
    fclose(f); return b;
}
static void put32(Bytes& b, size_t off, uint32_t v) { for (int i = 0; i < 4; ++i) b[off + i] = (uint8_t)(v >> (8 * i)); }
static void fix_crc(Bytes& b) { put32(b, 40, cepop::crc32(b.data() + 64, b.size() - 64)); }

static bool rejects(const Bytes& b) {
    Population p; Locations l;
    try { cepop::parse(b.data(), b.size(), p, l); } catch (const std::invalid_argument&) { return true; } catch (...) { return false; }
    return false;
}
static void expect_reject(const char* what, Bytes b, bool recrc = false) {
    if (recrc) fix_crc(b);
    bool ok = rejects(b);
    if (!ok) printf("not rejected: %s\n", what);
    CHECK(ok);
}

int main() {
    CHECK(cepop::crc32((const uint8_t*)"123456789", 9) == 0xCBF43926u);  // standard CRC-32 check value

    Bytes golden = read_file(CEPOP_FIXTURE);
    CHECK(golden.size() == 240);
    CHECK(cepop::expected_file_size(12, 7) == 240);

    // load via path -> equals hand-built extin::handmade layout (all S, timer 0)
    Population pop; Locations locs; cepop::Info info;
    cepop::load(CEPOP_FIXTURE, pop, locs, &info);
    CHECK(info.version == 1 && info.n_agents == 12 && info.n_locations == 7 && info.file_bytes == 240);
    CHECK(info.payload_crc32 == 0x2d76cb45u);
    { Population hp; Locations hl; extin::handmade(hp, hl);
      CHECK(pop.home_loc == hp.home_loc && pop.work_loc == hp.work_loc && locs.type == hl.type && locs.occupancy == hl.occupancy);
      CHECK(pop.state == std::vector<uint8_t>(12, S) && pop.timer == std::vector<uint16_t>(12, 0)); }

    // C++ serializer is byte-identical to the Python writer (cross-language format agreement)
    CHECK(cepop::serialize(pop, locs) == golden);

    // round trip with non-trivial state/timer values and sizes that exercise padding (N=13, L=5)
    { Population p; Locations l;
      l.type = {LOC_HOME, LOC_WORK, LOC_HOME, LOC_WORK, LOC_WORK};
      for (uint32_t a = 0; a < 13; ++a) { p.state.push_back(a % 4); p.timer.push_back((a % 4 == E || a % 4 == I) ? 1000 + a : 7);
          p.home_loc.push_back(a % 2 ? 0 : 2); p.work_loc.push_back(1 + 2 * (a % 2)); }
      l.occupancy.assign(5, 0); for (uint32_t a = 0; a < 13; ++a) { ++l.occupancy[p.home_loc[a]]; ++l.occupancy[p.work_loc[a]]; }
      Bytes b = cepop::serialize(p, l);
      CHECK(b.size() == cepop::expected_file_size(13, 5) && b.size() % 8 == 0);
      Population p2; Locations l2; cepop::parse(b.data(), b.size(), p2, l2);
      CHECK(p2.state == p.state && p2.timer == p.timer && p2.home_loc == p.home_loc && p2.work_loc == p.work_loc &&
            l2.type == l.type && l2.occupancy == l.occupancy); }

    // format-level rejections
    expect_reject("empty", Bytes());
    expect_reject("short header", Bytes(golden.begin(), golden.begin() + 63));
    { Bytes b = golden; b[0] = 'X'; expect_reject("bad magic", b); }
    { Bytes b = golden; b[8] = 2; expect_reject("bad version", b); }
    { Bytes b = golden; b[12] = 0x01; b[15] = 0x04; expect_reject("big-endian marker", b); }
    { Bytes b = golden; b[32] = 128; expect_reject("bad header_size", b); }
    { Bytes b = golden; b[36] = 1; expect_reject("flags", b); }
    { Bytes b = golden; b[50] = 1; expect_reject("reserved non-zero", b); }
    { Bytes b = golden; b[16] = 0; expect_reject("N changes size", b); }
    { Bytes b = golden; for (int i = 16; i < 24; ++i) b[i] = 0; expect_reject("N = 0", b); }
    { Bytes b = golden; for (int i = 24; i < 32; ++i) b[i] = 0; expect_reject("L = 0", b); }
    { Bytes b = golden; b[20] = 1; expect_reject("N > uint32", b); }  // N = 12 + 2^32
    { Bytes b = golden; b[28] = 1; expect_reject("L > uint32", b); }
    { Bytes b(golden.begin(), golden.end() - 8); expect_reject("truncated", b); }
    { Bytes b = golden; b.push_back(0); expect_reject("trailing byte", b); }
    { Bytes b = golden; b.resize(b.size() + 8, 0); expect_reject("trailing block", b); }
    { Bytes b = golden; b[100] ^= 1; expect_reject("payload bit flip (CRC)", b); }
    { Bytes b = golden; b[40] ^= 1; expect_reject("CRC field flip", b); }

    // semantic rejections (CRC repaired so they reach validate_input)
    //   offsets for N=12,L=7: state 64, timer 80, home 104, work 152, type 200, occ 208
    { Bytes b = golden; b[64 + 3] = 4; expect_reject("invalid state", b, true); }
    { Bytes b = golden; b[64 + 3] = I; expect_reject("I with timer 0", b, true); }
    { Bytes b = golden; b[104 + 4 * 4] = 0; expect_reject("home -> WORK", b, true); }
    { Bytes b = golden; b[152 + 4 * 4] = 1; expect_reject("work -> HOME", b, true); }
    { Bytes b = golden; b[104] = 7; expect_reject("home out of range", b, true); }
    { Bytes b = golden; b[152 + 3] = 0xFF; expect_reject("work out of range", b, true); }
    { Bytes b = golden; b[200 + 2] = 2; expect_reject("bad loc type", b, true); }
    { Bytes b = golden; b[208 + 4 * 1] += 1; expect_reject("occupancy too high", b, true); }
    { Bytes b = golden; b[208 + 4 * 6] -= 1; expect_reject("occupancy too low", b, true); }

    // I/O failure is not a format error
    { Population p; Locations l; bool io = false;
      try { cepop::load("/nonexistent/none.cepop", p, l); } catch (const std::runtime_error&) { io = true; } catch (...) {}
      CHECK(io); }
    // failed load leaves outputs untouched
    { Population p = pop; Locations l = locs; Bytes b = golden; b[100] ^= 1;
      try { cepop::parse(b.data(), b.size(), p, l); } catch (...) {}
      CHECK(p.home_loc == pop.home_loc && l.occupancy == locs.occupancy); }

    // loaded input runs on V0-V3 and all agree (infections seeded caller-side, as the external-input contract says)
    { Params p; p.days = 30; p.initial_infected = 3; p.beta_home = p.beta_work = 0.8;
      seed_infections(p, pop);
      CHECK(count_states(pop).i == 3);
      Result v0 = run_simulation(p, pop, locs);
      CHECK(v0.daily.size() == 31);
      CHECK(extin::daily_equal(v0, run_simulation_v1(p, pop, locs)));
      CHECK(extin::daily_equal(v0, run_simulation_v2(p, pop, locs)));
      CHECK(extin::daily_equal(v0, run_simulation_v3(p, pop, locs, false)));
      CHECK(extin::daily_equal(v0, run_simulation_v3(p, pop, locs, true)));
      for (const Counts& c : v0.daily) CHECK(c.s + c.e + c.i + c.r == 12); }

    printf(fails ? "EXTPOP READER FAILED\n" : "EXTPOP READER OK\n");
    return fails != 0;
}
