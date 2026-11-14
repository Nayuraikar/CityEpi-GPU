#include <utility>
#include <cuda_runtime.h>

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cmath>
#include <stdexcept>
#include <string>
#include <vector>
#include "rng.hpp"
#include "v6_rng.hpp"
#include "v6_simulation.hpp"

// V6: V5's two-kernel day structure with independently switchable optimizations (docs/v6_cuda.md).
// With every switch off the arithmetic and memory behaviour match V5 (the baseline row).
//
// Per simulated day (d = 0 .. days-1), on one non-blocking stream:
//   1. location_prob_kernel (thread per location): prob[l] from the infectious tally, zero the tally (one writer
//      per l); thread 0 increments the device day counter (ctr: d -> d+1). Only agent_step_kernel reads ctr, and
//      it runs after this kernel, so day = ctr - 1 and the day's counters live in slot ctr of `counts`.
//   2. agent_step_kernel (thread per agent): RNG draws, branchless state/timer update (reads only start-of-day
//      state + prob), integer atomics for the new-state counters and the next-day tally.
// The day is derived from a device counter so a CUDA Graph can replay the same two launches for many days.
// Daily S/E/I/R counts go to counts[4*(d+1) .. +3]; they return to the host per day (kSync) or once (kAsync/kGraph).
//
// Exactness: RNG is counter-based on the ORIGINAL agent id; every atomic sum is an integer, so no result depends
// on thread order. The probability keeps V0's operation order, 1.0 - exp((-beta * inf) / occ), with explicit
// round-to-nearest intrinsics and device exp(); built with -fmad=false and without fast-math. Device exp() is NOT
// claimed bit-identical to host libm; V0 equality of the final counts is the authoritative check.

#define V6_CHECK(call)                                                                              \
    do {                                                                                            \
        const cudaError_t e_ = (call);                                                              \
        if (e_ != cudaSuccess)                                                                      \
            throw std::runtime_error(std::string("V6 CUDA error: ") + #call + ": " +               \
                                     cudaGetErrorString(e_) + " (line " + std::to_string(__LINE__) + ")"); \
    } while (0)

