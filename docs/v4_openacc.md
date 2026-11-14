# V4 — OpenACC backend

`cityepi_v4` (`src/v4_openacc/v4_simulation.cpp`, `include/v4_simulation.hpp`) ports V1's fused pass to OpenACC.
Built only with `-DENABLE_OPENACC=ON` (default OFF); V0–V3 sources and targets are unchanged.

## Mapping
- Setup (`generate_synthetic`, `seed_infections`, initial tally) runs on the host, shared with V0–V3, untimed.
- `enter data copyin` once: state, timer, home/work ids, location type/occupancy, tally; `create` for prob.
  Data stays resident for all days. Per day only the four `uint32` state counts return (reduction scalars).
  `exit data copyout` returns state/timer once at the end; the host recounts them and checks them against the last device-side counts.
- Kernel A (per location): `prob[l]`, then zero the tally. Kernel B (per agent): RNG (counter-based, same `rng_inline.hpp`),
  branchless update, `acc atomic update` for next-day tally, `reduction(+)` for counts. All sums are integer ⇒ order independent.

## Execution mode (no silent CPU-as-GPU)
`v4_probe()` runs an `acc parallel` region that tests `acc_on_device(acc_device_not_host)`. `V4Result::info.mode` is
`NoOpenACC`, `Host` (runtime present, executing on CPU) or `Device`. `test_v4` and `bench_v4` print it first;
`--require-gpu` (or `CITYEPI_REQUIRE_GPU=1`) makes them fail, and `V4Config::require_gpu` makes `run_simulation_v4` throw, unless it is `Device`.
`bench_v4` marks V4 rows `gpu_claim=NO(host-fallback)` otherwise.

## Timing
- `Result::seconds` = day loop with data resident (kernel-only; comparable to V0–V3 `seconds`).
- `seconds_h2d`, `seconds_d2h`, `seconds_total` = transfers and end-to-end (host setup excluded for every backend).
- The per-day count reduction synchronises the host once a day, so kernel-only time includes that tiny sync/readback.

## Status: GPU validated on Kaggle (Tesla T4, NVHPC 26.9); two claims are explicitly not established
Two independent runs exist and must not be conflated:
1. **GCC 16.2 `-fopenacc` host fallback** (local, no device): semantics only (V4 == V0..V3, 166 comparisons). Not GPU evidence.
2. **Kaggle NVHPC GPU run** (below): real device execution. Evidence is under `bench/results/kaggle_v4/`.

Not established by either run:
- **Device/host `exp()` bitwise equivalence.** It does not hold (43/200000 sampled values differ); V4 matching V0 in the tested cases is empirical only.
- **Any speedup over a known or multi-threaded CPU baseline.** The Kaggle CPU architecture and core count were not recorded and the CPU build had OpenMP off.

### Environment (from the logs/CSV header; nothing else is known)
| Item | Value | Source |
|---|---|---|
| GPU | Tesla T4 (NVIDIA), `devicenum=0`; runtime reports 2 non-host devices, only device 0 used | `v4_gpu_test.log` header, profile log |
| Compiler | NVHPC `nvc++` 26.9 | `v4_gpu_test.log`, CSV header |
| OpenACC | `_OPENACC=201711` | `v4_gpu_test.log` |
| Flags | `-fast -O3 -DNDEBUG -std=c++17 -Wno-unknown-pragmas -O3 -acc=gpu -Minfo=accel -gpu=cc75`, Release, `openmp=OFF` | CSV header |
| Exec mode | `openacc-device` (`--require-gpu` path; no host fallback) | test log, CSV |
| Workload | 100 days, 7 repetitions (median; min/max/CV over reps), seed/ratios as V1 | CSV header |
| Not recorded | host CPU model, **CPU architecture**, core count, driver/CUDA version, git commit of the run | — |

`-fast` appears in the flags recorded in the CSV header; why it was enabled is not recorded. See "Bit-identity" for why it matters.

