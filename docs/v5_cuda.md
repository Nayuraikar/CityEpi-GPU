# V5 — naive CUDA backend

`cityepi_v5` (`src/v5_cuda/v5_simulation.cu`, `include/v5_simulation.hpp`, `include/v5_rng.hpp`) is a straightforward CUDA
port of the V4 kernel structure. Built only with `-DENABLE_CUDA=ON` (default OFF, independent of `ENABLE_OPENACC`);
V0–V4 sources, targets and results are unchanged. There is **no CPU fallback**: `run_simulation_v5` throws unless a CUDA device
really executed a probe kernel.

## Per-day design (three steps)
1. `location_prob_kernel` (thread per location): `prob[l] = occ ? 1.0 - exp(-beta * nin[l] / occ) : 0.0`, then `nin[l] = 0`
   (becomes next-day tally). Thread 0 also zeroes the 4 state counters.
2. `agent_step_kernel` (thread per agent): reads only start-of-day state and `prob`; counter-based RNG draws (susceptibles only);
   V4's branchless state/timer update; `atomicAdd` on `counts[new_state]` and, if infectious, on `nin[home]`, `nin[work]`.
3. `cudaMemcpy` of the 16-byte counter array to the host (synchronisation point; host checks `S+E+I+R == N`).

Simple 256-thread blocks, default stream, no shared memory, no warp tricks, no streams/graphs/pinned memory.
All device buffers are allocated once, copied in once and stay resident for all days; state/timer return once at the end and are
re-counted on the host against the last device-side counts.

## Determinism and V0 equivalence
- RNG: `rng_v5::` is a `__host__ __device__` copy of the V0 `rand01` stages (integer arithmetic + exact power-of-two scale), so host
  and device agree bitwise. Draws depend only on (seed, agent, day, slot), never on launch shape.
- All sums are integer atomics ⇒ independent of thread order.
- Floating point: the probability keeps V0's operation order `1.0 - exp((-beta * inf) / occ)`; built with `-fmad=false -prec-div=true
  -prec-sqrt=true` so no FMA contraction changes it. **Not guaranteed:** CUDA device `exp()` may differ from host libm by 1 ulp
  (V4 saw 43/200000 sampled differences). A flipped `u < prob` comparison would diverge from V0; `test_v5` prints the device-vs-host
  `1-exp(-x)` difference count, and V0 equality is the authoritative check.

## Build (Kaggle Tesla T4 = sm_75)
```
cmake -S . -B build-cuda -DENABLE_CUDA=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_CUDA_ARCHITECTURES=75
cmake --build build-cuda -j
build-cuda/test_v5 --require-gpu
build-cuda/bench_v5 7 10000 100000 1000000 5000000 > bench/results/kaggle_v5/v5_gpu_results.csv
```
(`cityepi_core` is linked `LINK_ONLY` so its `-Wall -Wextra` host options never reach `nvcc`. Needs CMake ≥ 3.18 and the CUDA toolkit.)

## Tests (`tests/test_v5.cpp`)
Host RNG bit-equality; device RNG bit-equality vs `rand01` (3 seeds × days × slots); V0 equality across sizes (1…1M incl. block-size
boundaries 255/256/257), betas {0, 0.3, 2, 1e6}, timers, zero/clamped durations, zero days, single-location atomic contention, and
determinism over repeated runs; failure injection (throw mid-run after days 1/7/20, fail each of the 9 device allocations in turn)
with `v5_live_allocations() == 0` after every path, and a clean run afterwards. Without a device, only the host RNG checks run, a
loud *SKIPPED* notice is printed and the exit code is 0; `--require-gpu` (or `CITYEPI_REQUIRE_GPU=1`) makes it exit 1. The CTest
entry always passes `--require-gpu`.

## Benchmark (`bench/bench_v5.cpp`)
Same methodology as `bench_v4` (identical Params/seed, warm-up, interleaved reps, every row checked identical to V0), CPU baselines
V0, V1, V2 (1 thread / max), V3 on the same host. `kernel_s` = day loop with data resident (includes the per-day 16-byte readback);
`e2e_s` = `cudaMalloc` + H2D + kernel + D2H, host population generation excluded for all backends; `events_s` = same day loop via
`cudaEvent`s. The CSV header records GPU (name, cc, SMs, memory), driver/runtime versions, nvcc version, CPU model, logical cores,
RAM, OS and the build flags. OpenMP is OFF by default in the CPU build, so `V2_maxT` is only multi-threaded if `-DENABLE_OPENMP=ON`
was used; report speedups against the CPU configuration actually recorded in the header.

## Status
Validated on a Kaggle Tesla T4 (CUDA 13.0.88, `-DCMAKE_CUDA_ARCHITECTURES=75`). The recorded benchmark in
`bench/results/kaggle_v5/` (`v5_benchmark.csv`, `v5_benchmark.log`, `v5_environment.log`) shows the V5 row bit-identical to V0
(`identical=yes`) at 10k, 100k, 1M and 5M agents; V5 day-loop medians were 0.00417 / 0.01785 / 0.15479 / 0.64766 s
(6.1x / 15.4x / 20.6x / 32.6x versus V0 on that host). That directory does not contain a `test_v5` log.

Earlier host-only validation (the real `.cu` compiled as C++ against a CPU emulation of the few CUDA runtime calls) checked the
logic, test harness, failure-injection paths and benchmark plumbing only.
