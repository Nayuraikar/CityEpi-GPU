#include <utility>
#include <cuda_runtime.h>

#include <atomic>
#include <chrono>
#include <cmath>
#include <stdexcept>
#include <string>
#include <vector>
#include "rng.hpp"
#include "v5_rng.hpp"
#include "v5_simulation.hpp"

// Naive CUDA mapping of V4's two fused kernels (see docs/v5_cuda.md). Per simulated day:
//   1. location_prob_kernel (one thread per location): prob[l] from the infectious tally, then zero the
//      tally (one writer per l); thread 0 also zeroes the 4 state counters.
//   2. agent_step_kernel (one thread per agent): RNG draws, branchless state/timer update (reads only
//      start-of-day state + prob), atomicAdd of the next-day tally and of the new-state counter.
//   3. cudaMemcpy of the 16-byte counter array to the host (also the per-day synchronisation point).
// RNG is counter-based and every atomic sum is an integer, so results do not depend on thread order.
// The prob expression keeps V0's floating-point operation order: 1.0 - exp((-beta * inf) / occ).
// Build with -fmad=false so no FMA contraction can alter it.

#define V5_CHECK(call)                                                                              \
    do {                                                                                            \
        const cudaError_t e_ = (call);                                                              \
        if (e_ != cudaSuccess)                                                                      \
            throw std::runtime_error(std::string("V5 CUDA error: ") + #call + ": " +               \
                                     cudaGetErrorString(e_) + " (line " + std::to_string(__LINE__) + ")"); \
    } while (0)

namespace {

constexpr int kBlock = 256;
constexpr uint32_t kProbeMagic = 0xC17E9111u;
std::atomic<int> g_live{0};

// ---------------------------------------------------------------- kernels
__global__ void probe_kernel(uint32_t* out) {
#ifdef __CUDA_ARCH__
    *out = kProbeMagic;  // only the device-compiled path can write this value
#else
    *out = 0;
#endif
}

__global__ void location_prob_kernel(const uint8_t* lt, const uint32_t* occ, uint32_t* nin, double* pr,
                                     uint32_t* counts, size_t nl, double beta_home, double beta_work) {
    const size_t l = (size_t)blockIdx.x * blockDim.x + threadIdx.x;
    if (l == 0) { counts[0] = 0; counts[1] = 0; counts[2] = 0; counts[3] = 0; }
    if (l >= nl) return;
    const double beta = lt[l] == LOC_HOME ? beta_home : beta_work;
    const uint32_t o = occ[l];
    pr[l] = o ? 1.0 - exp(-beta * nin[l] / o) : 0.0;
    nin[l] = 0;  // becomes the next-day tally
}

__global__ void agent_step_kernel(uint8_t* st, uint16_t* tm, const uint32_t* hl, const uint32_t* wl,
                                  const double* pr, uint32_t* nin, uint32_t* counts, size_t n, uint64_t hs,
                                  uint32_t day, uint16_t inc, uint16_t idur) {
    const size_t a = (size_t)blockIdx.x * blockDim.x + threadIdx.x;
    if (a >= n) return;
    const uint8_t s = st[a];
    const uint16_t t = tm[a];
    const uint32_t h = hl[a], w = wl[a];
    bool hit = false;
    if (s == S) {
        const uint64_t ha = rng_v5::agent_stage(hs, (uint32_t)a);
        const double u1 = rng_v5::draw(ha, day, SLOT_EXPOSE_HOME);
        const double u2 = rng_v5::draw(ha, day, SLOT_EXPOSE_WORK);
        hit = (u1 < pr[h]) | (u2 < pr[w]);
    }
    const uint16_t t1 = (uint16_t)(t - (uint16_t)(s == E || s == I));
    const bool z = t1 == 0;
    const bool toI = (s == E) & z, toR = (s == I) & z, toE = (s == S) & hit;
    const uint8_t ns = (uint8_t)(s + (toE | toI | toR));
    const uint16_t nt = toE ? inc : toI ? idur : (s == E || s == I) ? t1 : t;
    st[a] = ns;
    tm[a] = nt;
    atomicAdd(&counts[ns], 1u);
    if (ns == I) {
        atomicAdd(&nin[h], 1u);
        atomicAdd(&nin[w], 1u);
    }
}

__global__ void draws_kernel(uint64_t hs, const uint32_t* agents, uint32_t day, uint32_t slot, double* out, size_t n) {
    const size_t i = (size_t)blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= n) return;
    out[i] = rng_v5::draw(rng_v5::agent_stage(hs, agents[i]), day, slot);
}

