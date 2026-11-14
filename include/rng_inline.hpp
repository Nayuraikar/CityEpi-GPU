#pragma once
#include <cstdint>
#include "rng.hpp"

// Header-inlinable form of rand01 split into stages so callers can hoist the
// seed stage out of loops and share the per-agent stage between slots.
// Bit-identical to rand01(seed, agent, day, slot).
namespace rng_inl {
inline uint64_t mix(uint64_t x) {
    x += 0x9E3779B97F4A7C15ULL;
    x = (x ^ (x >> 30)) * 0xBF58476D1CE4E5B9ULL;
    x = (x ^ (x >> 27)) * 0x94D049BB133111EBULL;
    return x ^ (x >> 31);
}
inline uint64_t seed_stage(uint64_t seed) { return mix(seed); }
inline uint64_t agent_stage(uint64_t h_seed, uint32_t agent) { return mix(h_seed ^ agent); }
inline double draw(uint64_t h_agent, uint32_t day, uint32_t slot) {
    uint64_t h = mix(h_agent ^ ((uint64_t)day << 8 | slot));
    return (h >> 11) * (1.0 / 9007199254740992.0);
}
}  // namespace rng_inl
