#pragma once
#include "simulation.hpp"

// V3 (SIMD): same semantics/results as V0/V1/V2, single thread, ARM NEON intrinsics.
// use_simd=false (or a non-NEON target) runs the scalar fallback (V1-style loop).
Result run_simulation_v3(const Params& p, bool use_simd = true);
bool v3_neon_enabled();  // true if this build was compiled with NEON support
