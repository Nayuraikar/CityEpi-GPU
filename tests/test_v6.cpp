// V6 (optimized CUDA) correctness. Usage: test_v6 [--require-gpu]   (or CITYEPI_REQUIRE_GPU=1)
// Every V6 option set is checked bit-identical (daily S/E/I/R) to V0, and to V5 when it is built in too
// (CITYEPI_WITH_V5). No CPU fallback: without a device only host RNG checks run, a loud SKIPPED notice is
// printed and the exit code is 0 -- unless --require-gpu is given, which makes it exit 1.
// Device exp() vs host libm is reported informationally only; no bit-identity between them is claimed.
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <stdexcept>
#include <string>
#include <vector>
#include "rng_inline.hpp"
#include "v6_rng.hpp"
#include "v6_simulation.hpp"
#ifdef CITYEPI_WITH_V5
#include "v5_simulation.hpp"
#endif

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
            printf("  first divergence day %zu: ref S/E/I/R=%u/%u/%u/%u  V6 %u/%u/%u/%u\n", i,
                   a.daily[i].s, a.daily[i].e, a.daily[i].i, a.daily[i].r,
                   b.daily[i].s, b.daily[i].e, b.daily[i].i, b.daily[i].r);
            return;
        }
    printf("  daily length differs: %zu vs %zu\n", a.daily.size(), b.daily.size());
}

// ---- option sets under test
static V6Opts mk(bool agg, V6Mode m, bool se, bool sr, bool pl, uint32_t block, uint32_t gd = 32) {
    V6Opts o; o.agg_counts = agg; o.mode = m; o.skip_exp = se; o.skip_rng = sr; o.pred_loads = pl; o.block = block; o.graph_days = gd;
    return o;
}
// Individual optimizations, combinations, and every block size (baseline and all-on).
static std::vector<V6Opts> full_set() {
    std::vector<V6Opts> v;
    const V6Mode S_ = V6Mode::kSync, A_ = V6Mode::kAsync, G_ = V6Mode::kGraph;
    v.push_back(mk(0, S_, 0, 0, 0, 256));                                   // baseline (V5-equivalent)
    v.push_back(mk(1, S_, 0, 0, 0, 256));                                   // E1
    v.push_back(mk(0, A_, 0, 0, 0, 256));                                   // E2 async
    v.push_back(mk(0, G_, 0, 0, 0, 256));                                   // E2 graph (32 days / graph)
    v.push_back(mk(0, G_, 0, 0, 0, 256, 1));                                // graph, 1 day per graph
    v.push_back(mk(0, G_, 0, 0, 0, 256, 7));                                // graph, chunk that does not divide days
    v.push_back(mk(0, S_, 1, 0, 0, 256));                                   // E3 parts individually
    v.push_back(mk(0, S_, 0, 1, 0, 256));
    v.push_back(mk(0, S_, 0, 0, 1, 256));
    v.push_back(mk(0, S_, 1, 1, 1, 256));                                   // E3 all
    v.push_back(mk(1, A_, 0, 0, 0, 256));                                   // combinations
    v.push_back(mk(1, G_, 0, 0, 0, 256));
    v.push_back(mk(1, S_, 1, 1, 1, 256));
    v.push_back(mk(1, A_, 1, 1, 1, 256));
    v.push_back(mk(1, G_, 1, 1, 1, 256));                                   // E1+E2graph+E3
    for (uint32_t b : v6_supported_blocks()) {                              // E4: every block size
        if (b != 256) v.push_back(mk(0, S_, 0, 0, 0, b));
        v.push_back(mk(1, G_, 1, 1, 1, b));
        v.push_back(mk(1, S_, 0, 0, 0, b));
        v.push_back(mk(0, S_, 1, 1, 1, b));
    }
    return v;
}
static std::vector<V6Opts> quick_set() {   // used for the larger parameter sweeps
    return {mk(0, V6Mode::kSync, 0, 0, 0, 256), mk(1, V6Mode::kGraph, 1, 1, 1, 256), mk(1, V6Mode::kAsync, 0, 0, 0, 64),
            mk(0, V6Mode::kSync, 1, 1, 1, 1024)};
}

