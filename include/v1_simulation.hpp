#pragma once
#include "simulation.hpp"

// V1 (ILP): same semantics/results as run_simulation (V0), single thread, no intrinsics.
Result run_simulation_v1(const Params& p);
Result run_simulation_v1(const Params& p, const Population& pop, const Locations& locs);  // external input
