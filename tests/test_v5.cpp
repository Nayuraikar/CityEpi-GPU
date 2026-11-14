// V5 (CUDA) correctness vs V0. Usage: test_v5 [--require-gpu]   (or CITYEPI_REQUIRE_GPU=1)
// V5 has no CPU fallback. Without a CUDA device only the host-side RNG checks run, a loud SKIPPED notice
// is printed, and the exit code is 0 -- unless --require-gpu is given, which makes it exit 1.
// Everything that touches the device (RNG on device, V0 equality, failure injection) needs a real GPU.
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <stdexcept>
#include <vector>
#include "external_input_common.hpp"
#include "rng_inline.hpp"
#include "v5_rng.hpp"
#include "v5_simulation.hpp"

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
            printf("  first divergence day %zu: V0 S/E/I/R=%u/%u/%u/%u  V5 %u/%u/%u/%u\n", i,
                   a.daily[i].s, a.daily[i].e, a.daily[i].i, a.daily[i].r,
                   b.daily[i].s, b.daily[i].e, b.daily[i].i, b.daily[i].r);
            return;
        }
    printf("  daily length differs: %zu vs %zu\n", a.daily.size(), b.daily.size());
}

static void cmp(const Params& p, const char* tag) {
    Result r0 = run_simulation(p);
    V5Result v5 = run_simulation_v5(p);
    ++runs;
    if (!eq(r0, v5)) {
        printf("MISMATCH V0 vs V5 %s n=%u seed=%llu beta=%g\n", tag, p.n_agents, (unsigned long long)p.seed, p.beta_home);
        report_diff(r0, v5); ++fails;
    }
    for (const Counts& c : v5.daily) CHECK(c.s + c.e + c.i + c.r == p.n_agents);
    CHECK(v5.daily.size() == (size_t)p.days + 1);
    CHECK(v5.seconds_total >= v5.seconds);
    if (p.beta_home == 0 && p.beta_work == 0) CHECK(v5.daily.back().s == v5.daily.front().s);
    CHECK(v5_live_allocations() == 0);
}

