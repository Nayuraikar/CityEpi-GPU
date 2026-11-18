# Release checklist (Phase 5 / 6)

Legend: ☑ verified by an executed test or inspection (evidence given) · ◐ done with a stated limit · ☐ not done / cannot be done here.
Nothing is ticked on the strength of "should work". Details and raw numbers: [`testing.md`](testing.md).

## Functional

| | Item | Evidence / limit |
|---|---|---|
| ☑ | All frontend pages load | Playwright tests 1–6, 8–10 and the 3-viewport sweep load all 7 pages; every test fails on any page/console error |
| ☑ | All backend endpoints work | Sweep of 33 requests across the recorded and `/api/sim` routes returned the expected status (200; 204 on delete; 404 for out-of-range frame); POST `/runs` (202), cancel, delete, exports, snapshot routes also covered by `tests/backend` |
| ☑ | Backend test suite passes | 70/70, three clean runs after the fix; 5 more under 4 busy-loop CPU hogs (70/70 each) |
| ◐ | C++ CTest passes | 7/7 in `build-sim` (CPU) and 7/7 in `build-omp` (OpenMP). **GPU test targets (`test_v4/5/6`) were not run** — they need an NVIDIA GPU. Recorded Kaggle evidence is `V6 OK`, 4212 comparisons |
| ☑ | Python tests pass | 104/104 (needs `pyarrow`, `scipy`; without them 86 tests silently skip) |
| ☑ | Frontend unit tests pass | 23/23 including the live snapshot check (22 + 1 when no run id is supplied) |
| ☑ | Playwright smoke tests pass | 24/24, twice from a cold start, no retries |
| ☑ | Desktop layouts pass | 1440 and 1024 px: no horizontal overflow on any of the 7 pages |
| ☑ | Mobile layouts pass | 390 px: no overflow on any page, nor in the Viewer; drawer navigation works |
| ◐ | No unresolved critical console errors | Enforced for every flow the 24 tests exercise. Other flows (e.g. GIS at every zoom, basemap on) were not scripted |
| ☑ | No leaked simulation processes | After backend stress runs, the Playwright suite (including a cancelled 1000-day run) and manual servers: `pgrep` shows no `extpop_run`/`sleep` and ports 8765/5273 free |
| ◐ | No unexplained intermittent test failures | The one known failure was **root-caused** (two races in `runs.py`), reproduced, fixed, covered by regression tests, and stress-tested (6 × 1000 iterations clean). Absence of *any* other rare race cannot be proven |
| ☑ | Simulation Studio works | Tests 7–11 (validation, live run, progress, cancel, delete, exports) |
| ☑ | Snapshot Viewer works | Tests 9–10; day 100 equals the recorded S/E/I/R; per-day CSV cross-check shown |

## Scientific honesty

| | Item | Evidence / limit |
|---|---|---|
| ☑ | Benchmark provenance is accurate | The Performance Lab still shows the NEON-unavailable, OpenMP-off, 1M anomaly and "NEON slower than V1" notices (asserted in test 6). Docs updated to match the recorded files |
| ☑ | Existing Kaggle/benchmark/OSM/synthetic data intact | `find … -newer <session start>` over `ui_data_bundle`, `bench/results`, `data`, `config`, `benchmarks` returned nothing; no file in `src/`, `include/`, `scripts/` changed |
| ☑ | OSM and synthetic data are distinguished | GIS Real/Synthetic groups and notice; Population page caveats; asserted in tests 2–3; documented in `limitations.md` |
| ☑ | Epidemic model / RNG / backends unchanged | No change to `src/`, `include/`; only a missing `#include <algorithm>` in the tool header `tools/snapshot_writer.hpp` |
| ☑ | Recorded results reproduce live | Live V0 on the Mac: 34.63% attack rate, peak 2,891, incidence 598, checksum `b213860e1d97b2c8`, final S/E/I/R 65,371 / 1,257 / 2,343 / 31,029 — equals the recorded Kaggle V0 and V6 |
| ☐ | Fresh CUDA validation | **Not possible on the Mac and not run.** Workflow prepared: [`kaggle_cuda_workflow.md`](kaggle_cuda_workflow.md). Recorded T4 artifacts verified present and consistent |

## Documentation

| | Item |
|---|---|
| ☑ | Root `README.md` (new; `README.txt` kept untouched) |
| ☑ | `architecture.md`, `pagp_concepts.md`, `methodology.md`, `limitations.md`, `testing.md`, `demo_guide.md`, `kaggle_cuda_workflow.md` |
| ☑ | Stale docs reconciled: `v6_cuda.md` (was "not yet built/run, results pending"), `synthetic_population.md` §11 ("not yet executed") |
| ☑ | Demo checklist, 10- and 15-minute scripts, screenshot list, fallback plan, 23 viva Q&As (`demo_guide.md`) |
| ☑ | All remaining limitations documented (`limitations.md`, `methodology.md` §7) |

## Open items you should know about

1. **Restart the API on :8000** — the server running when Phase 5 started predates the `runs.py` fixes (and the density cache).
2. **`bench/results/kaggle_v6/` is an empty directory** (dated 15 Nov, before this work). The V6 artifacts live in `ui_data_bundle/bench/results/kaggle_v6/`
   and that is what the backend serves. `docs/v6_cuda.md` and the CMake/bench command lines still write to `bench/results/kaggle_v6/`. Decide whether to copy the
   bundle files there (I did not touch your results tree).
3. **No GPU result was produced on this machine** and none is claimed.
4. **Git:** nothing was committed or staged (no git commands were run). `frontend/package.json` and `package-lock.json` gained `@playwright/test`; `.gitignore` and
   `frontend/.gitignore` gained entries for test output and `__pycache__`/`backend/.cache`.
5. Playwright downloaded Chromium to `~/Library/Caches/ms-playwright`; `.venv` gained `pyarrow` and `scipy`.
6. Not tested: Safari/Firefox, screen readers, real touch devices, contrast audits, > 100k agents in the browser.
