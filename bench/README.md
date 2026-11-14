# V1 ILP notes
Hardware: Apple M1 (8 cores, 8 GB), macOS (Darwin 25.6), Apple clang 21.0.0, arm64.
Flags: `-std=c++17 -O3 -Wall -Wextra` (identical for V0/V1; no -march/-ffast-math/LTO). Single thread.
Run: `cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build && build/test_v1 && build/bench_v0v1 7`
Workload: homes=N/5, works=N/50, init=N/1000, 100 days, seed 42, 7 reps (+warm-up), median of kernel time.
Reports: `bench/reports/*.remarks.txt` (-Rpass vectorize/unroll/licm), `*.s` (asm, -O3).

## Findings (V0 hotspots -> V1 changes)
- V0 `compute_exposure`: per susceptible 2 out-of-line `rand01` calls (6 serial splitmix mixes, `mix(seed)`/`mix(agent)` recomputed, calls block scheduling), 2 `exp` + 2 div, `||` short-circuit branch, 4 separate passes over agents + `newly_exposed` buffer.
  Asm: contact.s has 2 `bl rand01`; v1_simulation.s has none in the agent loop (`exp` only in the per-location loop).
- V1: fused single pass; per-location probability table; inlined RNG with hoisted/shared stages (two independent chains); branchless transition + counters (csel/cset).
- Compiler report: V1 agent loop is NOT auto-vectorized (scatter + RNG), so gain is scalar ILP/fewer instructions, not SIMD.
- Results (median of 7, ms): 10k 16.4->7.3 (2.25x), 50k 81.0->36.4 (2.23x), 100k 193.7->87.5 (2.21x), 500k 887.8->373.1 (2.38x). Outputs identical to V0 in all runs.
- Caveat: part of the gain is fewer instructions/memory passes, not purely ILP; no per-change ablation was run.

# V2 OpenMP notes
Env/flags/hardware: `bench/results/v2_env.txt`. Raw results: `bench/results/v2_results.csv` (`build-omp/bench_v2 7`; 5 reps at >=500k).
Methodology = V0/V1 bench: same Params/seed (homes=N/5, works=N/50, init=N/1000, 100 days), warm-up, median kernel time (setup untimed). Every V2 run is checked bit-identical to V0 (`identical` col; 0 mismatches).
Compiler note: this build used Homebrew clang 23.1.5 (not Apple clang 21 of the V1 notes), so absolute V0/V1 times are not comparable with the V1 table above; all ratios here are same-binary.
Design: parallel `prob[l]` loop merges+zeroes per-thread histograms (one owner per location); agent loop reads only own state + read-only `prob[]`; scatter into thread-private histograms (Local) or shared+`omp atomic` (Atomic); counts via `reduction(+)` or atomics. Integer sums + counter RNG => deterministic for any threads/schedule (tests: threads 1,2,3,4,8 x 3 schedules x 2 reductions x chunks, vs V0 and V1; also non-OpenMP build, where pragmas compile away).
Efficiency = t(V2, 1 thread, same config) / (T * t(V2, T)). Hist memory = T*n_locs*4 B (1M agents: 6.7 MB at 8 threads vs 0.84 MB shared).

## Results (median s; speedup vs V0 / vs V1; efficiency) — 1M agents
| threads | static/local | dynamic(1024)/local | guided/local | static/atomic |
|---|---|---|---|---|
| 1 | 0.956 (1.85x/0.80x, 1.00) | 0.960 | 0.951 | 0.875 (2.02x/0.87x) |
| 2 | 0.492 (3.59x/1.54x, 0.97) | 0.541 | 0.526 | 1.921 (0.92x, eff 0.23) |
| 4 | 0.414 (4.27x/1.84x, 0.58) | 0.428 | 0.405 (4.36x, 0.59) | 2.670 (0.66x) |
| 8 | 0.416 (4.25x/1.83x, 0.29) | 0.400 (4.41x, 0.30) | 0.392 (4.51x/1.94x, 0.30) | 4.648 (0.38x) |
Best at 100k: static, 4 threads, 0.030 s (5.49x vs V0, 2.44x vs V1, eff 0.78). At 10k: peaks at 2-4 threads (~2.35x vs V0 = V1 level); 8 threads is slower than 4.

## Findings
- Local histograms + reductions are 3-10x faster than atomics at >=2 threads (atomics contend on shared locations/counters and ping-pong cache lines); atomics are only slightly faster at 1 thread (no merge pass). Atomic mode is slower than V0 beyond 2 threads.
- Schedules: static/dynamic/guided within ~±10% at most sizes (uniform work; susceptible-only RNG branch imbalance is small). Static wins at 100k/4-8 threads (dynamic/guided 1.4-1.8x slower at 8T/100k); guided/dynamic marginally best at 1M/8T (3-6%). Dynamic default chunk=1 would be pathological, so 1024 was used.
- V2@1 thread is ~0.8x of V1 (V1 faster serially: no parallel-region/merge overhead, local counters, `__restrict`); V2 only beats V1 from 2 threads.
- Scaling saturates at ~4 threads (1M: 4T 0.41 s vs 8T 0.40-0.42 s): the loop is memory/scatter bound and the M1 has 4 performance + 4 efficiency cores, so 8 threads add slower cores; efficiency at 8T ≈ 0.3. Small sizes lose to fork/join + merge overhead (10k @8T slower than 4T).
- Not tested: per-change ablation, OMP_PROC_BIND/places, larger-than-8 threads (hardware limit).
