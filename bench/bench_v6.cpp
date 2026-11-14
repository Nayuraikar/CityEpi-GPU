// V6 benchmark, same methodology as bench_v5 (identical Params/seed/days, warm-up, N interleaved repetitions,
// every run checked bit-identical to V0 and, when built together, to V5). Rows: V0, V5 (if CITYEPI_WITH_V5), and
// V6 option sets: the V5-equivalent baseline, each optimization alone, and combinations.
//   kernel_s : day loop with data resident (includes the count readback: per day for sync, once for async/graph)
//   e2e_s    : cudaMalloc + H2D (+ graph build) + kernel + D2H, host population generation excluded
//   events_s : the same day loop timed with cudaEvents
// A separate profiling pass (--profile-csv FILE) runs each V6 row once more with events between the two kernels.
// Usage: bench_v6 [reps] [sizes...] [--require-gpu] [--scenario default|low|high|all] [--rows substr[,substr]]
//                 [--profile-csv FILE]
#include <algorithm>
#include <cerrno>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <functional>
#include <string>
#include <vector>
#include "v6_simulation.hpp"
#ifdef CITYEPI_WITH_V5
#include "v5_simulation.hpp"
#endif

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
    fprintf(stderr, "bench_v6: %s '%s'\nusage: bench_v6 [reps (1..1000)] [agents (>=50 each) ...] [--require-gpu] "
                    "[--scenario default|low|high|all] [--rows substr,...] [--profile-csv FILE]\n", msg, arg);
    return 2;
}
static V6Opts mk(bool agg, V6Mode m, bool se, bool sr, bool pl, uint32_t block, uint32_t gd = 32) {
    V6Opts o; o.agg_counts = agg; o.mode = m; o.skip_exp = se; o.skip_rng = sr; o.pred_loads = pl; o.block = block; o.graph_days = gd;
    return o;
}
struct Scenario { const char* name; double beta; };

