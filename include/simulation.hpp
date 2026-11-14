#pragma once
#include <vector>
#include "agent.hpp"
#include "parameters.hpp"

struct Result {
    std::vector<Counts> daily;  // index 0 = initial state, then one per day
    double seconds = 0;
};

// Synthetic setup (homes ids [0,n_homes), works [n_homes, n_homes+n_works)).
void generate_synthetic(const Params& p, Population& pop, Locations& locs);
void seed_infections(const Params& p, Population& pop);

// Phase 1 (contact.cpp): from start-of-day state, flag susceptibles newly exposed. Does not modify pop.
void compute_exposure(const Params& p, const Population& pop, const Locations& locs,
                      uint32_t day, std::vector<uint8_t>& newly_exposed);
// Phase 2 (transitions.cpp): advance E/I timers, apply staged S->E.
void apply_transitions(const Params& p, Population& pop, const std::vector<uint8_t>& newly_exposed);

Counts count_states(const Population& pop);  // throws if S+E+I+R != N
void step(const Params& p, Population& pop, const Locations& locs, uint32_t day,
          std::vector<uint8_t>& scratch);
Result run_simulation(const Params& p);
