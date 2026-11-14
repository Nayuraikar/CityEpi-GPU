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
