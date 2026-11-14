// V0/V1/V2/V3/V5 benchmark: identical Params/seed, warm-up, N interleaved repetitions, every run checked
// bit-identical to V0. For V5 two timings are reported:
//   kernel_s : day loop with data already resident on the GPU (includes the 16-byte per-day count readback)
//   e2e_s    : cudaMalloc + H2D copy-in + kernel + D2H copy-out (host-side population generation excluded for all)
// For V0-V3 there are no transfers, so e2e_s == kernel_s. events_s = the V5 day loop timed with cudaEvents.
// V5 has no CPU fallback: without a CUDA device the V5 row is skipped (CPU baselines still run), and
// --require-gpu turns that into exit code 2.
// Usage: bench_v5 [reps] [sizes...] [--require-gpu]
#include <algorithm>
#include <cerrno>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <functional>
#include <vector>
#include "v1_simulation.hpp"
#include "v2_simulation.hpp"
#include "v3_simulation.hpp"
#include "v5_simulation.hpp"

#ifndef CITYEPI_BUILD_FLAGS
#define CITYEPI_BUILD_FLAGS "unknown"
#endif

static bool eq(const Result& a, const Result& b) {
    if (a.daily.size() != b.daily.size()) return false;
    for (size_t i = 0; i < a.daily.size(); ++i) if (!(a.daily[i] == b.daily[i])) return false;
    return true;
}
struct Stats { double med, mn, mx, cv; };
static Stats stats(std::vector<double> v) {
    if (v.empty()) return {0, 0, 0, 0};
    double mean = 0, var = 0;
    for (double t : v) mean += t;
    mean /= v.size();
    for (double t : v) var += (t - mean) * (t - mean);
    const double sd = v.size() > 1 ? std::sqrt(var / (v.size() - 1)) : 0;
    std::sort(v.begin(), v.end());
    return {v[v.size() / 2], v.front(), v.back(), mean > 0 ? 100 * sd / mean : 0};
}
static bool parse_pos(const char* s, uint32_t lo, uint32_t hi, uint32_t& out) {
    if (!s || !*s || *s == '-' || *s == '+') return false;
    char* end = nullptr; errno = 0;
    const unsigned long long v = strtoull(s, &end, 10);
    if (errno || *end || v < lo || v > hi) return false;
    out = (uint32_t)v;
    return true;
}
static int usage(const char* msg, const char* arg) {
    fprintf(stderr, "bench_v5: %s '%s'\nusage: bench_v5 [reps (1..1000)] [agents (>=50 each) ...] [--require-gpu]\n", msg, arg);
    return 2;
}

