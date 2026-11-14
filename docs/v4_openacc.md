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

## Status: GPU validation is PENDING
**Every V4 correctness result so far comes from GCC 16.2 `-fopenacc` host fallback** (`openacc-host-fallback`: no device, the
OpenACC regions run on the CPU, single-threaded, in shared memory). That run establishes the *semantics* only:
V4 == V0..V3 bit-identically in all 166 `test_v4` comparisons (sizes 1..1M, betas 0..1e6, timers, edge cases), plus RNG
bit-equality and exception-cleanup tests. It does **not** establish, and nothing here claims:
- that `nvc++` compiles V4 (or V0-V3) or that any NVHPC version supports every API/flag used;
- that device `exp()` matches host `exp()` (the test's device-vs-host `1-exp(-x)` comparison is trivially 0 on host fallback);
- that atomics/reductions are race-free in practice (host fallback never runs them concurrently);
- that data clauses are complete (host fallback shares memory, so a missing clause would go unnoticed;
  do not validate with `-gpu=managed`, which would hide this too);
- any GPU performance or speedup.

## Bit-identity / compiler-dependent differences
Integer logic and the RNG are exact (V4 uses `include/v4_rng.hpp`, a copy of the V1 RNG stages with `#pragma acc routine seq`,
tested equal to `rng_inl::`/`rand01`). The one floating-point risk is `1 - exp(-beta*I/occ)`: a device `exp` may differ from host
libm by ulps, and an agent whose uniform draw falls between the two values would diverge (and could cascade). The chance per run is
small but non-zero (order 1e-7 at 5M agents x 100 days, estimated, not measured). Avoid `-fast`/`-Mfprelaxed`. FMA contraction is
not expected to matter (no multiply-add pattern in the kernel); `-gpu=nofma` is available to rule it out. On a GPU, `test_v4` prints the
device-vs-host `1-exp(-x)` bitwise difference count and the first divergence day if V4 != V0; record any finding here.

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
Host-fallback numbers must not be quoted as GPU speedups.

## GPU validation checklist (all pending; needs an NVIDIA GPU and NVHPC)
1. `nvc++` compiles core, V3 and V4 targets (`-Wall/-Wextra` are skipped for NVHPC; the `-Wno-unknown-pragmas` flag core adds
   without OpenMP is unchecked under nvc++). The installed NVHPC/CUDA version must match the node's driver (`-gpu=cudaX.Y` may be needed);
   NVHPC may not be pre-installed on Kaggle.
2. `test_v4 --require-gpu` reports `openacc-device`, a device name, and every comparison identical to V0.
3. Device `1-exp(-x)` bitwise-difference count; whether `-gpu=nofma` is needed.
4. `-Minfo=accel` shows both loops offloaded and implicit `routine seq` / explicit routines accepted; `NV_ACC_NOTIFY=3` shows no
   per-day bulk transfers (expected: only the 4 reduction scalars).
5. `acc_get_property_string`/`acc_property_vendor` available in the installed NVHPC.
6. Kernel vs end-to-end timings (use `nsys`/`NV_ACC_TIME` for true per-kernel time: `kernel_s` here includes per-day launch,
   sync and scalar copy-back). Memory is not a constraint: about 11 B/agent on device (5M agents ~ 55 MB) plus location tables.
7. Behaviour under heavy atomic contention (the single-location test case).