__global__ void prob_eval_kernel(const double* x, double* out, size_t n) {
    const size_t i = (size_t)blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= n) return;
    out[i] = 1.0 - exp(-x[i]);
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
        if (++c.count == c.fail_at) throw std::runtime_error("V5: injected device allocation failure (test hook)");
        V5_CHECK(cudaMalloc((void**)&p, n * sizeof(T)));
        ++g_live;
    }
    ~DeviceBuffer() {
        if (p) { cudaFree(p); --g_live; }  // errors cannot be reported from a destructor
    }
    void upload(const T* host, size_t n) { V5_CHECK(cudaMemcpy(p, host, n * sizeof(T), cudaMemcpyHostToDevice)); }
    void download(T* host, size_t n) const { V5_CHECK(cudaMemcpy(host, p, n * sizeof(T), cudaMemcpyDeviceToHost)); }
};

struct Event {
    cudaEvent_t e = nullptr;
    Event() { V5_CHECK(cudaEventCreate(&e)); }
    Event(const Event&) = delete;
    Event& operator=(const Event&) = delete;
    ~Event() { if (e) cudaEventDestroy(e); }
};

size_t grid_for(size_t n) { return (n + kBlock - 1) / kBlock; }

std::string compiler_id() {
#ifdef __CUDACC_VER_MAJOR__
    return "nvcc " + std::to_string(__CUDACC_VER_MAJOR__) + "." + std::to_string(__CUDACC_VER_MINOR__) + "." +
           std::to_string(__CUDACC_VER_BUILD__);
#else
    return "unknown";
#endif
}

}  // namespace

int v5_live_allocations() { return g_live.load(); }

V5Info v5_probe() {
    V5Info i;
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
        V5_CHECK(cudaSetDevice(0));
        cudaDeviceProp pr;
        V5_CHECK(cudaGetDeviceProperties(&pr, 0));
        i.device_name = pr.name;
        i.cc_major = pr.major;
        i.cc_minor = pr.minor;
        i.sm_count = pr.multiProcessorCount;
        i.global_mem_bytes = pr.totalGlobalMem;
        V5_CHECK(cudaDriverGetVersion(&i.driver_version));
        V5_CHECK(cudaRuntimeGetVersion(&i.runtime_version));
        // Proof of execution: a kernel must run and write a value only device-compiled code can produce.
        AllocCtx ctx;
        DeviceBuffer<uint32_t> d;
        d.alloc(1, ctx);
        const uint32_t zero = 0;
        d.upload(&zero, 1);
        probe_kernel<<<1, 1>>>(d.p);
        V5_CHECK(cudaGetLastError());
        uint32_t got = 0;
        d.download(&got, 1);
        if (got != kProbeMagic) { i.error = "probe kernel did not execute on a device"; return i; }
        i.gpu_ok = true;
    } catch (const std::exception& ex) {
        i.error = ex.what();
    }
    return i;
}

void v5_eval_draws(uint64_t seed, const uint32_t* agents, uint32_t day, uint32_t slot, double* out, size_t n) {
    if (n == 0) return;
    AllocCtx ctx;
    DeviceBuffer<uint32_t> da;
    DeviceBuffer<double> dout;
    da.alloc(n, ctx);
    dout.alloc(n, ctx);
    da.upload(agents, n);
    draws_kernel<<<grid_for(n), kBlock>>>(rng_v5::seed_stage(seed), da.p, day, slot, dout.p, n);
    V5_CHECK(cudaGetLastError());
    dout.download(out, n);
}

void v5_eval_prob(const double* x, double* out, size_t n) {
    if (n == 0) return;
    AllocCtx ctx;
    DeviceBuffer<double> dx, dout;
    dx.alloc(n, ctx);
    dout.alloc(n, ctx);
    dx.upload(x, n);
    prob_eval_kernel<<<grid_for(n), kBlock>>>(dx.p, dout.p, n);
    V5_CHECK(cudaGetLastError());
    dout.download(out, n);
}

static V5Result v5_impl(const Params& p0, Population pop, Locations locs, const V5Config& cfg);

V5Result run_simulation_v5(const Params& p, const V5Config& cfg) {
    Population pop;
    Locations locs;
    make_synthetic_input(p, pop, locs);  // host setup, shared with V0-V6 (untimed)
    return v5_impl(p, std::move(pop), std::move(locs), cfg);
}

// External input: validated, then used as supplied (see simulation.hpp).
V5Result run_simulation_v5(const Params& p, const Population& in_pop, const Locations& in_locs, const V5Config& cfg) {
    Population pop;
    Locations locs;
    make_external_input(in_pop, in_locs, pop, locs);
    return v5_impl(p, std::move(pop), std::move(locs), cfg);
}

