#pragma once
#include "simulation.hpp"

// V3 hybrid experiment: V1's scalar RNG/exposure; NEON only for the branchless state/timer
// transition and state counts (blocks of 16). use_simd=false or non-NEON target: scalar fallback.
Result run_simulation_v3_hybrid(const Params& p, bool use_simd = true);
Result run_simulation_v3_hybrid(const Params& p, const Population& pop, const Locations& locs, bool use_simd = true);  // external input