namespace {

constexpr uint32_t kProbeMagic = 0xC17E9611u;
constexpr int kWarp = 32;
std::atomic<int> g_live{0};

// ---------------------------------------------------------------- device helpers
// 1 - exp(-beta * k / o) with V0's association ((-beta*k)/o) and explicit RN ops (never contracted into an FMA).
// SE (E3): k == 0 gives exactly 0 (-beta*0 is +-0, exp(+-0) = 1, 1 - 1 = +0), so skipping exp() cannot change it.
template <bool SE>
__device__ __forceinline__ double prob_value(double beta, uint32_t k, uint32_t o) {
    if (o == 0) return 0.0;
    if (SE && k == 0) return 0.0;
    return __dsub_rn(1.0, exp(__ddiv_rn(__dmul_rn(-beta, (double)k), (double)o)));
}

// ---------------------------------------------------------------- kernels
__global__ void probe_kernel(uint32_t* out) {
#ifdef __CUDA_ARCH__
    *out = kProbeMagic;  // only the device-compiled path can write this value
#else
    *out = 0;
#endif
}

template <int B, bool SE>
__global__ void __launch_bounds__(B)
location_prob_kernel(const uint8_t* __restrict__ lt, const uint32_t* __restrict__ occ, uint32_t* nin,
                     double* __restrict__ pr, uint32_t* ctr, size_t nl, double beta_home, double beta_work) {
    const size_t l = (size_t)blockIdx.x * B + threadIdx.x;
    if (l == 0) ctr[0] += 1;  // day counter; read only by agent_step_kernel (a later launch)
    if (l >= nl) return;
    const double beta = lt[l] == LOC_HOME ? beta_home : beta_work;
    pr[l] = prob_value<SE>(beta, nin[l], occ[l]);
    nin[l] = 0;  // becomes the next-day tally
}

// AGG (E1): aggregation of the 4 global STATE counters (S/E/I/R) only: per-state warp ballot + popc, block-level
//      shared sum, 4 global atomics per block. The location tallies (nin[home], nin[work]) are NOT aggregated:
//      agents are assigned to locations at random, so warps share almost no locations.
// SR   (E3): skip an RNG draw when the location probability is exactly 0 (u >= 0, so u < 0 is always false).
// PL   (E3): load home/work ids only when needed: susceptible (exposure) or becoming infectious (tally).
// No early return: every thread must reach the ballots and barriers.
template <int B, bool AGG, bool SR, bool PL>
__global__ void __launch_bounds__(B)
agent_step_kernel(uint8_t* __restrict__ st, uint16_t* __restrict__ tm, const uint32_t* __restrict__ hl,
                  const uint32_t* __restrict__ wl, const double* __restrict__ pr, uint32_t* nin,
                  uint32_t* counts, const uint32_t* ctr, size_t n, uint64_t hs, uint16_t inc, uint16_t idur) {
    const uint32_t cur = ctr[0];       // = day + 1
    const uint32_t day = cur - 1;
    uint32_t* const cnt = counts + 4 * (size_t)cur;
    const size_t a = (size_t)blockIdx.x * B + threadIdx.x;
    const bool valid = a < n;

    uint8_t s = 0, ns = 0;
    uint32_t h = 0, w = 0;
    if (valid) {
        s = st[a];
        const uint16_t t = tm[a];
        if constexpr (!PL) { h = hl[a]; w = wl[a]; }
        bool hit = false;
        if (s == S) {
            if constexpr (PL) { h = hl[a]; w = wl[a]; }
            const double ph = pr[h], pw = pr[w];
            if constexpr (SR) {
                if (ph > 0.0 || pw > 0.0) {
                    const uint64_t ha = rng_v6::agent_stage(hs, (uint32_t)a);
                    if (ph > 0.0) hit = rng_v6::draw(ha, day, SLOT_EXPOSE_HOME) < ph;
                    if (!hit && pw > 0.0) hit = rng_v6::draw(ha, day, SLOT_EXPOSE_WORK) < pw;
                }
            } else {
                const uint64_t ha = rng_v6::agent_stage(hs, (uint32_t)a);
                const double u1 = rng_v6::draw(ha, day, SLOT_EXPOSE_HOME);
                const double u2 = rng_v6::draw(ha, day, SLOT_EXPOSE_WORK);
                hit = (u1 < ph) | (u2 < pw);
            }
        }
        const uint16_t t1 = (uint16_t)(t - (uint16_t)(s == E || s == I));
        const bool z = t1 == 0;
        const bool toI = (s == E) & z, toR = (s == I) & z, toE = (s == S) & hit;
        ns = (uint8_t)(s + (toE | toI | toR));
        const uint16_t nt = toE ? inc : toI ? idur : (s == E || s == I) ? t1 : t;
        st[a] = ns;
        tm[a] = nt;
        // s == S never ends in I, so agents that tally were not loaded above
        if constexpr (PL) { if (ns == I && s != S) { h = hl[a]; w = wl[a]; } }
    }

    if constexpr (AGG) {
        __shared__ uint32_t sc[4];
        if (threadIdx.x < 4) sc[threadIdx.x] = 0;
        __syncthreads();
        const unsigned lane = threadIdx.x & (kWarp - 1);
#pragma unroll
        for (unsigned k = 0; k < 4; ++k) {
            const unsigned m = __ballot_sync(0xffffffffu, valid && ns == k);
            if (lane == 0 && m) atomicAdd(&sc[k], (uint32_t)__popc(m));
        }
        __syncthreads();
        if (threadIdx.x < 4 && sc[threadIdx.x]) atomicAdd(&cnt[threadIdx.x], sc[threadIdx.x]);
    } else if (valid) {
        atomicAdd(&cnt[ns], 1u);
    }
    if (valid && ns == I) {
        atomicAdd(&nin[h], 1u);
        atomicAdd(&nin[w], 1u);
    }
}

__global__ void draws_kernel(uint64_t hs, const uint32_t* agents, uint32_t day, uint32_t slot, double* out, size_t n) {
    const size_t i = (size_t)blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= n) return;
    out[i] = rng_v6::draw(rng_v6::agent_stage(hs, agents[i]), day, slot);
}

