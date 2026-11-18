# PAGP concepts in CityEpi-GPU

*PAGP = Parallel Architectures & GPU Programming.* For each concept below the table says **where it is implemented**, **what
evidence exists**, and **what is not claimed**. A concept is listed as implemented only if code for it exists; ideas that are only
discussed are marked *not implemented*. Line numbers refer to the sources as of this documentation pass and can drift; the
function/pragma names are the stable anchor.

The epidemic model (identical in every backend): each day, per location, the infection probability is
`prob[l] = 1 − exp(−β · infectious_tally[l] / occupancy[l])`; each susceptible agent draws against its home and destination
probabilities with a counter-based RNG keyed by `(seed, agent, day, slot)`; E → I → R timers advance; counts are tallied.

## Summary map

| # | Concept | Backends | Main files |
|---|---|---|---|
| 1 | Instruction-level parallelism | V1 | `src/v1_ilp/v1_simulation.cpp`, `include/rng_inline.hpp` |
| 2 | Thread-level parallelism (OpenMP) | V2 | `src/v2_openmp/v2_simulation.cpp` |
| 3 | OpenMP scheduling | V2 | `omp_set_schedule` / `schedule(runtime)` in `v2_simulation.cpp`, `bench/bench_v2.cpp` |
| 4 | SIMD / data-level parallelism | V3 | `src/v3_simd/v3_simulation.cpp`, `v3_hybrid.cpp` |
| 5 | GPU execution and SIMT | V4–V6 | `src/v5_cuda/v5_simulation.cu`, `src/v6_cuda/v6_simulation.cu` |
| 6 | OpenACC | V4 | `src/v4_openacc/v4_simulation.cpp` |
| 7 | CUDA memory management | V5, V6 | `v5_simulation.cu`, `v6_simulation.cu` |
| 8 | Hierarchical reductions | V2, V6 (and V4 data clauses) | `v2_simulation.cpp`, `v6_simulation.cu:129-141` |
| 9 | Warp-level primitives | V6 | `__ballot_sync` + `__popc`, `v6_simulation.cu:135-136` |
| 10 | Asynchronous execution | V6 | `V6Mode::kAsync`, `cudaMemcpyAsync`, non-blocking stream |
| 11 | CUDA Graphs | V6 | `V6Mode::kGraph`, `cudaStreamBeginCapture`/`cudaGraphInstantiate`/`cudaGraphLaunch` |
| 12 | Deterministic parallel execution | all | `include/rng*.hpp`, staged day design |
| 13 | Performance measurement | all | `bench/bench*.cpp`, `bench/analyze_v6.py` |
| 14 | Strong scaling, speedup, efficiency | V2, V4–V6 | `bench/bench_v2.cpp`, `bench/results/*` |
| 15 | Correctness validation | all | `tests/test_v*.cpp`, `tests/test_extpop_*.cpp` |

## 1. Instruction-level parallelism — V1

* **Implemented.** One fused pass instead of several; the RNG is inlined (`include/rng_inline.hpp`) with the seed stage hoisted and
  the agent stage shared by both slots, so two independent dependency chains are available to the out-of-order core; transitions
  and counters are branchless; `__restrict` pointers on the state arrays (`v1_simulation.cpp:50-53`); a per-location probability
  table so `exp` runs once per location, not once per agent.
* **Evidence.** `bench/README.md`: median-of-7 on Apple M1, 2.21–2.38× faster than V0 (10k → 500k agents), outputs identical to
  V0; compiler remarks and assembly in `bench/reports/` show V1's agent loop is **not** auto-vectorized, so the gain is scalar.
* **Not claimed.** No per-change ablation was run: part of the gain is fewer instructions and memory passes, not purely ILP.

## 2. Thread-level parallelism — V2 (OpenMP)

* **Implemented.** `#pragma omp parallel num_threads(T) reduction(+: cs, ce, ci, cr)` (`v2_simulation.cpp:46`); each location's
  probability has one writer; agents read only their own state and the read-only `prob[]`.
