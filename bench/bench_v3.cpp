// V0/V1/V2/V3 benchmark in one executable: same compiler/flags/Params/seed, warm-up, N reps,
// kernel-only time (Result::seconds, setup excluded). Every run is checked bit-identical to V0.
// Output CSV: median/min/max/CV (stdev/mean) per backend; speedups use medians.
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <functional>
#include <vector>
#include "v1_simulation.hpp"
#include "v2_simulation.hpp"
#include "v3_simulation.hpp"
#include "v3_hybrid.hpp"

static bool eq(const Result& a, const Result& b) {
    if (a.daily.size() != b.daily.size()) return false;
    for (size_t i = 0; i < a.daily.size(); ++i) if (!(a.daily[i] == b.daily[i])) return false;
    return true;
}

int main(int argc, char** argv) {
    const int reps = argc > 1 ? atoi(argv[1]) : 7;
    std::vector<uint32_t> sizes = {10000, 50000, 100000, 500000, 1000000};
    if (argc > 2) { sizes.clear(); for (int i = 2; i < argc; ++i) sizes.push_back((uint32_t)atoi(argv[i])); }
    const int hw = v2_max_threads();
    printf("# neon=%d openmp=%d max_threads=%d reps=%d days=100\n", (int)v3_neon_enabled(), (int)v2_openmp_enabled(), hw, reps);
    printf("agents,backend,median_s,min_s,max_s,cv_pct,speedup_v0,speedup_v1,identical\n");
    for (uint32_t n : sizes) {
        Params p; p.n_agents = n; p.n_homes = n / 5; p.n_works = n / 50; p.days = 100; p.initial_infected = n / 1000;
        Result ref = run_simulation(p);
        struct B { const char* name; std::function<Result()> f; };
        V2Config c1; c1.threads = 1; V2Config c4; c4.threads = std::min(4, hw);
        std::vector<B> bs = {
            {"V0", [&] { return run_simulation(p); }},
            {"V1", [&] { return run_simulation_v1(p); }},
            {"V2_1T", [&] { return (Result)run_simulation_v2(p, c1); }},
            {"V2_4T", [&] { return (Result)run_simulation_v2(p, c4); }},
            {"V3_scalar", [&] { return run_simulation_v3(p, false); }},
            {"V3_neon", [&] { return run_simulation_v3(p, true); }},
            {"V3_hybrid", [&] { return run_simulation_v3_hybrid(p, true); }},
            {"V3_hybrid_scalar", [&] { return run_simulation_v3_hybrid(p, false); }},
        };
        // interleave backends per repetition so thermal/frequency drift hits all equally
        std::vector<std::vector<double>> ts(bs.size());
        std::vector<bool> ok(bs.size(), true);
        for (auto& b : bs) b.f();  // warm-up
        for (int i = 0; i < reps; ++i)
            for (size_t k = 0; k < bs.size(); ++k) {
                Result r = bs[k].f();
                ts[k].push_back(r.seconds);
                ok[k] = ok[k] && eq(ref, r);
            }
        std::vector<double> med(bs.size());
        for (size_t k = 0; k < bs.size(); ++k) { auto v = ts[k]; std::sort(v.begin(), v.end()); med[k] = v[v.size() / 2]; }
        for (size_t k = 0; k < bs.size(); ++k) {
            double mean = 0, var = 0;
            for (double t : ts[k]) mean += t;
            mean /= ts[k].size();
            for (double t : ts[k]) var += (t - mean) * (t - mean);
            const double sd = ts[k].size() > 1 ? std::sqrt(var / (ts[k].size() - 1)) : 0;
            printf("%u,%s,%.5f,%.5f,%.5f,%.1f,%.2f,%.2f,%s\n", n, bs[k].name, med[k],
                   *std::min_element(ts[k].begin(), ts[k].end()), *std::max_element(ts[k].begin(), ts[k].end()),
                   100 * sd / mean, med[0] / med[k], med[1] / med[k], ok[k] ? "yes" : "NO");
        }
        fflush(stdout);
    }
}
