#pragma once
#include <cstdint>

// V5-private copy of the counter-based RNG stages (rng_inline.hpp / rng.cpp), callable from both host
// and CUDA device code. The arithmetic is character-for-character the same as rng_inl::; tests/test_v5.cpp
// checks bit-equality against rng_inl:: and rand01() on the host and, when a GPU is present, on the device.
// Pure integer arithmetic plus one exact power-of-two scale, so host and device agree bitwise.
#ifdef __CUDACC__
#define CITYEPI_HD __host__ __device__
#else
#define CITYEPI_HD
#endif

namespace rng_v5 {
CITYEPI_HD inline uint64_t mix(uint64_t x) {
    x += 0x9E3779B97F4A7C15ULL;
    x = (x ^ (x >> 30)) * 0xBF58476D1CE4E5B9ULL;
    x = (x ^ (x >> 27)) * 0x94D049BB133111EBULL;
    return x ^ (x >> 31);
}
CITYEPI_HD inline uint64_t seed_stage(uint64_t seed) { return mix(seed); }
CITYEPI_HD inline uint64_t agent_stage(uint64_t h_seed, uint32_t agent) { return mix(h_seed ^ agent); }
CITYEPI_HD inline double draw(uint64_t h_agent, uint32_t day, uint32_t slot) {
    uint64_t h = mix(h_agent ^ ((uint64_t)day << 8 | slot));
    return (h >> 11) * (1.0 / 9007199254740992.0);
}
}  // namespace rng_v5