* **Contention experiment.** Two scatter strategies selectable via `Reduce::Local` (private per-thread histograms, merged by the
  single owner of each location) and `Reduce::Atomic` (shared array, `#pragma omp atomic`, lines 74-79).
* **Evidence.** `bench/results/v2_results.csv`, `bench/README.md`, `bench/results/v2_env.txt` (Apple M1, Homebrew clang 23.1.5, libomp).
  At 1M agents, 8 threads: Local 4.25× vs V0 and Atomic 0.38× vs V0; thread-local reductions beat atomics 3–10× at ≥ 2 threads.
* **Not claimed.** Scaling saturates near 4 threads (the M1 has 4 performance + 4 efficiency cores; efficiency at 8 threads ≈ 0.3).
  `OMP_PROC_BIND`/places and > 8 threads were not tested.

## 3. OpenMP scheduling — V2

* **Implemented.** `#pragma omp for schedule(runtime)` (line 53) with `omp_set_schedule(kind, chunk)` (line 121), so static,
  dynamic(1024) and guided are compared in the same binary.
* **Evidence.** Within about ±10% at most sizes (uniform work); static wins at 100k with 4–8 threads (dynamic/guided 1.4–1.8× slower
  at 8T/100k); best 100k point: static, 4 threads, 5.49× vs V0, efficiency 0.78 (`bench/README.md`).

## 4. SIMD / data-level parallelism — V3

* **Implemented (aarch64 only).** `src/v3_simd/v3_simulation.cpp`: full NEON path — blocks of 16 agents, splitmix64 on two agents per
  vector with the 64-bit multiply **emulated** (`vmull_u32` and friends, line 65). `v3_hybrid.cpp`: scalar RNG with NEON transition
  and counting (`vld1q_u8`, `vceqq_u8`, `vbslq_u16`, lines 54-66). Both guarded by `#if defined(__aarch64__) && defined(__ARM_NEON)`;
  elsewhere a scalar fallback is compiled.
* **Evidence (Apple M1).** Full NEON ≈ 1.3× faster than V0 but ≈ 1.7–1.8× **slower than V1** at every size (and slower than its own
  scalar fallback); the hybrid is 1.10–1.14× faster than V1 at 10k–100k and indistinguishable from V1 at 500k–1M. The compiler did
  not auto-vectorize any V1/V3 loop (`bench/reports/*.remarks.txt`). Do not present SIMD as a win for this workload.
* **Provenance caveat.** The Kaggle V3 rows were produced on an x86 host where NEON is unavailable; they are scalar fallback
  measurements, **not** NEON measurements.

## 5. GPU execution and SIMT — V4, V5, V6

* **Implemented.** V5/V6: `location_prob_kernel` (thread per location) and `agent_step_kernel` (thread per agent), a day-by-day
  two-kernel structure. V6 uses `template<int B>` block sizes with `__launch_bounds__(B)` (`v6_simulation.cu:66,84`).
  The branchless state/timer update avoids intra-warp divergence in the transition itself; the exposure draw is guarded to
  susceptible agents.
* **Evidence.** Recorded on Kaggle Tesla T4 (cc 7.5, 40 SMs, nvcc 13.0.88): V5 and V6 kernel speedups vs the same-run V0, and per-kernel
  register/occupancy data (`# kernel_info`): V6 base step kernel 30 registers, 0 B local memory, 100% theoretical occupancy
  (`ui_data_bundle/bench/results/kaggle_v6/`). See `docs/v5_cuda.md` and `docs/v6_cuda.md`.
