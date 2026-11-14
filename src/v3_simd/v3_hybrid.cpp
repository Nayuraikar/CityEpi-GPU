#include <algorithm>
#include <chrono>
#include <cmath>
#include "rng_inline.hpp"
#include "v3_hybrid.hpp"
#if defined(__aarch64__) && defined(__ARM_NEON)
#include <arm_neon.h>
#define V3H_NEON 1
#endif

// Per block of 16 agents: (1) scalar exposure exactly as V1 (scalar splitmix, S agents only) -> hit[16];
// (2) NEON branchless transition + counts; (3) scalar scatter of next-day infectious tally.
namespace {
struct Ctx {
    uint8_t* st; uint16_t* tm; const uint32_t* hl; const uint32_t* wl; const double* pr;
    uint32_t* nin; uint32_t day; uint64_t hs; uint16_t inc, idur;
    uint32_t cs = 0, ce = 0, ci = 0, cr = 0;
};

inline bool exposed(const Ctx& c, size_t a) {
    const uint64_t ha = rng_inl::agent_stage(c.hs, (uint32_t)a);
    const double u1 = rng_inl::draw(ha, c.day, SLOT_EXPOSE_HOME);
    const double u2 = rng_inl::draw(ha, c.day, SLOT_EXPOSE_WORK);
    return (u1 < c.pr[c.hl[a]]) | (u2 < c.pr[c.wl[a]]);
}

inline void agent_scalar(Ctx& c, size_t a) {  // identical to V1 body (fallback + tail)
    const uint8_t s = c.st[a];
    const uint16_t t = c.tm[a];
    const uint32_t h = c.hl[a], w = c.wl[a];
    const bool hit = s == S ? exposed(c, a) : false;
    const uint16_t t1 = (uint16_t)(t - (uint16_t)(s == E || s == I));
    const bool z = t1 == 0;
    const bool toI = (s == E) & z, toR = (s == I) & z, toE = (s == S) & hit;
    const uint8_t ns = (uint8_t)(s + (toE | toI | toR));
    const uint16_t nt = toE ? c.inc : toI ? c.idur : (s == E || s == I) ? t1 : t;
    c.st[a] = ns;
    c.tm[a] = nt;
    c.cs += ns == S; c.ce += ns == E; c.ci += ns == I; c.cr += ns == R;
    const uint32_t isI = ns == I;
    c.nin[h] += isI;
    c.nin[w] += isI;
}

#ifdef V3H_NEON
inline uint16x8_t widen_lo(uint8x16_t m) { return vreinterpretq_u16_s16(vmovl_s8(vget_low_s8(vreinterpretq_s8_u8(m)))); }
inline uint16x8_t widen_hi(uint8x16_t m) { return vreinterpretq_u16_s16(vmovl_high_s8(vreinterpretq_s8_u8(m))); }

inline void block16(Ctx& c, size_t a) {
    uint8_t hitb[16];
    for (int i = 0; i < 16; ++i) hitb[i] = c.st[a + i] == S ? (uint8_t)exposed(c, a + i) : 0;

    const uint8x16_t s = vld1q_u8(c.st + a);
    const uint8x16_t hit = vceqq_u8(vld1q_u8(hitb), vdupq_n_u8(1));
    const uint8x16_t isS = vceqq_u8(s, vdupq_n_u8(S));
    const uint8x16_t isE = vceqq_u8(s, vdupq_n_u8(E)), isI = vceqq_u8(s, vdupq_n_u8(I));
    const uint8x16_t act = vorrq_u8(isE, isI);
    const uint16x8_t tl = vld1q_u16(c.tm + a), th = vld1q_u16(c.tm + a + 8);
    const uint16x8_t t1l = vaddq_u16(tl, widen_lo(act)), t1h = vaddq_u16(th, widen_hi(act));  // -1 where active
    const uint8x16_t z = vcombine_u8(vmovn_u16(vceqq_u16(t1l, vdupq_n_u16(0))), vmovn_u16(vceqq_u16(t1h, vdupq_n_u16(0))));
    const uint8x16_t toI = vandq_u8(isE, z), toR = vandq_u8(isI, z), toE = vandq_u8(isS, hit);
    const uint8x16_t ns = vsubq_u8(s, vorrq_u8(vorrq_u8(toE, toI), toR));
    const uint16x8_t inc = vdupq_n_u16(c.inc), idur = vdupq_n_u16(c.idur);
    auto nt = [&](uint16x8_t t, uint16x8_t t1, uint16x8_t mE, uint16x8_t mI, uint16x8_t mA) {
        return vbslq_u16(mE, inc, vbslq_u16(mI, idur, vbslq_u16(mA, t1, t)));
    };
    vst1q_u8(c.st + a, ns);
    vst1q_u16(c.tm + a, nt(tl, t1l, widen_lo(toE), widen_lo(toI), widen_lo(act)));
    vst1q_u16(c.tm + a + 8, nt(th, t1h, widen_hi(toE), widen_hi(toI), widen_hi(act)));

    auto cnt = [&](uint8_t v) { return (uint32_t)vaddvq_u8(vshrq_n_u8(vceqq_u8(ns, vdupq_n_u8(v)), 7)); };
    c.cs += cnt(S); c.ce += cnt(E); c.ci += cnt(I); c.cr += cnt(R);

    uint8_t nsb[16];
    vst1q_u8(nsb, ns);
    for (int i = 0; i < 16; ++i) {
        const uint32_t v = nsb[i] == I;
        c.nin[c.hl[a + i]] += v;
        c.nin[c.wl[a + i]] += v;
    }
}
#endif
}  // namespace

Result run_simulation_v3_hybrid(const Params& p0, bool use_simd) {
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
#ifndef V3H_NEON
    use_simd = false;
#endif
    std::vector<uint32_t> inf(nl, 0);
    std::vector<double> prob(nl);
    for (size_t a = 0; a < n; ++a) {
        const uint32_t isI = pop.state[a] == I;
        inf[pop.home_loc[a]] += isI;
        inf[pop.work_loc[a]] += isI;
    }
    Ctx c{pop.state.data(), pop.timer.data(), pop.home_loc.data(), pop.work_loc.data(), prob.data(),
          inf.data(), 0, rng_inl::seed_stage(p.seed), at_least1(p.incubation_days), at_least1(p.infectious_days)};

    auto t0 = std::chrono::steady_clock::now();
    for (uint32_t d = 0; d < p.days; ++d) {
        for (size_t l = 0; l < nl; ++l) {
            const double beta = locs.type[l] == LOC_HOME ? p.beta_home : p.beta_work;
            const uint32_t occ = locs.occupancy[l];
            prob[l] = occ ? 1.0 - std::exp(-beta * inf[l] / occ) : 0.0;
        }
        std::fill(inf.begin(), inf.end(), 0);
        c.day = d;
        c.cs = c.ce = c.ci = c.cr = 0;
        size_t a = 0;
#ifdef V3H_NEON
        if (use_simd)
            for (; a + 16 <= n; a += 16) block16(c, a);
#endif
        for (; a < n; ++a) agent_scalar(c, a);
        r.daily.push_back(Counts{c.cs, c.ce, c.ci, c.cr});
    }
    r.seconds = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
    return r;
}