template <bool SE>
__global__ void prob_eval_kernel(const double* beta, const uint32_t* nin, const uint32_t* occ, double* out, size_t n) {
    const size_t i = (size_t)blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= n) return;
    out[i] = prob_value<SE>(beta[i], nin[i], occ[i]);
}

// ---------------------------------------------------------------- RAII helpers
struct AllocCtx {            // numbers allocations of one run so a specific one can be made to fail
    uint32_t count = 0, fail_at = 0;
};

template <class T>
struct DeviceBuffer {
    T* p = nullptr;
    DeviceBuffer() = default;
    DeviceBuffer(const DeviceBuffer&) = delete;
    DeviceBuffer& operator=(const DeviceBuffer&) = delete;
    void alloc(size_t n, AllocCtx& c) {
        if (++c.count == c.fail_at) throw std::runtime_error("V6: injected device allocation failure (test hook)");
        V6_CHECK(cudaMalloc((void**)&p, n * sizeof(T)));
        ++g_live;
    }
    ~DeviceBuffer() {
        if (p) { cudaFree(p); --g_live; }  // errors cannot be reported from a destructor
    }
    void upload(const T* host, size_t n) { V6_CHECK(cudaMemcpy(p, host, n * sizeof(T), cudaMemcpyHostToDevice)); }
    void download(T* host, size_t n) const { V6_CHECK(cudaMemcpy(host, p, n * sizeof(T), cudaMemcpyDeviceToHost)); }
    void zero(size_t n) { V6_CHECK(cudaMemset(p, 0, n * sizeof(T))); }
};

struct Event {
    cudaEvent_t e = nullptr;
    Event() { V6_CHECK(cudaEventCreate(&e)); }
    Event(const Event&) = delete;
    Event& operator=(const Event&) = delete;
    ~Event() { if (e) cudaEventDestroy(e); }
};

struct Stream {
    cudaStream_t s = nullptr;
    Stream() { V6_CHECK(cudaStreamCreateWithFlags(&s, cudaStreamNonBlocking)); }
    Stream(const Stream&) = delete;
    Stream& operator=(const Stream&) = delete;
    ~Stream() { if (s) { cudaStreamSynchronize(s); cudaStreamDestroy(s); } }
};

// Declared after the graphs: destructs first, so no graph/event/host buffer is released while work is in flight
// (matters on exception paths between an async launch and the final synchronisation).
struct SyncOnExit {
    cudaStream_t s;
    explicit SyncOnExit(cudaStream_t st) : s(st) {}
    SyncOnExit(const SyncOnExit&) = delete;
    SyncOnExit& operator=(const SyncOnExit&) = delete;
    ~SyncOnExit() { cudaStreamSynchronize(s); }
};

struct GraphExec {
    cudaGraph_t g = nullptr;
    cudaGraphExec_t x = nullptr;
    GraphExec() = default;
    GraphExec(const GraphExec&) = delete;
    GraphExec& operator=(const GraphExec&) = delete;
    ~GraphExec() {
        if (x) cudaGraphExecDestroy(x);
        if (g) cudaGraphDestroy(g);
    }
};

std::string compiler_id() {
#ifdef __CUDACC_VER_MAJOR__
    return "nvcc " + std::to_string(__CUDACC_VER_MAJOR__) + "." + std::to_string(__CUDACC_VER_MINOR__) + "." +
           std::to_string(__CUDACC_VER_BUILD__);
#else
    return "unknown";
#endif
}

