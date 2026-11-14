#pragma once
#include "simulation.hpp"

// V2 (OpenMP): same semantics/results as V0/V1, parallel over agents. No CUDA/MPI/SIMD intrinsics.
enum class Sched { Static, Dynamic, Guided };
enum class Reduce { Local, Atomic };  // Local: thread-private histograms + reduction(+); Atomic: shared + atomics

struct V2Config {
    int threads = 0;           // 0 = OpenMP default (ignored in non-OpenMP builds)
    Sched sched = Sched::Static;
    int chunk = 0;             // 0 = runtime default
    Reduce reduce = Reduce::Local;
};

struct V2Result : Result {
    int threads = 1;            // team size actually used
    size_t hist_bytes = 0;      // location-tally memory (T private histograms, or 1 shared)
};

V2Result run_simulation_v2(const Params& p, const V2Config& cfg = V2Config());
V2Result run_simulation_v2(const Params& p, const Population& pop, const Locations& locs, const V2Config& cfg = V2Config());  // external input
bool v2_openmp_enabled();
int v2_max_threads();
