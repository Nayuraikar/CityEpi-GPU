# CityEpi-GPU — final demo guide

One story: **a deterministic epidemic model, executed seven ways, measured honestly, placed on real Bengaluru geography with a synthetic
population, and run live.** Everything shown is either a *recorded* artifact or a *live V0 run on the demo Mac*; say which, every time.

Contents: [Before you go on stage](#0-before-you-go-on-stage) · [Page/action checklist](#1-checklist-of-pages-and-actions) ·
[10-minute script](#2-10-minute-demo-script) · [15-minute script](#3-15-minute-presentation-script) · [Screenshots to capture](#4-suggested-screenshots) ·
[Fallback plan](#5-fallback-plan) · [Viva questions](#6-likely-technical-viva-questions-and-accurate-answers)

Ground rules for what you say: *synthetic agents*, never "residents"; *candidate buildings*, never "households" (except the synthetic
household table, which you call synthetic); GPU numbers are *recorded Kaggle T4* results, never "run here"; V7/V8 are *future work only*.

## 0. Before you go on stage

Do this 15 minutes before; none of it is optional.

1. **Restart the API from the current code** (an API started before Phase 5 still contains the cancellation race):
   ```bash
   cd backend && .venv/bin/uvicorn app.main:app --port 8000      # stop any older uvicorn first
   cd frontend && npm run dev                                    # http://localhost:5173
   ```
2. `cmake --build build-sim -j` so `build-sim/extpop_run` exists. Open **Simulation Studio**: V0 must be available; V6 must say
   *unavailable* (that is correct on the Mac).
3. **Pre-bake a fallback run.** In the Studio: household population, V0, 100 days, seed 42, 100 initially infected, *Record per-agent snapshots* → Run.
   It finishes in a few seconds; leave it in the history (runs persist until deleted). Verify **Open viewer** works and day 100 shows
   S/E/I/R = **65,371 / 1,257 / 2,343 / 31,029**.
4. Run `cd frontend && npm run e2e` once (≈ 2 min; it uses its own ports and does not touch your run history). 24 tests should pass.
5. Leave **"Street basemap (online)"** switched **off** (it is off by default). The demo needs no internet.
6. Browser: 1440 px wide window, zoom 100%, Chrome or Edge, one tab, notifications off. Use the sidebar's *Collapse* button if you want more room.
7. Have these tabs ready in order: `#overview`, `#gpu`, `#gis`, `#population`, `#epidemic`, `#scenarios`, `#studio`.

## 1. Checklist of pages and actions

| ✔ | Page | Action | Say |
|---|---|---|---|
| ☐ | Overview | scroll once: population, outcome, pipeline, "Recorded results vs live simulation" | "Recorded results are read-only; only the Studio runs code." |
| ☐ | PAGP Lab → Architecture | open V0→V6 list; play the ILP and reduction animations | what changes per version |
| ☐ | PAGP Lab → Benchmarks | pick a size; show speedup vs V0; open the provenance notes | speedup is **same-run** only; caveats |
| ☐ | PAGP Lab → CUDA deep dive | show E1–E4 table + acceptance rule + 1M anomaly | optimisations, and the unexplained anomaly |
| ☐ | PAGP Lab → Correctness | show 4212 comparisons / `V6 OK` | exactness evidence |
| ☐ | GIS Explorer | toggle Buildings/Roads/Healthcare; turn on Synthetic destinations and Occupied candidate homes; zoom to ≥ 14; hover a point | OSM vs synthetic labels |
| ☐ | Population Explorer | household-size PMF, occupancy, assignment distance | "experimental PMF, not census" |
| ☐ | Epidemic Analysis | Legacy tab, Household tab, then Low/Baseline/High | recorded curves, V6 recorded runs |
| ☐ | Scenario Comparison | legacy vs household; sensitivity; ten-seed validation | what each does and does **not** show |
| ☐ | Simulation Studio | household population, V0, 100 d, seed 42, 100 infected, snapshots on → Run | live, real progress |
| ☐ | Viewer | play, pause, seek to day 78 and 100, step ←/→, Active infection view | counters + fixed-home limitation |
| ☐ | Studio | click CSV and JSON export | exports are the run's own data |

## 2. 10-minute demo script

| Time | Part | Do / say |
|---|---|---|
| 0:00–1:00 | **1. Introduction** | Overview. "CityEpi-GPU simulates S→E→I→R spread among 100,000 *synthetic* agents on Bengaluru Urban's real OSM geography. Each simulated day touches every agent, so it is a natural target for parallel hardware. Same model, seven ways to execute it." Point to the banner: synthetic, experimental. |
| 1:00–3:00 | **2. Parallel architecture** | PAGP Lab → Architecture. Walk V0 (sequential reference) → V1 (ILP, same single thread) → V2 (OpenMP threads) → V3 (NEON) → V4 (OpenACC) → V5 (CUDA, atomics contend on 4 counters) → V6 (warp/block aggregation, async, graphs). "The key design choice: counter-based RNG keyed by (seed, agent, day, slot) and a staged day, so every version must give **bit-identical** counts." |
| 3:00–5:00 | **3. Performance** | Benchmarks tab. "Speedups are always against V0 **from the same run**." Show V1 ≈ 2.2×, V2 scaling saturating at 4 threads, V3 NEON *slower than V1* ("SIMD did not help; I report that"), V4/V5/V6 on the recorded T4. Open the caveats panel: x86 V3 rows are scalar fallbacks; OpenACC run had OpenMP off; V6 1M-agent anomaly is unexplained. CUDA deep dive: E1 aggregation is the biggest gain. Correctness tab: 4212 comparisons `V6 OK`. |
| 5:00–6:30 | **4. GIS and population** | GIS Explorer: OSM layers, then synthetic destinations and candidate homes, zoom ≥ 14, hover. Population Explorer: household-size PMF ("experimental"), assignment distances. "Candidate homes are OSM buildings that received synthetic agents — not verified households." |
| 6:30–7:30 | **5. Epidemic analysis** | Epidemic Analysis: household baseline 34.629% attack rate, peak 2,891 on day 78, vs legacy 0.802%. Scenario Comparison: sensitivity 0.755% / 34.629% / 71.089% and ten seeds. "Not a pure household test; β values behind low/high labels are not recorded; ten seeds = stochastic variability only." |
| 7:30–9:30 | **6. Live simulation** | Studio: household population, **V0** (V6 is unavailable here — "needs an NVIDIA GPU; Kaggle results are recorded"). 100 days, seed 42, 100 infected, snapshots on, Run. Watch progress. Open viewer: play at 4×, pause, seek to day 78, step, switch to Active infection. Read the counters at day 100: 65,371 / 1,257 / 2,343 / 31,029 — "identical to the recorded Kaggle V0 and V6 run". Point to the persistent note: **fixed home positions, nothing moves**. |
| 9:30–10:00 | **7. Conclusion** | One sentence each: parallel techniques applied and measured; GPU speedups recorded on T4; synthetic data and experimental parameters; V7 multi-scenario GPU and V8 MPI are future work. |

## 3. 15-minute presentation script

Use the 10-minute flow with these additions (slides optional; the dashboard is the slide deck).

| Time | Addition |
|---|---|
| 0:00–2:00 (Part 1) | Motivation: epidemic simulation cost grows with agents × days × repetitions. Show the pipeline diagram on Overview. Name the data honestly: OSM layers real; population synthetic. |
| 2:00–5:30 (Part 2) | Add the *why* for each step: V1 removes redundant work and exposes two independent dependency chains (ILP); V2 per-thread histograms vs atomics (3–10× difference); V3 shows that a technique can lose (no 64-bit lane multiply on NEON); V4 directive offload vs V5 explicit kernels; V6 reduces 100k+ atomic updates to 4 per block. Show the determinism argument: draws depend on (seed, agent, day, slot) only. |
| 5:30–9:00 (Part 3) | Show V2 scaling table (1M agents: 1 → 8 threads, efficiency 0.97 → 0.29) and what limits it (memory/scatter bound, 4P+4E cores). Show V6 acceptance rule and which switches pass/fail (skiprng, predload rejected). Explain `kernel` vs `e2e` time and why profile CSVs are 100-day aggregates. |
| 9:00–11:00 (Part 4) | Explain extraction: OSM buildings → Tier A/B/C residential candidates; landuse/amenity/healthcare/leisure → destinations with placeholder capacities; proximity de-duplication; distance-kernel assignment with capacity caps. Show category chips on the GIS page. |
| 11:00–12:30 (Part 5) | Explain the legacy-vs-household confound, sensitivity labels, ten-seed meaning, and the "not a forecast" statement. |
| 12:30–14:00 (Part 6) | Live run as above, plus **cancel a 1000-day run** to show real progress and process-group termination, then the CSV export. |
| 14:00–15:00 (Part 7) | Summary table of what is validated (exactness vs V0 on all backends; V6 on T4; live Mac V0 = Kaggle V0 checksum `b213860e1d97b2c8`) and what is not (calibration, real mobility, any real-world prediction, V7/V8). |

## 4. Suggested screenshots

Capture these yourself from the real running app (do not mock them). 1440 × 900 unless stated.

1. Overview (top and "Recorded results vs live simulation" section).
2. PAGP Lab: Architecture list; Benchmarks with the provenance notice visible; CUDA deep dive with the 1M anomaly notice; Correctness.
3. GIS Explorer at city scale (density grid) and at zoom 16 with synthetic destinations + candidate homes and a hover tooltip.
4. Population Explorer: household-size distribution and assignment distance.
5. Epidemic Analysis: household baseline S/E/I/R; Low/Baseline/High comparison.
6. Scenario Comparison: ten-seed attack-rate chart and statistics table.
7. Simulation Studio mid-run (progress bar, live counters) and after completion (result tiles).
8. Viewer at day 0, day 78 and day 100 with the S/E/I/R strip visible; Active-infection mode; the scientific note.
9. 390 px mobile: Overview and Viewer.
10. Terminal: `ctest` 7/7, pytest, Playwright 24 passed (real output).

## 5. Fallback plan

| Failure | What to do |
|---|---|
| **No internet** | Nothing needed: the basemap is off by default and every page serves local files. If the basemap was switched on, switch it off. |
| **Live simulation fails or is slow** | Use the pre-baked run from step 0.3 (select it in *Run history* → **Open viewer**). Say "this is the same configuration I ran a few minutes ago on this machine." A completed run is real data, not a recording of a recording. |
| **`extpop_run` missing / Studio says V0 unavailable** | Show the recorded Epidemic and Scenario pages; the Studio page still demonstrates validation (type `0` days → error, button disabled) and the V6-unavailable explanation. Then run `cmake --build build-sim -j` after the talk. |
| **Backend down** | Pages show "Could not load recorded data … Retry" — use it as a demonstration of failure handling, restart `uvicorn`, click Retry. |
| **Browser/Leaflet problem** | Reload; use a second pre-opened tab. As a last resort show `docs/` figures and the e2e terminal output. |
| **Question about a GPU run** | State plainly: no GPU on this machine; GPU numbers are the recorded Kaggle T4 artifacts; the workflow to re-run is in `docs/kaggle_cuda_workflow.md`. Never imply otherwise. |
| **Out of time** | Cut Part 4 detail, keep Parts 3, 5 and 6 (the live run is the proof). |

## 6. Likely technical viva questions and accurate answers

**1. How do you know the parallel versions are correct?**
Every backend's daily S/E/I/R counts must equal V0's exactly. The RNG is counter-based on (seed, agent, day, slot) and all reductions are
integer, so scheduling cannot change the result. V6 is checked in 4212 comparisons on a T4, over sizes straddling every warp/block boundary,
several β and seeds; the benchmark CSV has `identical_v0 = yes` on all rows. Caveat: device `exp()` is not guaranteed bit-identical to host
`exp()` (541/200000 sampled values differ in the last bits, max relative 3e-15), so exactness is established by the counts, not assumed.

**2. Why is V1 faster with one thread?**
Fewer instructions and memory passes (fused loop, inlined RNG with shared stages, a probability table so `exp` runs per location not per
agent) and two independent RNG dependency chains the out-of-order core can overlap; 2.21–2.38× on the M1. We did not ablate each change, so
we do not attribute the gain purely to ILP.

**3. Why did thread-local histograms beat atomics in V2?**
Atomics on `nin[home/work]` and the four counters contend and bounce cache lines; local histograms need a merge but no sharing. Recorded: 3–10×
faster for ≥ 2 threads; atomics only win slightly at 1 thread (no merge pass).

**4. Why does V2 stop scaling at about 4 threads?**
The loop is memory/scatter bound and the M1 has 4 performance + 4 efficiency cores, so threads 5–8 add slower cores; efficiency at 8 threads is
≈ 0.3. Not tested: thread pinning, > 8 threads.

**5. SIMD gave no benefit. Is that a bug?**
No — it is a recorded result. NEON has no 64-bit lane multiply, so splitmix64 is emulated (`vmull_u32`), which costs more than scalar `mul`; the
scatter/gather parts stay scalar. Full NEON ≈ 1.3× vs V0 but ≈ 1.7–1.8× slower than V1. A hybrid (scalar RNG + NEON transition) is 1.10–1.14× faster than
V1 at 10k–100k and within noise at 1M. The compiler also did not auto-vectorize any loop. These are hypotheses for *why*; no per-part ablation was run.

**6. What are the Kaggle V3 numbers?**
Scalar-fallback measurements: Kaggle is x86 and NEON is aarch64-only. Only the M1 data are NEON data.

**7. What is the difference between V4 and V5?**
V4 uses OpenACC directives (`#pragma acc parallel loop`, data regions) compiled by NVHPC; V5 is hand-written CUDA kernels (thread per location, thread
per agent, `atomicAdd` on counters) with a per-day host readback. V4 at 10k is slower than V0 (0.92×) — launch/sync cost dominates small sizes
(plausible, not separately measured).

**8. What makes V6 faster than V5?**
Independent, individually tested switches: E1 aggregates the four state counters with `__ballot_sync` + `__popc` → block shared sums → 4 global atomics per
block; E2 removes the per-day host sync (async) and optionally replays days through a CUDA Graph; E3 skips work that provably cannot change a decision
(`exp` when the tally is 0); E4 changes block size. Recorded: E1 is the largest single gain; graphs add little beyond async here. Acceptance rule: >
max(3%, 2×CV) at ≥ 2 sizes with no regression > 2% elsewhere — so `skiprng` and `predload` were rejected.

**9. Why not aggregate the location-tally atomics too?**
Agents are assigned to homes/destinations essentially at random, so the 32 lanes of a warp almost never share a location; aggregation would find no
duplicates. (Sorting agents by location could change that; deferred.)

**10. Explain the V6 anomaly at 1M agents.**
I cannot: `V6_base` is about 35% slower there than every non-aggregating variant, including ones that should be neutral. There is no profiler evidence for a
cause, so I report it as unexplained. It also inflates the 1M column of the "improvement vs base" table.

**11. Kernel time vs end-to-end time?**
Kernel = the 100-day loop with data resident (includes the count readback). End-to-end adds allocation, host↔device copies and graph build. Speedups in the
dashboard are kernel-only unless labelled; end-to-end speedups are smaller and are in the same CSVs.

**12. Why compare speedups only within one benchmark run?**
V4 and V5/V6 were measured in different Kaggle sessions on hosts with different CPUs, so their V0 baselines differ (e.g. V0 at 10k is 0.026 s vs 0.030 s). Mixing baselines
would make GPU versions look better or worse for reasons unrelated to the GPU.

**13. Can you show V6 running live?**
Not on this machine: it is an Apple M1 with no NVIDIA GPU, and the Studio correctly reports V6 as unavailable. V6 numbers are recorded Kaggle T4 artifacts; the
Mac's live V0 run reproduces the same daily checksum (`b213860e1d97b2c8`) as the recorded V0 and V6.

**14. Is the epidemic prediction realistic for Bengaluru?**
No, and it is not claimed to be. The population, destinations, capacities and household sizes are synthetic assumptions; β values and durations are experimental;
there is no mobility, age structure or calibration. The point is the parallel implementation and the geospatial pipeline.

**15. Why is the household attack rate 34.6% but the legacy one 0.8%?**
The populations differ in household structure *and* in home/destination assignments, so the gap is not a clean causal test of households. Under the experimental
parameters, households concentrate contacts at home locations, which plausibly drives the difference, but this was not isolated.

**16. What do the low/baseline/high scenarios correspond to?**
Three transmission settings (attack rates 0.755% / 34.629% / 71.089%). The exact β values are not recorded in the bundle configuration, so I do not quote them.

**17. What do ten seeds tell you?**
Stochastic variability of the simulation on one synthetic population (seeds 42–51, V0 CPU, household population). Not uncertainty about the real city, and V6 is not in that experiment.

**18. How are "occupied candidate homes" defined?**
OSM buildings classified as residential candidates (Tier A/B/C from tags/landuse) that received at least one synthetic agent. They are not surveyed households.

**19. How does the map work, and why don't agents move?**
Each agent is drawn at its fixed home coordinates; the model has one home and one destination per agent and no physical movement. The viewer replays each agent's
real S/E/I/R state per day from a CESNAP snapshot; a state change does not show where transmission occurred (it may have been at the destination).

**20. How do you know the snapshot shown is the real run?**
The backend validates the CESNAP file (size, CRC-32, per-frame counts against the daily CSV, home locations against the CEPOP, CRC equal to the one the executable reported)
before marking the run completed; the viewer cross-checks each shown day against the CSV and displays a mismatch if there is one.

**21. What happens when you cancel a run?**
The API sends SIGTERM to the run's process group, then SIGKILL after a grace period (also for orphaned group members); partial outputs are removed so a cancelled run cannot look like
a result. Phase 5 found and fixed two races here (cancel-while-queued being overwritten by "running", and an orphaned child blocking cancellation).

**22. Why is the benchmark workload different from the Bengaluru population?**
Speed benchmarks use the synthetic generator (homes = N/5, works = N/50, init = N/1000) at 10k–5M agents for scaling studies; the Bengaluru household population
(100,000 agents) is used for epidemic validation and live runs, and V0 = V6 equality was verified on it.

**23. What is not implemented?**
V7 (multi-scenario GPU), V8 (MPI), pinned/unified memory, `__shfl` reductions, interventions, mobility. They are future work only.
