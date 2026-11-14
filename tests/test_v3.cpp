#include <cstdio>
#include "v1_simulation.hpp"
#include "v2_simulation.hpp"
#include "v3_simulation.hpp"
#include "v3_hybrid.hpp"

static int fails = 0, runs = 0;
#define CHECK(c) do { if (!(c)) { printf("FAIL %s:%d %s\n", __FILE__, __LINE__, #c); ++fails; } } while (0)

static bool eq(const Result& a, const Result& b) {
    if (a.daily.size() != b.daily.size()) return false;
    for (size_t i = 0; i < a.daily.size(); ++i) if (!(a.daily[i] == b.daily[i])) return false;
    return true;
}

// V3 (SIMD and scalar fallback) must match V0, V1 and V2 exactly; population conserved every day.
static void cmp(const Params& p, const char* tag) {
    Result r0 = run_simulation(p), r1 = run_simulation_v1(p), r2 = run_simulation_v2(p);
    Result v3 = run_simulation_v3(p, true), v3s = run_simulation_v3(p, false);
    Result hy = run_simulation_v3_hybrid(p, true), hys = run_simulation_v3_hybrid(p, false);
    ++runs;
    if (!eq(r0, v3) || !eq(r1, v3) || !eq(r2, v3) || !eq(r0, v3s) ||
        !eq(r0, hy) || !eq(r1, hy) || !eq(r2, hy) || !eq(r0, hys)) {
        printf("MISMATCH %s n=%u seed=%llu\n", tag, p.n_agents, (unsigned long long)p.seed); ++fails;
    }
    for (const Counts& c : v3.daily) CHECK(c.s + c.e + c.i + c.r == p.n_agents);
    for (const Counts& c : hy.daily) CHECK(c.s + c.e + c.i + c.r == p.n_agents);
    if (p.beta_home == 0 && p.beta_work == 0) {  // zero transmission: nobody new gets exposed
        CHECK(v3.daily.back().s + p.initial_infected >= p.n_agents || p.initial_infected >= p.n_agents);
        CHECK(v3.daily.back().s == v3.daily.front().s);
        CHECK(hy.daily.back().s == hy.daily.front().s);
    }
}

int main() {
    printf("NEON %s\n", v3_neon_enabled() ? "ON" : "OFF (scalar fallback only)");
    // sizes straddle the 16-agent block: 1, <16, ==16, tails, odd susceptible counts
    for (uint64_t s : {1ull, 42ull, 7ull})
        for (uint32_t n : {1u, 2u, 15u, 16u, 17u, 31u, 32u, 33u, 100u, 5000u, 30001u})
            for (double beta : {0.0, 0.3, 2.0, 1e6}) {
                Params p; p.n_agents = n; p.n_homes = n / 5 + 1; p.n_works = n / 50 + 1; p.days = 40;
                p.seed = s; p.beta_home = p.beta_work = beta; p.initial_infected = n / 50 + 1;
                cmp(p, "sweep");
            }
    // timer transitions: durations 1 (immediate E->I->R), long, and asymmetric betas; zero/all infected
    for (uint16_t inc : {1, 2, 6}) for (uint16_t idur : {1, 3, 9}) {
        Params p; p.n_agents = 3001; p.n_homes = 700; p.n_works = 40; p.days = 80; p.beta_home = 0.1; p.beta_work = 0.6;
        p.incubation_days = inc; p.infectious_days = idur; cmp(p, "timers");
        p.initial_infected = 0; cmp(p, "no-initial");
        p.initial_infected = p.n_agents; cmp(p, "all-infected");
    }
    { Params p; p.n_agents = 4000; p.n_homes = 800; p.n_works = 80; p.days = 60; p.incubation_days = 0; p.infectious_days = 0;
      cmp(p, "zero-durations(clamped)"); }
    { Params p; p.n_agents = 4000; p.n_homes = 800; p.n_works = 80; p.days = 60; p.beta_home = 0; p.beta_work = 0.5; cmp(p, "home-off");
      p.beta_home = 0.5; p.beta_work = 0; cmp(p, "work-off"); }
    // determinism: repeated runs identical
    { Params p; p.n_agents = 20000; p.n_homes = 4000; p.n_works = 400; p.days = 60; p.initial_infected = 20;
      Result a = run_simulation_v3(p);
      for (int i = 0; i < 5; ++i) CHECK(eq(a, run_simulation_v3(p)));
      Result h = run_simulation_v3_hybrid(p);
      for (int i = 0; i < 5; ++i) CHECK(eq(h, run_simulation_v3_hybrid(p))); }
    printf("%d V3 (NEON+scalar+hybrid) comparisons; %s\n", runs, fails ? "V3 FAILED" : "V3 OK");
    return fails != 0;
}
