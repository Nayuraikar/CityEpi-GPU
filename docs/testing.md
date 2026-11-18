# Testing

Results below were obtained on the development MacBook Air M1 (macOS, Chromium via Playwright 1.49.1, Node 22.12, Python 3.12) during
the Phase 5 pass. They are measurements of that machine at that time, not guarantees.

## Suites, commands and recorded results

| Suite | Command | Result (Phase 5) |
|---|---|---|
| C++ CTest, CPU build (V0–V3, external input, CEPOP reader, extpop integration) | `cmake --build build-sim -j && ctest --test-dir build-sim --output-on-failure` | **7/7 passed** |
| C++ CTest, OpenMP build (Homebrew clang 23, real threads for V2) | `cmake --build build-omp -j && ctest --test-dir build-omp --output-on-failure` | **7/7 passed** (after the include fix below; it failed to *build* before) |
| Backend API (run lifecycle, snapshots, dashboard data) | `backend/.venv/bin/python -m pytest tests/backend -q` | **70 passed**, repeated 3× clean after the fix, plus 5× under 4 busy-loop CPU hogs (70/70 each) |
| Python (CEPOP codec, generator, households, pipeline guard) | `.venv/bin/python -m pytest tests/python -q` | **104 passed** (needs `pyarrow` and `scipy` in `.venv`; without them 2 files are *skipped*, hiding 86 tests) |
| Frontend typecheck | `cd frontend && npm run typecheck` | clean |
| Frontend production build | `cd frontend && npm run build` | succeeds; JS 1,032 kB (301 kB gzip), CSS 51 kB (13.5 kB gzip) |
| Frontend unit tests (viewer core, form validation) | `cd frontend && npm run test:unit` | **22 passed, 1 skipped** (the skip is the live check below) |
| Frontend unit tests incl. live snapshot check | `CITYEPI_API=http://127.0.0.1:8765 CITYEPI_RUN=<completed snapshot run id> node --experimental-transform-types --test tests/viewerCore.test.ts tests/simForm.test.ts` | **23 passed, 0 skipped** |
| Playwright browser tests | `cd frontend && npm run e2e` | **24 passed**, twice from a cold start (≈ 1.7 min each) |
| Recorded GPU correctness | *not re-run* | `kaggle_v6/test_v6.log`: `4212 V6 comparisons on Tesla T4; V6 OK` |

GPU test targets (`test_v4/5/6`) are built only with `-DENABLE_CUDA*` / `-DENABLE_OPENACC` and cannot run on the Mac; see
[`kaggle_cuda_workflow.md`](kaggle_cuda_workflow.md).

## One-time setup

```bash
# C++
cmake -S . -B build-sim -DCMAKE_BUILD_TYPE=Release && cmake --build build-sim -j        # builds extpop_run used by the API
# backend (own venv)
python3 -m venv backend/.venv && backend/.venv/bin/pip install -r backend/requirements.txt pytest httpx
# python tests (root venv; geopandas etc. are needed by the generator tests)
.venv/bin/pip install pytest pyarrow scipy            # plus geopandas, shapely, pandas, numpy
# frontend
cd frontend && npm install && npm run e2e:install     # downloads Chromium for Playwright
```

## The Playwright suite (`frontend/e2e`)

`npm run e2e` starts **its own** backend (`uvicorn` on :8765, isolated temporary runs directory, wiped before and after) and its own
Vite **dev** server (:5273). It never talks to a backend already running on :8000, so a stale backend cannot satisfy a test. Dev mode is
intentional: React StrictMode double-mounts effects only in development, which is where the Leaflet error appeared. Every test fails on
any `pageerror` or `console.error`. `E2E_REUSE=1` attaches to servers you already started on those ports.

| # | Requirement | Spec |
|---|---|---|
| 1 | Overview loads | `pages.spec.ts` |
| 2 | GIS map loads, layers toggle, keyboard pan/zoom | `pages.spec.ts` |
| 3 | Population Explorer renders distributions | `pages.spec.ts` |
| 4 | Epidemic Analysis valid charts, all scenario tabs, recorded 34.6% | `pages.spec.ts` |
| 5 | Scenario Comparison renders | `pages.spec.ts` |
| 6 | Performance Lab tabs + provenance caveats visible + deep link | `pages.spec.ts` |
| 7 | Simulation Studio validation | `studio.spec.ts` |
| 8 | Live run starts, shows real progress, cancels, full run equals the recorded baseline (34.63%, peak 2,891, incidence 598, checksum `b213860e1d97b2c8`) | `studio.spec.ts` |
| 9 | Snapshot run opens the Viewer; day 100 S/E/I/R equals 65,371 / 1,257 / 2,343 / 31,029 | `studio.spec.ts` |
| 10 | Play, pause, step, seek, replay, reset, keyboard, 390 px layout | `studio.spec.ts` |
| 11 | CSV/JSON exports download; population conserved on every row | `studio.spec.ts` |
| 12 | No horizontal overflow on all 7 pages at 1440, 1024, 390 px | `responsive.spec.ts` |
| – | Mobile drawer, Tab focus ring, accessible names, tab/switch state, repeated navigation | `responsive.spec.ts` |
| – | Current-build API contract, error + Retry states, old-backend notice, unreachable API, bad ids | `api.spec.ts` |

