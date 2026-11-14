// External population input (V0-V3 + hybrid; V4-V6 are covered inside test_v4/test_v5/test_v6).
// Proves: (1) an externally supplied pair equals the synthetic path bit-for-bit when it holds the same data,
// (2) hand-built non-synthetic layouts run identically on every backend, (3) input is not mutated,
// (4) shared validation rejects each malformed input, (5) existing synthetic APIs are unchanged.
#include <cstdio>
#include "external_input_common.hpp"
#include "v1_simulation.hpp"
#include "v2_simulation.hpp"
#include "v3_hybrid.hpp"
#include "v3_simulation.hpp"

static int fails = 0;
#define CHECK(c) do { if (!(c)) { printf("FAIL %s:%d %s\n", __FILE__, __LINE__, #c); ++fails; } } while (0)
using extin::daily_equal;
using extin::throws_invalid;

static void all_backends_equal(const Params& p, const Population& pop, const Locations& locs, const char* tag) {
    Result v0 = run_simulation(p, pop, locs);
    bool ok = daily_equal(v0, run_simulation_v1(p, pop, locs)) &&
              daily_equal(v0, run_simulation_v2(p, pop, locs)) &&
              daily_equal(v0, run_simulation_v3(p, pop, locs, false)) &&
              daily_equal(v0, run_simulation_v3(p, pop, locs, true)) &&
              daily_equal(v0, run_simulation_v3_hybrid(p, pop, locs, false)) &&
              daily_equal(v0, run_simulation_v3_hybrid(p, pop, locs, true));
    if (!ok) printf("MISMATCH across backends: %s\n", tag);
    CHECK(ok);
    for (const Counts& c : v0.daily) CHECK(c.s + c.e + c.i + c.r == pop.size());
}

