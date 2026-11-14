// V4 (OpenACC) correctness vs V0-V3. Usage: test_v4 [--require-gpu]   (or CITYEPI_REQUIRE_GPU=1)
// Passing on host fallback proves semantics only; it says nothing about GPU execution. The execution
// mode is printed first, and --require-gpu fails the test unless regions really ran on a device.
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <stdexcept>
#include "v1_simulation.hpp"
#include "v2_simulation.hpp"
#include "v3_simulation.hpp"
#include "v3_hybrid.hpp"
#include "external_input_common.hpp"
#include "rng_inline.hpp"
#include "v4_rng.hpp"
#include "v4_simulation.hpp"

static int fails = 0, runs = 0;
#define CHECK(c) do { if (!(c)) { printf("FAIL %s:%d %s\n", __FILE__, __LINE__, #c); ++fails; } } while (0)

static bool eq(const Result& a, const Result& b) {
    if (a.daily.size() != b.daily.size()) return false;
    for (size_t i = 0; i < a.daily.size(); ++i) if (!(a.daily[i] == b.daily[i])) return false;
    return true;
}
static void report_diff(const Result& a, const Result& b) {
    for (size_t i = 0; i < a.daily.size() && i < b.daily.size(); ++i)
        if (!(a.daily[i] == b.daily[i])) {
            printf("  first divergence day %zu: V0 S/E/I/R=%u/%u/%u/%u  V4 %u/%u/%u/%u\n", i,
                   a.daily[i].s, a.daily[i].e, a.daily[i].i, a.daily[i].r,
                   b.daily[i].s, b.daily[i].e, b.daily[i].i, b.daily[i].r);
            return;
        }
    printf("  daily length differs: %zu vs %zu\n", a.daily.size(), b.daily.size());
}

static void cmp(const Params& p, const char* tag, bool all_backends = true) {
    Result r0 = run_simulation(p);
    V4Result v4 = run_simulation_v4(p);
    ++runs;
    if (!eq(r0, v4)) {
        printf("MISMATCH V0 vs V4 %s n=%u seed=%llu\n", tag, p.n_agents, (unsigned long long)p.seed);
        report_diff(r0, v4); ++fails;
    }
    if (all_backends) {
        Result r1 = run_simulation_v1(p), r2 = run_simulation_v2(p), r3 = run_simulation_v3(p, true),
               hy = run_simulation_v3_hybrid(p, true);
        if (!eq(r1, v4) || !eq(r2, v4) || !eq(r3, v4) || !eq(hy, v4)) {
            printf("MISMATCH V1/V2/V3/hybrid vs V4 %s n=%u seed=%llu\n", tag, p.n_agents, (unsigned long long)p.seed); ++fails;
        }
    }
    for (const Counts& c : v4.daily) CHECK(c.s + c.e + c.i + c.r == p.n_agents);
    CHECK(v4.daily.size() == (size_t)p.days + 1);
    CHECK(v4.seconds_total >= v4.seconds);
    if (p.beta_home == 0 && p.beta_work == 0) CHECK(v4.daily.back().s == v4.daily.front().s);
}