static void cmp(const Params& p, const char* tag, const std::vector<V6Opts>& set) {
    const Result r0 = run_simulation(p);
#ifdef CITYEPI_WITH_V5
    const V5Result r5 = run_simulation_v5(p);
    if (!eq(r0, r5)) { printf("NOTE: V5 differs from V0 for %s n=%u (baseline V5 issue)\n", tag, p.n_agents); }
#endif
    for (const V6Opts& o : set) {
        V6Config c; c.opts = o;
        V6Result v = run_simulation_v6(p, c);
        ++runs;
        if (!eq(r0, v)) {
            printf("MISMATCH V0 vs V6[%s] %s n=%u seed=%llu beta=%g\n", v6_describe(o).c_str(), tag, p.n_agents,
                   (unsigned long long)p.seed, p.beta_home);
            report_diff(r0, v); ++fails;
        }
#ifdef CITYEPI_WITH_V5
        if (!eq(r5, v)) { printf("MISMATCH V5 vs V6[%s] %s n=%u\n", v6_describe(o).c_str(), tag, p.n_agents); ++fails; }
#endif
        for (const Counts& k : v.daily) CHECK(k.s + k.e + k.i + k.r == p.n_agents);
        CHECK(v.daily.size() == (size_t)p.days + 1);
        CHECK(v.seconds_total >= v.seconds);
        if (p.beta_home == 0 && p.beta_work == 0) CHECK(v.daily.back().s == v.daily.front().s);
        CHECK(v6_live_allocations() == 0);
    }
}