// ---------------------------------------------------------------- kernel plans (compile-time options -> launchers)
struct DayArgs {
    uint8_t* st; uint16_t* tm; const uint32_t* hl; const uint32_t* wl; const uint8_t* lt; const uint32_t* occ;
    uint32_t* nin; double* pr; uint32_t* counts; uint32_t* ctr;
    size_t n, nl; uint64_t hs; uint16_t inc, idur; double bh, bw;
};
struct Plan {
    void (*loc)(const DayArgs&, cudaStream_t);
    void (*step)(const DayArgs&, cudaStream_t);
    const void* loc_fn;
    const void* step_fn;
    int block;
};

template <int B, bool SE>
void launch_loc(const DayArgs& a, cudaStream_t s) {
    location_prob_kernel<B, SE><<<(unsigned)((a.nl + B - 1) / B), B, 0, s>>>(a.lt, a.occ, a.nin, a.pr, a.ctr, a.nl, a.bh, a.bw);
    V6_CHECK(cudaGetLastError());
}
template <int B, bool AGG, bool SR, bool PL>
void launch_step(const DayArgs& a, cudaStream_t s) {
    agent_step_kernel<B, AGG, SR, PL><<<(unsigned)((a.n + B - 1) / B), B, 0, s>>>(
        a.st, a.tm, a.hl, a.wl, a.pr, a.nin, a.counts, a.ctr, a.n, a.hs, a.inc, a.idur);
    V6_CHECK(cudaGetLastError());
}
template <int B, bool AGG, bool SR, bool PL, bool SE>
Plan make_plan() {
    return Plan{&launch_loc<B, SE>, &launch_step<B, AGG, SR, PL>, (const void*)&location_prob_kernel<B, SE>,
                (const void*)&agent_step_kernel<B, AGG, SR, PL>, B};
}

template <int B>
Plan select_flags(const V6Opts& o) {
    const int k = (o.agg_counts ? 8 : 0) | (o.skip_rng ? 4 : 0) | (o.pred_loads ? 2 : 0) | (o.skip_exp ? 1 : 0);
    switch (k) {
#define V6_CASE(K, A, R, P, E) case K: return make_plan<B, A, R, P, E>();
        V6_CASE(0, false, false, false, false) V6_CASE(1, false, false, false, true)
        V6_CASE(2, false, false, true, false)  V6_CASE(3, false, false, true, true)
        V6_CASE(4, false, true, false, false)  V6_CASE(5, false, true, false, true)
        V6_CASE(6, false, true, true, false)   V6_CASE(7, false, true, true, true)
        V6_CASE(8, true, false, false, false)  V6_CASE(9, true, false, false, true)
        V6_CASE(10, true, false, true, false)  V6_CASE(11, true, false, true, true)
        V6_CASE(12, true, true, false, false)  V6_CASE(13, true, true, false, true)
        V6_CASE(14, true, true, true, false)   V6_CASE(15, true, true, true, true)
#undef V6_CASE
    }
    throw std::logic_error("V6: unreachable flag combination");
}

void validate(const V6Opts& o) {
    bool ok = false;
    for (uint32_t b : v6_supported_blocks()) ok = ok || b == o.block;
    if (!ok) throw std::invalid_argument("V6: unsupported block size " + std::to_string(o.block));
    if (o.mode != V6Mode::kSync && o.mode != V6Mode::kAsync && o.mode != V6Mode::kGraph)
        throw std::invalid_argument("V6: invalid mode");
    if (o.graph_days < 1) throw std::invalid_argument("V6: graph_days must be >= 1");
}

Plan select_plan(const V6Opts& o) {
    validate(o);
    switch (o.block) {
        case 64: return select_flags<64>(o);
        case 128: return select_flags<128>(o);
        case 256: return select_flags<256>(o);
        case 512: return select_flags<512>(o);
        default: return select_flags<1024>(o);
    }
}

