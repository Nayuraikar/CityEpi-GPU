#include <cmath>
#include "rng.hpp"
#include "simulation.hpp"

void compute_exposure(const Params& p, const Population& pop, const Locations& locs,
                      uint32_t day, std::vector<uint8_t>& newly_exposed) {
    const size_t n = pop.size();
    std::vector<uint32_t> inf(locs.size(), 0);  // ids are disjoint, one array serves both phases
    for (size_t a = 0; a < n; ++a)
        if (pop.state[a] == I) { ++inf[pop.home_loc[a]]; ++inf[pop.work_loc[a]]; }

    newly_exposed.assign(n, 0);
    for (size_t a = 0; a < n; ++a) {
        if (pop.state[a] != S) continue;
        const uint32_t h = pop.home_loc[a], w = pop.work_loc[a];
        // p = 1 - exp(-beta * I/N); two independent draws == 1-(1-ph)(1-pw), no double count.
        const double ph = locs.occupancy[h] ? 1.0 - std::exp(-p.beta_home * inf[h] / locs.occupancy[h]) : 0.0;
        const double pw = locs.occupancy[w] ? 1.0 - std::exp(-p.beta_work * inf[w] / locs.occupancy[w]) : 0.0;
        const bool hit = rand01(p.seed, (uint32_t)a, day, SLOT_EXPOSE_HOME) < ph ||
                         rand01(p.seed, (uint32_t)a, day, SLOT_EXPOSE_WORK) < pw;
        newly_exposed[a] = hit;
    }
}
