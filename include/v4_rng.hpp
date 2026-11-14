#pragma once
#include <cstdint>

// V4-private copy of the counter-based RNG stages from rng_inline.hpp, with explicit
// `#pragma acc routine seq` so they are callable from OpenACC device kernels on any compiler.
// The arithmetic is character-for-character the same as rng_inl::; tests/test_v4.cpp checks
// bit-equality against rng_inl:: and rand01(). V0-V3 headers are untouched.
namespace rng_v4 {
#pragma acc routine seq
inline uint64_t mix(uint64_t x) {
    x += 0x9E3779B97F4A7C15ULL;
    x = (x ^ (x >> 30)) * 0xBF58476D1CE4E5B9ULL;
    x = (x ^ (x >> 27)) * 0x94D049BB133111EBULL;
    return x ^ (x >> 31);
}
#pragma acc routine seq
inline uint64_t seed_stage(uint64_t seed) { return mix(seed); }
#pragma acc routine seq
inline uint64_t agent_stage(uint64_t h_seed, uint32_t agent) { return mix(h_seed ^ agent); }
#pragma acc routine seq
inline double draw(uint64_t h_agent, uint32_t day, uint32_t slot) {
    uint64_t h = mix(h_agent ^ ((uint64_t)day << 8 | slot));
    return (h >> 11) * (1.0 / 9007199254740992.0);
}
}  // namespace rng_v4
