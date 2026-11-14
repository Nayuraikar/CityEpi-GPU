#include <utility>
#include <chrono>
#include <cmath>
#include <stdexcept>
#include <string>
#include <atomic>
#include "rng.hpp"
#include "v4_rng.hpp"
#include "v4_simulation.hpp"
#ifdef _OPENACC
#include <openacc.h>
#endif

// Mapping of V1's fused pass onto OpenACC (see docs/v4_openacc.md):
//  kernel A (per location): prob[l] from infectious tally, then zero the tally (one writer per l).
//  kernel B (per agent):    RNG draws, branchless state/timer update, next-day tally via
//                           `acc atomic update` (integer -> order independent), state counts via
//                           reduction(+) (integer -> order independent).
// RNG is counter-based and all sums are integer, so results do not depend on gang/vector layout.
// Only floating-point difference source: exp() on device vs host libm (see v4_eval_prob / tests).

const char* v4_mode_name(V4Mode m) {
    switch (m) {
        case V4Mode::NoOpenACC: return "no-openacc (serial host loops)";
        case V4Mode::Host: return "openacc-host-fallback";
        default: return "openacc-device";
    }
}

static std::string compiler_id() {
#if defined(__NVCOMPILER)
    return "NVHPC nvc++ " + std::to_string(__NVCOMPILER_MAJOR__) + "." + std::to_string(__NVCOMPILER_MINOR__);
#elif defined(__clang__)
    return std::string("clang ") + __clang_version__;
#elif defined(__GNUC__)
    return std::string("GCC ") + __VERSION__;
#else
    return "unknown";
#endif
}

V4Info v4_probe() {
    V4Info i;
    i.compiler = compiler_id();
#ifdef _OPENACC
    i.openacc_version = _OPENACC;
    i.mode = V4Mode::Host;
    i.num_devices = acc_get_num_devices(acc_device_not_host);
    int on_dev = 0;
#pragma acc parallel copy(on_dev)
    { on_dev = acc_on_device(acc_device_not_host) ? 1 : 0; }
    if (on_dev) {
        i.mode = V4Mode::Device;
        const acc_device_t t = acc_get_device_type();
        const int num = acc_get_device_num(t);
        const char* nm = acc_get_property_string(num, t, acc_property_name);
        const char* vd = acc_get_property_string(num, t, acc_property_vendor);
        if (nm) i.device_name = nm;
        if (vd) i.device_vendor = vd;
    }
#endif
    return i;
}

void v4_eval_prob(const double* x, double* out, size_t n) {
    const size_t nn = n;
#pragma acc parallel loop copyin(x[0:nn]) copyout(out[0:nn])
    for (size_t i = 0; i < nn; ++i) out[i] = 1.0 - std::exp(-x[i]);
}

namespace {
std::atomic<int> g_live{0};

// RAII owner of the run's device mappings. Destructor deletes them (no copy-out) on every exit path
// that did not call finish(), including exceptions, so mappings cannot outlive a run or alias a
// later run whose host vectors reuse the same addresses.
struct DeviceData {
    uint8_t* st; uint16_t* tm; const uint32_t* hl; const uint32_t* wl;
    const uint8_t* lt; const uint32_t* occ; uint32_t* nin; double* pr;
    size_t n, nl;
    bool active = false;

    void enter() {
        uint8_t* st_ = st; uint16_t* tm_ = tm; const uint32_t* hl_ = hl; const uint32_t* wl_ = wl;
        const uint8_t* lt_ = lt; const uint32_t* occ_ = occ; uint32_t* nin_ = nin; double* pr_ = pr;
        const size_t n_ = n, nl_ = nl;
        (void)st_; (void)tm_; (void)hl_; (void)wl_; (void)lt_; (void)occ_; (void)nin_; (void)pr_; (void)n_; (void)nl_;
        active = true; ++g_live;  // set first: a partial failure still triggers cleanup
#pragma acc enter data copyin(st_[0:n_], tm_[0:n_], hl_[0:n_], wl_[0:n_], lt_[0:nl_], occ_[0:nl_], nin_[0:nl_]) create(pr_[0:nl_])
#pragma acc wait
    }
    void finish() {  // normal path: copy results back, release everything
        uint8_t* st_ = st; uint16_t* tm_ = tm; const uint32_t* hl_ = hl; const uint32_t* wl_ = wl;
        const uint8_t* lt_ = lt; const uint32_t* occ_ = occ; uint32_t* nin_ = nin; double* pr_ = pr;
        const size_t n_ = n, nl_ = nl;
        (void)st_; (void)tm_; (void)hl_; (void)wl_; (void)lt_; (void)occ_; (void)nin_; (void)pr_; (void)n_; (void)nl_;
        active = false; --g_live;
#pragma acc exit data copyout(st_[0:n_], tm_[0:n_]) delete(hl_[0:n_], wl_[0:n_], lt_[0:nl_], occ_[0:nl_], nin_[0:nl_], pr_[0:nl_])
    }
    ~DeviceData() {
        if (!active) return;
        uint8_t* st_ = st; uint16_t* tm_ = tm; const uint32_t* hl_ = hl; const uint32_t* wl_ = wl;
        const uint8_t* lt_ = lt; const uint32_t* occ_ = occ; uint32_t* nin_ = nin; double* pr_ = pr;
        const size_t n_ = n, nl_ = nl;
        (void)st_; (void)tm_; (void)hl_; (void)wl_; (void)lt_; (void)occ_; (void)nin_; (void)pr_; (void)n_; (void)nl_;
        --g_live;
#pragma acc exit data delete(st_[0:n_], tm_[0:n_], hl_[0:n_], wl_[0:n_], lt_[0:nl_], occ_[0:nl_], nin_[0:nl_], pr_[0:nl_])
    }
};
}  // namespace

