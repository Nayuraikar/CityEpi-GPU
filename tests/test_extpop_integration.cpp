// Reader -> V0 (always) and Reader -> V6 (only in an ENABLE_CUDA_V6 build, and only if a GPU really executes code).
// Usage: test_extpop_integration [--require-gpu]   (or CITYEPI_REQUIRE_GPU=1)
// Without a build that has V6, or without a usable GPU, the V6 part prints a loud SKIPPED notice and exits 0 -- unless
// --require-gpu is given, which turns that into a failure (same convention as test_v6).
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <string>
#include <vector>
#include <unistd.h>
#include "extpop_cli.hpp"
#include "external_input_common.hpp"
#include "v1_simulation.hpp"
#include "v2_simulation.hpp"
#include "v3_simulation.hpp"
#ifdef CITYEPI_WITH_V6
#include "v6_simulation.hpp"
#endif

#ifndef CEPOP_FIXTURE
#error "CEPOP_FIXTURE must point at tests/fixtures/tiny.cepop"
#endif

static int fails = 0;
#define CHECK(c) do { if (!(c)) { printf("FAIL %s:%d %s\n", __FILE__, __LINE__, #c); ++fails; } } while (0)
namespace fs = std::filesystem;

// Run the CLI in-process, capture stdout+stderr and the exit code.
static int cli(const std::vector<std::string>& args, std::string& text) {
    std::vector<std::string> a = {"extpop_run"};
    a.insert(a.end(), args.begin(), args.end());
    std::vector<char*> argv;
    for (auto& s : a) argv.push_back(s.data());
    FILE* f = tmpfile();
    int rc = extpop::run_cli((int)argv.size(), argv.data(), f, f);
    fflush(f); rewind(f);
    text.clear();
    char buf[4096]; size_t n;
    while ((n = fread(buf, 1, sizeof buf, f)) > 0) text.append(buf, n);
    fclose(f);
    return rc;
}
static bool has(const std::string& t, const char* s) { return t.find(s) != std::string::npos; }

// Deterministic non-synthetic layout: interleaved HOME/WORK ids, very uneven occupancy, some unused locations.
static void build_geo_like(Population& pop, Locations& locs, uint32_t n) {
    const uint32_t L = 900;
    locs.type.resize(L);
    std::vector<uint32_t> homes, works;
    for (uint32_t l = 0; l < L; ++l) { locs.type[l] = (l % 11 == 3) ? LOC_WORK : LOC_HOME; (locs.type[l] == LOC_HOME ? homes : works).push_back(l); }
    pop.state.assign(n, S); pop.timer.assign(n, 0); pop.home_loc.resize(n); pop.work_loc.resize(n);
    uint64_t x = 88172645463325252ull;
    auto rnd = [&]() { x ^= x << 13; x ^= x >> 7; x ^= x << 17; return x; };
    for (uint32_t a = 0; a < n; ++a) {
        const uint64_t r1 = rnd() % 1000, r2 = rnd() % 1000;
        pop.home_loc[a] = homes[(r1 * r1 / 1000) * homes.size() / 1000];       // skewed toward low ids
        pop.work_loc[a] = works[(r2 * r2 / 1000) * works.size() / 1000];
    }
    locs.occupancy.assign(L, 0);
    for (uint32_t a = 0; a < n; ++a) { ++locs.occupancy[pop.home_loc[a]]; ++locs.occupancy[pop.work_loc[a]]; }
}

static void write_bytes(const fs::path& p, const std::vector<uint8_t>& b) {
    std::ofstream f(p, std::ios::binary); f.write((const char*)b.data(), (std::streamsize)b.size());
}

