# V6 — optimized CUDA backend

`cityepi_v6` (`src/v6_cuda/v6_simulation.cu`, `include/v6_simulation.hpp`, `include/v6_rng.hpp`) keeps V5's two-kernel day
structure and adds **independently switchable** optimizations. V5 is untouched and remains the baseline; V6 has its own RNG copy,
host-info helper, test (`tests/test_v6.cpp`), benchmark (`bench/bench_v6.cpp`) and results directory (`bench/results/kaggle_v6/`).

> **Status (reconciled in Phase 5): implemented, built with nvcc 13.0.88 and run on a Kaggle Tesla T4.** The recorded
> artifacts are in `ui_data_bundle/bench/results/kaggle_v6/` (the repository-level `bench/results/kaggle_v6/` directory is
> currently empty; see `docs/release_checklist.md`). Everything below that says "recorded" comes from those files; nothing was
> re-run on the development Mac (no NVIDIA GPU). Defaults in the code stay at the V5-equivalent baseline; the acceptance table
> below says which switches *would* qualify, it does not change any default.

## Build / run
```
# V6 alone
cmake -S . -B build-cuda -DENABLE_CUDA_V6=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_CUDA_ARCHITECTURES=75 [-DCITYEPI_V6_PTXAS_VERBOSE=ON]
# V5 and V6 together (adds the V5 row to bench_v6 and V6==V5 checks to test_v6)
cmake -S . -B build-cuda -DENABLE_CUDA=ON -DENABLE_CUDA_V6=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_CUDA_ARCHITECTURES=75
cmake --build build-cuda -j
build-cuda/test_v6 --require-gpu | tee bench/results/kaggle_v6/test_v6.log
build-cuda/bench_v6 7 10000 100000 1000000 5000000 --profile-csv bench/results/kaggle_v6/v6_profile.csv \
    > bench/results/kaggle_v6/v6_benchmark.csv
build-cuda/bench_v6 7 10000 100000 1000000 5000000 --scenario all ...   # optional: low/high beta scenarios
python3 bench/analyze_v6.py bench/results/kaggle_v6/v6_benchmark.csv    # acceptance table
```
CUDA flags (`-fmad=false -prec-div=true -prec-sqrt=true -lineinfo`) are applied only to CUDA translation units; no fast-math.
`ENABLE_CUDA_V6` defaults to OFF; the default build is unchanged.

## What the V5 benchmark says (`bench/results/kaggle_v5/`, T4, 100 days)
| agents | V5 day loop | per day | per agent per day |
|---|---|---|---|
| 10k | 4.17 ms | 41.7 µs | 4.2 ns |
| 100k | 17.85 ms | 178 µs | 1.8 ns |
| 1M | 154.8 ms | 1.55 ms | 1.5 ns |
| 5M | 647.7 ms | 6.48 ms | 1.3 ns |

From 100k up, the cost is linear at ~1.3–1.8 ns/agent/day, far above a pure-bandwidth estimate (~14 B/agent plus gathers is
roughly 0.2–0.4 ms/day at 5M). That points at serialisation rather than bandwidth. At 10k, the per-day cost is dominated by
launch/sync latency (hypothesis).

**Two different kinds of atomic counters (do not conflate them):**
- **State counters (4 words, S/E/I/R).** Every one of the N agents adds to one of only 4 global addresses each day, so all N atomics
  contend on 4 addresses. Warp/block aggregation reduces global atomics from N to 4 per block. This is **E1** (`agg_counts`),
  implemented and kept as an independent experiment; the agent-to-location layout is irrelevant to it.
- **Location tallies (`nin[home]`, `nin[work]`, ~0.22N words).** Only infectious agents add, to randomly scattered addresses.
  Agents are assigned to homes/works uniformly at random (`generate_synthetic`), so the 32 agents of a warp almost never share a
  location: warp-level aggregation of *these* atomics would find no duplicates and is **not** implemented. Sorting agents by one
  location layer (E6) could make it useful for that layer only; deferred.

