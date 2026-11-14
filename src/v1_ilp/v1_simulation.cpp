#include <algorithm>
#include <chrono>
#include <cmath>
#include "rng_inline.hpp"
#include "v1_simulation.hpp"

// ILP changes vs V0 (see bench/README.md for evidence):
//  1. One fused pass/day: exposure + transition + state counting + next-day infectious tally
//     (V0: 4 passes, newly_exposed buffer, count pass).
//  2. Per-location infection probability table (n_locs exp+div per day, not 2 per susceptible).
//  3. RNG inlined; seed stage hoisted, agent stage shared by both slots; the two slot chains
//     are independent -> overlapped. Both draws always evaluated (no short-circuit branch).
//  4. Branchless state/timer update and counters (no mispredicts on E/I/R mix);
//     counters in locals; I-tally scatter is branchless (adds 0/1).
Result run_simulation_v1(const Params& p0) {
    Params p = p0;
    if (p.incubation_days < 1) p.incubation_days = 1;
    if (p.infectious_days < 1) p.infectious_days = 1;
    Population pop;
    Locations locs;
    generate_synthetic(p, pop, locs);
    seed_infections(p, pop);
    const size_t n = pop.size(), nl = locs.size();
    Result r;
    r.daily.push_back(count_states(pop));

    std::vector<uint32_t> inf(nl, 0);
    std::vector<double> prob(nl);
    for (size_t a = 0; a < n; ++a) {
        const uint32_t isI = pop.state[a] == I;
        inf[pop.home_loc[a]] += isI;
        inf[pop.work_loc[a]] += isI;
    }
    const uint64_t hs = rng_inl::seed_stage(p.seed);
    const uint16_t inc = at_least1(p.incubation_days), idur = at_least1(p.infectious_days);
    uint8_t* __restrict st = pop.state.data();
    uint16_t* __restrict tm = pop.timer.data();
    const uint32_t* __restrict hl = pop.home_loc.data();
    const uint32_t* __restrict wl = pop.work_loc.data();

    auto t0 = std::chrono::steady_clock::now();
    for (uint32_t d = 0; d < p.days; ++d) {
        for (size_t l = 0; l < nl; ++l) {  // independent iterations: exp latencies overlap
            const double beta = locs.type[l] == LOC_HOME ? p.beta_home : p.beta_work;
            const uint32_t occ = locs.occupancy[l];
            prob[l] = occ ? 1.0 - std::exp(-beta * inf[l] / occ) : 0.0;
        }
        std::fill(inf.begin(), inf.end(), 0);  // reuse as next-day tally
        uint32_t cs = 0, ce = 0, ci = 0, cr = 0;
        uint32_t* __restrict nin = inf.data();
        const double* __restrict pr = prob.data();
        for (size_t a = 0; a < n; ++a) {
            const uint8_t s = st[a];
            const uint16_t t = tm[a];
            const uint32_t h = hl[a], w = wl[a];
            bool hit = false;
            if (s == S) {  // skip RNG for non-susceptibles (they are the majority late in the run)
                const uint64_t ha = rng_inl::agent_stage(hs, (uint32_t)a);
                const double u1 = rng_inl::draw(ha, d, SLOT_EXPOSE_HOME);  // independent chains
                const double u2 = rng_inl::draw(ha, d, SLOT_EXPOSE_WORK);
                hit = (u1 < pr[h]) | (u2 < pr[w]);
            }
            const uint16_t t1 = (uint16_t)(t - (uint16_t)(s == E || s == I));
            const bool z = t1 == 0;
            const bool toI = (s == E) & z, toR = (s == I) & z, toE = (s == S) & hit;
            const uint8_t ns = (uint8_t)(s + (toE | toI | toR));  // S->E->I->R are consecutive
            const uint16_t nt = toE ? inc : toI ? idur : (s == E || s == I) ? t1 : t;
            st[a] = ns;
            tm[a] = nt;
            cs += ns == S; ce += ns == E; ci += ns == I; cr += ns == R;
            const uint32_t isI = ns == I;
            nin[h] += isI;
            nin[w] += isI;
        }
        r.daily.push_back(Counts{cs, ce, ci, cr});
    }
    r.seconds = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
    return r;
}
