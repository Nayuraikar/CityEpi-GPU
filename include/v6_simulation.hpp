#pragma once
#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>
#include "simulation.hpp"

// V6 (optimized CUDA): same epidemic model, staged transitions and counter-based RNG as V0-V5, with
// independently switchable optimizations measured against the V5-equivalent baseline (all switches off).
// Plain C++ header: no CUDA includes. No CPU fallback: run_simulation_v6 throws without a working device.
//
// Switches (see docs/v6_cuda.md for the experiment log; defaults stay at the baseline until the acceptance
// rule is satisfied by benchmark evidence):
//   E1 agg_counts : hierarchical state-counter aggregation (warp ballot/popc -> block shared -> 4 global atomics)
//   E2 mode       : kSync (V5-like per-day readback), kAsync (no per-day sync, one deferred readback),
//                   kGraph (async + CUDA Graph of `graph_days` days per launch)
//   E3 skip_exp / skip_rng / pred_loads : exact work skipping (bit-exact decisions, see docs)
//   E4 block      : threads per block, one of v6_supported_blocks()

enum class V6Mode { kSync = 0, kAsync = 1, kGraph = 2 };

struct V6Opts {
    bool agg_counts = false;       // E1
    V6Mode mode = V6Mode::kSync;   // E2
    uint32_t graph_days = 32;      // E2 (kGraph only): days captured per graph, >= 1
    bool skip_exp = false;         // E3: skip exp() when the location tally is 0
    bool skip_rng = false;         // E3: skip an RNG draw when the location probability is exactly 0
    bool pred_loads = false;       // E3: load home/work ids only for agents that need them
    uint32_t block = 256;          // E4
};
std::string v6_describe(const V6Opts& o);               // e.g. "agg+graph32+skipexp+b512" ("base" if all off)
std::vector<uint32_t> v6_supported_blocks();            // {64,128,256,512,1024}

struct V6Info {
    bool gpu_ok = false;          // a CUDA device exists AND a probe kernel really executed on it
    std::string error;
    int num_devices = 0;
    std::string device_name;
    int cc_major = 0, cc_minor = 0;
    int sm_count = 0;
    int max_threads_per_sm = 0;
    size_t global_mem_bytes = 0;
    int driver_version = 0;
    int runtime_version = 0;
    std::string compiler;
};
V6Info v6_probe();                // never throws

struct V6HostInfo {
    std::string cpu_model;
    std::string os;
    int logical_cores = 0;
    size_t mem_bytes = 0;
};
V6HostInfo v6_host_info();

// Register/occupancy facts for the two kernels selected by `o` (needs a device; throws std::runtime_error otherwise).
struct V6KernelInfo {
    int loc_regs = 0, step_regs = 0;
    size_t loc_local_bytes = 0, step_local_bytes = 0;      // > 0 means register spills / local arrays
    size_t loc_static_smem = 0, step_static_smem = 0;
    int loc_blocks_per_sm = 0, step_blocks_per_sm = 0;
    double loc_occupancy_pct = 0, step_occupancy_pct = 0;  // resident threads / max threads per SM
};
V6KernelInfo v6_kernel_info(const V6Opts& o);

struct V6Config {
    V6Opts opts;
    bool profile = false;         // per-kernel cudaEvent timings (separate pass: events between kernels, no host sync)
    // TEST HOOKS (defaults: never). Neither alters any result.
    uint32_t inject_failure_after_day = 0xFFFFFFFFu;  // throw once this many days are done (all modes), buffers allocated
    uint32_t inject_alloc_failure_at = 0;             // 1-based: make the k-th device allocation fail (0 = never)
};

constexpr uint32_t v6_planned_allocations() { return 10; }  // device buffers per run
int v6_live_allocations();        // alive device allocations (0 between runs)

struct V6Result : Result {        // Result::seconds = day loop only, data resident (includes count readback)
    V6Info info;
    V6Opts opts;
    double seconds_h2d = 0;       // cudaMalloc + copy-in (+ graph build in kGraph mode)
    double seconds_d2h = 0;       // final copy-out of state/timer
    double seconds_total = 0;
    double seconds_events = 0;    // day loop timed with cudaEvents on the stream
    double prof_loc_ms = 0;       // cfg.profile only: summed location_prob_kernel time
    double prof_step_ms = 0;      // cfg.profile only: summed agent_step_kernel time
};
V6Result run_simulation_v6(const Params& p, const V6Config& cfg = V6Config());

// Diagnostics (need a device; throw std::runtime_error otherwise).
void v6_eval_draws(uint64_t seed, const uint32_t* agents, uint32_t day, uint32_t slot, double* out, size_t n);
// Runs the kernel's probability expression on the device for each (beta, nin, occ) triple, with or without the
// E3 `nin == 0` shortcut. The expression uses explicit round-to-nearest operations and device exp().
void v6_eval_prob(const double* beta, const uint32_t* nin, const uint32_t* occ, bool skip_exp, double* out, size_t n);