int main(int argc, char** argv) {
    bool require_gpu = getenv("CITYEPI_REQUIRE_GPU") != nullptr;
    for (int i = 1; i < argc; ++i) if (!strcmp(argv[i], "--require-gpu")) require_gpu = true;

    const V4Info info = v4_probe();
    printf("V4 execution mode : %s\n", v4_mode_name(info.mode));
    printf("compiler          : %s\n", info.compiler.c_str());
    printf("_OPENACC          : %d, non-host devices: %d\n", info.openacc_version, info.num_devices);
    if (info.mode == V4Mode::Device) printf("device            : %s (%s)\n", info.device_name.c_str(), info.device_vendor.c_str());
    else printf("NOTE: NOT running on a GPU; this validates semantics only.\n");

    // V4-private RNG must be bit-identical to rand01 / rng_inl
    {
        const uint64_t hs = rng_v4::seed_stage(42), hi = rng_inl::seed_stage(42);
        CHECK(hs == hi);
        for (uint32_t a = 0; a < 20000; ++a) {
            const uint64_t ha = rng_v4::agent_stage(hs, a);
            CHECK(ha == rng_inl::agent_stage(hi, a));
            for (uint32_t d : {0u, 1u, 99u}) for (uint32_t sl : {3u, 4u}) {
                const double u = rng_v4::draw(ha, d, sl);
                CHECK(u == rng_inl::draw(ha, d, sl));
                CHECK(u == rand01(42, a, d, sl));
            }
        }
    }
    // exception-path cleanup: no mapping may survive a failed run, and later runs stay correct
    {
        CHECK(v4_live_mappings() == 0);
        Params p; p.n_agents = 3000; p.n_homes = 600; p.n_works = 60; p.days = 20; p.initial_infected = 10;
        Result ref = run_simulation(p);
        for (uint32_t fail_day : {1u, 7u, 20u}) {
            V4Config c; c.inject_failure_after_day = fail_day; bool threw = false;
            try { run_simulation_v4(p, c); } catch (const std::runtime_error&) { threw = true; }
            CHECK(threw);
            CHECK(v4_live_mappings() == 0);
            CHECK(eq(ref, run_simulation_v4(p)));   // fresh run after a failed one is still exact
            CHECK(v4_live_mappings() == 0);
        }
        V4Config g; g.require_gpu = true;           // require-gpu rejection happens before any mapping
        if (info.mode != V4Mode::Device) {
            try { run_simulation_v4(p, g); } catch (const std::runtime_error&) {}
            CHECK(v4_live_mappings() == 0);
        }
    }
    // execution-mode guard: require_gpu must throw unless a device is really used
    {
        V4Config c; c.require_gpu = true; bool threw = false;
        Params p; p.n_agents = 100; p.n_homes = 20; p.n_works = 2; p.days = 2;
        try { run_simulation_v4(p, c); } catch (const std::runtime_error&) { threw = true; }
        CHECK(threw == (info.mode != V4Mode::Device));
    }
    if (require_gpu && info.mode != V4Mode::Device) { printf("FAIL: --require-gpu but mode is %s\n", v4_mode_name(info.mode)); return 1; }

    // sizes: tiny, odd, vector-width straddling, larger
    for (uint64_t s : {1ull, 42ull, 7ull})
        for (uint32_t n : {1u, 2u, 15u, 16u, 17u, 31u, 32u, 33u, 100u, 5000u, 30001u})
            for (double beta : {0.0, 0.3, 2.0, 1e6}) {
                Params p; p.n_agents = n; p.n_homes = n / 5 + 1; p.n_works = n / 50 + 1; p.days = 40;
                p.seed = s; p.beta_home = p.beta_work = beta; p.initial_infected = n / 50 + 1;
                cmp(p, "sweep");
            }
    // larger populations (V0-V3 still all compared)
    for (uint32_t n : {100000u, 1000000u}) {
        Params p; p.n_agents = n; p.n_homes = n / 5; p.n_works = n / 50; p.days = 30; p.initial_infected = n / 1000;
        cmp(p, "large");
    }
    // few locations => heavy atomic contention on the tally
    { Params p; p.n_agents = 50000; p.n_homes = 1; p.n_works = 1; p.days = 30; p.initial_infected = 50; cmp(p, "single-location"); }
    for (uint16_t inc : {1, 2, 6}) for (uint16_t idur : {1, 3, 9}) {
        Params p; p.n_agents = 3001; p.n_homes = 700; p.n_works = 40; p.days = 80; p.beta_home = 0.1; p.beta_work = 0.6;
        p.incubation_days = inc; p.infectious_days = idur; cmp(p, "timers");
        p.initial_infected = 0; cmp(p, "no-initial");
        p.initial_infected = p.n_agents; cmp(p, "all-infected");
    }
    { Params p; p.n_agents = 4000; p.n_homes = 800; p.n_works = 80; p.days = 60; p.incubation_days = 0; p.infectious_days = 0;
      cmp(p, "zero-durations(clamped)"); }
    { Params p; p.n_agents = 4000; p.n_homes = 800; p.n_works = 80; p.days = 0; cmp(p, "zero-days"); }
    { Params p; p.n_agents = 4000; p.n_homes = 800; p.n_works = 80; p.days = 60; p.beta_home = 0; p.beta_work = 0.5; cmp(p, "home-off");
      p.beta_home = 0.5; p.beta_work = 0; cmp(p, "work-off"); }
    // determinism
    { Params p; p.n_agents = 20000; p.n_homes = 4000; p.n_works = 400; p.days = 60; p.initial_infected = 20;
      Result a = run_simulation_v4(p);
      for (int i = 0; i < 5; ++i) CHECK(eq(a, run_simulation_v4(p))); }
    // external population input: hand-built (non-synthetic layout) and synthetic-as-external equal V0 / the synthetic path
    {
        Params p; p.days = 30; p.beta_home = p.beta_work = 0.5;
        Population pop; Locations locs; extin::handmade(pop, locs);
        CHECK(extin::daily_equal(run_simulation(p, pop, locs), run_simulation_v4(p, pop, locs)));
        Params q; q.n_agents = 4000; q.n_homes = 800; q.n_works = 80; q.days = 40; q.initial_infected = 30;
        Population sp; Locations sl; make_synthetic_input(q, sp, sl);
        CHECK(extin::daily_equal(run_simulation_v4(q), run_simulation_v4(q, sp, sl)));
        CHECK(extin::daily_equal(run_simulation(q), run_simulation_v4(q, sp, sl)));
        Population bp = pop; bp.home_loc[4] = 0;   // home id pointing at a WORK location
        CHECK(extin::throws_invalid([&] { run_simulation_v4(p, bp, locs); }));
        CHECK(v4_live_mappings() == 0);
    }
    // invalid input still rejected like V0
    { Params p; p.n_agents = 0; bool threw = false; try { run_simulation_v4(p); } catch (const std::exception&) { threw = true; } CHECK(threw); }

    // Compiler/device-dependent FP: device exp() vs host libm, bitwise. Informational: the V0 equality
    // above is the authoritative check; ulp differences here only matter if a draw lands between them.
    {
        const size_t m = 200000; std::vector<double> x(m), d(m);
        for (size_t i = 0; i < m; ++i) x[i] = 1e-9 + 30.0 * (double)i / m;
        v4_eval_prob(x.data(), d.data(), m);
        size_t diff = 0; double maxrel = 0;
        for (size_t i = 0; i < m; ++i) {
            const double h = 1.0 - std::exp(-x[i]);
            if (h != d[i]) { ++diff; maxrel = std::fmax(maxrel, std::fabs(h - d[i]) / h); }
        }
        printf("1-exp(-x) device vs host: %zu/%zu bitwise differences, max rel diff %.3g (%s)\n", diff, m, maxrel,
               info.mode == V4Mode::Device ? "device libm" : "host");
    }
    printf("%d V4 comparisons [%s]; %s\n", runs, v4_mode_name(info.mode), fails ? "V4 FAILED" : "V4 OK");
    return fails != 0;
}
