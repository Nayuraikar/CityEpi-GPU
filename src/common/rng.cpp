#include "rng.hpp"

static inline uint64_t mix(uint64_t x) {  // splitmix64 finalizer
    x += 0x9E3779B97F4A7C15ULL;
    x = (x ^ (x >> 30)) * 0xBF58476D1CE4E5B9ULL;
    x = (x ^ (x >> 27)) * 0x94D049BB133111EBULL;
    return x ^ (x >> 31);
}

double rand01(uint64_t seed, uint32_t agent_id, uint32_t day, uint32_t slot) {
    uint64_t h = mix(seed);
    h = mix(h ^ agent_id);
    h = mix(h ^ ((uint64_t)day << 8 | slot));
    return (h >> 11) * (1.0 / 9007199254740992.0);
}