### Verified results
- **Build** (`v4_build.log`): all targets built with nvc++ (core, V3, V4, tests, benches). `-Minfo=accel` shows both V4 loops
  (`run_simulation_v4` lines 159 and 168) as `Generating NVIDIA GPU code`, `gang, vector(128)`, `reduction(+:cs,cr,ce,ci)`;
  the four `rng_v4::*` functions compile as `acc routine seq`; `DeviceData::enter/finish/~DeviceData` generate the expected
  `enter data copyin/create` and `exit data copyout/delete`. Only warnings: unused `use_simd` in `v3_simulation.cpp:147` and `v3_hybrid.cpp:85`.
- **Correctness** (`v4_gpu_test.log`): `V4 execution mode: openacc-device`, device Tesla T4; **166 V4 comparisons [openacc-device]; V4 OK**.
  The log does not itemise the comparisons; this is the test's own pass summary. The benchmark `identical` column is `yes` for every row
  (checked against V0 each repetition). The log is `NV_ACC_NOTIFY` output (about 92k lines); the only non-notify lines are the 6 summary lines.
- **Device `exp()` vs host**: `1-exp(-x) device vs host: 43/200000 bitwise differences, max rel diff 2.66e-15`.
  **Device and host `exp()` are therefore NOT bitwise equivalent.** The test summary reports all 166 comparisons passed, but that is an empirical
  result for those inputs; it is not a proof, and a future input could land a uniform draw between the two values and diverge.
- **Data movement** (`v4_gpu_profile.log`, `NV_ACC_TIME`, 32 runs = 4 sizes x (1 warm-up + 7 reps), all sizes summed):
  3200 launches each of kernel A (line 159) and kernel B (line 168) = 100 days x 32 runs, plus 3200 reduction kernels.
  Per-day traffic is only the four 4-byte reduction scalars (12800 copyin + 12800 copyout = 4 x 3200). Bulk arrays move once per run
  (`enter` 32 regions, `finish` 32 regions). This confirms data stays resident.
- **Where device time goes** (summed over sizes, device time): kernel B 1.595 s (~58%), kernel A 0.890 s (~32%), reductions 0.091 s (~3%),
  per-day scalar copies 0.043 s in + 0.127 s out, bulk enter 0.143 s, finish 0.034 s. Not broken out per size.

### Methodology: kernel-only vs end-to-end
- **Kernel-only** (`kernel_*`, `Result::seconds`): the 100-day loop with data resident. It *includes* per-day launches, the reduction and
  the 4-scalar readback/sync, so it is "loop time", not pure GPU kernel time. It is the figure comparable to V0-V3 `seconds`.
- **End-to-end** (`e2e_*`): kernel-only + H2D (`enter data`) + D2H (`exit data`). Host synthetic setup is excluded for every backend.
  CPU backends have no transfers, so their e2e equals kernel-only.
- Speedups: `kernel_speedup_v0` uses kernel medians, `e2e_speedup_v0` uses e2e medians; both are against V0 of the same run.
  Do not quote the kernel-only speedup as the end-to-end one.

### Results (median of 7, 100 days, seconds; speedups are against the Kaggle V0 of this same run; raw: `bench/results/kaggle_v4/v4_gpu_results.csv`)
| Agents | V0 | V1 | V4 kernel | V4 e2e | H2D | D2H | V4 kernel vs V0 | V4 e2e vs V0 | V4 kernel CV% |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 10,000 | 0.02625 | 0.01556 | 0.02848 | 0.02881 | 0.00026 | 0.00007 | 0.92x | 0.91x | 12.0 |
| 100,000 | 0.23946 | 0.12528 | 0.03422 | 0.03494 | 0.00058 | 0.00013 | 7.00x | 6.85x | 4.5 |
| 1,000,000 | 2.79995 | 1.34204 | 0.08187 | 0.08601 | 0.00332 | 0.00068 | 34.20x | 32.55x | 1.2 |
| 5,000,000 | 18.65620 | 9.29286 | 0.28109 | 0.29908 | 0.01419 | 0.00351 | 66.37x | 62.38x | 4.1 |

