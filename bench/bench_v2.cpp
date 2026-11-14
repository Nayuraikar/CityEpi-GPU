// V0/V1/V2 benchmark. Timing identical to bench.cpp: warm-up, reps, median of Result::seconds
// (kernel loop only; setup excluded). Same Params/seed for every backend.
#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>
#include "v1_simulation.hpp"
#include "v2_simulation.hpp"

static double med(std::vector<double> v) { std::sort(v.begin(), v.end()); return v[v.size() / 2]; }
static bool eq(const Result& a, const Result& b) {
    if (a.daily.size() != b.daily.size()) return false;
    for (size_t i = 0; i < a.daily.size(); ++i) if (!(a.daily[i] == b.daily[i])) return false;
    return true;
}
static const char* sn(Sched s) { return s == Sched::Static ? "static" : s == Sched::Dynamic ? "dynamic" : "guided"; }

int main(int argc, char** argv) {
    const int reps = argc > 1 ? atoi(argv[1]) : 7;
    std::vector<uint32_t> sizes = {10000, 50000, 100000, 500000, 1000000};
    if (argc > 2) { sizes.clear(); for (int i = 2; i < argc; ++i) sizes.push_back((uint32_t)atoi(argv[i])); }
    const int hw = v2_max_threads();
    std::vector<int> tl = {1, 2, 4};
    if (hw > 4) tl.push_back(hw);
    printf("# openmp=%d max_threads=%d reps=%d days=100 dynamic/guided chunk: dyn=1024 guided=default\n",
           (int)v2_openmp_enabled(), hw, reps);
    printf("agents,backend,threads,sched,reduce,chunk,median_s,speedup_v0,speedup_v1,speedup_v2_t1,efficiency,hist_MB,identical\n");
    for (uint32_t n : sizes) {
        Params p; p.n_agents = n; p.n_homes = n / 5; p.n_works = n / 50; p.days = 100; p.initial_infected = n / 1000;
        const int R = n >= 500000 ? std::min(reps, 5) : reps;
        run_simulation(p); run_simulation_v1(p);
        std::vector<double> t0, t1; Result ref;
        for (int i = 0; i < R; ++i) { ref = run_simulation(p); t0.push_back(ref.seconds); t1.push_back(run_simulation_v1(p).seconds); }
        const double m0 = med(t0), m1 = med(t1);
        printf("%u,V0,1,-,-,-,%.5f,1.00,%.2f,-,-,0,yes\n", n, m0, m1 / m0);
        printf("%u,V1,1,-,-,-,%.5f,%.2f,1.00,-,-,0,yes\n", n, m1, m0 / m1);
        struct Cfg { Sched s; Reduce r; int chunk; };
        const Cfg cfgs[] = {{Sched::Static, Reduce::Local, 0}, {Sched::Dynamic, Reduce::Local, 1024},
                            {Sched::Guided, Reduce::Local, 0}, {Sched::Static, Reduce::Atomic, 0}};
        std::vector<double> base(4, 0);
        for (int t : tl)
            for (size_t ci = 0; ci < 4; ++ci) {
                V2Config c; c.threads = t; c.sched = cfgs[ci].s; c.reduce = cfgs[ci].r; c.chunk = cfgs[ci].chunk;
                run_simulation_v2(p, c);
                std::vector<double> ts; bool ok = true; size_t hb = 0;
                for (int i = 0; i < R; ++i) { V2Result r = run_simulation_v2(p, c); ts.push_back(r.seconds); ok &= eq(ref, r); hb = r.hist_bytes; }
                const double m = med(ts);
                if (t == 1) base[ci] = m;
                printf("%u,V2,%d,%s,%s,%d,%.5f,%.2f,%.2f,%.2f,%.2f,%.2f,%s\n", n, t, sn(c.sched),
                       c.reduce == Reduce::Local ? "local" : "atomic", c.chunk, m, m0 / m, m1 / m, base[ci] / m,
                       base[ci] / m / t, hb / 1048576.0, ok ? "yes" : "NO");
                fflush(stdout);
            }
    }
}
