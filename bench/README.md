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

# V3 SIMD (ARM NEON) notes
Env/flags: `bench/results/v3_env.txt`. Raw results: `bench/results/v3_results.csv` (`build-v3-omp/bench_v3 7`, 7 reps at every size, 100 days, warm-up, kernel time only; backends interleaved per repetition; every run checked bit-identical to V0 -> all `yes`).
Build/run: `cmake -S . -B build-v3-omp -DCMAKE_BUILD_TYPE=Release -DENABLE_OPENMP=ON -DCMAKE_CXX_COMPILER=/opt/homebrew/opt/llvm/bin/clang++ && cmake --build build-v3-omp && build-v3-omp/test_v3 && build-v3-omp/bench_v3 7`
(Plain `cmake -S . -B build && cmake --build build` with Apple clang also builds and passes test_v0..v3.) Target: `cityepi_v3` lib, `test_v3`, `bench_v3`.
Design: blocks of 16 agents; compact susceptible indices; splitmix64 on 2 agents/vector (64-bit multiply emulated with `umull/umlal.2d`, both slot chains interleaved); double compare; branchless u8/u16 transition (`cmeq.16b`, `bsl.16b`); vector counts; scalar gathers of `prob[]`, scalar scatter into the tally, scalar `exp` per-location loop (kept scalar so results stay bit-identical). `use_simd=false` / non-NEON targets use the scalar fallback (V1-style loop).

## Results (median s, M1, single thread unless noted; speedup = vs V0 / vs V1; CV = stdev/mean over 7 reps)
| agents | V0 | V1 | V2 1T | V2 4T | V3 scalar fallback | V3 NEON (vs V0 / vs V1, CV) |
|---|---|---|---|---|---|---|
| 10k | 0.0165 | 0.0072 | 0.0093 | 0.0081 | 0.0077 | 0.0127 (1.30x / 0.57x, 3.4%) |
| 50k | 0.0828 | 0.0363 | 0.0460 | 0.0173 | 0.0391 | 0.0627 (1.32x / 0.58x, 29%*) |
| 100k | 0.1652 | 0.0730 | 0.0927 | 0.0305 | 0.0785 | 0.1237 (1.34x / 0.59x, 0.2%) |
| 500k | 0.896 | 0.370 | 0.501 | 0.185 | 0.432 | 0.648 (1.38x / 0.57x, 4.1%) |
| 1M | 1.792 | 0.747 | 0.957 | 0.415 | 0.875 | 1.357 (1.32x / 0.55x, 6.5%) |
*one outlier rep (min 0.061, max 0.118). V0/V2-4T show CVs up to 10-42% at large sizes (thermal/P-E core scheduling); read those with caution.

**Honest conclusion: the NEON version is ~1.3x faster than V0 but ~1.7-1.8x SLOWER than V1 at every size (and slower than its own scalar fallback by ~1.5x).** SIMD did not help this workload as implemented.

## Vectorization evidence
- Compiler auto-vectorization (`bench/reports/v3_*.remarks.txt`, Apple clang 21 and Homebrew clang 23): **no loop in V1 or V3 was auto-vectorized.** Reasons reported: per-location loop (`exp` call: "call instruction cannot be vectorized"), agent loops ("Control flow cannot be substituted for a select"/store/call), tail loop and agent loop "cost-model indicates vectorization is not beneficial".
- Hand-written NEON is confirmed in generated assembly (`v3_simulation.{apple,homebrew}.s`): `umull.2d` x6, `umlal.2d` x12 (64-bit multiply emulation), `ucvtf.2d` x2, `fcmlt.2d` x2, `cmeq.16b` x8, `bsl.16b` x6, `cmeq.8h`, `sshll`, `xtn.2s`, `shrn.2s`, `ushr.2d`, `shl.2d`, `eor.16b`/`eor3.16b`.
- Vectorized by intrinsics: RNG mixing, double conversion/compare, state/timer transition, state counts. Scalar: `prob[h]/prob[w]` gathers, `nin[]` scatter (conflicting indices), `exp` loop, S-index compaction, per-lane hit extraction.

