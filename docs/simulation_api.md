# Simulation execution API (`/api/sim/*`)

Launches the C++ `extpop_run` executable. Epidemic logic is never reimplemented in Python/JS. Separate from the read-only recorded-results endpoints.

Build (V0, any machine): `cmake -S . -B build-sim -DCMAKE_BUILD_TYPE=Release && cmake --build build-sim --target extpop_run`
GPU host later: build with `-DENABLE_CUDA_V6=ON` into `build-cuda/` (or set `CITYEPI_EXTPOP_RUN_V6`); V6 appears as available only if a probe run succeeds.
Env: `CITYEPI_EXTPOP_RUN`, `CITYEPI_EXTPOP_RUN_V6`, `CITYEPI_RUNS_DIR` (default `backend/.runs/`), `CITYEPI_SIM_MAX_CONCURRENT` (default 2).

| Endpoint | Purpose |
|---|---|
| `GET /capabilities` | datasets, backends (available + reason), limits, defaults, host |
| `POST /validate` | validate a config without starting anything |
| `POST /runs` | start (202) or 422 with field errors; states `queued → running → completed/failed/cancelled` |
| `GET /runs`, `GET /runs/{id}` | metadata, state, real progress (`day/total_days`, latest S/E/I/R) |
| `GET /runs/{id}/series?since=D` | daily rows incl. new infections (live while running) |
| `POST /runs/{id}/cancel`, `DELETE /runs/{id}` | cancel (kills process group); delete a finished run |
| `GET /runs/{id}/log`, `/export.csv`, `/export.json` | stderr/stdout tail, exports |

Progress comes from `extpop_run --progress` (one line per simulated day, V0 only). V6 reports no per-day progress, so `progress.fraction` stays `null` (never estimated).
Each run: unique id, own directory (`meta.json`, `stdout.log`, `stderr.log`, `progress.csv`, `daily_<backend>.csv`, `result.json`). Failed/cancelled runs keep logs but no result files.
Tests: `cd backend && .venv/bin/python -m pytest ../tests/backend`.

Per-agent daily snapshots (opt-in `snapshots: true`, **V0 only**, not supported by V6): see `docs/snapshot_format.md`. Endpoints: `GET /runs/{id}/snapshots`, `/snapshots/frames/{day}`, `/snapshots/home-positions`; exposed only after validation against the run's daily CSV.

---

# Simulation Studio and Simulation Viewer — user guide

## Start the application
```
# 1. C++ executable (CPU, any machine) — once
cmake -S . -B build-sim -DCMAKE_BUILD_TYPE=Release && cmake --build build-sim --target extpop_run

# 2. Backend (from the repository root; use the backend virtualenv, which has fastapi/pandas/pyarrow/shapely)
cd backend && .venv/bin/python -m uvicorn app.main:app --port 8000

# 3. Frontend (second terminal)
cd frontend && npm install && npm run dev        # http://localhost:5173, proxies /api to 127.0.0.1:8000
```
Restart the backend after pulling new code: a server started earlier keeps serving the old routes (a page that shows “404 … restart it” is talking to an outdated server). `CITYEPI_API=http://127.0.0.1:PORT npm run dev` points the dev proxy at another port.

## Live runs versus recorded results
* **Simulation Studio runs are live.** Each run starts the real `extpop_run` process on the machine hosting the backend, in its own directory, and its numbers belong only to the configuration shown on the run card.
* **Everything else (Overview, Epidemic Analysis, Scenario Comparison, PAGP Performance Lab) shows recorded results** (Kaggle T4 / Apple M1 artifacts). They are never re-executed and a live run never modifies them.
* The viewer header badge “Your live run · replay” marks a replay of a Studio run from its own snapshot file.

## Backends and availability
| Backend | Here | Notes |
|---|---|---|
| V0 · CPU reference | available when `build-sim/extpop_run` exists | real per-day progress; the only backend with snapshots |
| V6 · CUDA | **unavailable without a CUDA build + GPU** | availability is probed by actually running a 1-day job; on a Mac the reason shown is “executable not found”. Recorded Kaggle V6 results are in the PAGP Performance Lab. Nothing is simulated. |

V1–V5 are not exposed by `extpop_run` and therefore cannot be launched from the Studio.

## Parameters and validation
Days 1–1000, seed 0–2^53−1, initial infected 0–population (default 100; never defaults to the population size), β home / β destination 0–100 (`--beta-home`, `--beta-work`), incubation and infectious days 1–365. The form validates before submission; the server validates again and is authoritative. At most `max_concurrent_runs` (default 2) execute at once; extra submissions wait as *queued* and can be cancelled while queued.

## Create a snapshot-enabled run
1. Select **V0 · CPU reference**.
2. Tick **Record per-agent snapshots** (estimated size is shown; ≈ agents × (days+1) / 4 bytes; limited to 400 days — `snapshot_max_days` in `/capabilities`). It does not change results: the daily checksum is identical with and without snapshots (verified).
3. Run. When the run completes the server validates the snapshot against the run’s own daily CSV and the dataset’s home locations; only then does **Open viewer** become enabled (and the run gets a **MAP** tag in the history).
4. A run started without snapshots cannot be replayed — start a new one.

## The Viewer
* Frame *d* is every agent’s real V0 state at the end of day *d* (day 0 = the seeded state). Playback steps through stored frames only; nothing is interpolated.
* Agents are drawn at their **fixed home locations**. The model has no movement, a state change does not show where transmission occurred, and no transmission links exist.
* **Composition**: each cell/agent is coloured by the exact S/E/I/R mix. **Active infection**: cells shaded by the share of Exposed + Infectious agents. Below zoom 14 agents are aggregated into grid cells; from zoom 14 each agent is drawn.
* Controls: reset, previous/next day, play/pause/replay, speed 0.5–4×, timeline slider, click on the chart to seek. Keys: Space, ←, →. Counters, map, chart marker and day label always show the same day; the “Details” panel states whether that day’s counts and incidence match the daily CSV exactly.
* The chart can show S/E/I/R, E/I/R (hides the large susceptible curve so the epidemic wave is visible) or daily incidence.

## Limitations
Snapshots exist for V0 only (the CESNAP writer is wired into the V0 loop; V6 would need its own device-to-host per-day copies). Populations are synthetic, not census data, and all transmission rates are experimental.

## Tests
```
backend/.venv/bin/python -m pytest tests/backend                           # API, run manager, snapshots (53)
(cd build-sim && ctest)                                                    # C++ targets (7)
cd frontend && npx tsc -b && npx vite build
node --experimental-strip-types   --test tests/viewerCore.test.ts          # viewer core (+ live checks with CITYEPI_API / CITYEPI_RUN = a completed 100-day snapshot run)
node --experimental-transform-types --test tests/simForm.test.ts           # Studio form validation
```