void check_conserved(const uint32_t* c, size_t n) {
    if ((uint64_t)c[0] + c[1] + c[2] + c[3] != n) throw std::runtime_error("population not conserved");
}

size_t grid_for(size_t n, int b) { return (n + b - 1) / b; }

}  // namespace

// ---------------------------------------------------------------- public API
std::vector<uint32_t> v6_supported_blocks() { return {64, 128, 256, 512, 1024}; }

std::string v6_describe(const V6Opts& o) {
    std::string s;
    auto add = [&](const std::string& x) { s += (s.empty() ? "" : "+") + x; };
    if (o.agg_counts) add("agg");
    if (o.mode == V6Mode::kAsync) add("async");
    if (o.mode == V6Mode::kGraph) add("graph" + std::to_string(o.graph_days));
    if (o.skip_exp) add("skipexp");
    if (o.skip_rng) add("skiprng");
    if (o.pred_loads) add("predload");
    if (o.block != 256) add("b" + std::to_string(o.block));
    return s.empty() ? "base" : s;
}

int v6_live_allocations() { return g_live.load(); }

V6Info v6_probe() {
    V6Info i;
    i.compiler = compiler_id();
    try {
        int nd = 0;
        const cudaError_t e = cudaGetDeviceCount(&nd);
        if (e != cudaSuccess) {
            cudaGetLastError();
            i.error = std::string("cudaGetDeviceCount: ") + cudaGetErrorString(e);
            return i;
        }
        i.num_devices = nd;
        if (nd == 0) { i.error = "no CUDA device"; return i; }
        V6_CHECK(cudaSetDevice(0));
        cudaDeviceProp pr;
        V6_CHECK(cudaGetDeviceProperties(&pr, 0));
        i.device_name = pr.name;
        i.cc_major = pr.major;
        i.cc_minor = pr.minor;
        i.sm_count = pr.multiProcessorCount;
        i.max_threads_per_sm = pr.maxThreadsPerMultiProcessor;
        i.global_mem_bytes = pr.totalGlobalMem;
        V6_CHECK(cudaDriverGetVersion(&i.driver_version));
        V6_CHECK(cudaRuntimeGetVersion(&i.runtime_version));
        AllocCtx ctx;
        DeviceBuffer<uint32_t> d;
        d.alloc(1, ctx);
        const uint32_t zero = 0;
        d.upload(&zero, 1);
        probe_kernel<<<1, 1>>>(d.p);
        V6_CHECK(cudaGetLastError());
        uint32_t got = 0;
        d.download(&got, 1);
        if (got != kProbeMagic) { i.error = "probe kernel did not execute on a device"; return i; }
        i.gpu_ok = true;
    } catch (const std::exception& ex) {
        i.error = ex.what();
    }
    return i;
}

V6KernelInfo v6_kernel_info(const V6Opts& o) {
    const Plan pl = select_plan(o);
    int dev = 0, maxthr = 0;
    V6_CHECK(cudaSetDevice(0));
    V6_CHECK(cudaGetDevice(&dev));
    V6_CHECK(cudaDeviceGetAttribute(&maxthr, cudaDevAttrMaxThreadsPerMultiProcessor, dev));
    V6KernelInfo k;
    cudaFuncAttributes a;
    int nb = 0;
    V6_CHECK(cudaFuncGetAttributes(&a, pl.loc_fn));
    V6_CHECK(cudaOccupancyMaxActiveBlocksPerMultiprocessor(&nb, pl.loc_fn, pl.block, 0));
    k.loc_regs = a.numRegs; k.loc_local_bytes = a.localSizeBytes; k.loc_static_smem = a.sharedSizeBytes;
    k.loc_blocks_per_sm = nb; k.loc_occupancy_pct = maxthr ? 100.0 * nb * pl.block / maxthr : 0;
    V6_CHECK(cudaFuncGetAttributes(&a, pl.step_fn));
    V6_CHECK(cudaOccupancyMaxActiveBlocksPerMultiprocessor(&nb, pl.step_fn, pl.block, 0));
    k.step_regs = a.numRegs; k.step_local_bytes = a.localSizeBytes; k.step_static_smem = a.sharedSizeBytes;
    k.step_blocks_per_sm = nb; k.step_occupancy_pct = maxthr ? 100.0 * nb * pl.block / maxthr : 0;
    return k;
}