int main(int argc, char** argv) {
    bool require_gpu = getenv("CITYEPI_REQUIRE_GPU") != nullptr;
    for (int i = 1; i < argc; ++i) if (!strcmp(argv[i], "--require-gpu")) require_gpu = true;

    const V5Info info = v5_probe();
    const V5HostInfo host = v5_host_info();
    printf("V5 CUDA device    : %s\n", info.gpu_ok ? "YES (probe kernel executed on device)" : "NO");
    printf("host              : %s, %d logical cores, %s\n", host.cpu_model.c_str(), host.logical_cores, host.os.c_str());
    printf("compiler          : %s\n", info.compiler.c_str());
    if (info.gpu_ok)
        printf("device            : %s cc%d.%d, %d SMs, %.1f GiB, driver %d, runtime %d\n", info.device_name.c_str(),
               info.cc_major, info.cc_minor, info.sm_count, info.global_mem_bytes / 1073741824.0,
               info.driver_version, info.runtime_version);
    else printf("reason            : %s\n", info.error.c_str());

    // RNG: V5 copy must be bit-identical to rand01 / rng_inl (host side).
    {
        const uint64_t hs = rng_v5::seed_stage(42), hi = rng_inl::seed_stage(42);
        CHECK(hs == hi);
        for (uint32_t a = 0; a < 20000; ++a) {
            const uint64_t ha = rng_v5::agent_stage(hs, a);
            CHECK(ha == rng_inl::agent_stage(hi, a));
            for (uint32_t d : {0u, 1u, 99u}) for (uint32_t sl : {3u, 4u}) {
                const double u = rng_v5::draw(ha, d, sl);
                CHECK(u == rng_inl::draw(ha, d, sl));
                CHECK(u == rand01(42, a, d, sl));
            }
        }
    }

    if (!info.gpu_ok) {
        printf("\n*** SKIPPED: no CUDA device executed code. Host-side RNG checks only (%s). ***\n"
               "*** This is NOT GPU validation of V5. ***\n", fails ? "FAILED" : "passed");
        if (require_gpu) { printf("FAIL: --require-gpu but no CUDA device is available\n"); return 1; }
        return fails != 0;
    }

    // RNG on the device must equal rand01 bitwise (many agents, several days/slots/seeds)
    for (uint64_t seed : {1ull, 42ull, 0xFFFFFFFFFFFFFFFFull}) {
        const size_t m = 100000;
        std::vector<uint32_t> ag(m); std::vector<double> out(m);
        for (size_t i = 0; i < m; ++i) ag[i] = (uint32_t)(i * 40503u + 7u);
        for (uint32_t d : {0u, 1u, 99u, 1000u}) for (uint32_t sl : {0u, 3u, 4u}) {
            v5_eval_draws(seed, ag.data(), d, sl, out.data(), m);
            size_t bad = 0;
            for (size_t i = 0; i < m; ++i) bad += out[i] != rand01(seed, ag[i], d, sl);
            CHECK(bad == 0);
        }
    }
    CHECK(v5_live_allocations() == 0);

    // failure injection: no device allocation may survive a failed run, later runs stay exact
    {
        Params p; p.n_agents = 3000; p.n_homes = 600; p.n_works = 60; p.days = 20; p.initial_infected = 10;
        Result ref = run_simulation(p);
        for (uint32_t fail_day : {1u, 7u, 20u}) {
            V5Config c; c.inject_failure_after_day = fail_day; bool threw = false;
            try { run_simulation_v5(p, c); } catch (const std::runtime_error&) { threw = true; }
            CHECK(threw);
            CHECK(v5_live_allocations() == 0);
            CHECK(eq(ref, run_simulation_v5(p)));
            CHECK(v5_live_allocations() == 0);
        }
        for (uint32_t k = 1; k <= 9; ++k) {  // fail the k-th of the 9 device allocations
            V5Config c; c.inject_alloc_failure_at = k; bool threw = false;
            try { run_simulation_v5(p, c); } catch (const std::runtime_error&) { threw = true; }
            CHECK(threw);
            CHECK(v5_live_allocations() == 0);
        }
        CHECK(eq(ref, run_simulation_v5(p)));
        CHECK(v5_live_allocations() == 0);
    }

    // sizes: tiny, odd, block-size straddling (256), larger
    for (uint64_t s : {1ull, 42ull, 7ull})
        for (uint32_t n : {1u, 2u, 15u, 16u, 17u, 31u, 32u, 33u, 100u, 255u, 256u, 257u, 5000u, 30001u})
            for (double beta : {0.0, 0.3, 2.0, 1e6}) {
                Params p; p.n_agents = n; p.n_homes = n / 5 + 1; p.n_works = n / 50 + 1; p.days = 40;
                p.seed = s; p.beta_home = p.beta_work = beta; p.initial_infected = n / 50 + 1;
                cmp(p, "sweep");
            }
    for (uint32_t n : {100000u, 1000000u}) {
        Params p; p.n_agents = n; p.n_homes = n / 5; p.n_works = n / 50; p.days = 30; p.initial_infected = n / 1000;
        cmp(p, "large");
    }
    // few locations => heavy atomic contention on the tally and counters
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
    // determinism (atomics/launch order must not matter)
    { Params p; p.n_agents = 20000; p.n_homes = 4000; p.n_works = 400; p.days = 60; p.initial_infected = 20;
      Result a = run_simulation_v5(p);
      for (int i = 0; i < 5; ++i) CHECK(eq(a, run_simulation_v5(p))); }
    // external population input: hand-built (non-synthetic layout) and synthetic-as-external equal V0 / the synthetic path
    {
        Params p; p.days = 30; p.beta_home = p.beta_work = 0.5;
        Population pop; Locations locs; extin::handmade(pop, locs);
        CHECK(extin::daily_equal(run_simulation(p, pop, locs), run_simulation_v5(p, pop, locs)));
        Params q; q.n_agents = 4000; q.n_homes = 800; q.n_works = 80; q.days = 40; q.initial_infected = 30;
        Population sp; Locations sl; make_synthetic_input(q, sp, sl);
        CHECK(extin::daily_equal(run_simulation_v5(q), run_simulation_v5(q, sp, sl)));
        CHECK(extin::daily_equal(run_simulation(q), run_simulation_v5(q, sp, sl)));
        Population bp = pop; bp.home_loc[4] = 0;   // home id pointing at a WORK location
        CHECK(extin::throws_invalid([&] { run_simulation_v5(p, bp, locs); }));
        CHECK(v5_live_allocations() == 0);
    }
    // invalid input still rejected like V0
    { Params p; p.n_agents = 0; bool threw = false; try { run_simulation_v5(p); } catch (const std::exception&) { threw = true; } CHECK(threw);
      CHECK(v5_live_allocations() == 0); }

    // Informational: device exp() vs host libm, bitwise. The V0 equality above is the authoritative check.
    {
        const size_t m = 200000; std::vector<double> x(m), d(m);
        for (size_t i = 0; i < m; ++i) x[i] = 1e-9 + 30.0 * (double)i / m;
        v5_eval_prob(x.data(), d.data(), m);
        size_t diff = 0; double maxrel = 0;
        for (size_t i = 0; i < m; ++i) {
            const double h = 1.0 - std::exp(-x[i]);
            if (h != d[i]) { ++diff; maxrel = std::fmax(maxrel, std::fabs(h - d[i]) / h); }
        }
        printf("1-exp(-x) device vs host: %zu/%zu bitwise differences, max rel diff %.3g\n", diff, m, maxrel);
    }
    CHECK(v5_live_allocations() == 0);
    printf("%d V5 comparisons on %s; %s\n", runs, info.device_name.c_str(), fails ? "V5 FAILED" : "V5 OK");
    return fails != 0;
}
