# Experimental methodology

Every value below was read from a recorded file or source in this repository (path given). Where something was **not recorded**, this
document says so instead of filling it in.

## 1. Hardware and toolchains

| Evidence set | Hardware | Compiler / flags | Source of the record |
|---|---|---|---|
| V0–V2 CPU benchmarks | Apple M1, 8 cores (4P+4E), 8 GB, macOS (Darwin 25.6), arm64 | V1 notes: Apple clang 21.0.0. V2/V3 builds: Homebrew clang 23.1.5, `-std=c++17 -O3 -Wall -Wextra`, `-fopenmp=libomp` for OpenMP builds, no `-march`/`-ffast-math`/LTO | `bench/README.md`, `bench/results/v2_env.txt`, `v3_env.txt` |
| V3 NEON / hybrid | Apple M1 (aarch64 NEON) | Homebrew clang 23.1.5; Apple clang 21 and Homebrew assembly in `bench/reports/` | `bench/README.md`, `v3_env.txt` |
| V4 OpenACC | Kaggle Tesla T4; Kaggle host CPU model/architecture **not recorded** | NVHPC `nvc++ 26.9`, `-fast -O3 -std=c++17 -acc=gpu -gpu=cc75`, **`openmp=OFF`** | header of `bench/results/kaggle_v4/v4_gpu_results.csv` |
| V5 CUDA | Kaggle Tesla T4 (2 devices visible), driver 580.178.04 | nvcc 13.0.88 | `kaggle_v5/v5_environment.log` |
| V6 CUDA | Kaggle Tesla T4 (cc 7.5, 40 SMs, 14.6 GiB), Intel Xeon @ 2.00 GHz, 4 logical cores, 31.3 GiB, Linux 6.18.55 x86_64 | nvcc 13.0.88, `-O3 -DNDEBUG -fmad=false -prec-div=true -prec-sqrt=true -lineinfo`, `openmp=OFF`, archs=75; git commit `b6006aa…` ("Add V6 optimized CUDA backend") | header of `kaggle_v6/v6_benchmark_all.csv`, `cuda_version.txt`, `git_commit.txt`, `gpu_info.txt` |
| Population generation / household validation | Kaggle x86_64, 4 CPUs, Python 3.13, g++ 13.3 (Ubuntu 24.04), nvcc | recorded in `kaggle_run_record.json` | `data/synthetic/*_households_v1/kaggle_run_record.json` |
| Live Studio runs (this project's demo machine) | MacBook Air M1; the API records the host CPU and core count with every run | `build-sim` (Release), V0 only | `meta.json` of each run, `/api/sim/capabilities` → `host` |

Dates: the M1 and Kaggle runs were recorded on 2026-11-14 (file headers).

## 2. Benchmark configurations

| Set | Agent counts | Days | Repetitions | Notes |
|---|---|---|---|---|
| V0/V1 (`bench/bench.cpp`) | 10k, 50k, 100k, 500k | 100 | 7 + warm-up | `homes = N/5`, `works = N/50`, `initial infected = N/1000`, seed 42 |
| V2 (`bench/bench_v2.cpp`) | 10k … 1M, threads 1/2/4/8, static/dynamic(1024)/guided, local vs atomic | 100 | 7 (5 at ≥ 500k) | efficiency definition in `bench/README.md` |
| V3 (`bench/bench_v3.cpp`) | 10k, 50k, 100k, 500k, 1M | 100 | 7 at every size, backends interleaved per repetition | NEON, scalar fallback, hybrid, V1/V2 reference |
| V4 (`bench/bench_v4.cpp`) | 10k, 100k, 1M, 5M | 100 | 7 | same-run V0 baseline |
| V5 (`bench/bench_v5.cpp`) | 10k, 100k, 1M, 5M | 100 | 7 (`v5_benchmark.log`) | CPU V0–V3 rows from the same Kaggle run |
| V6 (`bench/bench_v6.cpp`) | 10k, 100k, 1M, 5M | 100 | 7, `--scenario all` (default/low/high β) | 264 data rows (3 scenarios × 4 sizes × 22 backends); V5 built into the same binary |

The synthetic benchmark workload (the sizes above) is *not* the Bengaluru population. The Bengaluru household population (100,000
agents, 238,841 locations) is used for the epidemic validation runs and the live Studio runs, not for the speed benchmarks.

## 3. Warm-up and repetition policy

One untimed warm-up run, then N interleaved repetitions (backends alternate within a repetition so thermal and scheduling drift hits
all of them). The reported statistic is the **median**; min, max and the coefficient of variation (CV = stdev/mean) are stored with it.
Large CVs are not hidden: e.g. V2 at 10k has CV 77% on the Kaggle host, and the V3 notes flag outlier repetitions explicitly.

## 4. Timing methodology: kernel time vs end-to-end time

* **`kernel_s`** — the 100-day loop with the population already resident (CPU: setup excluded). For GPU backends it **includes** the daily
  count readback (per day in sync mode, one deferred copy in async/graph mode).
* **`e2e_s`** — additionally includes `cudaMalloc`, host→device copies, graph build (graph rows) and the final device→host copy. Host
  population generation is excluded.
* **`events_s`** — the same loop timed with `cudaEvent`s (cross-check on `kernel_s`).
* **Profile CSVs** (`v6_profile*.csv`, per-kernel `loc_ms_median`/`step_ms_median`) come from a **separate profiling pass** and are
  **aggregated over the 100-day loop**; they are not per-day metrics and not directly comparable with the benchmark timings.
* **Speedup** = same-run V0 time ÷ backend time. Never divide a V6 time by a V0 time from a different Kaggle session.
* **Efficiency (V2)** = t(V2, 1 thread) ÷ (T × t(V2, T)) on the same configuration.

## 5. Correctness methodology

* Reference: **V0** (sequential, `src/common/`). It is not modified to make tests pass.
* **Bit-exactness**: every backend's daily S/E/I/R sequence must equal V0's exactly (integers; the RNG is counter-based and integer-only).
* Test geometry: sizes around warp/block boundaries (1…30001), β ∈ {0, 0.3, 2, 1e6}, several seeds, single-location contention, zero/one
  day, no/all initially infected, determinism over repeated runs (see `tests/test_v6.cpp`, `docs/v6_cuda.md`).
* **Resource correctness (V6)**: zero live device allocations/streams/events/graphs after every success *and* injected-failure path.
* **Device `exp()`** is not claimed bit-identical to host libm; differences are counted and printed informationally, and exactness rests
  on the counts matching V0.
* **External population**: CEPOP reader tests (all rejection paths), `extpop_integration` (reader → V0 equals a direct run), and the
  recorded V0 = V6 equality on the real household CEPOP (`extpop_v0_v6.json`).
* **Live runs**: the API refuses to call a run `completed` unless the CSV has `days+1` rows, population is conserved, the executable
  printed `RESULT: PASS`, and (with snapshots) the CESNAP file validated against the CSV and the CEPOP.

## 6. Epidemic validation experiments (recorded)

All use V0 on the 100,000-agent synthetic Bengaluru populations, 100 days, initial infected 100 unless stated.

| Experiment | Recorded result |
|---|---|
| Household baseline (seed 42) | final S/E/I/R 65,371 / 1,257 / 2,343 / 31,029; attack rate 34.629%; peak infectious 2,891 (day 78); peak daily incidence 598 (day 66) |
| Legacy baseline (seed 42) | final S/E/I/R 99,198 / 2 / 8 / 792; attack rate 0.802%; peak infectious 122 (day 4); peak incidence 29 (day 2) |
| Transmission sensitivity | attack rates 0.755% (low), 34.629% (baseline), 71.089% (high) |
| Ten-seed validation | seeds 42–51 × three transmission scenario labels, V0 CPU only, household population only |

Interpretation limits: legacy vs household also differ in home/destination assignment (not a pure household-effect test); the scenario
*labels* low/baseline/high are recorded but the **β values are not in the bundle configuration**, so no β value may be claimed from the
label; ten seeds measure stochastic variability on one synthetic population, not uncertainty about the real city; V6 is not part of the
ten-seed experiment.

## 7. Known anomalies and provenance caveats

1. **Kaggle V3 rows are scalar-fallback measurements.** They ran on x86 where NEON is unavailable; only the M1 data are NEON data.
2. **OpenACC Kaggle run built with OpenMP off.** `V2_maxT` there is not a multithreaded measurement; the host CPU was not recorded.
3. **V6 at 1M agents** shows `V6_base` ≈ 35% slower than every non-aggregating variant; **unexplained**, no profiler evidence.
4. **Profile CSVs are aggregated over 100 days.**
5. **V5/V6 and V4 are separate Kaggle sessions** with their own V0 baselines; compare speedups only within a run.
6. **V3 full NEON is slower than V1 on the M1** (≈ 0.55–0.59×); the hybrid gains only 1.05–1.17× over V1 and is within noise at 1M.
7. **High CVs on shared hosts** (V2 maxT, small sizes) — read those rows with the CV column.
8. **The repository-level `bench/results/kaggle_v6/` directory is empty;** the V6 artifacts are in `ui_data_bundle/bench/results/kaggle_v6/`.

## 8. Reproducibility instructions

CPU (Mac or Linux):
```bash
cmake -S . -B build-sim -DCMAKE_BUILD_TYPE=Release && cmake --build build-sim -j
ctest --test-dir build-sim --output-on-failure
build-sim/bench_v0v1 7                                  # V0/V1
cmake -S . -B build-omp -DCMAKE_BUILD_TYPE=Release -DENABLE_OPENMP=ON -DCMAKE_CXX_COMPILER=/opt/homebrew/opt/llvm/bin/clang++
cmake --build build-omp -j && build-omp/test_v2 && build-omp/bench_v2 7
```
GPU (needs an NVIDIA GPU; not possible on the M1 Mac): see [`kaggle_cuda_workflow.md`](kaggle_cuda_workflow.md). Do **not** write new results into
the existing result directories; use a new directory per run and compare with `bench/analyze_v6.py`.

Live simulation on the demo machine: start the backend and frontend (README), open **Simulation Studio**, choose the household population,
V0, 100 days, seed 42, 100 initially infected. The result must be final S/E/I/R 65,371 / 1,257 / 2,343 / 31,029 and daily checksum
`b213860e1d97b2c8`; this is asserted by `frontend/e2e/studio.spec.ts` (test 8) and `tests/backend/test_sim_api.py::test_real_run_matches_recorded`.