void v6_eval_draws(uint64_t seed, const uint32_t* agents, uint32_t day, uint32_t slot, double* out, size_t n) {
    if (n == 0) return;
    AllocCtx ctx;
    DeviceBuffer<uint32_t> da;
    DeviceBuffer<double> dout;
    da.alloc(n, ctx);
    dout.alloc(n, ctx);
    da.upload(agents, n);
    draws_kernel<<<(unsigned)grid_for(n, 256), 256>>>(rng_v6::seed_stage(seed), da.p, day, slot, dout.p, n);
    V6_CHECK(cudaGetLastError());
    dout.download(out, n);
}

void v6_eval_prob(const double* beta, const uint32_t* nin, const uint32_t* occ, bool skip_exp, double* out, size_t n) {
    if (n == 0) return;
    AllocCtx ctx;
    DeviceBuffer<double> db, dout;
    DeviceBuffer<uint32_t> dn, doc;
    db.alloc(n, ctx); dn.alloc(n, ctx); doc.alloc(n, ctx); dout.alloc(n, ctx);
    db.upload(beta, n); dn.upload(nin, n); doc.upload(occ, n);
    const unsigned g = (unsigned)grid_for(n, 256);
    if (skip_exp) prob_eval_kernel<true><<<g, 256>>>(db.p, dn.p, doc.p, dout.p, n);
    else prob_eval_kernel<false><<<g, 256>>>(db.p, dn.p, doc.p, dout.p, n);
    V6_CHECK(cudaGetLastError());
    dout.download(out, n);
}

static V6Result v6_impl(const Params& p0, Population pop, Locations locs, const V6Config& cfg);

V6Result run_simulation_v6(const Params& p, const V6Config& cfg) {
    Population pop;
    Locations locs;
    make_synthetic_input(p, pop, locs);  // host setup, shared with V0-V6 (untimed)
    return v6_impl(p, std::move(pop), std::move(locs), cfg);
}

// External input: validated, then used as supplied (see simulation.hpp).
V6Result run_simulation_v6(const Params& p, const Population& in_pop, const Locations& in_locs, const V6Config& cfg) {
    Population pop;
    Locations locs;
    make_external_input(in_pop, in_locs, pop, locs);
    return v6_impl(p, std::move(pop), std::move(locs), cfg);
}