int main(int argc, char** argv) {
    int reps = 7;
    bool require_gpu = getenv("CITYEPI_REQUIRE_GPU") != nullptr;
    std::vector<uint32_t> sizes;
    int pos = 0;
    for (int i = 1; i < argc; ++i) {
        if (!strcmp(argv[i], "--require-gpu")) require_gpu = true;
        else if (argv[i][0] == '-' && argv[i][1] == '-') return usage("unknown option", argv[i]);
        else if (pos++ == 0) {
            uint32_t v; if (!parse_pos(argv[i], 1, 1000, v)) return usage("invalid repetition count", argv[i]);
            reps = (int)v;
        } else {
            uint32_t v;
            if (!parse_pos(argv[i], 50, 100000000u, v)) return usage("invalid agent count", argv[i]);
            sizes.push_back(v);
        }
    }
    if (sizes.empty()) sizes = {10000, 100000, 1000000, 5000000};
    const V5Info info = v5_probe();
    const V5HostInfo host = v5_host_info();
    const bool gpu = info.gpu_ok;
    if (require_gpu && !gpu) { fprintf(stderr, "--require-gpu: no CUDA device executed code (%s)\n", info.error.c_str()); return 2; }

    printf("# exec_mode=%s\n", gpu ? "cuda-device" : "no-cuda-device (V5 skipped)");
    printf("# gpu_model=%s cc=%d.%d sms=%d mem_gib=%.1f\n", gpu ? info.device_name.c_str() : "none", info.cc_major,
           info.cc_minor, info.sm_count, info.global_mem_bytes / 1073741824.0);
    printf("# cuda_driver=%d cuda_runtime=%d devices=%d\n", info.driver_version, info.runtime_version, info.num_devices);
    printf("# cpu_model=%s\n# cpu_logical_cores=%d mem_gib=%.1f\n# os=%s\n", host.cpu_model.c_str(), host.logical_cores,
           host.mem_bytes / 1073741824.0, host.os.c_str());
    printf("# cuda_compiler=%s\n# flags=%s\n", info.compiler.c_str(), CITYEPI_BUILD_FLAGS);
    printf("# repetitions=%d (median reported; min/max/cv over reps) days=100\n", reps);
    printf("# note: V0-V3 are CPU baselines built here (see flags); V2_maxT uses %d threads only if OpenMP was enabled in the CPU build.\n", v2_max_threads());
    if (!gpu) printf("# WARNING: no CUDA device; V5 rows omitted.\n");
    printf("agents,backend,exec_mode,kernel_median_s,kernel_min_s,kernel_max_s,kernel_cv_pct,"
           "e2e_median_s,e2e_cv_pct,h2d_median_s,d2h_median_s,events_median_s,kernel_speedup_v0,e2e_speedup_v0,identical,gpu_claim\n");

    const int hw = v2_max_threads();
    for (uint32_t n : sizes) {
        Params p; p.n_agents = n; p.n_homes = n / 5; p.n_works = n / 50; p.days = 100; p.initial_infected = n / 1000;
        Result ref = run_simulation(p);
        struct B { const char* name; const char* mode; std::function<Result()> f; };
        V2Config c1; c1.threads = 1; V2Config cm; cm.threads = hw;
        std::vector<B> bs = {
            {"V0", "cpu-serial", [&] { return run_simulation(p); }},
            {"V1", "cpu-serial", [&] { return run_simulation_v1(p); }},
            {"V2_1T", "cpu-omp", [&] { return (Result)run_simulation_v2(p, c1); }},
            {"V2_maxT", "cpu-omp", [&] { return (Result)run_simulation_v2(p, cm); }},
            {"V3_simd", "cpu-simd", [&] { return run_simulation_v3(p, true); }},
        };
        const size_t k5 = bs.size();
        std::vector<double> h2d, d2h, e2e, ev;
        if (gpu)
            bs.push_back({"V5", "cuda-device", [&] {
                V5Result r = run_simulation_v5(p);
                h2d.push_back(r.seconds_h2d); d2h.push_back(r.seconds_d2h); e2e.push_back(r.seconds_total);
                ev.push_back(r.seconds_events);
                return (Result)r; }});
        std::vector<std::vector<double>> ts(bs.size());
        std::vector<bool> ok(bs.size(), true);
        for (auto& b : bs) b.f();  // warm-up (device init, page faults)
        h2d.clear(); d2h.clear(); e2e.clear(); ev.clear();
        for (int i = 0; i < reps; ++i)
            for (size_t k = 0; k < bs.size(); ++k) {
                Result r = bs[k].f();
                ts[k].push_back(r.seconds);
                ok[k] = ok[k] && eq(ref, r);
            }
        const Stats s0 = stats(ts[0]);
        for (size_t k = 0; k < bs.size(); ++k) {
            const Stats sk = stats(ts[k]);
            const bool is5 = k == k5;
            const Stats se = is5 ? stats(e2e) : sk;
            printf("%u,%s,%s,%.5f,%.5f,%.5f,%.1f,%.5f,%.1f,%.5f,%.5f,%.5f,%.2f,%.2f,%s,%s\n", n, bs[k].name, bs[k].mode,
                   sk.med, sk.mn, sk.mx, sk.cv, se.med, se.cv,
                   is5 ? stats(h2d).med : 0.0, is5 ? stats(d2h).med : 0.0, is5 ? stats(ev).med : 0.0,
                   s0.med / sk.med, s0.med / se.med, ok[k] ? "yes" : "NO", is5 ? "yes" : "n/a");
        }
        fflush(stdout);
    }
}