V0 and V1 columns are CSV medians. Speedups are the CSV's `kernel_speedup_v0` / `e2e_speedup_v0`, rounded; no other comparison is made. All rows `identical=yes`.

### 10K GPU overhead and scaling
- At 10K agents V4 is **slower than the Kaggle V0 (0.92x kernel, 0.91x e2e)**. Do not present V4 as faster at small sizes.
- H2D+D2H is only 0.33 ms (~1% of 28.8 ms), so transfers do not account for the 10K slowdown. **Inference, not measured:** the time looks like a roughly fixed per-day cost (28.5 ms / 100 days ~ 0.285 ms/day) of
  3 launches (A, B, reduction), a 4-scalar copy-in/out and a host sync. It is based on the 100K-vs-10K timings; per-size launch costs were not profiled.
- Observed scaling: going 10K -> 100K (10x agents) raises V4 kernel time only 1.20x (0.0285 -> 0.0342 s), while the CPU backends in this CSV rise ~8-10x.
  100K -> 1M is 2.39x for 10x agents; 1M -> 5M is 3.43x for 5x agents. The cause of this shape was not profiled per size.
- Crossover vs V0/V1 lies between 10K and 100K; no size in between was run, so it is not located more precisely.
- Kaggle V0 time grows 711x for 500x agents (10K -> 5M), while V4 grows far less, so the measured kernel speedup vs V0 rises with N: 0.92x, 7.0x, 34.2x, 66.4x. No claim is made beyond these sizes and this machine.
- 10K kernel CV is 12% (V0 16%): timings at that size are noisy; differences of a few percent are not significant.

### Limitations and inconsistencies in this data
- **CPU rows are not the project's M1 baselines.** The Kaggle CPU model, **architecture** and core count were not recorded. The `V3_neon` label is inherited from the code;
  nvc++ reports the `use_simd` parameter "set but never used", so that row is **apparently scalar** (its timing is close to V1). Whether a NEON/SIMD path was compiled was not verified.
  Do not compare these CPU numbers to the M1 tables in `bench/README.md`.
- **Build had `openmp=OFF`** (CSV header), so `V2_maxT` is not evidence of parallel CPU performance and must not be quoted as such (its timings are close to V2_1T and V1 in this CSV).
  The speedups here are against CPU code that was effectively single-threaded; a threaded CPU baseline was not measured.
- CPU backends V1-V3 are ~1.7-2.1x vs V0 across all sizes on this machine; V0 itself is machine-specific, so this is not comparable to the M1 tables
  (which list their own V1/V2/V3 speedups over M1 V0).
- Single GPU model, single run session, 4 problem sizes, one seed. GPU clocks, driver and other load on the machine were not recorded.
- `-fast` was used (see Bit-identity); the bit-identity results hold for this compiler/flags/GPU only.
- Per-kernel profile times are summed over all four sizes (the log does not separate them), so per-size kernel breakdowns are unavailable. `NV_ACC_NOTIFY`/`NV_ACC_TIME`
  were enabled for the test and profile logs. Whether the benchmark CSV run had them enabled is not recorded, so the profile and benchmark runs are not assumed to be separate.
- Atomic-contention behaviour (checklist item 7) is covered only through the correctness tests passing, not by a performance measurement.
- Device 1 of 2 was never used; no multi-GPU claim is made.

### Evidence files and Git policy
`bench/results/kaggle_v4/`: `v4_gpu_results.csv` (raw benchmark, tracked, 2.8 KB) and `v4_build.log` (6 KB, tracked) are kept as evidence.
`v4_gpu_test.log` (18 MB, 92k lines) and `v4_gpu_profile.log` (7 MB, 36k lines) are `NV_ACC_NOTIFY`/`NV_ACC_TIME` traces, are repetitive (>99% notify lines)
and are git-ignored; the facts taken from them are quoted above. Keep the originals locally/archived if audit is needed.