static V5Result v5_impl(const Params& p0, Population pop, Locations locs, const V5Config& cfg) {
    using clk = std::chrono::steady_clock;
    auto secs = [](clk::time_point a, clk::time_point b) { return std::chrono::duration<double>(b - a).count(); };

    Params p = p0;
    if (p.incubation_days < 1) p.incubation_days = 1;
    if (p.infectious_days < 1) p.infectious_days = 1;
    const size_t n = pop.size(), nl = locs.size();

    V5Result r;
    r.info = v5_probe();
    if (!r.info.gpu_ok) throw std::runtime_error("V5: no usable CUDA device (" + r.info.error + ")");
    r.daily.push_back(count_states(pop));

    std::vector<uint32_t> inf(nl, 0);  // initial tally (host, untimed; same as V1/V2/V4)
    for (size_t a = 0; a < n; ++a) {
        const uint32_t isI = pop.state[a] == I;
        inf[pop.home_loc[a]] += isI;
        inf[pop.work_loc[a]] += isI;
    }
    const uint64_t hs = rng_v5::seed_stage(p.seed);
    const uint16_t inc = at_least1(p.incubation_days), idur = at_least1(p.infectious_days);

    const auto t_start = clk::now();
    AllocCtx ctx;
    ctx.fail_at = cfg.inject_alloc_failure_at;
    DeviceBuffer<uint8_t> d_st, d_lt;
    DeviceBuffer<uint16_t> d_tm;
    DeviceBuffer<uint32_t> d_hl, d_wl, d_occ, d_nin, d_counts;
    DeviceBuffer<double> d_pr;
    d_st.alloc(n, ctx); d_tm.alloc(n, ctx); d_hl.alloc(n, ctx); d_wl.alloc(n, ctx);
    d_lt.alloc(nl, ctx); d_occ.alloc(nl, ctx); d_nin.alloc(nl, ctx); d_pr.alloc(nl, ctx);
    d_counts.alloc(4, ctx);
    d_st.upload(pop.state.data(), n);
    d_tm.upload(pop.timer.data(), n);
    d_hl.upload(pop.home_loc.data(), n);
    d_wl.upload(pop.work_loc.data(), n);
    d_lt.upload(locs.type.data(), nl);
    d_occ.upload(locs.occupancy.data(), nl);
    d_nin.upload(inf.data(), nl);
    V5_CHECK(cudaDeviceSynchronize());
    const auto t_in = clk::now();

    const size_t grid_l = grid_for(nl), grid_a = grid_for(n);
    Event ev0, ev1;
    V5_CHECK(cudaEventRecord(ev0.e));
    for (uint32_t d = 0; d < p.days; ++d) {
        location_prob_kernel<<<grid_l, kBlock>>>(d_lt.p, d_occ.p, d_nin.p, d_pr.p, d_counts.p, nl, p.beta_home, p.beta_work);
        V5_CHECK(cudaGetLastError());
        agent_step_kernel<<<grid_a, kBlock>>>(d_st.p, d_tm.p, d_hl.p, d_wl.p, d_pr.p, d_nin.p, d_counts.p, n, hs, d, inc, idur);
        V5_CHECK(cudaGetLastError());
        uint32_t c[4] = {0, 0, 0, 0};
        d_counts.download(c, 4);  // synchronous: waits for both kernels
        if ((uint64_t)c[0] + c[1] + c[2] + c[3] != n) throw std::runtime_error("population not conserved");
        r.daily.push_back(Counts{c[S], c[E], c[I], c[R]});
        if (d + 1 == cfg.inject_failure_after_day) throw std::runtime_error("V5: injected failure (test hook)");
    }
    V5_CHECK(cudaEventRecord(ev1.e));
    V5_CHECK(cudaEventSynchronize(ev1.e));
    const auto t_k = clk::now();
    float ms = 0;
    V5_CHECK(cudaEventElapsedTime(&ms, ev0.e, ev1.e));

    d_st.download(pop.state.data(), n);
    d_tm.download(pop.timer.data(), n);
    const auto t_end = clk::now();

    // Transferred-back state must agree with the last device-side daily counts.
    if (!(count_states(pop) == r.daily.back())) throw std::runtime_error("V5: device/host state mismatch");

    r.seconds = secs(t_in, t_k);
    r.seconds_h2d = secs(t_start, t_in);
    r.seconds_d2h = secs(t_k, t_end);
    r.seconds_total = secs(t_start, t_end);
    r.seconds_events = ms / 1000.0;
    return r;
}