* **Not claimed.** Occupancy is theoretical (from the compiler's resource report), not a profiler-measured achieved occupancy.

## 6. OpenACC — V4

* **Implemented.** `#pragma acc enter data copyin(...)`/`exit data copyout(...)`, `#pragma acc parallel loop` (`v4_simulation.cpp:50,67,89,98`),
  built with NVHPC `nvc++ -acc=gpu` or GCC `-fopenacc` (host fallback).
* **Evidence.** Kaggle T4, NVHPC nvc++ 26.9, 100 days, 7 reps (`bench/results/kaggle_v4/`, `docs/v4_openacc.md`): kernel-only 0.92× (10k),
  7.0× (100k), 34.2× (1M), 66.4× (5M) vs the V0 of the same run; at 10k V4 is slower than V0.
* **Provenance caveat.** That run was built with OpenMP **disabled**: its `V2_maxT` row is not a multithreaded measurement, and its CPU
  rows came from a host whose model/architecture was not recorded.

## 7. CUDA memory management — V5, V6

* **Implemented.** Device buffers allocated once and kept resident for all days (`cudaMalloc`, RAII wrapper that frees and tracks live
  allocations, `v6_simulation.cu:175-179`); RAII `Event` and `Stream` (non-blocking stream, lines 188-196); a `SyncOnExit` guard that
  synchronises before resources are destroyed on an exception path (line 204). Daily counts live in a `(days+1)×4` device array.
  `v6_live_allocations()` is asserted to be 0 after every success and failure path in `tests/test_v6.cpp` (including injected failure
  of each of the 10 allocations).
* **Not implemented.** Pinned host memory, unified memory, shared-memory tiling of agent data. (V5 states "no pinned memory" explicitly.)

## 8. Hierarchical reductions — V2, V6

* **V2:** per-thread histograms merged per location, `reduction(+: …)` on the state counters.
* **V6 (switch E1, `agg_counts`):** per-warp ballot/popcount per state → block-level shared counters (`__shared__ uint32_t sc[4]`) →
  4 global atomics per block instead of N (`v6_simulation.cu:129-141`). The *location tallies* (`nin[home|work]`) are deliberately **not**
  aggregated: warp lanes almost never share a location, so aggregation would find no duplicates (see `docs/v6_cuda.md`).
* **Evidence.** E1 is the largest single recorded gain: +26% / +68% / +84% / +64% vs `V6_base` at 10k / 100k / 1M / 5M (`bench/analyze_v6.py`
  on the recorded CSV; 1M inflated by the unexplained `V6_base` anomaly, see §13). Exactness argument: integer sums are order independent.

## 9. Warp-level primitives — V6

* **Implemented.** `__ballot_sync(0xffffffff, valid && ns == k)` followed by `__popc(m)` and one shared atomic per warp and state
  (`v6_simulation.cu:135-136`), only in the E1 path. `valid` masks the partial last warp (tested with sizes 1…30001 around every
  warp and block boundary).
* **Not implemented.** `__shfl_*` reductions and cooperative groups. Do not describe V6 as using shuffles.

## 10. Asynchronous execution — V6

* **Implemented.** `V6Mode::kAsync`: no per-day host synchronisation; per-day counts are copied with `cudaMemcpyAsync` into a host buffer
  and checked after the loop (population conservation is verified for every day, just later) (`v6_simulation.cu:524`).
* **Evidence.** Recorded gains vs `V6_base`: +38% / +15% / +36% / +0.4% at 10k / 100k / 1M / 5M — the benefit shrinks to nothing at 5M,
  where launch/sync latency is no longer the bottleneck (consistent with, but not proof of, that explanation).

## 11. CUDA Graphs — V6

* **Implemented.** `V6Mode::kGraph` with `graph_days` days per graph: stream capture (`cudaStreamBeginCapture`, line 493),
  `cudaGraphInstantiate` (lines 503-507, with a `CUDART_VERSION >= 12000` signature branch), repeated `cudaGraphLaunch` (line 541) plus a tail graph for the
  remainder. The day index is a device counter so one graph can replay many days.
* **Evidence.** `graph32`/`graph1` vs `async` differ by about 0.5–3.4 percentage points at 10k–1M and ≤ 0.1 at 5M
  (`analyze_v6.py` output) — graphs add little beyond async here; the table in `docs/v6_cuda.md` keeps that modest result.
  Graph build cost is counted in `e2e`, not `kernel`.

## 12. Deterministic parallel execution — all backends

* **Implemented.** (a) Counter-based RNG: a draw depends only on `(seed, agent, day, slot)`, never on thread, block, warp or launch
  shape (`include/rng.hpp`, per-backend copies `v4_rng.hpp`, `v5_rng.hpp`, `v6_rng.hpp`, callable on host *and* device so equality is
  testable bitwise). (b) Staged day: agents read only start-of-day state. (c) Integer-only reductions, so order does not matter.
* **Evidence.** Daily S/E/I/R compared against V0 for every backend/option set; for V6, 4212 comparisons plus `identical_v0`/`identical_v5 = yes`
  on every recorded row; the same checksum `b213860e1d97b2c8` for V0 (Apple M1, live), V0 (Kaggle) and V6 (T4) on the household population.
* **Limit.** Device `exp()` is not guaranteed bit-identical to host libm (V6 log: 541/200000 sampled bitwise differences, max relative 3.06e-15; V4: 43/200000).
  Exactness is established empirically by the counts, not assumed.

## 13. Performance measurement

* **Method.** Same `Params`/seed for all backends, warm-up run, interleaved repetitions, median with min/max/CV, every row checked against V0.
  `kernel_s` = day loop with data resident (including the count readback); `e2e_s` additionally includes allocation, copies and graph build;
  `events_s` = cudaEvent timing of the same loop. Profile CSVs are a **separate pass** and aggregate over the 100-day loop (not per day).
  Full detail: [`methodology.md`](methodology.md).
* **Acceptance rule (recorded, unchanged).** A V6 switch becomes a default only if its median kernel time improves by more than
  max(3%, 2×CV) at ≥ 2 sizes vs `V6_base`, with no regression above 2% at any other size (`bench/analyze_v6.py`).
* **Known anomaly.** At 1M agents `V6_base` is ≈ 35% slower than every non-aggregating variant; it is **unexplained** (no profiler evidence).

## 14. Strong scaling, speedup and parallel efficiency

* **Definitions used.** Speedup = t(reference)/t(backend) with both measured in the **same benchmark run**. Parallel efficiency (V2) =
  t(V2, 1 thread)/(T × t(V2, T)) on the same configuration. Strong scaling = fixed problem size, growing thread count (V2 table in `bench/README.md`).
* **Evidence.** V2 (M1): 1M agents, static/local: 1 thread 0.956 s → 2: 0.492 (eff 0.97) → 4: 0.414 (eff 0.58) → 8: 0.416 (eff 0.29).
  GPU backends scale with problem size, not thread count: V5 28.8× at 100k, 48.0× at 5M vs V0 (same recorded run).
* **Caveats.** V5/V6 and V4 come from different Kaggle sessions; never compare a V4 speedup with a V6 speedup. CPU rows from Kaggle are not comparable to the M1 rows.

## 15. Correctness validation

* **C++ (CTest, `build-sim`):** `v0`, `v1`, `v2`, `v3` (each backend vs V0, V2 over 1770 configurations per build), `external_input`,
  `extpop_reader` (CEPOP codec + every rejection path), `extpop_integration` (CEPOP → V0 equals a direct run). GPU tests `test_v4/5/6`
  need a GPU build (`test_v4`/`test_v6` accept `--require-gpu`, which turns a missing GPU into a failure instead of a skip).
* **Recorded GPU evidence:** `kaggle_v6/test_v6.log` (4212 V6 comparisons on Tesla T4, `V6 OK`); V4 166 comparisons (`docs/v4_openacc.md`).
* **Python:** CEPOP codec, generator, households, golden fixture, pipeline guard (`tests/python`); backend API, snapshot format and run
  lifecycle (`tests/backend`).
* **Browser:** `frontend/e2e/*.spec.ts` (see [`testing.md`](testing.md)), including a live V0 run whose day-100 S/E/I/R must equal the recorded values.

## What the project does **not** demonstrate

Multi-GPU or multi-scenario execution (V7), distributed memory / MPI (V8), pinned/unified memory, `__shfl` reductions, tensor cores,
profiler-measured achieved occupancy, or any GPU result produced on the development Mac.
