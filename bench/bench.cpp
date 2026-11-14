#include <cstdlib>
#include <algorithm>
#include <cstdio>
#include <vector>
#include "v1_simulation.hpp"

static double med(std::vector<double> v) { std::sort(v.begin(), v.end()); return v[v.size() / 2]; }

int main(int argc, char** argv) {
    const int reps = argc > 1 ? atoi(argv[1]) : 7;
    printf("agents,v0_median_s,v1_median_s,speedup,identical\n");
    for (uint32_t n : {10000u, 50000u, 100000u, 500000u}) {
        Params p; p.n_agents = n; p.n_homes = n / 5; p.n_works = n / 50; p.days = 100; p.initial_infected = n / 1000;
        std::vector<double> t0, t1; bool ok = true;
        run_simulation(p); run_simulation_v1(p);  // warm-up
        for (int i = 0; i < reps; ++i) {
            Result a = run_simulation(p), b = run_simulation_v1(p);
            t0.push_back(a.seconds); t1.push_back(b.seconds);
            for (size_t k = 0; k < a.daily.size(); ++k) ok &= a.daily[k] == b.daily[k];
        }
        printf("%u,%.5f,%.5f,%.2f,%s\n", n, med(t0), med(t1), med(t0) / med(t1), ok ? "yes" : "NO");
    }
}