## Defects found and fixed in Phase 5

1. **Intermittent backend failure (root cause found).** The Phase 4 failure that "passed on three reruns" is a real race in
   `backend/app/sim/runs.py`. A stress loop (submit then cancel immediately, 400–1000 iterations) reproduced two failure modes:
   *(a)* the worker checked "still queued?" and wrote `RUNNING` in two separate critical sections, so a `cancel()` in between was
   overwritten by `RUNNING` and the process started anyway (1 in 400 runs ended `running`); *(b)* after `SIGTERM` to the process group, a child
   forked at that instant survived as an orphan holding the stdout pipe, and the `SIGKILL` escalation waited only for the group leader, so the
   run stayed `running` (and the orphan lived) until the child exited on its own (observed once in roughly 4,000 stress iterations). Fixes: one atomic queued→running transition;
   escalation now waits for the whole group and `SIGKILL`s survivors after the grace period; timeouts also reach orphaned members.
   Regression tests: `test_immediate_cancel_never_resurrects_run`, `test_cancel_kills_orphaned_group_members`. After the fix: 6 × 1000 stress
   iterations, 0 failures, no leaked processes. The API server running on :8000 must be **restarted** to pick this up.
2. **Leaflet StrictMode error (reproduced and fixed).** `GISExplorer` added the boundary GeoJSON layer in a promise callback without checking the
   map was still the live one; in StrictMode the first map is already removed → `Cannot read properties of undefined (reading 'appendChild')`.
   Reproduced in dev mode on `#gis`; fixed with a `mapRef.current === map` guard (as `SimulationViewer` already had); 3 consecutive clean sweeps of all
   pages; now enforced by the e2e console-error fixture.
3. **Performance Lab tab ignored hash changes** made while already on the page (Back/paste of `#gpu/ok`): added a `hashchange` listener.
4. **Accessibility:** GIS map now has an accessible name, keyboard instructions and a live-region summary of visible layers; progress bar has a name and
   value text; run state changes are announced.
5. **Latency:** `/api/geo/density/*` took ≈ 0.9 s on every call (measured); it is now memoised (first call per cell size ≈ 1.2 s, repeats ≈ 25 ms).
6. **Build portability bug (C++ tool, not the model).** `tools/snapshot_writer.hpp` used `std::fill` without `#include <algorithm>`. It compiled with Apple clang
   (transitive include, so `build-sim` was fine) but `extpop_run` failed to build with the Homebrew clang 23 toolchain used for the OpenMP/V3 benchmark builds (`build-omp`).
   Fixed by adding the include; no algorithm, model, RNG or backend code was touched. Afterwards `build-omp` passes 7/7 and its `extpop_run` reproduces the
   recorded household checksum `b213860e1d97b2c8`.
7. **Hidden tests:** two Python test files silently skipped without `pyarrow`/`scipy` in the root venv (86 tests). Now installed and passing.

## Measurements (Apple M1, local, single run; read as order-of-magnitude)

| Item | Measured |
|---|---|
| Production bundle | JS 1,032 kB (301 kB gzip); Vite warns about the > 500 kB chunk. Not split: not needed for a local demo. |
| First load, dev server (unbundled), networkidle | Overview 1.8 s, GIS 2.5 s, Population 1.3 s, Epidemic 1.2 s, Scenarios 1.5 s, Perf Lab 1.1 s, Studio 1.0 s |
| JS heap after load | 48–73 MiB per page; 21 further navigations did not triple the heap and left ≤ 1 Leaflet container |
| API (median of 5) | overview 4 ms, epidemic 11 ms, benchmarks 28 ms, perf 7 ms, boundary 62 ms, occupied-homes points 411 ms (1.0 MiB), destination points 468 ms (2.0 MiB), buildings density 882 ms → 25 ms cached |
| Live V0 run, household population, 100 days | 0.23 s engine time (Apple M1) vs 0.50 s for V0 in the recorded Kaggle run |
| Snapshot, 100,000 agents × 101 frames | 2.79 MiB file; 9.6 MiB decoded frame cache in the browser; JS heap 69 MiB |
| Viewer draw (100k agents) | 17 ms grid view (262 cells), 8 ms at zoom 15 (827 agents in view), ≈ 3 ms when stepping; 20 "next day" clicks in 1.25 s |

The point-layer endpoints (0.4–0.5 s) were the slowest remaining responses and were **not** optimised; they are fetched once per layer.

## Not tested

Safari/Firefox, real touch devices, screen readers, colour-contrast/colour-blindness audits, > 100k agents in the browser, Linux/Windows hosts,
and any GPU backend on this machine.