int main(int argc, char** argv) {
    bool require_gpu = getenv("CITYEPI_REQUIRE_GPU") != nullptr;
    for (int i = 1; i < argc; ++i) if (!strcmp(argv[i], "--require-gpu")) require_gpu = true;
    const fs::path tmp = fs::temp_directory_path() / ("extpop_it_" + std::to_string((long long)getpid()));
    fs::create_directories(tmp);

    // ---------------- reader -> V0 : CLI result equals a direct run on the in-memory pair
    Population gp; Locations gl;
    build_geo_like(gp, gl, 6000);
    validate_input(gp, gl);
    const std::string geo_file = (tmp / "geo.cepop").string();
    write_bytes(geo_file, cepop::serialize(gp, gl));
    {
        Params p; p.days = 40; p.seed = 7; p.initial_infected = 50; p.beta_home = 0.6; p.beta_work = 0.9;
        Population ref = gp; seed_infections(p, ref);
        Result v0 = run_simulation(p, ref, gl);
        std::string out;
        int rc = cli({"--input", geo_file, "--days", "40", "--seed", "7", "--init", "50", "--beta-home", "0.6", "--beta-work", "0.9",
                      "--expect-agents", "6000", "--expect-locations", "900", "--daily-csv", (tmp / "d").string()}, out);
        if (rc != 0) printf("%s\n", out.c_str());
        CHECK(rc == 0);
        CHECK(has(out, "validate_input=ok") && has(out, "v0_status=ok") && has(out, "v0_population_conserved=yes") && has(out, "RESULT: PASS"));
        char want[64]; snprintf(want, sizeof want, "v0_daily_checksum=%016llx", (unsigned long long)extpop::daily_checksum(v0));
        CHECK(has(out, want));
        CHECK(fs::exists(tmp / "d_v0.csv"));
        // snapshots (opt-in, V0): identical daily result/checksum, exact file size, no partial file left, V6/both refused
        {
            const std::string sd = (tmp / "snap").string();
            std::string so;
            int src = cli({"--input", geo_file, "--days", "40", "--seed", "7", "--init", "50", "--beta-home", "0.6", "--beta-work", "0.9",
                           "--snapshots", sd}, so);
            CHECK(src == 0 && has(so, want) && has(so, "snapshots_status=ok") && has(so, "snapshots_frames=41"));
            CHECK(fs::file_size(fs::path(sd) / "states.cesnap") == extpop::SnapshotWriter::expected_size(6000, 41));
            CHECK(!fs::exists(fs::path(sd) / "states.cesnap.partial"));
            std::string bo;
            CHECK(cli({"--input", geo_file, "--backend", "v6", "--snapshots", sd}, bo) != 0 && has(bo, "V0"));
        }
        // daily counts conserved and the epidemic actually moved (so equality below is not vacuous)
        for (const Counts& c : v0.daily) CHECK((uint64_t)c.s + c.e + c.i + c.r == 6000);
        CHECK(v0.daily.back().r > 0 || v0.daily.back().i > 50);
        // reader-loaded pair equals the original arrays and feeds every CPU backend identically
        Population lp; Locations ll; cepop::load(geo_file, lp, ll);
        CHECK(lp.home_loc == gp.home_loc && lp.work_loc == gp.work_loc && ll.type == gl.type && ll.occupancy == gl.occupancy);
        seed_infections(p, lp);
        CHECK(extpop::daily_equal(v0, run_simulation(p, lp, ll)));
        CHECK(extpop::daily_equal(v0, run_simulation_v1(p, lp, ll)));
        CHECK(extpop::daily_equal(v0, run_simulation_v2(p, lp, ll)));
        CHECK(extpop::daily_equal(v0, run_simulation_v3(p, lp, ll, true)));
    }
    // golden fixture via CLI, with and without seeding, deterministic output
    {
        std::string a, b;
        CHECK(cli({"--input", CEPOP_FIXTURE, "--days", "20", "--init", "3", "--seed", "5"}, a) == 0);
        CHECK(cli({"--input", CEPOP_FIXTURE, "--days", "20", "--init", "3", "--seed", "5"}, b) == 0);
        CHECK(a == b && has(a, "agents=12") && has(a, "locations=7") && has(a, "payload_crc32=0x2d76cb45"));
        std::string c;
        CHECK(cli({"--input", CEPOP_FIXTURE, "--days", "20", "--init", "0"}, c) == 0);
        CHECK(has(c, "v0_final=S12/E0/I0/R0"));   // nothing seeded -> nothing evolves
        std::string j;
        CHECK(cli({"--input", CEPOP_FIXTURE, "--days", "5", "--json", (tmp / "r.json").string()}, j) == 0);
        std::ifstream jf(tmp / "r.json"); std::string js((std::istreambuf_iterator<char>(jf)), {});
        CHECK(has(js, "\"pass\": true") && has(js, "\"agents\": 12") && has(js, "\"v6\": null"));
    }

    // ---------------- invalid input and error handling
    {
        std::string o;
        CHECK(cli({"--input", (tmp / "missing.cepop").string()}, o) == 1 && has(o, "cannot load"));
        CHECK(cli({}, o) == 1 && has(o, "--input is required"));
        CHECK(cli({"--input", CEPOP_FIXTURE, "--bogus", "1"}, o) == 1 && has(o, "unknown option"));
        CHECK(cli({"--input", CEPOP_FIXTURE, "--days", "0"}, o) == 1);
        CHECK(cli({"--input", CEPOP_FIXTURE, "--days", "12x"}, o) == 1);
        CHECK(cli({"--input", CEPOP_FIXTURE, "--seed", "-3"}, o) == 1);
        CHECK(cli({"--input", CEPOP_FIXTURE, "--incubation", "0"}, o) == 1);
        CHECK(cli({"--input", CEPOP_FIXTURE, "--beta-work", "-1"}, o) == 1);
        CHECK(cli({"--input", CEPOP_FIXTURE, "--backend", "v9"}, o) == 1);
        CHECK(cli({"--input", CEPOP_FIXTURE, "--days"}, o) == 1 && has(o, "needs a value"));
        CHECK(cli({"--input", CEPOP_FIXTURE, "--v6-agg"}, o) == 1 && has(o, "require --backend"));
        CHECK(cli({"--input", CEPOP_FIXTURE, "--expect-agents", "13"}, o) == 1 && has(o, "expected 13 agents"));
        CHECK(cli({"--input", CEPOP_FIXTURE, "--expect-locations", "8"}, o) == 1 && has(o, "expected 8 locations"));
        // corrupted files: CRC flip, truncation, trailing byte, semantic corruption with a repaired CRC
        std::vector<uint8_t> good = cepop::serialize(gp, gl);
        auto try_bad = [&](const char* name, std::vector<uint8_t> b, const char* msg, bool recrc) {
            if (recrc) { uint32_t crc = cepop::crc32(b.data() + 64, b.size() - 64); for (int i = 0; i < 4; ++i) b[40 + i] = (uint8_t)(crc >> (8 * i)); }
            const fs::path f = tmp / name; write_bytes(f, b);
            std::string t; int rc = cli({"--input", f.string()}, t);
            if (rc != 1 || !has(t, msg)) printf("bad-file case '%s' rc=%d: %s\n", name, rc, t.c_str());
            CHECK(rc == 1 && has(t, msg));
        };
        { auto b = good; b[200] ^= 0x10; try_bad("crc.cepop", b, "CRC", false); }
        { auto b = good; b.resize(b.size() - 8); try_bad("trunc.cepop", b, "file size", false); }
        { auto b = good; b.push_back(0); try_bad("trail.cepop", b, "file size", false); }
        { auto b = good; b[0] = 'Z'; try_bad("magic.cepop", b, "bad magic", false); }
        { auto b = good; b[64] = 9; try_bad("state.cepop", b, "invalid state", true); }                        // state[0] = 9
        { auto b = good; const size_t home0 = 6000 * 3 + 64; (void)home0; b[16] = 0; b[17] = 0; b[18] = 0; b[19] = 0; b[20] = 0; try_bad("n0.cepop", b, "cepop:", false); }
        { std::ofstream(tmp / "empty.cepop").close(); std::string t; CHECK(cli({"--input", (tmp / "empty.cepop").string()}, t) == 1 && has(t, "header")); }
    }

    // ---------------- V6 availability contract
    {
        std::string o;
#ifdef CITYEPI_WITH_V6
        const V6Info gpu = v6_probe();
        printf("V6 build: gpu_ok=%d %s\n", gpu.gpu_ok, gpu.gpu_ok ? gpu.device_name.c_str() : gpu.error.c_str());
        if (!gpu.gpu_ok) {
            CHECK(cli({"--input", CEPOP_FIXTURE, "--backend", "v6"}, o) == 2 && has(o, "no usable GPU"));
            CHECK(cli({"--input", CEPOP_FIXTURE, "--backend", "both"}, o) == 2 && has(o, "no usable GPU"));
            printf("SKIPPED: V6 reader integration (no usable GPU here)%s\n", require_gpu ? " -- but --require-gpu was given" : "");
            if (require_gpu) ++fails;
        } else {
            CHECK(cli({"--input", CEPOP_FIXTURE, "--backend", "v6", "--v6-block", "100"}, o) == 1 && has(o, "--v6-block"));
            // CLI V0-vs-V6 on golden fixture and geo-like population, several option sets
            const std::vector<std::vector<std::string>> sets = {
                {}, {"--v6-agg"}, {"--v6-mode", "async"}, {"--v6-mode", "graph", "--v6-graph-days", "7"},
                {"--v6-skip-exp", "--v6-skip-rng", "--v6-pred-loads"}, {"--v6-agg", "--v6-mode", "graph", "--v6-block", "512", "--v6-skip-exp"}};
            for (const char* f : {CEPOP_FIXTURE, geo_file.c_str()})
                for (const auto& s : sets) {
                    std::vector<std::string> a = {"--input", f, "--backend", "both", "--days", "35", "--init", "40", "--seed", "11", "--beta-home", "0.7", "--beta-work", "1.1"};
                    a.insert(a.end(), s.begin(), s.end());
                    int rc = cli(a, o);
                    if (rc != 0) printf("%s\n", o.c_str());
                    CHECK(rc == 0 && has(o, "v0_v6_daily_equal=yes") && has(o, "v6_population_conserved=yes") && has(o, "RESULT: PASS"));
                }
            // direct API: external pair loaded by the reader gives identical daily counts on V6 and V0
            Population lp; Locations ll; cepop::load(geo_file, lp, ll);
            Params p; p.days = 30; p.seed = 3; p.initial_infected = 60; p.beta_home = p.beta_work = 0.8;
            seed_infections(p, lp);
            Result v0 = run_simulation(p, lp, ll);
            V6Result v6 = run_simulation_v6(p, lp, ll);
            CHECK(extpop::daily_equal(v0, v6));
            CHECK(v6_live_allocations() == 0);
        }
#else
        CHECK(cli({"--input", CEPOP_FIXTURE, "--backend", "v6"}, o) == 2 && has(o, "built without V6"));
        CHECK(cli({"--input", CEPOP_FIXTURE, "--backend", "both"}, o) == 2 && has(o, "built without V6"));
        printf("SKIPPED: V6 reader integration (binary built without ENABLE_CUDA_V6)%s\n", require_gpu ? " -- but --require-gpu was given" : "");
        if (require_gpu) ++fails;
#endif
    }

    fs::remove_all(tmp);
    printf(fails ? "EXTPOP INTEGRATION FAILED\n" : "EXTPOP INTEGRATION OK\n");
    return fails != 0;
}
