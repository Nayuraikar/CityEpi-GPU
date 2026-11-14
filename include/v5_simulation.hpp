#pragma once
#include <cstddef>
#include <cstdint>
#include <string>
#include "simulation.hpp"

// V5 (naive CUDA): same epidemic model, staged transitions and counter-based RNG as V0-V4.
// Population and location tables are allocated once on the GPU and stay resident for every day; per
// day only a 16-byte counter array (4 x uint32 S/E/I/R counts) returns to the host.
// Plain C++ header: no CUDA includes, so tests/benchmarks are ordinary C++ translation units.
//
// There is no CPU fallback. If no CUDA device can actually execute a kernel, run_simulation_v5 throws.

struct V5Info {
    bool gpu_ok = false;          // a CUDA device exists AND a probe kernel really executed on it
    std::string error;            // why gpu_ok is false (empty when true)
    int num_devices = 0;
    std::string device_name;
    int cc_major = 0, cc_minor = 0;
    int sm_count = 0;
    size_t global_mem_bytes = 0;
    int driver_version = 0;       // e.g. 12040 = CUDA 12.4
    int runtime_version = 0;
    std::string compiler;         // nvcc version used to build the library
};
V5Info v5_probe();                // never throws

struct V5HostInfo {
    std::string cpu_model;
    std::string os;
    int logical_cores = 0;
    size_t mem_bytes = 0;
};
V5HostInfo v5_host_info();        // CPU/OS facts for benchmark headers (best effort, "unknown" if absent)

struct V5Config {
    // TEST HOOKS (defaults: never). Neither alters any result.
    uint32_t inject_failure_after_day = 0xFFFFFFFFu;  // throw after this many days, buffers allocated
    uint32_t inject_alloc_failure_at = 0;             // 1-based: make the k-th device allocation fail (0 = never)
};

// Number of V5 device allocations currently alive (0 between runs; tests prove no leak on any path).
int v5_live_allocations();

struct V5Result : Result {        // Result::seconds = day loop only, data resident (kernel-only)
    V5Info info;
    double seconds_h2d = 0;       // cudaMalloc + initial copy-in
    double seconds_d2h = 0;       // final copy-out of state/timer
    double seconds_total = 0;     // h2d + day loop + d2h (end-to-end; excludes host setup)
    double seconds_events = 0;    // same day loop timed with cudaEvents on the GPU timeline
};

V5Result run_simulation_v5(const Params& p, const V5Config& cfg = V5Config());

// Diagnostics (need a device; throw std::runtime_error otherwise).
// Device evaluation of rand01(seed, agents[i], day, slot) and of 1-exp(-x) (the probability expression).
void v5_eval_draws(uint64_t seed, const uint32_t* agents, uint32_t day, uint32_t slot, double* out, size_t n);
void v5_eval_prob(const double* x, double* out, size_t n);
