#include <cstdio>
#include <cstdlib>
#include <cstring>
#include "simulation.hpp"

int main(int argc, char** argv) {
    Params p;
    if (argc % 2 == 0) { fprintf(stderr, "option missing value\n"); return 1; }
    for (int i = 1; i + 1 < argc; i += 2) {
        const char *k = argv[i], *v = argv[i + 1];
        if (!strcmp(k, "--agents")) p.n_agents = atoi(v);
        else if (!strcmp(k, "--homes")) p.n_homes = atoi(v);
        else if (!strcmp(k, "--works")) p.n_works = atoi(v);
        else if (!strcmp(k, "--days")) p.days = atoi(v);
        else if (!strcmp(k, "--seed")) p.seed = strtoull(v, nullptr, 10);
        else if (!strcmp(k, "--beta-home")) p.beta_home = atof(v);
        else if (!strcmp(k, "--beta-work")) p.beta_work = atof(v);
        else if (!strcmp(k, "--incubation") || !strcmp(k, "--infectious")) {
            long d = atol(v);
            if (d < 1 || d > 65535) { fprintf(stderr, "%s must be in [1,65535]\n", k); return 1; }
            (k[3] == 'n' ? p.incubation_days : p.infectious_days) = (uint16_t)d;
        }
        else if (!strcmp(k, "--init")) p.initial_infected = atoi(v);
        else { fprintf(stderr, "unknown option %s\n", k); return 1; }
    }
    try {
        Result r = run_simulation(p);
        printf("day,S,E,I,R\n");
        for (size_t d = 0; d < r.daily.size(); ++d)
            printf("%zu,%u,%u,%u,%u\n", d, r.daily[d].s, r.daily[d].e, r.daily[d].i, r.daily[d].r);
        fprintf(stderr, "time_s=%.4f\n", r.seconds);
    } catch (const std::exception& e) { fprintf(stderr, "error: %s\n", e.what()); return 1; }
}