int v4_live_mappings() { return g_live.load(); }

static V4Result v4_impl(const Params& p0, Population pop, Locations locs, const V4Config& cfg);

V4Result run_simulation_v4(const Params& p, const V4Config& cfg) {
    Population pop;
    Locations locs;
    make_synthetic_input(p, pop, locs);  // host setup, shared with V0-V6 (untimed)
    return v4_impl(p, std::move(pop), std::move(locs), cfg);
}

// External input: validated, then used as supplied (see simulation.hpp).
V4Result run_simulation_v4(const Params& p, const Population& in_pop, const Locations& in_locs, const V4Config& cfg) {
    Population pop;
    Locations locs;
    make_external_input(in_pop, in_locs, pop, locs);
    return v4_impl(p, std::move(pop), std::move(locs), cfg);
}

static V4Result v4_impl(const Params& p0, Population pop, Locations locs, const V4Config& cfg) {
    using clk = std::chrono::steady_clock;
    auto secs = [](clk::time_point a, clk::time_point b) { return std::chrono::duration<double>(b - a).count(); };

    Params p = p0;
    if (p.incubation_days < 1) p.incubation_days = 1;
    if (p.infectious_days < 1) p.infectious_days = 1;
    const size_t n = pop.size(), nl = locs.size();

    V4Result r;
    r.info = v4_probe();
    if (cfg.require_gpu && r.info.mode != V4Mode::Device)
        throw std::runtime_error(std::string("V4: GPU execution required but mode is '") +
                                 v4_mode_name(r.info.mode) + "'");
    r.daily.push_back(count_states(pop));

    std::vector<uint32_t> inf(nl, 0);
    std::vector<double> prob(nl, 0.0);
    for (size_t a = 0; a < n; ++a) {  // initial tally (host, untimed; same as V1/V2)
        const uint32_t isI = pop.state[a] == I;
        inf[pop.home_loc[a]] += isI;
        inf[pop.work_loc[a]] += isI;
    }
    const uint64_t hs = rng_v4::seed_stage(p.seed);
    const uint16_t inc = at_least1(p.incubation_days), idur = at_least1(p.infectious_days);
    const double beta_home = p.beta_home, beta_work = p.beta_work;
    uint8_t* st = pop.state.data();
    uint16_t* tm = pop.timer.data();
    const uint32_t* hl = pop.home_loc.data();
    const uint32_t* wl = pop.work_loc.data();
    const uint8_t* lt = locs.type.data();
    const uint32_t* occ = locs.occupancy.data();
    uint32_t* nin = inf.data();
    double* pr = prob.data();

    const auto t_start = clk::now();
    DeviceData dev{st, tm, hl, wl, lt, occ, nin, pr, n, nl};
    dev.enter();
    const auto t_in = clk::now();

    for (uint32_t d = 0; d < p.days; ++d) {
#pragma acc parallel loop present(lt[0:nl], occ[0:nl], nin[0:nl], pr[0:nl])
        for (size_t l = 0; l < nl; ++l) {
            const double beta = lt[l] == LOC_HOME ? beta_home : beta_work;
            const uint32_t o = occ[l];
            pr[l] = o ? 1.0 - std::exp(-beta * nin[l] / o) : 0.0;
            nin[l] = 0;  // becomes next-day tally
        }
        uint32_t cs = 0, ce = 0, ci = 0, cr = 0;
#pragma acc parallel loop present(st[0:n], tm[0:n], hl[0:n], wl[0:n], nin[0:nl], pr[0:nl]) \
    reduction(+ : cs, ce, ci, cr)
        for (size_t a = 0; a < n; ++a) {
            const uint8_t s = st[a];
            const uint16_t t = tm[a];
            const uint32_t h = hl[a], w = wl[a];
            bool hit = false;
            if (s == S) {
                const uint64_t ha = rng_v4::agent_stage(hs, (uint32_t)a);
                const double u1 = rng_v4::draw(ha, d, SLOT_EXPOSE_HOME);
                const double u2 = rng_v4::draw(ha, d, SLOT_EXPOSE_WORK);
                hit = (u1 < pr[h]) | (u2 < pr[w]);
            }
            const uint16_t t1 = (uint16_t)(t - (uint16_t)(s == E || s == I));
            const bool z = t1 == 0;
            const bool toI = (s == E) & z, toR = (s == I) & z, toE = (s == S) & hit;
            const uint8_t ns = (uint8_t)(s + (toE | toI | toR));
            const uint16_t nt = toE ? inc : toI ? idur : (s == E || s == I) ? t1 : t;
            st[a] = ns;
            tm[a] = nt;
            cs += ns == S; ce += ns == E; ci += ns == I; cr += ns == R;
            if (ns == I) {
#pragma acc atomic update
                nin[h] += 1;
#pragma acc atomic update
                nin[w] += 1;
            }
        }
        if ((uint64_t)cs + ce + ci + cr != n) throw std::runtime_error("population not conserved");
        r.daily.push_back(Counts{cs, ce, ci, cr});
        if (d + 1 == cfg.inject_failure_after_day) throw std::runtime_error("V4: injected failure (test hook)");
    }
#pragma acc wait
    const auto t_k = clk::now();
    dev.finish();
    const auto t_end = clk::now();

    // Transferred-back state must agree with the last device-side daily counts.
    if (!(count_states(pop) == r.daily.back())) throw std::runtime_error("V4: device/host state mismatch");

    r.seconds = secs(t_in, t_k);
    r.seconds_h2d = secs(t_start, t_in);
    r.seconds_d2h = secs(t_k, t_end);
    r.seconds_total = secs(t_start, t_end);
    return r;
}
