#pragma once
#include <cstdint>

// V6-private copy of the counter-based RNG stages (same arithmetic as rng_inl:: / rng_v5::), callable from host
// and CUDA device code. Keeping a private copy leaves V5 untouched and lets V6 build without it.
// Pure integer arithmetic plus one exact power-of-two scale, so host and device agree bitwise.
// RNG keys are the ORIGINAL agent ids and the original slot numbers; V6 never renumbers agents.
#ifdef __CUDACC__
#define CITYEPI_V6_HD __host__ __device__
#else
#define CITYEPI_V6_HD
#endif

namespace rng_v6 {
CITYEPI_V6_HD inline uint64_t mix(uint64_t x) {
    x += 0x9E3779B97F4A7C15ULL;
    x = (x ^ (x >> 30)) * 0xBF58476D1CE4E5B9ULL;
    x = (x ^ (x >> 27)) * 0x94D049BB133111EBULL;
    return x ^ (x >> 31);
}
CITYEPI_V6_HD inline uint64_t seed_stage(uint64_t seed) { return mix(seed); }
CITYEPI_V6_HD inline uint64_t agent_stage(uint64_t h_seed, uint32_t agent) { return mix(h_seed ^ agent); }
CITYEPI_V6_HD inline double draw(uint64_t h_agent, uint32_t day, uint32_t slot) {
    uint64_t h = mix(h_agent ^ ((uint64_t)day << 8 | slot));
    return (h >> 11) * (1.0 / 9007199254740992.0);
}
}  // namespace rng_v6
