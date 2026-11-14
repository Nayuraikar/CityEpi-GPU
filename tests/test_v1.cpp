#include <cstdio>
#include "rng_inline.hpp"
#include "v1_simulation.hpp"

static int fails = 0;
#define CHECK(c) do { if (!(c)) { printf("FAIL %s:%d %s\n", __FILE__, __LINE__, #c); ++fails; } } while (0)

static bool same(const Params& p) {
    Result a = run_simulation(p), b = run_simulation_v1(p);
    if (a.daily.size() != b.daily.size()) return false;
    for (size_t i = 0; i < a.daily.size(); ++i) if (!(a.daily[i] == b.daily[i])) return false;
    return true;
}

int main() {
    for (uint64_t s : {1ull, 42ull, 7ull, 123456789ull})
        for (uint32_t n : {1u, 17u, 5000u, 50000u})
            for (double beta : {0.0, 0.3, 2.0, 1e6}) {
                Params p; p.n_agents = n; p.n_homes = n / 5 + 1; p.n_works = n / 50 + 1; p.days = 60;
                p.seed = s; p.beta_home = p.beta_work = beta; p.initial_infected = n / 50 + 1;
                CHECK(same(p));
            }
    { Params p; p.n_agents = 3000; p.n_homes = 700; p.n_works = 40; p.days = 80; p.beta_home = 0.1; p.beta_work = 0.6;
      p.incubation_days = 1; p.infectious_days = 1; CHECK(same(p));
      p.incubation_days = 6; p.infectious_days = 9; CHECK(same(p));
      p.initial_infected = 0; CHECK(same(p)); }
    for (uint32_t a = 0; a < 2000; ++a)  // inlined RNG bit-identical to V0 rand01
        for (uint32_t slot : {3u, 4u}) {
            uint64_t ha = rng_inl::agent_stage(rng_inl::seed_stage(99), a);
            CHECK(rng_inl::draw(ha, a % 90, slot) == rand01(99, a, a % 90, slot));
        }
    printf(fails ? "V1 FAILED\n" : "V1 OK\n");
    return fails != 0;
}
