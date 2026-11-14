#include <cstdio>
#include <stdexcept>
#include "simulation.hpp"

static int fails = 0;
#define CHECK(c) do { if (!(c)) { printf("FAIL %s:%d %s\n", __FILE__, __LINE__, #c); ++fails; } } while (0)

static Params small() {
    Params p; p.n_agents = 5000; p.n_homes = 1000; p.n_works = 100; p.days = 40; p.initial_infected = 20;
    return p;
}

int main() {
    { Params p = small(); p.beta_home = p.beta_work = 0;  // zero transmission
      Result r = run_simulation(p);
      for (auto& c : r.daily) CHECK(c.e == 0);
      CHECK(r.daily.back().i == 0 && r.daily.back().r == 20 && r.daily.back().s == p.n_agents - 20); }
    { Params p = small(); p.initial_infected = 0;  // zero initial infections
      Result r = run_simulation(p);
      for (auto& c : r.daily) CHECK(c.s == p.n_agents); }
    { Params p = small(); Result a = run_simulation(p), b = run_simulation(p);  // reproducibility
      CHECK(a.daily.size() == b.daily.size());
      bool same = true; for (size_t i = 0; i < a.daily.size(); ++i) same &= a.daily[i] == b.daily[i];
      CHECK(same);
      CHECK(a.daily.back().r > 20);  // epidemic actually spreads
      CHECK(a.daily[0].i == 20);
      p.seed = 7; Result c = run_simulation(p);
      bool diff = false; for (size_t i = 0; i < a.daily.size(); ++i) diff |= !(a.daily[i] == c.daily[i]);
      CHECK(diff); }
    { Params p = small(); p.beta_home = p.beta_work = 1e6;  // staged transitions
      Population pop; Locations locs; generate_synthetic(p, pop, locs); seed_infections(p, pop);
      CHECK(locs.size() == p.n_homes + p.n_works);
      uint64_t occ = 0; for (auto o : locs.occupancy) occ += o; CHECK(occ == 2ull * p.n_agents);
      std::vector<uint8_t> scratch; step(p, pop, locs, 0, scratch);
      Counts c = count_states(pop);
      CHECK(c.i == 20 && c.e > 0 && c.s + c.e == p.n_agents - 20);  // new exposures not infectious same day
      for (uint32_t d = 1; d < p.incubation_days; ++d) step(p, pop, locs, d, scratch);
      for (size_t a = 0; a < pop.size(); ++a) if (pop.state[a] == E) CHECK(pop.timer[a] >= 1); }
    { Params p = small(); Population pop; pop.state = {E, I, I, S}; pop.timer = {1, 1, 2, 0};  // E->I, I->R
      std::vector<uint8_t> ne = {0, 0, 0, 1}; apply_transitions(p, pop, ne);
      CHECK(pop.state[0] == I && pop.timer[0] == p.infectious_days);
      CHECK(pop.state[1] == R); CHECK(pop.state[2] == I && pop.timer[2] == 1);
      CHECK(pop.state[3] == E && pop.timer[3] == p.incubation_days); }
    { Params p = small(); p.n_agents = 0;  // zero population
      bool threw = false; try { run_simulation(p); } catch (const std::invalid_argument&) { threw = true; }
      CHECK(threw); p = small(); p.n_works = 0; threw = false;
      try { run_simulation(p); } catch (const std::invalid_argument&) { threw = true; }
      CHECK(threw); }
    { Params p = small(); Population pop; Locations locs; generate_synthetic(p, pop, locs);  // per-phase occupancy
      uint64_t h = 0, w = 0;
      for (size_t l = 0; l < locs.size(); ++l) (locs.type[l] == LOC_HOME ? h : w) += locs.occupancy[l];
      CHECK(h == p.n_agents && w == p.n_agents);
      std::vector<uint32_t> hc(locs.size(), 0), wc(locs.size(), 0);
      for (size_t a = 0; a < pop.size(); ++a) {
        CHECK(locs.type[pop.home_loc[a]] == LOC_HOME && locs.type[pop.work_loc[a]] == LOC_WORK);
        ++hc[pop.home_loc[a]]; ++wc[pop.work_loc[a]]; }
      bool ok = true; for (size_t l = 0; l < locs.size(); ++l) ok &= (hc[l] + wc[l] == locs.occupancy[l]);
      CHECK(ok); }
    { Params p = small(); p.beta_home = p.beta_work = 1e6;  // empty location + identical home/work, no NaN/crash
      Population pop; pop.state = {I, S}; pop.timer = {5, 0}; pop.home_loc = {0, 0}; pop.work_loc = {0, 2};
      Locations locs; locs.type = {LOC_HOME, LOC_WORK, LOC_WORK}; locs.occupancy = {2, 0, 1};
      std::vector<uint8_t> ne; compute_exposure(p, pop, locs, 0, ne);
      CHECK(ne[0] == 0 && ne[1] == 1);  // susceptible shares home 0 with infectious agent
      pop.work_loc[1] = 1; pop.home_loc[1] = 2; locs.occupancy = {1, 0, 1};  // only empty/clean locs
      compute_exposure(p, pop, locs, 0, ne); CHECK(ne[1] == 0); }
    { Params p = small(); p.incubation_days = 1; p.infectious_days = 1; p.beta_home = p.beta_work = 1e6;  // min timers
      p.days = 60; Result r = run_simulation(p);
      CHECK(r.daily.back().s + r.daily.back().e + r.daily.back().i + r.daily.back().r == p.n_agents);
      Population pop; pop.state = {S}; pop.timer = {0}; std::vector<uint8_t> ne = {1};
      apply_transitions(p, pop, ne); CHECK(pop.state[0] == E && pop.timer[0] == 1);
      apply_transitions(p, pop, {0}); CHECK(pop.state[0] == I && pop.timer[0] == 1);
      apply_transitions(p, pop, {0}); CHECK(pop.state[0] == R);
      p.incubation_days = 0; pop.state = {S}; pop.timer = {0};  // zero durations clamped, no underflow
      apply_transitions(p, pop, ne); CHECK(pop.state[0] == E && pop.timer[0] == 1); }
    printf(fails ? "%d FAILED\n" : "all tests passed\n", fails);
    return fails != 0;
}
