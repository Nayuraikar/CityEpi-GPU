#pragma once
#include <cstddef>
#include <string>
#include <vector>
#include "simulation.hpp"

// V4 (OpenACC): same semantics/results as V0-V3. Population and location tables stay resident on
// the accelerator across all simulation days; only per-day counts (4 x uint32 reduction) return.
//
// EXECUTION MODE: OpenACC silently falls back to the host when no device is available, so every
// run probes where an `acc parallel` region really executes and reports it in V4Result.
// Nothing should be called "GPU" unless exec_mode == V4Mode::Device.
enum class V4Mode { NoOpenACC,  // built without -fopenacc/-acc: pragmas ignored, plain serial loops
                    Host,       // OpenACC runtime present but regions execute on the host CPU
                    Device };   // regions execute on an accelerator (acc_on_device(not_host) == true)

const char* v4_mode_name(V4Mode m);

struct V4Info {
    V4Mode mode = V4Mode::NoOpenACC;
    int openacc_version = 0;      // value of _OPENACC (0 if not compiled with OpenACC)
    int num_devices = 0;          // non-host devices visible to the runtime
    std::string device_name;      // empty on host
    std::string device_vendor;
    std::string compiler;         // compiler id/version used for this translation unit
};
V4Info v4_probe();                // runs a tiny kernel to see where it executes

struct V4Config {
    bool require_gpu = false;     // throw std::runtime_error unless exec_mode == Device
    // TEST HOOK (default: never): throw std::runtime_error after this many simulated days, while
    // device data is mapped, to exercise exception-path cleanup. Does not alter any result.
    uint32_t inject_failure_after_day = 0xFFFFFFFFu;
};

// Number of V4 run-scoped device mappings currently alive (0 between runs; used by tests to prove
// that no mapping leaks on any exit path).
int v4_live_mappings();

struct V4Result : Result {        // Result::seconds = day loop only, data resident (kernel-only)
    V4Info info;
    double seconds_h2d = 0;       // enter data (initial copy-in)
    double seconds_d2h = 0;       // exit data (final copy-out of state/timer)
    double seconds_total = 0;     // h2d + kernel + d2h  (end-to-end incl. transfers; excl. host setup)
};

V4Result run_simulation_v4(const Params& p, const V4Config& cfg = V4Config());
V4Result run_simulation_v4(const Params& p, const Population& pop, const Locations& locs, const V4Config& cfg = V4Config());  // external input

// Diagnostic for compiler/device-dependent FP: evaluates 1-exp(-x) on the OpenACC device for x[i]
// (same expression as the probability kernel). Compared bitwise against host std::exp in tests.
void v4_eval_prob(const double* x, double* out, size_t n);
