#include <chrono>
#include <stdexcept>
#include "rng.hpp"
#include "simulation.hpp"

void generate_synthetic(const Params& p, Population& pop, Locations& locs) {
    const size_t n = p.n_agents;
    if (n == 0 || p.n_homes == 0 || p.n_works == 0) throw std::invalid_argument("empty population/locations");
    pop.state.assign(n, S);
    pop.timer.assign(n, 0);
    pop.home_loc.resize(n);
    pop.work_loc.resize(n);
    locs.type.assign(p.n_homes + p.n_works, LOC_HOME);
    for (uint32_t w = 0; w < p.n_works; ++w) locs.type[p.n_homes + w] = LOC_WORK;
    locs.occupancy.assign(locs.type.size(), 0);
    for (size_t a = 0; a < n; ++a) {
        uint32_t h = (uint32_t)(rand01(p.seed, (uint32_t)a, 0, SLOT_ASSIGN_HOME) * p.n_homes);
        uint32_t w = p.n_homes + (uint32_t)(rand01(p.seed, (uint32_t)a, 0, SLOT_ASSIGN_WORK) * p.n_works);
        pop.home_loc[a] = h;
        pop.work_loc[a] = w;
        ++locs.occupancy[h];
        ++locs.occupancy[w];
    }
}

void seed_infections(const Params& p, Population& pop) {  // exactly k, via selection sampling
    const uint32_t n = (uint32_t)pop.size();
    uint32_t need = p.initial_infected < n ? p.initial_infected : n;
    for (uint32_t a = 0; a < n && need > 0; ++a)
        if (rand01(p.seed, a, 0, SLOT_INIT) * (n - a) < need) {
            pop.state[a] = I;
            pop.timer[a] = at_least1(p.infectious_days);
            --need;
        }
}

Counts count_states(const Population& pop) {
    Counts c;
    for (uint8_t s : pop.state) {
        switch (s) { case S: ++c.s; break; case E: ++c.e; break; case I: ++c.i; break; default: ++c.r; }
    }
    if (c.s + c.e + c.i + c.r != pop.size()) throw std::runtime_error("population not conserved");
    return c;
}

void step(const Params& p, Population& pop, const Locations& locs, uint32_t day,
          std::vector<uint8_t>& scratch) {
    compute_exposure(p, pop, locs, day, scratch);
    apply_transitions(p, pop, scratch);
}

Result run_simulation(const Params& p0) {
    Params p = p0;
    if (p.incubation_days < 1) p.incubation_days = 1;
    if (p.infectious_days < 1) p.infectious_days = 1;
    Population pop;
    Locations locs;
    generate_synthetic(p, pop, locs);
    seed_infections(p, pop);
    Result r;
    r.daily.push_back(count_states(pop));
    std::vector<uint8_t> scratch;
    auto t0 = std::chrono::steady_clock::now();
    for (uint32_t d = 0; d < p.days; ++d) {
        step(p, pop, locs, d, scratch);
        r.daily.push_back(count_states(pop));
    }
    r.seconds = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
    return r;
}