## Why SIMD loses (hypotheses, not ablated)
- NEON has no 64-bit lane multiply: each splitmix mix costs ~8 vector ops for 2 lanes vs 2 scalar `mul` for 1 lane, and there are 3 mixes per susceptible with 2 lanes only -> RNG is slower than scalar, and it dominates early in the run when most agents are susceptible.
- The irregular parts (gathers, scatter, compaction, lane extraction through memory) stay scalar and add store/reload traffic; the loop is memory/scatter bound (see V2 notes), so wider ALU work cannot help.
- The transition itself is cheap in V1 already (branchless `csel/cset`).
- Not tested: hybrid (scalar RNG + NEON transition only), a different RNG better suited to 32-bit lanes (would change results), per-part ablation.

# V3 hybrid SIMD experiment (scalar RNG + NEON transition/counts)
Files: `include/v3_hybrid.hpp`, `src/v3_simd/v3_hybrid.cpp` (`run_simulation_v3_hybrid(p, use_simd)`); V3 scalar/NEON sources unchanged. Tests: `test_v3` now also checks hybrid (NEON and scalar fallback) vs V0/V1/V2 (162 comparisons incl. tails/timers/zero-beta/conservation/determinism; passes in Apple-clang serial and Homebrew-clang OpenMP builds).
Raw results: `bench/results/v3_hybrid_results.csv` (`build-v3-omp/bench_v3 7`; same env/flags as `v3_env.txt`; 6+2 backends in one executable, interleaved per rep, all outputs bit-identical to V0). The earlier `v3_results.csv` is untouched.
Design: per block of 16 agents, scalar V1 exposure (scalar splitmix, S agents only) writes `hit[16]`; NEON does the branchless u8/u16 transition (`cmeq`, `bsl`), vector counts; scalar scatter of the infectious tally; scalar tail (<16) and non-NEON fallback = V1 body.

## Results (median s; speedup vs V1; CV)
| agents | V1 | V3 NEON (full) | V3 hybrid | hybrid vs V1 | hybrid vs V0 | hybrid CV |
|---|---|---|---|---|---|---|
| 10k | 0.00709 | 0.01251 | 0.00625 | 1.14x | 2.61x | 0.2% |
| 50k | 0.03627 | 0.06068 | 0.03275 | 1.11x | 2.47x | 0.1% |
| 100k | 0.07277 | 0.12334 | 0.06626 | 1.10x | 2.49x | 0.2% |
| 500k | 0.36917 | 0.63898 | 0.35265 | 1.05x | 2.38x | 11.9% |
| 1M | 0.96424 (noisy) | 1.42222 | 0.82488 | 1.17x (see below) | 2.13x | 5.2% |
Hybrid-scalar fallback is 0.94-0.97x of V1 (as V3 scalar). V2 4T: 1.0-2.45x vs V1 (see CSV).
1M is noisy: in the main run V1 had min 0.773 / median 0.964 (CV 11%); a separate rerun of 1M only gave V1 0.836, hybrid 0.829 (1.01x), V3 NEON 1.376. At 1M the honest reading is **hybrid ≈ V1 (1.0-1.17x, not distinguishable from noise)**. 500k likewise has a high-variance outlier (hybrid max 0.47).

## Verdict
The hybrid **is modestly faster than V1 at 10k-100k (1.10-1.14x, low variance, 7 reps)**, roughly equal at 500k-1M where the loop becomes memory/scatter bound. It is far better than the full-NEON V3 (~1.9-2.0x faster), confirming that the emulated 64-bit multiply RNG was the cause of the earlier slowdown. The gain is small: only the transition+counts (a minor part of the per-agent cost) is vectorized.

## Compiler remarks / assembly (`bench/reports/v3_hybrid.{apple,homebrew}.{remarks.txt,s}`)
- Auto-vectorizer: no loop vectorized (agent loops "cost-model indicates vectorization is not beneficial"/"loop not vectorized"; per-location loop: `exp` call). Vectorization is from intrinsics only.
- Assembly shows NEON in the block kernel: `cmeq.16b` x8, `bsl.16b` x6, `cmeq.8h` x2, `sshll.8h`/`sxtl` x2, `addp.16b`/`uaddlv`-style horizontal sums (Homebrew: `addp.16b`; Apple: `uaddlv/addv`), `ld1/st1` 16-byte loads/stores. No `umull.2d`/`ucvtf.2d` (RNG is scalar; scalar `ucvtf d,x` x22 + `mul` remain).
- Still scalar: RNG + `pr[]` gathers (hit loop), tally scatter, `exp` loop, count/hit store-reload via a 16-byte stack array.
Limits: 16 scalar RNG evaluations still precede each vector block, the transition was already cheap/branchless in V1, and scatter/gather dominate at large N, so the ceiling is small. Not ablated per part.
