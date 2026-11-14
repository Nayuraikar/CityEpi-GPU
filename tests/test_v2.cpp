#include <cstdio>
#include "v1_simulation.hpp"
#include "v2_simulation.hpp"

static int fails = 0, runs = 0;
#define CHECK(c) do { if (!(c)) { printf("FAIL %s:%d %s\n", __FILE__, __LINE__, #c); ++fails; } } while (0)

static bool eq(const Result& a, const Result& b) {
    if (a.daily.size() != b.daily.size()) return false;
    for (size_t i = 0; i < a.daily.size(); ++i) if (!(a.daily[i] == b.daily[i])) return false;
    return true;
}

// V0 and V1 computed once; every V2 config (threads x schedule x reduction [x chunk]) must match both.
static void all_cfgs(const Params& p, bool chunks) {
    Result r0 = run_simulation(p), r1 = run_simulation_v1(p);
    CHECK(eq(r0, r1));
    for (int t : {1, 2, 3, 4, 8})
        for (Sched s : {Sched::Static, Sched::Dynamic, Sched::Guided})
            for (Reduce rd : {Reduce::Local, Reduce::Atomic})
                for (int ch : chunks ? std::initializer_list<int>{0, 1, 7, 64} : std::initializer_list<int>{0}) {
                    V2Config c; c.threads = t; c.sched = s; c.reduce = rd; c.chunk = ch;
                    V2Result r2 = run_simulation_v2(p, c);
                    ++runs;
                    if (!eq(r0, r2)) { printf("MISMATCH t=%d sched=%d red=%d chunk=%d n=%u\n", t, (int)s, (int)rd, ch, p.n_agents); ++fails; }
                }
}

int main() {
    printf("OpenMP %s, max threads %d\n", v2_openmp_enabled() ? "ON" : "OFF", v2_max_threads());
    for (uint64_t s : {1ull, 42ull})
        for (uint32_t n : {1u, 17u, 5000u, 30000u})
            for (double beta : {0.0, 0.3, 2.0, 1e6}) {
                Params p; p.n_agents = n; p.n_homes = n / 5 + 1; p.n_works = n / 50 + 1; p.days = 40;
                p.seed = s; p.beta_home = p.beta_work = beta; p.initial_infected = n / 50 + 1;
                all_cfgs(p, n == 5000);
            }
    { Params p; p.n_agents = 3000; p.n_homes = 700; p.n_works = 40; p.days = 80; p.beta_home = 0.1; p.beta_work = 0.6;
      p.incubation_days = 1; p.infectious_days = 1; all_cfgs(p, false);
      p.incubation_days = 6; p.infectious_days = 9; all_cfgs(p, false);
      p.initial_infected = 0; all_cfgs(p, false); }
    // determinism: repeated runs with many threads are identical
    { Params p; p.n_agents = 20000; p.n_homes = 4000; p.n_works = 400; p.days = 60; p.initial_infected = 20;
      V2Config c; c.threads = 8; c.sched = Sched::Dynamic; c.chunk = 16;
      Result a = run_simulation_v2(p, c);
      for (int i = 0; i < 5; ++i) CHECK(eq(a, run_simulation_v2(p, c))); }
    printf("%d V2 runs; %s\n", runs, fails ? "V2 FAILED" : "V2 OK");
    return fails != 0;
}
