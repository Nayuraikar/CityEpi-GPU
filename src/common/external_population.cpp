#include "external_population.hpp"
#include <array>
#include <cstdio>
#include <cstring>
#include <limits>
#include <stdexcept>
#include "simulation.hpp"  // validate_input

namespace cepop {
namespace {

const uint8_t kMagic[8] = {'C', 'E', 'P', 'O', 'P', 'v', '1', 0};
constexpr uint64_t kU32Max = std::numeric_limits<uint32_t>::max();

[[noreturn]] void fail(const std::string& m) { throw std::invalid_argument("cepop: " + m); }
uint64_t align8(uint64_t x) { return (x + 7u) & ~uint64_t(7); }

uint16_t rd16(const uint8_t* p) { return (uint16_t)(p[0] | (p[1] << 8)); }
uint32_t rd32(const uint8_t* p) { return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24); }
uint64_t rd64(const uint8_t* p) { return (uint64_t)rd32(p) | ((uint64_t)rd32(p + 4) << 32); }
void wr16(uint8_t* p, uint16_t v) { p[0] = (uint8_t)v; p[1] = (uint8_t)(v >> 8); }
void wr32(uint8_t* p, uint32_t v) { for (int i = 0; i < 4; ++i) p[i] = (uint8_t)(v >> (8 * i)); }
void wr64(uint8_t* p, uint64_t v) { wr32(p, (uint32_t)v); wr32(p + 4, (uint32_t)(v >> 32)); }

struct Offsets { uint64_t state, timer, home, work, type, occ, total; };
Offsets offsets(uint64_t n, uint64_t nl) {
    Offsets o;
    o.state = kHeaderSize;
    o.timer = align8(o.state + n);
    o.home = align8(o.timer + 2 * n);
    o.work = align8(o.home + 4 * n);
    o.type = align8(o.work + 4 * n);
    o.occ = align8(o.type + nl);
    o.total = align8(o.occ + 4 * nl);
    return o;
}

}  // namespace

uint32_t crc32(const uint8_t* data, size_t n) {
    static const std::array<uint32_t, 256> table = [] {
        std::array<uint32_t, 256> t{};
        for (uint32_t i = 0; i < 256; ++i) {
            uint32_t c = i;
            for (int k = 0; k < 8; ++k) c = (c & 1u) ? (0xEDB88320u ^ (c >> 1)) : (c >> 1);
            t[i] = c;
        }
        return t;
    }();
    uint32_t c = 0xFFFFFFFFu;
    for (size_t i = 0; i < n; ++i) c = table[(c ^ data[i]) & 0xFFu] ^ (c >> 8);
    return c ^ 0xFFFFFFFFu;
}

uint64_t expected_file_size(uint64_t n, uint64_t nl) { return offsets(n, nl).total; }

void parse(const uint8_t* d, size_t size, Population& pop, Locations& locs, Info* info) {
    if (size < kHeaderSize) fail("file smaller than the 64-byte header (" + std::to_string(size) + " bytes)");
    if (std::memcmp(d, kMagic, 8) != 0) fail("bad magic");
    const uint32_t ver = rd32(d + 8);
    if (ver != kVersion) fail("unsupported version " + std::to_string(ver));
    if (rd32(d + 12) != kEndianMarker) fail("bad endian marker");
    const uint64_t n = rd64(d + 16), nl = rd64(d + 24);
    if (rd32(d + 32) != kHeaderSize) fail("bad header_size");
    if (rd32(d + 36) != 0) fail("unsupported flags");
    const uint32_t crc = rd32(d + 40);
    for (size_t i = 44; i < kHeaderSize; ++i)
        if (d[i] != 0) fail("reserved header bytes are non-zero");
    if (n == 0 || n > kU32Max) fail("n_agents out of range: " + std::to_string(n));
    if (nl == 0 || nl > kU32Max) fail("n_locations out of range: " + std::to_string(nl));
    const Offsets o = offsets(n, nl);
    if ((uint64_t)size != o.total)
        fail("file size " + std::to_string(size) + " != expected " + std::to_string(o.total) + " for N=" + std::to_string(n) +
             " L=" + std::to_string(nl));
    if (crc32(d + kHeaderSize, size - kHeaderSize) != crc) fail("payload CRC-32 mismatch");

    Population p;
    Locations l;
    p.state.assign(d + o.state, d + o.state + n);
    p.timer.resize(n);
    p.home_loc.resize(n);
    p.work_loc.resize(n);
    for (uint64_t a = 0; a < n; ++a) {
        p.timer[a] = rd16(d + o.timer + 2 * a);
        p.home_loc[a] = rd32(d + o.home + 4 * a);
        p.work_loc[a] = rd32(d + o.work + 4 * a);
    }
    l.type.assign(d + o.type, d + o.type + nl);
    l.occupancy.resize(nl);
    for (uint64_t i = 0; i < nl; ++i) l.occupancy[i] = rd32(d + o.occ + 4 * i);
    validate_input(p, l);  // throws std::invalid_argument
    pop = std::move(p);
    locs = std::move(l);
    if (info) { info->version = ver; info->n_agents = n; info->n_locations = nl; info->payload_crc32 = crc; info->file_bytes = size; }
}

void load(const std::string& path, Population& pop, Locations& locs, Info* info) {
    FILE* f = std::fopen(path.c_str(), "rb");
    if (!f) throw std::runtime_error("cepop: cannot open " + path);
    std::vector<uint8_t> buf;
    uint8_t chunk[1 << 16];
    size_t r;
    while ((r = std::fread(chunk, 1, sizeof chunk, f)) > 0) buf.insert(buf.end(), chunk, chunk + r);
    const bool err = std::ferror(f) != 0;
    std::fclose(f);
    if (err) throw std::runtime_error("cepop: read error on " + path);
    parse(buf.data(), buf.size(), pop, locs, info);
}

std::vector<uint8_t> serialize(const Population& pop, const Locations& locs) {
    const uint64_t n = pop.state.size(), nl = locs.type.size();
    if (pop.timer.size() != n || pop.home_loc.size() != n || pop.work_loc.size() != n || locs.occupancy.size() != nl)
        throw std::invalid_argument("cepop: serialize: inconsistent array sizes");
    if (n == 0 || nl == 0 || n > kU32Max || nl > kU32Max) throw std::invalid_argument("cepop: serialize: N/L out of range");
    const Offsets o = offsets(n, nl);
    std::vector<uint8_t> b(o.total, 0);
    std::memcpy(b.data() + o.state, pop.state.data(), n);
    for (uint64_t a = 0; a < n; ++a) {
        wr16(b.data() + o.timer + 2 * a, pop.timer[a]);
        wr32(b.data() + o.home + 4 * a, pop.home_loc[a]);
        wr32(b.data() + o.work + 4 * a, pop.work_loc[a]);
    }
    std::memcpy(b.data() + o.type, locs.type.data(), nl);
    for (uint64_t i = 0; i < nl; ++i) wr32(b.data() + o.occ + 4 * i, locs.occupancy[i]);
    std::memcpy(b.data(), kMagic, 8);
    wr32(b.data() + 8, kVersion);
    wr32(b.data() + 12, kEndianMarker);
    wr64(b.data() + 16, n);
    wr64(b.data() + 24, nl);
    wr32(b.data() + 32, (uint32_t)kHeaderSize);
    wr32(b.data() + 40, crc32(b.data() + kHeaderSize, b.size() - kHeaderSize));
    return b;
}

}  // namespace cepop