## Bit-identity / compiler-dependent differences
Integer logic and the RNG are exact (V4 uses `include/v4_rng.hpp`, a copy of the V1 RNG stages with `#pragma acc routine seq`,
tested equal to `rng_inl::`/`rand01`). The one floating-point risk is `1 - exp(-beta*I/occ)`: a device `exp` may differ from host
libm by ulps, and an agent whose uniform draw falls between the two values would diverge (and could cascade). The chance per run is
small but non-zero (order 1e-7 at 5M agents x 100 days, estimated, not measured). The Kaggle run used `-fast` and still matched V0 in all tested cases, but `-fast`/`-Mfprelaxed` are not recommended and were not ablated. FMA contraction is
not expected to matter (no multiply-add pattern in the kernel); `-gpu=nofma` is available to rule it out. Measured on the T4: 43/200000 sampled `1-exp(-x)` values differ bitwise (max rel diff 2.66e-15), so device and host `exp` are not bitwise equivalent; no V4 != V0 case was observed. `-gpu=nofma` was not tried.

## Device-data lifetime
`DeviceData` (RAII) owns the run's mappings: `enter data` on construction path, `finish()` copies state/timer out and releases on the
normal path, and the destructor deletes (no copy-out) on any exception. `v4_live_mappings()` must be 0 between runs; `test_v4` checks it
after injected failures (`V4Config::inject_failure_after_day`, a test hook that is off by default).

## Build
GCC host fallback (local correctness only):
```
cmake -S . -B build-v4-host -DENABLE_OPENACC=ON -DCMAKE_CXX_COMPILER=g++-16 -DCMAKE_BUILD_TYPE=Release
cmake --build build-v4-host -j && ./build-v4-host/test_v4 && ./build-v4-host/bench_v4 7
```
NVHPC GPU:
```
cmake -S . -B build-v4-gpu -DENABLE_OPENACC=ON -DCMAKE_CXX_COMPILER=nvc++ -DCMAKE_BUILD_TYPE=Release -DCITYEPI_GPU_CC=75   # T4=75, P100=60
cmake --build build-v4-gpu -j
./build-v4-gpu/test_v4 --require-gpu
./build-v4-gpu/bench_v4 7 --require-gpu > bench/results/v4_gpu.csv   # args: [reps 1..1000] [agents >= 50 ...]
```
Manual: `nvc++ -std=c++17 -O3 -acc=gpu -gpu=cc75 -Minfo=accel -Iinclude src/common/{simulation,contact,transitions,rng}.cpp src/v1_ilp/*.cpp src/v2_openmp/*.cpp src/v3_simd/*.cpp src/v4_openacc/*.cpp tests/test_v4.cpp -o test_v4`

## Benchmark output
`bench_v4` header lists exec mode, GPU model, compiler, flags, device count and repetitions; rows give median/min/max/CV of kernel time,
median e2e/H2D/D2H for V4, speedups vs V0 (medians), and an `identical` flag per backend checked against V0 each rep.
Host-fallback numbers must not be quoted as GPU speedups. GPU results: `bench/results/kaggle_v4/`.

## GPU validation checklist (status after the Kaggle T4 run)
1. nvc++ compiles core, V3 and V4 targets: **done** (NVHPC 26.9; only the unused `use_simd` warnings). CUDA/driver version not recorded.
2. `test_v4 --require-gpu`: **done**, `openacc-device`, Tesla T4, 166 comparisons passed ("V4 OK").
3. Device `1-exp(-x)` difference count: **done**, 43/200000 differ (max rel 2.66e-15). `-gpu=nofma` **not tried**.
4. `-Minfo=accel` offload and no per-day bulk transfers: **done** (build log; profile log shows only 4-byte scalars per day).
5. Device-name query: **works** (printed as "Tesla T4 (NVIDIA)").
6. Kernel vs end-to-end timings: **done** (CSV). Per-kernel `NV_ACC_TIME` data is available only aggregated over all sizes.
7. Heavy atomic contention: correctness only (the test suite passed; this log does not itemise which test exercised contention); no performance measurement.
Open: CPU model and threaded CPU baseline on the same machine, finer size sweep between 10K and 100K, `-fast` vs no `-fast`, `-gpu=nofma`.