int main(int argc, char** argv) {
    bool require_gpu = getenv("CITYEPI_REQUIRE_GPU") != nullptr;
    for (int i = 1; i < argc; ++i) if (!strcmp(argv[i], "--require-gpu")) require_gpu = true;

    const V6Info info = v6_probe();
    const V6HostInfo host = v6_host_info();
    printf("V6 CUDA device    : %s\n", info.gpu_ok ? "YES (probe kernel executed on device)" : "NO");
    printf("host              : %s, %d logical cores, %s\n", host.cpu_model.c_str(), host.logical_cores, host.os.c_str());
    printf("compiler          : %s\n", info.compiler.c_str());
#ifdef CITYEPI_WITH_V5
    printf("V5 cross-check    : enabled (every V6 run is also compared with V5)\n");
#else
    printf("V5 cross-check    : not built (V0 comparison only)\n");
#endif
    if (info.gpu_ok)
        printf("device            : %s cc%d.%d, %d SMs, %.1f GiB, driver %d, runtime %d\n", info.device_name.c_str(),
               info.cc_major, info.cc_minor, info.sm_count, info.global_mem_bytes / 1073741824.0,
               info.driver_version, info.runtime_version);
    else printf("reason            : %s\n", info.error.c_str());

    // RNG: V6 copy must be bit-identical to rand01 / rng_inl (host side).
    {
        const uint64_t hs = rng_v6::seed_stage(42), hi = rng_inl::seed_stage(42);
        CHECK(hs == hi);
        for (uint32_t a = 0; a < 20000; ++a) {
            const uint64_t ha = rng_v6::agent_stage(hs, a);
            CHECK(ha == rng_inl::agent_stage(hi, a));
            for (uint32_t d : {0u, 1u, 99u}) for (uint32_t sl : {3u, 4u}) {
                const double u = rng_v6::draw(ha, d, sl);
                CHECK(u == rng_inl::draw(ha, d, sl));
                CHECK(u == rand01(42, a, d, sl));
            }
        }
    }
    // option validation needs no device
    for (uint32_t bad : {0u, 1u, 32u, 100u, 256u + 1u, 2048u}) {
        V6Config c; c.opts.block = bad; bool threw = false;
        try { run_simulation_v6(Params(), c); } catch (const std::invalid_argument&) { threw = true; } catch (const std::exception&) {}
        CHECK(threw);
    }
    { V6Config c; c.opts.mode = V6Mode::kGraph; c.opts.graph_days = 0; bool threw = false;
      try { run_simulation_v6(Params(), c); } catch (const std::invalid_argument&) { threw = true; } catch (const std::exception&) {}
      CHECK(threw); }
    CHECK(v6_live_allocations() == 0);

    if (!info.gpu_ok) {
        printf("\n*** SKIPPED: no CUDA device executed code. Host-side RNG/option checks only (%s). ***\n"
               "*** This is NOT GPU validation of V6. ***\n", fails ? "FAILED" : "passed");
        if (require_gpu) { printf("FAIL: --require-gpu but no CUDA device is available\n"); return 1; }
        return fails != 0;
    }

    // register / occupancy report + sanity for every block size
    for (uint32_t b : v6_supported_blocks()) for (int all : {0, 1}) {
        V6Opts o = mk(all, all ? V6Mode::kGraph : V6Mode::kSync, all, all, all, b);
        const V6KernelInfo k = v6_kernel_info(o);
        printf("kernel_info %-34s loc: %3d regs occ %5.1f%% | step: %3d regs, %zu B local, occ %5.1f%%\n",
               v6_describe(o).c_str(), k.loc_regs, k.loc_occupancy_pct, k.step_regs, k.step_local_bytes, k.step_occupancy_pct);
        CHECK(k.loc_regs > 0 && k.step_regs > 0 && k.loc_blocks_per_sm >= 1 && k.step_blocks_per_sm >= 1);
    }

    // RNG on the device must equal rand01 bitwise
    for (uint64_t seed : {1ull, 42ull, 0xFFFFFFFFFFFFFFFFull}) {
        const size_t m = 100000;
        std::vector<uint32_t> ag(m); std::vector<double> out(m);
        for (size_t i = 0; i < m; ++i) ag[i] = (uint32_t)(i * 40503u + 7u);
        for (uint32_t d : {0u, 1u, 99u, 1000u}) for (uint32_t sl : {0u, 3u, 4u}) {
            v6_eval_draws(seed, ag.data(), d, sl, out.data(), m);
            size_t bad = 0;
            for (size_t i = 0; i < m; ++i) bad += out[i] != rand01(seed, ag[i], d, sl);
            CHECK(bad == 0);
        }
    }
    CHECK(v6_live_allocations() == 0);

    // E3 exactness: with and without the nin == 0 shortcut the device expression is bitwise identical
    {
        std::vector<double> beta; std::vector<uint32_t> nin, occ;
        for (double b : {0.0, 1e-12, 0.01, 0.3, 1.0, 2.0, 50.0, 1e6})
            for (uint32_t k : {0u, 1u, 2u, 7u, 100u, 5000u})
                for (uint32_t o : {0u, 1u, 3u, 50u, 100000u}) { beta.push_back(b); nin.push_back(k); occ.push_back(o); }
        const size_t m = beta.size();
        std::vector<double> a(m), b(m);
        v6_eval_prob(beta.data(), nin.data(), occ.data(), false, a.data(), m);
        v6_eval_prob(beta.data(), nin.data(), occ.data(), true, b.data(), m);
        size_t bad = 0, zero_cases = 0;
        for (size_t i = 0; i < m; ++i) {
            if (std::memcmp(&a[i], &b[i], sizeof(double)) != 0) ++bad;
            if (nin[i] == 0) { ++zero_cases; CHECK(a[i] == 0.0 && !std::signbit(a[i])); }
        }
        printf("E3 skip_exp: %zu/%zu bitwise differences (%zu nin==0 cases all +0.0)\n", bad, m, zero_cases);
        CHECK(bad == 0);
    }
    CHECK(v6_live_allocations() == 0);

    // failure injection, every mode: no device allocation may survive; later runs stay exact
    {
        Params p; p.n_agents = 3000; p.n_homes = 600; p.n_works = 60; p.days = 20; p.initial_infected = 10;
        const Result ref = run_simulation(p);
        for (V6Mode m : {V6Mode::kSync, V6Mode::kAsync, V6Mode::kGraph})
            for (uint32_t fail_day : {1u, 7u, 20u}) {
                V6Config c; c.opts = mk(1, m, 1, 1, 1, 128, 7); c.inject_failure_after_day = fail_day; bool threw = false;
                try { run_simulation_v6(p, c); } catch (const std::runtime_error&) { threw = true; }
                CHECK(threw);
                CHECK(v6_live_allocations() == 0);
                V6Config ok; ok.opts = c.opts;
                CHECK(eq(ref, run_simulation_v6(p, ok)));
                CHECK(v6_live_allocations() == 0);
            }
        for (V6Mode m : {V6Mode::kSync, V6Mode::kGraph})
            for (uint32_t k = 1; k <= v6_planned_allocations(); ++k) {  // fail each device allocation in turn
                V6Config c; c.opts = mk(0, m, 0, 0, 0, 256); c.inject_alloc_failure_at = k; bool threw = false;
                try { run_simulation_v6(p, c); } catch (const std::runtime_error&) { threw = true; }
                CHECK(threw);
                CHECK(v6_live_allocations() == 0);
            }
        V6Config clean; CHECK(eq(ref, run_simulation_v6(p, clean)));
        CHECK(v6_live_allocations() == 0);
        // profile pass returns the same results and positive per-kernel times
        V6Config pc; pc.profile = true; pc.opts = mk(1, V6Mode::kGraph, 1, 1, 1, 256);
        V6Result pr = run_simulation_v6(p, pc);
        CHECK(eq(ref, pr)); CHECK(pr.prof_loc_ms > 0 && pr.prof_step_ms > 0);
    }

    // sizes: tiny, odd, partial warps, and tails around every supported block size (64..1024)
    const std::vector<uint32_t> sizes = {1, 2, 15, 16, 17, 31, 32, 33, 63, 64, 65, 100, 127, 128, 129, 255, 256, 257,
                                         511, 512, 513, 1023, 1024, 1025, 2049, 5000, 30001};
    const std::vector<V6Opts> full = full_set(), quick = quick_set();
    printf("option sets: full=%zu quick=%zu\n", full.size(), quick.size());
    for (uint32_t n : sizes)
        for (double beta : {0.0, 0.3, 2.0, 1e6}) {
            Params p; p.n_agents = n; p.n_homes = n / 5 + 1; p.n_works = n / 50 + 1; p.days = 40;
            p.seed = 42; p.beta_home = p.beta_work = beta; p.initial_infected = n / 50 + 1;
            cmp(p, "sweep", full);
        }
    for (uint64_t s : {1ull, 7ull})
        for (uint32_t n : {1u, 33u, 257u, 1025u, 30001u})
            for (double beta : {0.0, 0.3, 2.0, 1e6}) {
                Params p; p.n_agents = n; p.n_homes = n / 5 + 1; p.n_works = n / 50 + 1; p.days = 40;
                p.seed = s; p.beta_home = p.beta_work = beta; p.initial_infected = n / 50 + 1;
                cmp(p, "seeds", quick);
            }
    for (uint32_t n : {100000u, 1000000u}) {
        Params p; p.n_agents = n; p.n_homes = n / 5; p.n_works = n / 50; p.days = 30; p.initial_infected = n / 1000;
        cmp(p, "large", full);
    }
    { Params p; p.n_agents = 50000; p.n_homes = 1; p.n_works = 1; p.days = 30; p.initial_infected = 50; cmp(p, "single-location", full); }
    for (uint16_t inc : {1, 2, 6}) for (uint16_t idur : {1, 3, 9}) {
        Params p; p.n_agents = 3001; p.n_homes = 700; p.n_works = 40; p.days = 80; p.beta_home = 0.1; p.beta_work = 0.6;
        p.incubation_days = inc; p.infectious_days = idur; cmp(p, "timers", quick);
        p.initial_infected = 0; cmp(p, "no-initial", quick);
        p.initial_infected = p.n_agents; cmp(p, "all-infected", quick);
    }
    { Params p; p.n_agents = 4000; p.n_homes = 800; p.n_works = 80; p.days = 60; p.incubation_days = 0; p.infectious_days = 0;
      cmp(p, "zero-durations(clamped)", full); }
    { Params p; p.n_agents = 4000; p.n_homes = 800; p.n_works = 80; p.days = 0; cmp(p, "zero-days", full); }
    { Params p; p.n_agents = 4000; p.n_homes = 800; p.n_works = 80; p.days = 1; cmp(p, "one-day", full); }
    { Params p; p.n_agents = 4000; p.n_homes = 800; p.n_works = 80; p.days = 60; p.beta_home = 0; p.beta_work = 0.5; cmp(p, "home-off", full);
      p.beta_home = 0.5; p.beta_work = 0; cmp(p, "work-off", full); }
    // determinism (atomics, aggregation and launch order must not matter)
    { Params p; p.n_agents = 20000; p.n_homes = 4000; p.n_works = 400; p.days = 60; p.initial_infected = 20;
      for (const V6Opts& o : quick) {
          V6Config c; c.opts = o;
          V6Result a = run_simulation_v6(p, c);
          for (int i = 0; i < 4; ++i) CHECK(eq(a, run_simulation_v6(p, c)));
      } }
    // invalid input still rejected like V0
    { Params p; p.n_agents = 0; bool threw = false; try { run_simulation_v6(p); } catch (const std::exception&) { threw = true; } CHECK(threw);
      CHECK(v6_live_allocations() == 0); }

    // Informational only: device exp() vs host libm. No bit-identity is claimed; V0 equality above is authoritative.
    {
        const size_t m = 200000; std::vector<double> beta(m, 1.0); std::vector<uint32_t> nin(m), occ(m, 1000000u);
        std::vector<double> d(m);
        for (size_t i = 0; i < m; ++i) { nin[i] = (uint32_t)(1 + i * 29999 / m * 1000); }
        v6_eval_prob(beta.data(), nin.data(), occ.data(), false, d.data(), m);
        size_t diff = 0; double maxrel = 0;
        for (size_t i = 0; i < m; ++i) {
            const double h = 1.0 - std::exp((-beta[i] * nin[i]) / occ[i]);
            if (h != d[i]) { ++diff; maxrel = std::fmax(maxrel, std::fabs(h - d[i]) / h); }
        }
        printf("1-exp(-x) device vs host (informational): %zu/%zu bitwise differences, max rel diff %.3g\n", diff, m, maxrel);
    }
    CHECK(v6_live_allocations() == 0);
    printf("%d V6 comparisons on %s; %s\n", runs, info.device_name.c_str(), fails ? "V6 FAILED" : "V6 OK");
    return fails != 0;
}