static V6Result v6_impl(const Params& p0, Population pop, Locations locs, const V6Config& cfg) {
    using clk = std::chrono::steady_clock;
    auto secs = [](clk::time_point a, clk::time_point b) { return std::chrono::duration<double>(b - a).count(); };

    const Plan plan = select_plan(cfg.opts);  // validates options before anything is allocated
    Params p = p0;
    if (p.incubation_days < 1) p.incubation_days = 1;
    if (p.infectious_days < 1) p.infectious_days = 1;
    const size_t n = pop.size(), nl = locs.size();

    V6Result r;
    r.opts = cfg.opts;
    r.info = v6_probe();
    if (!r.info.gpu_ok) throw std::runtime_error("V6: no usable CUDA device (" + r.info.error + ")");
    r.daily.push_back(count_states(pop));

    std::vector<uint32_t> inf(nl, 0);  // initial tally (host, untimed; same as V1/V2/V4/V5)
    for (size_t a = 0; a < n; ++a) {
        const uint32_t isI = pop.state[a] == I;
        inf[pop.home_loc[a]] += isI;
        inf[pop.work_loc[a]] += isI;
    }
    const uint32_t days = p.days;
    const uint64_t hs = rng_v6::seed_stage(p.seed);
    const uint16_t inc = at_least1(p.incubation_days), idur = at_least1(p.infectious_days);

    const auto t_start = clk::now();
    AllocCtx ctx;
    ctx.fail_at = cfg.inject_alloc_failure_at;
    DeviceBuffer<uint8_t> d_st, d_lt;
    DeviceBuffer<uint16_t> d_tm;
    DeviceBuffer<uint32_t> d_hl, d_wl, d_occ, d_nin, d_counts, d_ctr;
    DeviceBuffer<double> d_pr;
    d_st.alloc(n, ctx); d_tm.alloc(n, ctx); d_hl.alloc(n, ctx); d_wl.alloc(n, ctx);
    d_lt.alloc(nl, ctx); d_occ.alloc(nl, ctx); d_nin.alloc(nl, ctx); d_pr.alloc(nl, ctx);
    d_counts.alloc(4 * (size_t)(days + 1), ctx);
    d_ctr.alloc(1, ctx);
    d_st.upload(pop.state.data(), n);
    d_tm.upload(pop.timer.data(), n);
    d_hl.upload(pop.home_loc.data(), n);
    d_wl.upload(pop.work_loc.data(), n);
    d_lt.upload(locs.type.data(), nl);
    d_occ.upload(locs.occupancy.data(), nl);
    d_nin.upload(inf.data(), nl);
    d_counts.zero(4 * (size_t)(days + 1));
    d_ctr.zero(1);

    std::vector<uint32_t> h_counts(4 * (size_t)(days + 1), 0);  // before the stream: outlives pending async copies
    Stream stream;
    DayArgs a{d_st.p, d_tm.p, d_hl.p, d_wl.p, d_lt.p, d_occ.p, d_nin.p, d_pr.p, d_counts.p, d_ctr.p,
              n, nl, hs, inc, idur, p.beta_home, p.beta_work};

    // kGraph: capture `chunk` days (two launches each) once; build is setup cost (counted in seconds_h2d).
    const uint32_t chunk = std::min(cfg.opts.graph_days, std::max(days, 1u));
    GraphExec g_full, g_tail;
    SyncOnExit sync_guard(stream.s);
    const bool use_graph = cfg.opts.mode == V6Mode::kGraph && !cfg.profile && days > 0;
    const uint32_t full_launches = days / chunk, tail_days = days % chunk;
    if (use_graph) {
        auto build = [&](GraphExec& ge, uint32_t nd) {
            V6_CHECK(cudaStreamBeginCapture(stream.s, cudaStreamCaptureModeThreadLocal));
            try {
                for (uint32_t i = 0; i < nd; ++i) { plan.loc(a, stream.s); plan.step(a, stream.s); }
            } catch (...) {
                cudaGraph_t junk = nullptr;
                cudaStreamEndCapture(stream.s, &junk);
                if (junk) cudaGraphDestroy(junk);
                throw;
            }
            V6_CHECK(cudaStreamEndCapture(stream.s, &ge.g));
#if defined(CUDART_VERSION) && CUDART_VERSION >= 12000
            V6_CHECK(cudaGraphInstantiate(&ge.x, ge.g, 0));
#else
            V6_CHECK(cudaGraphInstantiate(&ge.x, ge.g, nullptr, nullptr, 0));
#endif
        };
        if (full_launches > 0) build(g_full, chunk);
        if (tail_days > 0) build(g_tail, tail_days);
    }
    V6_CHECK(cudaDeviceSynchronize());
    const auto t_in = clk::now();

    Event ev0, ev1;
    V6_CHECK(cudaEventRecord(ev0.e, stream.s));
    std::vector<Event> pe(cfg.profile ? 3 * (size_t)days : 0);  // profile: per day before loc, after loc, after step
    const bool deferred = cfg.opts.mode != V6Mode::kSync || cfg.profile;
    if (!deferred) {
        for (uint32_t d = 0; d < days; ++d) {
            plan.loc(a, stream.s);
            plan.step(a, stream.s);
            uint32_t c[4] = {0, 0, 0, 0};
            V6_CHECK(cudaMemcpyAsync(c, d_counts.p + 4 * (size_t)(d + 1), sizeof c, cudaMemcpyDeviceToHost, stream.s));
            V6_CHECK(cudaStreamSynchronize(stream.s));
            check_conserved(c, n);
            r.daily.push_back(Counts{c[S], c[E], c[I], c[R]});
            if (d + 1 == cfg.inject_failure_after_day) throw std::runtime_error("V6: injected failure (test hook)");
        }
        V6_CHECK(cudaEventRecord(ev1.e, stream.s));
    } else {
        if (cfg.profile) {
            for (uint32_t d = 0; d < days; ++d) {
                V6_CHECK(cudaEventRecord(pe[3 * (size_t)d].e, stream.s));
                plan.loc(a, stream.s);
                V6_CHECK(cudaEventRecord(pe[3 * (size_t)d + 1].e, stream.s));
                plan.step(a, stream.s);
                V6_CHECK(cudaEventRecord(pe[3 * (size_t)d + 2].e, stream.s));
            }
        } else if (use_graph) {
            for (uint32_t i = 0; i < full_launches; ++i) V6_CHECK(cudaGraphLaunch(g_full.x, stream.s));
            if (tail_days > 0) V6_CHECK(cudaGraphLaunch(g_tail.x, stream.s));
        } else {
            for (uint32_t d = 0; d < days; ++d) { plan.loc(a, stream.s); plan.step(a, stream.s); }
        }
        // one deferred readback of every day's counters (part of the timed region, like V5's per-day copies)
        V6_CHECK(cudaMemcpyAsync(h_counts.data(), d_counts.p, h_counts.size() * sizeof(uint32_t),
                                 cudaMemcpyDeviceToHost, stream.s));
        V6_CHECK(cudaEventRecord(ev1.e, stream.s));
    }
    V6_CHECK(cudaEventSynchronize(ev1.e));
    const auto t_k = clk::now();
    float ms = 0;
    V6_CHECK(cudaEventElapsedTime(&ms, ev0.e, ev1.e));

    if (deferred) {
        if (cfg.inject_failure_after_day >= 1 && cfg.inject_failure_after_day <= days)
            throw std::runtime_error("V6: injected failure (test hook)");
        for (uint32_t d = 1; d <= days; ++d) {
            const uint32_t* c = &h_counts[4 * (size_t)d];
            check_conserved(c, n);
            r.daily.push_back(Counts{c[S], c[E], c[I], c[R]});
        }
        if (cfg.profile)
            for (uint32_t d = 0; d < days; ++d) {
                float x = 0;
                V6_CHECK(cudaEventElapsedTime(&x, pe[3 * (size_t)d].e, pe[3 * (size_t)d + 1].e));
                r.prof_loc_ms += x;
                V6_CHECK(cudaEventElapsedTime(&x, pe[3 * (size_t)d + 1].e, pe[3 * (size_t)d + 2].e));
                r.prof_step_ms += x;
            }
    }

    d_st.download(pop.state.data(), n);
    d_tm.download(pop.timer.data(), n);
    const auto t_end = clk::now();

    // Transferred-back state must agree with the last device-side daily counts.
    if (!(count_states(pop) == r.daily.back())) throw std::runtime_error("V6: device/host state mismatch");

    r.seconds = secs(t_in, t_k);
    r.seconds_h2d = secs(t_start, t_in);
    r.seconds_d2h = secs(t_k, t_end);
    r.seconds_total = secs(t_start, t_end);
    r.seconds_events = ms / 1000.0;
    return r;
}