## Per-day design
Two kernels on one non-blocking stream; the day index is a device counter so a CUDA Graph can replay the same launches.
1. `location_prob_kernel<B,SE>` (thread per location): `prob[l]`, zero the tally; thread 0 increments the day counter `ctr`.
2. `agent_step_kernel<B,AGG,SR,PL>` (thread per agent): `day = ctr-1`; RNG draws; V5's branchless transition; counters go to
   `counts[4*ctr + state]`; infectious agents add to the next-day tally.
Daily counts live in a `(days+1)*4` device array. They return to the host per day (`kSync`) or once at the end (`kAsync`, `kGraph`).

## Switches (each independently selectable; `V6Opts`)
| Switch | Option | Idea | Exactness argument |
|---|---|---|---|
| baseline | all off | V5-equivalent | same arithmetic as V5; day from device counter |
| E1 | `agg_counts` | **state counters (S/E/I/R only)**: per-warp `__ballot_sync`+`__popc` for each state, block-level shared sum, 4 global atomics per block | integer sums |
| E2a | `mode=kAsync` | no per-day host sync; one deferred readback; conservation checked per day afterwards | integer; checks identical, only later |
| E2b | `mode=kGraph`, `graph_days` | async + CUDA Graph of N days per launch (tail graph for the remainder) | same kernels |
| E3a | `skip_exp` | skip `exp` when tally is 0 | `-beta*0` is ±0, `exp(±0)=1`, `1-1=+0`: result is exactly +0 (also tested bitwise) |
| E3b | `skip_rng` | skip an RNG draw when the location probability is exactly 0 | draw `u ≥ 0` so `u < 0` is always false |
| E3c | `pred_loads` | load home/work ids only for susceptible agents and agents becoming infectious | pure load elision |
| E4 | `block` | 64/128/256/512/1024 threads per block (compile-time template, `__launch_bounds__`) | launch shape only; RNG depends on (seed, agent, day, slot) |

Graph build/instantiation is counted in `seconds_h2d`/`e2e`, not in `kernel_s`. All kernels use the **original agent id** for RNG
(no renumbering) and the same slot mapping as V0.

## Floating-point notes
- Probability is `1.0 - exp((-beta * inf) / occ)` with `__dmul_rn`, `__ddiv_rn`, `__dsub_rn` (explicit round-to-nearest) and device
  `exp()`, plus `-fmad=false`; no `--use_fast_math`, no float `exp`, `prob` stays `double`.