int main(int argc, char** argv) {
    int reps = 7;
    bool require_gpu = getenv("CITYEPI_REQUIRE_GPU") != nullptr;
    std::string scen = "default", rows_filter, profile_csv;
    std::vector<uint32_t> sizes;
    int pos = 0;
    for (int i = 1; i < argc; ++i) {
        if (!strcmp(argv[i], "--require-gpu")) require_gpu = true;
        else if (!strcmp(argv[i], "--scenario") && i + 1 < argc) scen = argv[++i];
        else if (!strcmp(argv[i], "--rows") && i + 1 < argc) rows_filter = argv[++i];
        else if (!strcmp(argv[i], "--profile-csv") && i + 1 < argc) profile_csv = argv[++i];
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
    std::vector<Scenario> scens;
    if (scen == "default" || scen == "all") scens.push_back({"default", 0.3});
    if (scen == "low" || scen == "all") scens.push_back({"low", 0.02});
    if (scen == "high" || scen == "all") scens.push_back({"high", 2.0});
    if (scens.empty()) return usage("unknown scenario", scen.c_str());

    const V6Info info = v6_probe();
    const V6HostInfo host = v6_host_info();
    const bool gpu = info.gpu_ok;
    if (require_gpu && !gpu) { fprintf(stderr, "--require-gpu: no CUDA device executed code (%s)\n", info.error.c_str()); return 2; }
    if (!gpu) { fprintf(stderr, "bench_v6: no CUDA device (%s); V6 has no CPU fallback\n", info.error.c_str()); return 2; }

    using Row = std::pair<std::string, V6Opts>;
    const V6Mode S_ = V6Mode::kSync, A_ = V6Mode::kAsync, G_ = V6Mode::kGraph;
    std::vector<Row> v6rows = {
        {"V6_base", mk(0, S_, 0, 0, 0, 256)},
        {"V6_E1", mk(1, S_, 0, 0, 0, 256)},
        {"V6_E2_async", mk(0, A_, 0, 0, 0, 256)},
        {"V6_E2_graph32", mk(0, G_, 0, 0, 0, 256, 32)},
        {"V6_E2_graph1", mk(0, G_, 0, 0, 0, 256, 1)},
        {"V6_E3_skipexp", mk(0, S_, 1, 0, 0, 256)},
        {"V6_E3_skiprng", mk(0, S_, 0, 1, 0, 256)},
        {"V6_E3_predload", mk(0, S_, 0, 0, 1, 256)},
        {"V6_E3_all", mk(0, S_, 1, 1, 1, 256)},
        {"V6_E4_b64", mk(0, S_, 0, 0, 0, 64)},
        {"V6_E4_b128", mk(0, S_, 0, 0, 0, 128)},
        {"V6_E4_b512", mk(0, S_, 0, 0, 0, 512)},
        {"V6_E4_b1024", mk(0, S_, 0, 0, 0, 1024)},
        {"V6_E1_E2async", mk(1, A_, 0, 0, 0, 256)},
        {"V6_E1_E2graph", mk(1, G_, 0, 0, 0, 256)},
        {"V6_E1_E3", mk(1, S_, 1, 1, 1, 256)},
        {"V6_E1_E2graph_E3", mk(1, G_, 1, 1, 1, 256)},
        {"V6_E1_E2graph_E3_b128", mk(1, G_, 1, 1, 1, 128)},
        {"V6_E1_E2graph_E3_b512", mk(1, G_, 1, 1, 1, 512)},
        {"V6_E1_E2graph_E3_b1024", mk(1, G_, 1, 1, 1, 1024)},
        // Targeted E3 ablations on top of E1 + E2 graph (block 128 / 256).
        // The all-three combo (V6_E1_E2graph_E3, V6_E1_E2graph_E3_b128) is defined above.
        {"V6_E1_E2graph_skipexp_b128", mk(1, G_, 1, 0, 0, 128)},
        {"V6_E1_E2graph_skipexp_b256", mk(1, G_, 1, 0, 0, 256)},
        {"V6_E1_E2graph_skiprng_b128", mk(1, G_, 0, 1, 0, 128)},
        {"V6_E1_E2graph_skiprng_b256", mk(1, G_, 0, 1, 0, 256)},
        {"V6_E1_E2graph_predload_b128", mk(1, G_, 0, 0, 1, 128)},
        {"V6_E1_E2graph_predload_b256", mk(1, G_, 0, 0, 1, 256)},
    };
    if (!rows_filter.empty()) {
        std::vector<Row> keep;
        for (const Row& r : v6rows) {
            bool m = r.first == "V6_base";  // the baseline is always kept: acceptance needs it
            size_t st = 0;
            while (!m && st <= rows_filter.size()) {
                size_t en = rows_filter.find(',', st); if (en == std::string::npos) en = rows_filter.size();
                const std::string tok = rows_filter.substr(st, en - st);
                if (!tok.empty() && r.first.find(tok) != std::string::npos) m = true;
                st = en + 1;
            }
            if (m) keep.push_back(r);
        }
        v6rows = keep;
    }

    printf("# exec_mode=cuda-device\n");
    printf("# gpu_model=%s cc=%d.%d sms=%d max_threads_per_sm=%d mem_gib=%.1f\n", info.device_name.c_str(), info.cc_major,
           info.cc_minor, info.sm_count, info.max_threads_per_sm, info.global_mem_bytes / 1073741824.0);
    printf("# cuda_driver=%d cuda_runtime=%d devices=%d\n", info.driver_version, info.runtime_version, info.num_devices);
    printf("# cpu_model=%s\n# cpu_logical_cores=%d mem_gib=%.1f\n# os=%s\n", host.cpu_model.c_str(), host.logical_cores,
           host.mem_bytes / 1073741824.0, host.os.c_str());
    printf("# cuda_compiler=%s\n# flags=%s\n", info.compiler.c_str(), CITYEPI_BUILD_FLAGS);
#ifdef CITYEPI_WITH_V5
    printf("# v5_row=included (V5 built in the same binary with its own flags)\n");
#else
    printf("# v5_row=absent (build with -DENABLE_CUDA=ON as well to include it)\n");
#endif
    printf("# repetitions=%d (median reported; min/max/cv over reps) days=100 scenarios=%s\n", reps, scen.c_str());
    printf("# note: kernel_s includes the count readback (per day for sync mode, one deferred copy for async/graph); "
           "e2e_s also includes graph build for graph rows.\n");
    for (const Row& r : v6rows) {
        try {
            const V6KernelInfo k = v6_kernel_info(r.second);
            printf("# kernel_info %s: loc regs=%d local=%zuB blocks/sm=%d occ=%.1f%% | step regs=%d local=%zuB smem=%zuB blocks/sm=%d occ=%.1f%%\n",
                   r.first.c_str(), k.loc_regs, k.loc_local_bytes, k.loc_blocks_per_sm, k.loc_occupancy_pct, k.step_regs,
                   k.step_local_bytes, k.step_static_smem, k.step_blocks_per_sm, k.step_occupancy_pct);
        } catch (const std::exception& e) { printf("# kernel_info %s: unavailable (%s)\n", r.first.c_str(), e.what()); }
    }
    printf("scenario,agents,backend,opts,kernel_median_s,kernel_min_s,kernel_max_s,kernel_cv_pct,e2e_median_s,e2e_cv_pct,"
           "h2d_median_s,d2h_median_s,events_median_s,kernel_speedup_v0,kernel_speedup_v5,e2e_speedup_v0,identical_v0,identical_v5\n");

    FILE* pf = nullptr;
    if (!profile_csv.empty()) {
        pf = fopen(profile_csv.c_str(), "w");
        if (!pf) { fprintf(stderr, "cannot open %s\n", profile_csv.c_str()); return 2; }
        fprintf(pf, "scenario,agents,backend,opts,loc_ms_median,step_ms_median,loc_pct\n");
    }

    int bad = 0;
    for (const Scenario& sc : scens)
        for (uint32_t n : sizes) {
            Params p; p.n_agents = n; p.n_homes = n / 5; p.n_works = n / 50; p.days = 100; p.initial_infected = n / 1000;
            p.beta_home = p.beta_work = sc.beta;
            const Result ref = run_simulation(p);
            struct B { std::string name, opts; std::function<Result()> f; bool is_v6; };
            std::vector<B> bs;
            bs.push_back({"V0", "cpu-serial", [&] { return run_simulation(p); }, false});
            std::vector<std::vector<double>> h2d, d2h, e2e, ev;
            size_t k5 = (size_t)-1;
#ifdef CITYEPI_WITH_V5
            k5 = bs.size();
            bs.push_back({"V5", "cuda-device", [&] { return (Result)run_simulation_v5(p); }, false});
#endif
            const size_t first6 = bs.size();
            h2d.resize(bs.size() + v6rows.size()); d2h = h2d; e2e = h2d; ev = h2d;
            for (size_t i = 0; i < v6rows.size(); ++i) {
                const size_t slot = first6 + i;
                const V6Opts o = v6rows[i].second;
                bs.push_back({v6rows[i].first, v6_describe(o), [&, slot, o] {
                    V6Config c; c.opts = o;
                    V6Result r = run_simulation_v6(p, c);
                    h2d[slot].push_back(r.seconds_h2d); d2h[slot].push_back(r.seconds_d2h);
                    e2e[slot].push_back(r.seconds_total); ev[slot].push_back(r.seconds_events);
                    return (Result)r; }, true});
            }
            std::vector<std::vector<double>> ts(bs.size());
            std::vector<bool> ok0(bs.size(), true), ok5(bs.size(), true);
            Result ref5 = ref;
#ifdef CITYEPI_WITH_V5
            ref5 = run_simulation_v5(p);
#endif
            for (auto& b : bs) b.f();  // warm-up (device init, page faults)
            for (size_t k = 0; k < bs.size(); ++k) { h2d[k].clear(); d2h[k].clear(); e2e[k].clear(); ev[k].clear(); }
            for (int i = 0; i < reps; ++i)
                for (size_t k = 0; k < bs.size(); ++k) {
                    Result r = bs[k].f();
                    ts[k].push_back(r.seconds);
                    ok0[k] = ok0[k] && eq(ref, r);
                    ok5[k] = ok5[k] && eq(ref5, r);
                }
            const Stats s0 = stats(ts[0]);
            Stats s5{0, 0, 0, 0};
            if (k5 != (size_t)-1) s5 = stats(ts[k5]);
            for (size_t k = 0; k < bs.size(); ++k) {
                const Stats sk = stats(ts[k]);
                const bool gp = bs[k].is_v6 || k == k5;
                const Stats se = gp ? stats(e2e[k]) : sk;
                printf("%s,%u,%s,%s,%.5f,%.5f,%.5f,%.1f,%.5f,%.1f,%.5f,%.5f,%.5f,%.2f,%s,%.2f,%s,%s\n", sc.name, n,
                       bs[k].name.c_str(), bs[k].opts.c_str(), sk.med, sk.mn, sk.mx, sk.cv, se.med, se.cv,
                       gp ? stats(h2d[k]).med : 0.0, gp ? stats(d2h[k]).med : 0.0, gp ? stats(ev[k]).med : 0.0,
                       s0.med / sk.med,
                       (gp && s5.med > 0) ? (std::to_string(s5.med / sk.med).substr(0, 5)).c_str() : "n/a",
                       s0.med / se.med, ok0[k] ? "yes" : "NO",
                       k5 == (size_t)-1 ? "n/a" : (ok5[k] ? "yes" : "NO"));
                if (!ok0[k] || (k5 != (size_t)-1 && !ok5[k])) ++bad;
            }
            fflush(stdout);
            if (pf)
                for (const Row& r : v6rows) {  // separate profiling pass (3 reps, median), not part of the timings above
                    std::vector<double> lm, sm;
                    for (int i = 0; i < 3; ++i) {
                        V6Config c; c.opts = r.second; c.profile = true;
                        V6Result pr = run_simulation_v6(p, c);
                        lm.push_back(pr.prof_loc_ms); sm.push_back(pr.prof_step_ms);
                    }
                    const double l = stats(lm).med, s = stats(sm).med;
                    fprintf(pf, "%s,%u,%s,%s,%.4f,%.4f,%.1f\n", sc.name, n, r.first.c_str(), v6_describe(r.second).c_str(),
                            l, s, l + s > 0 ? 100 * l / (l + s) : 0.0);
                    fflush(pf);
                }
        }
    if (pf) fclose(pf);
    if (bad) { fprintf(stderr, "bench_v6: %d row(s) not identical to the reference\n", bad); return 1; }
    return 0;
}
