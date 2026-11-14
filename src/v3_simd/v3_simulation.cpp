#include <utility>
#include <algorithm>
#include <chrono>
#include <cmath>
#include "rng_inline.hpp"
#include "v3_simulation.hpp"
#if defined(__aarch64__) && defined(__ARM_NEON)
#include <arm_neon.h>
#define V3_NEON 1
#endif

// SIMD strategy (see bench/README.md for evidence):
//  Per block of 16 agents:
//   1. compact indices of susceptibles (RNG is only needed for them, as in V1);
//   2. splitmix64 RNG on 2 agents per 128-bit vector (NEON has no 64-bit lane multiply:
//      emulated with vmull_u32); the two slot chains are interleaved; compare in double (bit-exact);
//   3. branchless state/timer transition on 16 u8 / 2x8 u16 lanes + vector state counts;
//   4. scatter into the per-location tally stays scalar (conflicting indices).
//  Per-location loop (exp) stays scalar so probabilities are bit-identical to V0/V1.

bool v3_neon_enabled() {
#ifdef V3_NEON
    return true;
#else
    return false;
#endif
}

namespace {
struct Ctx {
    uint8_t* st; uint16_t* tm; const uint32_t* hl; const uint32_t* wl; const double* pr;
    uint32_t* nin; uint32_t day; uint64_t hs; uint16_t inc, idur;
    uint32_t cs = 0, ce = 0, ci = 0, cr = 0;
};

// V1 per-agent body; used for the scalar fallback and the <16 agent tail.
inline void agent_scalar(Ctx& c, size_t a) {
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
    c.cs += ns == S; c.ce += ns == E; c.ci += ns == I; c.cr += ns == R;
    const uint32_t isI = ns == I;
    c.nin[h] += isI;
    c.nin[w] += isI;
}

#ifdef V3_NEON
// low 64 bits of a * k for a constant k, per 64-bit lane
inline uint64x2_t mul64k(uint64x2_t a, uint32x2_t klo, uint32x2_t khi) {
    const uint32x2_t alo = vmovn_u64(a), ahi = vshrn_n_u64(a, 32);
    const uint64x2_t lo = vmull_u32(alo, klo);
    const uint64x2_t cross = vmlal_u32(vmull_u32(ahi, klo), alo, khi);  // only low 32 bits matter
    return vaddq_u64(lo, vshlq_n_u64(cross, 32));
}
inline uint64x2_t mix2(uint64x2_t x) {  // rng_inl::mix on two lanes
    static const uint32x2_t k1l = vdup_n_u32((uint32_t)0xBF58476D1CE4E5B9ULL), k1h = vdup_n_u32((uint32_t)(0xBF58476D1CE4E5B9ULL >> 32));
    static const uint32x2_t k2l = vdup_n_u32((uint32_t)0x94D049BB133111EBULL), k2h = vdup_n_u32((uint32_t)(0x94D049BB133111EBULL >> 32));
    x = vaddq_u64(x, vdupq_n_u64(0x9E3779B97F4A7C15ULL));
    x = mul64k(veorq_u64(x, vshrq_n_u64(x, 30)), k1l, k1h);
    x = mul64k(veorq_u64(x, vshrq_n_u64(x, 27)), k2l, k2h);
    return veorq_u64(x, vshrq_n_u64(x, 31));
}
inline float64x2_t to_unit(uint64x2_t h) {  // (h>>11) * 2^-53, exact
    return vmulq_f64(vcvtq_f64_u64(vshrq_n_u64(h, 11)), vdupq_n_f64(1.0 / 9007199254740992.0));
}

inline uint16x8_t widen_lo(uint8x16_t m) { return vreinterpretq_u16_s16(vmovl_s8(vget_low_s8(vreinterpretq_s8_u8(m)))); }
inline uint16x8_t widen_hi(uint8x16_t m) { return vreinterpretq_u16_s16(vmovl_high_s8(vreinterpretq_s8_u8(m))); }

inline void block16(Ctx& c, size_t a) {
    const uint8x16_t s = vld1q_u8(c.st + a);
    const uint8x16_t isS = vceqq_u8(s, vdupq_n_u8(S));

    // 1+2: exposure draws for susceptibles only, two agents per vector.
    uint8_t hitb[16] = {0};
    uint8_t sm[16];
    vst1q_u8(sm, isS);
    uint8_t idx[17];
    int k = 0;
    for (int i = 0; i < 16; ++i) { idx[k] = (uint8_t)i; k += sm[i] & 1; }
    if (k) {
        idx[k] = idx[k - 1];  // pad odd count with a duplicate (result discarded)
        const uint64x2_t vhs = vdupq_n_u64(c.hs);
        const uint64x2_t dh = vdupq_n_u64((uint64_t)c.day << 8 | SLOT_EXPOSE_HOME);
        const uint64x2_t dw = vdupq_n_u64((uint64_t)c.day << 8 | SLOT_EXPOSE_WORK);
        for (int j = 0; j < k; j += 2) {
            const size_t a0 = a + idx[j], a1 = a + idx[j + 1];
            const uint64_t ag[2] = {(uint32_t)a0, (uint32_t)a1};
            const uint64x2_t ha = mix2(veorq_u64(vhs, vld1q_u64(ag)));
            const uint64x2_t m1 = mix2(veorq_u64(ha, dh));  // independent chains
            const uint64x2_t m2 = mix2(veorq_u64(ha, dw));
            const double ph[2] = {c.pr[c.hl[a0]], c.pr[c.hl[a1]]};  // gathers stay scalar
            const double pw[2] = {c.pr[c.wl[a0]], c.pr[c.wl[a1]]};
            const uint64x2_t hit = vorrq_u64(vcltq_f64(to_unit(m1), vld1q_f64(ph)),
                                             vcltq_f64(to_unit(m2), vld1q_f64(pw)));
            hitb[idx[j]] = (uint8_t)(vgetq_lane_u64(hit, 0) & 1);
            if (j + 1 < k) hitb[idx[j + 1]] = (uint8_t)(vgetq_lane_u64(hit, 1) & 1);
        }
    }

    // 3: branchless transition on 16 lanes.
    const uint8x16_t hit = vceqq_u8(vld1q_u8(hitb), vdupq_n_u8(1));
    const uint8x16_t isE = vceqq_u8(s, vdupq_n_u8(E)), isI = vceqq_u8(s, vdupq_n_u8(I));
    const uint8x16_t act = vorrq_u8(isE, isI);
    const uint16x8_t tl = vld1q_u16(c.tm + a), th = vld1q_u16(c.tm + a + 8);
    const uint16x8_t t1l = vaddq_u16(tl, widen_lo(act)), t1h = vaddq_u16(th, widen_hi(act));  // -1 where active
    const uint8x16_t z = vcombine_u8(vmovn_u16(vceqq_u16(t1l, vdupq_n_u16(0))), vmovn_u16(vceqq_u16(t1h, vdupq_n_u16(0))));
    const uint8x16_t toI = vandq_u8(isE, z), toR = vandq_u8(isI, z), toE = vandq_u8(isS, hit);
    const uint8x16_t ns = vsubq_u8(s, vorrq_u8(vorrq_u8(toE, toI), toR));  // -(-1) = +1
    const uint16x8_t inc = vdupq_n_u16(c.inc), idur = vdupq_n_u16(c.idur);
    auto nt = [&](uint16x8_t t, uint16x8_t t1, uint16x8_t mE, uint16x8_t mI, uint16x8_t mA) {
        return vbslq_u16(mE, inc, vbslq_u16(mI, idur, vbslq_u16(mA, t1, t)));
    };
    vst1q_u8(c.st + a, ns);
    vst1q_u16(c.tm + a, nt(tl, t1l, widen_lo(toE), widen_lo(toI), widen_lo(act)));
    vst1q_u16(c.tm + a + 8, nt(th, t1h, widen_hi(toE), widen_hi(toI), widen_hi(act)));

    // vector counts (each compare mask 0xFF -> 1, horizontal add)
    auto cnt = [&](uint8_t v) { return (uint32_t)vaddvq_u8(vshrq_n_u8(vceqq_u8(ns, vdupq_n_u8(v)), 7)); };
    c.cs += cnt(S); c.ce += cnt(E); c.ci += cnt(I); c.cr += cnt(R);

    // 4: scalar scatter of next-day infectious tally.
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

static Result v3_impl(const Params& p0, Population pop, Locations locs, bool use_simd);

Result run_simulation_v3(const Params& p, bool use_simd) {
    Population pop;
    Locations locs;
    make_synthetic_input(p, pop, locs);  // host setup, shared with V0-V6 (untimed)
    return v3_impl(p, std::move(pop), std::move(locs), use_simd);
}

// External input: validated, then used as supplied (see simulation.hpp).
Result run_simulation_v3(const Params& p, const Population& in_pop, const Locations& in_locs, bool use_simd) {
    Population pop;
    Locations locs;
    make_external_input(in_pop, in_locs, pop, locs);
    return v3_impl(p, std::move(pop), std::move(locs), use_simd);
}

static Result v3_impl(const Params& p0, Population pop, Locations locs, bool use_simd) {
    Params p = p0;
    if (p.incubation_days < 1) p.incubation_days = 1;
    if (p.infectious_days < 1) p.infectious_days = 1;
    const size_t n = pop.size(), nl = locs.size();
    Result r;
    r.daily.push_back(count_states(pop));
#ifndef V3_NEON
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
#ifdef V3_NEON
        if (use_simd)
            for (; a + 16 <= n; a += 16) block16(c, a);
#endif
        for (; a < n; ++a) agent_scalar(c, a);
        r.daily.push_back(Counts{c.cs, c.ce, c.ci, c.cr});
    }
    r.seconds = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
    return r;
}
