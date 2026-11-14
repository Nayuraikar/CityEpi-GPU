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

// ---- Population input shared by V0-V6 -------------------------------------------------------
// Every backend runs on a (Population, Locations) pair. By default it is synthetic; an externally built
// pair (e.g. a geographic population) can be passed to the `run_simulation*(p, pop, locs, ...)` overloads.
// External input is used AS SUPPLIED (state/timer are not re-seeded; call seed_infections yourself if you
// want seeded infections). Params::n_agents/n_homes/n_works/initial_infected are ignored for it.
//
// Throws std::invalid_argument unless: pop arrays share one non-zero size; locs.type/occupancy share one
// non-zero size; both fit uint32 ids; state in {S,E,I,R}; timer >= 1 for E/I agents; type in {HOME,WORK};
// home_loc/work_loc in range and pointing at HOME/WORK locations; occupancy[l] == agents referencing l.
void validate_input(const Population& pop, const Locations& locs);
// generate_synthetic + seed_infections (exactly what every backend did before external input existed).
void make_synthetic_input(const Params& p, Population& pop, Locations& locs);
// validate_input, then copy into the working pair a backend mutates.
void make_external_input(const Population& in_pop, const Locations& in_locs, Population& pop, Locations& locs);

// Phase 1 (contact.cpp): from start-of-day state, flag susceptibles newly exposed. Does not modify pop.
void compute_exposure(const Params& p, const Population& pop, const Locations& locs,
                      uint32_t day, std::vector<uint8_t>& newly_exposed);
// Phase 2 (transitions.cpp): advance E/I timers, apply staged S->E.
void apply_transitions(const Params& p, Population& pop, const std::vector<uint8_t>& newly_exposed);

Counts count_states(const Population& pop);  // throws if S+E+I+R != N
void step(const Params& p, Population& pop, const Locations& locs, uint32_t day,
          std::vector<uint8_t>& scratch);
Result run_simulation(const Params& p);
Result run_simulation(const Params& p, const Population& pop, const Locations& locs);  // external input