- **Device `exp()` is not claimed bit-identical to host libm.** `test_v6` prints the device-vs-host difference count
  informationally. The authoritative check is that V6's daily counts equal V0's (and V5's when built together) in every test.
- E3a/E3b are exact only for the decision `u < prob`, which is all that consumes `prob`; with NaN/inf `beta` the decisions also agree.

## Correctness evidence (recorded, Kaggle T4)
`tests/test_v6.cpp` (CTest entry `v6`, runs with `--require-gpu`) covers: host RNG bit-equality; device RNG bit-equality; invalid
options (no device); bitwise `skip_exp` on/off equality of the device expression; failure injection in all three modes (after days
1/7/20) and failure of each of the 10 device allocations in turn, with `v6_live_allocations()==0` after every path; per-kernel
registers/occupancy printout for all block sizes; V0 equality (and V5 when built together) for every option set — each single
optimization, combinations (E1+E2, E1+E3, E1+E2graph+E3, ...), and every block size 64…1024 — over sizes
1,2,15,16,17,31,32,33,63,64,65,100,127,128,129,255,256,257,511,512,513,1023,1024,1025,2049,5000,30001 (partial warps and block tails
for all block sizes) × betas {0,0.3,2,1e6}; extra seeds; 100k/1M; single-location contention; timers; no/all initially infected;
zero/clamped durations; 0 and 1 days; home-/work-off; determinism over repeated runs.

**Recorded result** (`kaggle_v6/test_v6.log`, last line): `4212 V6 comparisons on Tesla T4; V6 OK`. Device: Tesla T4 cc 7.5, 40 SMs,
14.6 GiB, driver 13000, runtime 13000, nvcc 13.0.88 (`cuda_version.txt`, `gpu_info.txt`). Per-row exactness is also recorded in
the benchmark CSV: `identical_v0` and `identical_v5` are `yes` on every row of `v6_benchmark_all.csv`. The log also reports
`E3 skip_exp: 0/240 bitwise differences` and, informationally, `1-exp(-x) device vs host: 541/200000 bitwise differences, max rel
diff 3.06e-15` (device `exp()` is not bit-identical to host libm; exactness rests on the daily counts matching V0).

Independent cross-check on the household population (`ui_data_bundle/data/synthetic/bengaluru_urban_N100000_seed42_households_v1/extpop_v0_v6.json`):
V0 and V6 (options `base`) give the same daily checksum `b213860e1d97b2c8` and final S/E/I/R 65,371 / 1,257 / 2,343 / 31,029.

## Benchmark methodology
Same as V5: identical Params/seed (100 days, `beta=0.3`), warm-up, interleaved repetitions, median/min/max/CV, every row compared
with V0 and V5. `kernel_s` = day loop with data resident including count readback; `e2e_s` additionally includes allocation, copies,
graph build and final copy-out; `events_s` = cudaEvent timing. A **separate** profiling pass (`--profile-csv`) records per-kernel event
times. Register count, spills and occupancy per row are printed in the CSV header (`# kernel_info`). Optional scenarios
(`--scenario low|high|all`) change `beta` to test dependence on the S/E/I/R mix. CPU rows V1–V3 are omitted here (V0 only); V5 results
in `bench/results/kaggle_v5/` are not modified.

**Acceptance rule:** an optimization becomes a default only if its median kernel time improves by more than max(3%, 2×CV) at two or
more sizes versus `V6_base`, with no regression above 2% at any other size (`bench/analyze_v6.py`). Negative results stay in this report.

## Experiment results (recorded, Kaggle T4, 7 repetitions, 100 days, `--scenario all`)
Output of `python3 bench/analyze_v6.py ui_data_bundle/bench/results/kaggle_v6/v6_benchmark_all.csv`, executed on the recorded CSV
(default scenario). Positive = faster than `V6_base`; `*` = above max(3%, 2×CV); the verdict applies the acceptance rule above.

| backend | 10k | 100k | 1M | 5M | verdict |
|---|---|---|---|---|---|
| V6_E1 (aggregation) | +26.1%* | +67.5%* | +83.7%* | +63.9%* | ACCEPT |
| V6_E2_async | +38.1%* | +14.9%* | +35.9%* | +0.4% | ACCEPT |
| V6_E2_graph32 | +40.5%* | +15.4%* | +36.5%* | +0.4% | ACCEPT |
| V6_E2_graph1 | +41.5%* | +15.6%* | +36.6%* | +0.5% | ACCEPT |
| V6_E3_skipexp | +7.0% | +5.4%* | +38.3%* | +3.6%* | ACCEPT |
| V6_E3_skiprng | -2.0% | -0.4% | +35.3%* | +0.0% | reject |
| V6_E3_predload | -3.0% | +0.2% | +35.3%* | -0.2% | reject |
| V6_E3_all | +6.5% | +4.8%* | +38.0%* | +3.3%* | ACCEPT |
| V6_E4_b64 | +9.0% | +4.4%* | +35.3%* | -0.1% | ACCEPT |
| V6_E4_b128 | +8.0% | +3.0% | +35.4%* | -0.1% | reject |
| V6_E4_b512 | -17.4% | -2.5% | +35.3%* | +0.2% | reject |
| V6_E4_b1024 | -46.3% | -2.5% | +34.5%* | +0.1% | reject |
| V6_E1_E2async | +63.9%* | +78.8%* | +87.3%* | +64.1%* | ACCEPT |
| V6_E1_E2graph | +66.4%* | +79.5%* | +87.3%* | +64.1%* | ACCEPT |
| V6_E1_E3 | +31.3%* | +68.5%* | +88.2%* | +67.1%* | ACCEPT |
| V6_E1_E2graph_E3 | +71.1%* | +82.4%* | +89.3%* | +67.4%* | ACCEPT |
| V6_E1_E2graph_E3_b128 | +77.9%* | +83.8%* | +89.6%* | +67.4%* | ACCEPT |
| V6_E1_E2graph_E3_b512 | +66.7%* | +79.5%* | +88.5%* | +67.3%* | ACCEPT |
| V6_E1_E2graph_E3_b1024 | +49.3%* | +76.1%* | +86.5%* | +66.2%* | ACCEPT |

**Unexplained 1M anomaly (not explained, not hidden).** At 1M agents `V6_base` (≈131 ms) is about 35% slower than *every*
non-aggregating variant, including variants that should be neutral there (`skiprng`, `predload`, `b128`…). The "+35%" entries in
the 1M column of rejected rows are therefore a property of the `V6_base` reference at that size, not evidence for those switches.
No profiler data explains it; do not attribute the 1M column to a mechanism. (`V6_base` CV at 1M is 5.7% vs 0.1–0.2% at 5M.)

**Speedups versus V0 from the same recorded run** (kernel time, data resident, default scenario; V0 is the Xeon CPU row of the
same CSV; `kernel_speedup_v0` column): V5 7.5× / 28.8× / 26.0× / 48.0× and `V6_E1_E2graph_E3_b128` 33.7× / 180× / 294× / 180×
at 10k / 100k / 1M / 5M. These are *kernel-only* numbers; `e2e_speedup_v0` (includes allocation, copies, graph build) is smaller
and is in the same CSV. V5 and V6 come from different Kaggle sessions than the V4 results, so do not mix baselines across runs.

Registers / occupancy (`# kernel_info` in the CSV): `V6_base` location kernel 28 regs, step kernel 30 regs, 0 B local memory,
100% theoretical occupancy; `V6_E1` step kernel 34 regs and 16 B shared memory, 100% occupancy. Per-kernel time split:
`kaggle_v6/v6_profile.csv` (profile values are aggregated over the 100-day loop, not per day).

## Deferred (not implemented)
E5 vectorised multi-agent threads, E6 agent renumbering with `orig_id` for RNG, E7 persistent cooperative kernel, E8 pull-model CSR
with an infectious bitmap. They are revisited only if the profile shows the agent kernel still bound by atomics or memory traffic.

## Pre-GPU audit (host-side emulation, not a GPU result)
Before the first nvcc build the unmodified V5 and V6 `.cu` sources were compiled as C++ against a throw-away CPU emulation of the CUDA
runtime (kept outside the repo; it runs kernels as thread loops with real barriers/ballots for the aggregation path, records graph
launches, and counts live allocations, streams, events, graphs and graph execs). It checks logic and resource accounting only; it says
nothing about GPU execution, device `exp()`, atomics or speed.
- 954 V6 runs (all 48 flag combinations of E1 × {sync, async, graph} × E3 sub-flags, every block size, sizes 1/33/130/1100,
  betas 0/0.3/2/1e6, single location, zero days) matched V0 **and** emulated V5 bit-for-bit.
- Day counter: fresh buffers are zeroed per run; repeated runs, graph chunks of 1/7/23/24/100 days (including tails) stayed exact.
  Daily slot `4*ctr` is in range `[4, 4*days+3]`.
- Failure injection (all modes, days 1/7/23), failure of each device allocation and of the one-past-last, profile mode, invalid
  options and `n_agents=0`: afterwards 0 live allocations, streams, events, graphs and graph execs.
- Mutation checks confirm the harness can fail: a counter that never increments aborts, a popcount that drops lane 31 raises
  "population not conserved", a wrong `skip_rng` threshold gives hundreds of V0/V5 mismatches.
- Audit fix: a `SyncOnExit` guard now synchronises the stream before graphs, events and host buffers are destroyed on an exception
  path, so nothing is released while asynchronous work may still be in flight.
