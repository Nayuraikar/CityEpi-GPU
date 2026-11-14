#include <utility>
#include <chrono>
#include <cmath>
#include <algorithm>
#include "rng_inline.hpp"
#include "v2_simulation.hpp"
#ifdef _OPENMP
#include <omp.h>
#endif

// Parallelisation (see bench/README.md):
//  - prob[l] loop: one writer per l. It also sums+zeroes the per-thread histograms for location l
//    (each l is owned by exactly one thread here -> no race).
//  - agent loop: agent a reads only its own state and read-only prob[]; writes only st[a], tm[a].
//  - scatter nin[home/work]: Local = private histogram per thread (no sharing), Atomic = shared + atomic.
//  - state counts: Local = reduction(+) (integers -> order independent), Atomic = shared atomics.
// RNG is counter-based and all sums are integer, so results are independent of threads/schedule.

bool v2_openmp_enabled() {
#ifdef _OPENMP
    return true;
#else
    return false;
#endif
}
int v2_max_threads() {
#ifdef _OPENMP
    return omp_get_max_threads();
#else
    return 1;
#endif
}

namespace {
struct Ctx {
    uint8_t* st; uint16_t* tm; const uint32_t* hl; const uint32_t* wl; const double* pr;
    size_t n; uint32_t day; uint64_t hs; uint16_t inc, idur; int T;
    std::vector<std::vector<uint32_t>>* hist;
};

template <bool ATOMIC>
Counts agent_pass(const Ctx& c) {
    uint32_t cs = 0, ce = 0, ci = 0, cr = 0;
    uint32_t g[4] = {0, 0, 0, 0};  // shared counters (Atomic mode only)
    const int T = c.T; (void)T;
#pragma omp parallel num_threads(T) reduction(+ : cs, ce, ci, cr)
    {
        int tid = 0;
#ifdef _OPENMP
        tid = omp_get_thread_num();
#endif
        uint32_t* nin = (*c.hist)[ATOMIC ? 0 : tid].data();  // private (Local) or shared (Atomic)
#pragma omp for schedule(runtime)
        for (long a = 0; a < (long)c.n; ++a) {
            const uint8_t s = c.st[a];
            const uint16_t t = c.tm[a];
            const uint32_t h = c.hl[a], w = c.wl[a];
            bool hit = false;
            if (s == S) {
                const uint64_t ha = rng_inl::agent_stage(c.hs, (uint32_t)a);
                const double u1 = rng_inl::draw(ha, c.day, SLOT_EXPOSE_HOME);
                const double u2 = rng_inl::draw(ha, c.day, SLOT_EXPOSE_WORK);
                hit = (u1 < c.pr[h]) | (u2 < c.pr[w]);
            }
            const uint16_t t1 = (uint16_t)(t - (uint16_t)(s == E || s == I));
            const bool z = t1 == 0;
            const bool toI = (s == E) & z, toR = (s == I) & z, toE = (s == S) & hit;
            const uint8_t ns = (uint8_t)(s + (toE | toI | toR));
            const uint16_t nt = toE ? c.inc : toI ? c.idur : (s == E || s == I) ? t1 : t;
            c.st[a] = ns;
            c.tm[a] = nt;
            const uint32_t isI = ns == I;
            if (ATOMIC) {
#pragma omp atomic
                g[ns] += 1;
                if (isI) {
#pragma omp atomic
                    nin[h] += 1;
#pragma omp atomic
                    nin[w] += 1;
                }
            } else {
                cs += ns == S; ce += ns == E; ci += ns == I; cr += ns == R;
                nin[h] += isI;
                nin[w] += isI;
            }
        }
    }
    return ATOMIC ? Counts{g[0], g[1], g[2], g[3]} : Counts{cs, ce, ci, cr};
}
}  // namespace

static V2Result v2_impl(const Params& p0, Population pop, Locations locs, const V2Config& cfg);

V2Result run_simulation_v2(const Params& p, const V2Config& cfg) {
    Population pop;
    Locations locs;
    make_synthetic_input(p, pop, locs);  // host setup, shared with V0-V6 (untimed)
    return v2_impl(p, std::move(pop), std::move(locs), cfg);
}

// External input: validated, then used as supplied (see simulation.hpp).
V2Result run_simulation_v2(const Params& p, const Population& in_pop, const Locations& in_locs, const V2Config& cfg) {
    Population pop;
    Locations locs;
    make_external_input(in_pop, in_locs, pop, locs);
    return v2_impl(p, std::move(pop), std::move(locs), cfg);
}

static V2Result v2_impl(const Params& p0, Population pop, Locations locs, const V2Config& cfg) {
    Params p = p0;
    if (p.incubation_days < 1) p.incubation_days = 1;
    if (p.infectious_days < 1) p.infectious_days = 1;
    const size_t n = pop.size(), nl = locs.size();

    int T = 1;
#ifdef _OPENMP
    T = cfg.threads > 0 ? cfg.threads : omp_get_max_threads();
    omp_sched_t k = cfg.sched == Sched::Static ? omp_sched_static
                  : cfg.sched == Sched::Dynamic ? omp_sched_dynamic : omp_sched_guided;
    omp_set_schedule(k, cfg.chunk);
#endif
    V2Result r;
    r.threads = T;
    r.daily.push_back(count_states(pop));

    const bool atomic = cfg.reduce == Reduce::Atomic;
    std::vector<std::vector<uint32_t>> hist(atomic ? 1 : T, std::vector<uint32_t>(nl, 0));
    r.hist_bytes = hist.size() * nl * sizeof(uint32_t);
    for (size_t a = 0; a < n; ++a) {  // initial tally (serial, untimed)
        const uint32_t isI = pop.state[a] == I;
        hist[0][pop.home_loc[a]] += isI;
        hist[0][pop.work_loc[a]] += isI;
    }
    std::vector<double> prob(nl);
    Ctx c{pop.state.data(), pop.timer.data(), pop.home_loc.data(), pop.work_loc.data(), prob.data(),
          n, 0, rng_inl::seed_stage(p.seed), at_least1(p.incubation_days), at_least1(p.infectious_days), T, &hist};
    const int H = (int)hist.size();

    auto t0 = std::chrono::steady_clock::now();
    for (uint32_t d = 0; d < p.days; ++d) {
#pragma omp parallel for num_threads(T) schedule(static)
        for (long l = 0; l < (long)nl; ++l) {
            uint32_t inf = 0;
            for (int h = 0; h < H; ++h) { inf += hist[h][l]; hist[h][l] = 0; }  // merge + reset
            const double beta = locs.type[l] == LOC_HOME ? p.beta_home : p.beta_work;
            const uint32_t occ = locs.occupancy[l];
            prob[l] = occ ? 1.0 - std::exp(-beta * inf / occ) : 0.0;
        }
        c.day = d;
        r.daily.push_back(atomic ? agent_pass<true>(c) : agent_pass<false>(c));
    }
    r.seconds = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
    return r;
}
