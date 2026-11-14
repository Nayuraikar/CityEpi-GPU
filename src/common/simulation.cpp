#include <chrono>
#include <limits>
#include <stdexcept>
#include <string>
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

void make_synthetic_input(const Params& p, Population& pop, Locations& locs) {
    generate_synthetic(p, pop, locs);
    seed_infections(p, pop);
}

void validate_input(const Population& pop, const Locations& locs) {
    auto fail = [](const std::string& m) { throw std::invalid_argument("external population: " + m); };
    const size_t n = pop.state.size(), nl = locs.type.size();
    if (n == 0) fail("no agents");
    if (pop.timer.size() != n || pop.home_loc.size() != n || pop.work_loc.size() != n)
        fail("state/timer/home_loc/work_loc sizes differ (" + std::to_string(n) + "/" + std::to_string(pop.timer.size()) +
             "/" + std::to_string(pop.home_loc.size()) + "/" + std::to_string(pop.work_loc.size()) + ")");
    if (nl == 0) fail("no locations");
    if (locs.occupancy.size() != nl)
        fail("locations type/occupancy sizes differ (" + std::to_string(nl) + "/" + std::to_string(locs.occupancy.size()) + ")");
    if (n > std::numeric_limits<uint32_t>::max() || nl > std::numeric_limits<uint32_t>::max())
        fail("agent or location count exceeds uint32 ids");
    for (size_t l = 0; l < nl; ++l)
        if (locs.type[l] != LOC_HOME && locs.type[l] != LOC_WORK)
            fail("location " + std::to_string(l) + " has invalid type " + std::to_string(locs.type[l]));
    std::vector<uint32_t> occ(nl, 0);
    for (size_t a = 0; a < n; ++a) {
        const std::string who = "agent " + std::to_string(a) + ": ";
        if (pop.state[a] > R) fail(who + "invalid state " + std::to_string(pop.state[a]));
        if ((pop.state[a] == E || pop.state[a] == I) && pop.timer[a] == 0) fail(who + "E/I agent with timer 0");
        const uint32_t h = pop.home_loc[a], w = pop.work_loc[a];
        if (h >= nl) fail(who + "home_loc " + std::to_string(h) + " out of range (" + std::to_string(nl) + " locations)");
        if (w >= nl) fail(who + "work_loc " + std::to_string(w) + " out of range (" + std::to_string(nl) + " locations)");
        if (locs.type[h] != LOC_HOME) fail(who + "home_loc " + std::to_string(h) + " is not a HOME location");
        if (locs.type[w] != LOC_WORK) fail(who + "work_loc " + std::to_string(w) + " is not a WORK location");
        ++occ[h];
        ++occ[w];
    }
    for (size_t l = 0; l < nl; ++l)
        if (occ[l] != locs.occupancy[l])
            fail("location " + std::to_string(l) + " occupancy " + std::to_string(locs.occupancy[l]) +
                 " != agents assigned " + std::to_string(occ[l]));
}

void make_external_input(const Population& in_pop, const Locations& in_locs, Population& pop, Locations& locs) {
    validate_input(in_pop, in_locs);
    pop = in_pop;
    locs = in_locs;
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

static Result run_v0_impl(const Params& p0, Population pop, Locations locs) {
    Params p = p0;
    if (p.incubation_days < 1) p.incubation_days = 1;
    if (p.infectious_days < 1) p.infectious_days = 1;
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

Result run_simulation(const Params& p) {
    Params q = p;  // clamp before generating, as before (seed_infections uses infectious_days)
    if (q.incubation_days < 1) q.incubation_days = 1;
    if (q.infectious_days < 1) q.infectious_days = 1;
    Population pop;
    Locations locs;
    make_synthetic_input(q, pop, locs);
    return run_v0_impl(q, std::move(pop), std::move(locs));
}

Result run_simulation(const Params& p, const Population& in_pop, const Locations& in_locs) {
    Population pop;
    Locations locs;
    make_external_input(in_pop, in_locs, pop, locs);
    return run_v0_impl(p, std::move(pop), std::move(locs));
}