int main() {
    // (1) synthetic data passed as external == synthetic path, for every backend
    for (uint64_t seed : {1ull, 42ull, 99ull})
        for (double beta : {0.0, 0.3, 2.0}) {
            Params p; p.n_agents = 4000; p.n_homes = 800; p.n_works = 80; p.days = 40; p.seed = seed;
            p.beta_home = p.beta_work = beta; p.initial_infected = 30;
            Population pop; Locations locs; make_synthetic_input(p, pop, locs);
            Population pop0; Locations locs0; generate_synthetic(p, pop0, locs0); seed_infections(p, pop0);
            CHECK(pop.state == pop0.state && pop.timer == pop0.timer && pop.home_loc == pop0.home_loc &&
                  pop.work_loc == pop0.work_loc && locs.type == locs0.type && locs.occupancy == locs0.occupancy);
            CHECK(daily_equal(run_simulation(p), run_simulation(p, pop, locs)));
            CHECK(daily_equal(run_simulation_v1(p), run_simulation_v1(p, pop, locs)));
            CHECK(daily_equal(run_simulation_v2(p), run_simulation_v2(p, pop, locs)));
            CHECK(daily_equal(run_simulation_v3(p), run_simulation_v3(p, pop, locs)));
            CHECK(daily_equal(run_simulation_v3_hybrid(p), run_simulation_v3_hybrid(p, pop, locs)));
            all_backends_equal(p, pop, locs, "synthetic-as-external");
        }
    // synthetic params with out-of-range-ish values still behave as before (incubation/infectious 0 clamp)
    { Params p; p.n_agents = 3000; p.n_homes = 700; p.n_works = 40; p.days = 50; p.incubation_days = 0; p.infectious_days = 0;
      Population pop; Locations locs; make_synthetic_input(p, pop, locs);
      CHECK(daily_equal(run_simulation(p), run_simulation(p, pop, locs)));
      CHECK(daily_equal(run_simulation_v1(p), run_simulation_v1(p, pop, locs))); }

    // (2) hand-built non-synthetic layout: identical on all backends, and mismatching Params sizes are ignored
    for (double beta : {0.0, 0.5, 5.0}) {
        Params p; p.days = 30; p.beta_home = p.beta_work = beta; p.n_agents = 999999; p.n_homes = 1; p.n_works = 1;
        Population pop; Locations locs; extin::handmade(pop, locs);
        all_backends_equal(p, pop, locs, "handmade");
        Result r = run_simulation(p, pop, locs);
        CHECK(r.daily.size() == 31);
        CHECK((r.daily[0] == Counts{9, 1, 1, 1}));
        if (beta == 0.0) {  // no transmission: E(2d)->I, I(4d)->R, seeded I(4d)->R, nothing else moves
            CHECK((r.daily.back() == Counts{9, 0, 0, 3}));
            CHECK((r.daily[1] == Counts{9, 1, 1, 1}));  // E timer 2->1, I timer 4->3
            CHECK((r.daily[2] == Counts{9, 0, 2, 1}));  // E->I
        }
    }
    // all-susceptible external population with no seeding stays untouched
    { Params p; p.days = 20; Population pop; Locations locs; extin::handmade(pop, locs);
      pop.state.assign(12, S); pop.timer.assign(12, 0);
      Result r = run_simulation(p, pop, locs); CHECK((r.daily.back() == Counts{12, 0, 0, 0}));
      // caller-side seeding through the public API
      p.initial_infected = 3; seed_infections(p, pop); CHECK(count_states(pop).i == 3);
      all_backends_equal(p, pop, locs, "handmade-seeded"); }

    // (3) input is not mutated by any backend
    { Params p; p.days = 25; Population pop; Locations locs; extin::handmade(pop, locs);
      Population pc = pop; Locations lc = locs;
      run_simulation(p, pop, locs); run_simulation_v1(p, pop, locs); run_simulation_v2(p, pop, locs);
      run_simulation_v3(p, pop, locs); run_simulation_v3_hybrid(p, pop, locs);
      CHECK(pop.state == pc.state && pop.timer == pc.timer && pop.home_loc == pc.home_loc && pop.work_loc == pc.work_loc);
      CHECK(locs.type == lc.type && locs.occupancy == lc.occupancy); }

    // (4) validation
    { Population pop; Locations locs; extin::handmade(pop, locs);
      validate_input(pop, locs);  // good input passes
      auto bad = [&](const char* what, auto mutate) {
          Population p2 = pop; Locations l2 = locs; mutate(p2, l2);
          bool t = throws_invalid([&] { validate_input(p2, l2); }) &&
                   throws_invalid([&] { make_external_input(p2, l2, p2, l2); });
          Params p; p.days = 3;
          t = t && throws_invalid([&] { run_simulation(p, p2, l2); }) && throws_invalid([&] { run_simulation_v1(p, p2, l2); }) &&
              throws_invalid([&] { run_simulation_v2(p, p2, l2); }) && throws_invalid([&] { run_simulation_v3(p, p2, l2); }) &&
              throws_invalid([&] { run_simulation_v3_hybrid(p, p2, l2); });
          if (!t) printf("validation did not reject: %s\n", what);
          CHECK(t);
      };
      bad("empty population", [](Population& p, Locations&) { p = Population(); });
      bad("no locations", [](Population&, Locations& l) { l = Locations(); });
      bad("timer size", [](Population& p, Locations&) { p.timer.pop_back(); });
      bad("home size", [](Population& p, Locations&) { p.home_loc.pop_back(); });
      bad("work size", [](Population& p, Locations&) { p.work_loc.push_back(0); });
      bad("occupancy size", [](Population&, Locations& l) { l.occupancy.pop_back(); });
      bad("state value", [](Population& p, Locations&) { p.state[3] = 4; });
      bad("E with timer 0", [](Population& p, Locations&) { p.state[2] = E; p.timer[2] = 0; });
      bad("I with timer 0", [](Population& p, Locations&) { p.timer[0] = 0; });
      bad("home out of range", [](Population& p, Locations&) { p.home_loc[4] = 7; });
      bad("work out of range", [](Population& p, Locations&) { p.work_loc[4] = 0xFFFFFFFFu; });
      bad("home points at WORK", [](Population& p, Locations&) { p.home_loc[4] = 0; });
      bad("work points at HOME", [](Population& p, Locations&) { p.work_loc[4] = 1; });
      bad("bad location type", [](Population&, Locations& l) { l.type[2] = 2; });
      bad("occupancy too high", [](Population&, Locations& l) { ++l.occupancy[1]; });
      bad("occupancy too low", [](Population&, Locations& l) { --l.occupancy[3]; });
      bad("unused location with occupancy", [](Population&, Locations& l) { l.occupancy[5] = 1; });
      // an unreferenced location with occupancy 0 is legal
      { Population p2 = pop; Locations l2 = locs; l2.type.push_back(LOC_HOME); l2.occupancy.push_back(0); validate_input(p2, l2); }
    }

    // (5) existing behavior preserved: invalid synthetic params still throw
    { Params p; p.n_agents = 0; CHECK(throws_invalid([&] { run_simulation(p); })); CHECK(throws_invalid([&] { run_simulation_v1(p); }));
      CHECK(throws_invalid([&] { run_simulation_v2(p); })); CHECK(throws_invalid([&] { run_simulation_v3(p); }));
      CHECK(throws_invalid([&] { run_simulation_v3_hybrid(p); })); }

    printf(fails ? "EXTERNAL INPUT FAILED\n" : "EXTERNAL INPUT OK\n");
    return fails != 0;
}
