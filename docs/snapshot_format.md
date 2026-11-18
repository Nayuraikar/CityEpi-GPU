# CESNAP v1: per-agent daily state snapshots

**Scope: V0 (CPU reference) only.** `extpop_run --backend v6|both` rejects `--snapshots`, the API rejects `snapshots=true` for V6, and nothing here claims V6 support.

Produced by `extpop_run --snapshots DIR` (opt-in, default off). Writes `DIR/states.cesnap`. Written to `states.cesnap.partial` and renamed only after the footer is complete, so a crashed run never leaves a file that looks valid. The writer only *reads* `Population::state` after each completed day: the transition algorithm and RNG are untouched, and results/checksum are byte-identical with and without snapshots. Without `--snapshots` the code path is the unchanged `run_simulation`.

## What a snapshot is (and is not)
* **Frame d** = every agent's real V0 state at the **end of day d**. Frame 0 = after seeding, before any step. A run of D days has **D+1 frames**, matching the `D+1` rows of `daily_v0.csv`.
* **Agent id = array index** (CEPOP order, equal to `agent_id` in `agents.parquet`). The file embeds `home_loc[agent]` so every agent keeps a stable link to its home location; `locations.geoparquet` row *i* = location id *i* gives lon/lat.
* Agents have **fixed home coordinates; nothing moves**. Draw agents at their `home_loc` coordinates.
* A snapshot says *when* an agent changed state, **not where or from whom it was infected**. Transmission also happens at the destination (`beta_work`), so an infection must never be presented as having occurred at home. No transmission links are recorded and none may be fabricated from this data.

## Binary layout (little-endian)
| offset | size | field |
|---|---|---|
| 0 | 8 | magic `"CESNAP1\0"` |
| 8 | 4 | version = 1 |
| 12 | 4 | endian marker `0x01020304` |
| 16 | 8 | n_agents N |
| 24 | 8 | n_frames F (= days + 1) |
| 32 | 4 | header_size = 64 |
| 36 | 4 | bits per agent = 2 |
| 40 | 4 | frame_bytes = ceil(N/4) |
| 44 | 4 | flags = 0 |
| 48 | 4 | CEPOP payload CRC-32 of the input dataset |
| 52 | 4 | backend id (0 = V0) |
| 56 | 8 | seed |
| 64 | 4N | `home_loc` u32 per agent; zero-padded to 8 |
| next | F x frame_bytes | frames; agent i = bits `2*(i%4)` of byte `i/4`; unused tail bits 0; zero-padded to 8 after the last frame |
| next | F x 16 | counts table: S,E,I,R as u32 per frame (counted by the writer from the packed states) |
| end-16 | 16 | footer: payload CRC-32 u32, 0 u32, `"CESNAPE\0"` |

State encoding: **S=0, E=1, I=2, R=3**. Payload CRC-32 (zlib/IEEE) covers bytes `[64, footer)`. File size is exactly determined by (N, F): `expected_size()` in `snapshot_writer.hpp` / `snapshots.py`; any other size is rejected.
Size = about `N/4` bytes per day. 100,000 agents x 101 frames = **2,926,696 bytes (2.8 MiB)**.

## Memory
The writer holds one packed frame (N/4 bytes) plus the 16-byte-per-frame counts table. The Python reader memory-maps the file and decodes one frame at a time. Peak RSS of `extpop_run` on the household run is about 9 MB with or without snapshots.

## Python reader (`backend/app/sim/snapshots.py`)
```python
r = SnapshotReader("states.cesnap")   # raises SnapshotError on bad magic/version/size/etc.
r.validate(daily_rows, expect_home_loc)   # CRC, stored-vs-decoded counts, conservation, padding bits, == daily CSV, == dataset home_loc
r.frame(day) -> uint8[N]; r.frame_counts(day); r.home_loc(); r.counts_table(); r.info()
```
CLI: `python -m app.sim.snapshots states.cesnap --csv daily_v0.csv`.

## API (`/api/sim/runs/{id}/...`)
Request `snapshots: true` (V0 only, runs <= 400 days). After the run succeeds the manager validates the file against the run's own daily CSV and the dataset's `home_loc`. Any failure fails the run (`invalid_output`) and deletes the snapshot directory. `meta.snapshots.available` becomes true only after that validation.

| Endpoint | Returns |
|---|---|
| `GET /snapshots` | info (agents, frames, encoding, CRC) + scientific notes |
| `GET /snapshots/frames/{day}` | N bytes, one state per agent (0..3) in agent-id order |
| `GET /snapshots/home-positions` | float32 `[lon,lat]` x N: coordinates of each agent's actual `home_loc` |

404 if snapshots were not requested / not validated / the file is gone or damaged; 409 if the run is not completed.

## Simulation Viewer (frontend)
Simulation Studio → run with "Record per-agent snapshots" (V0) → **Open viewer**. Data: `/snapshots`, `/snapshots/home-positions`, `/snapshots/frames/{day}` plus `/series` for the daily CSV. Counters, attack rate and incidence are computed from the selected frame; each day is cross-checked against the CSV and a mismatch is shown. Below map zoom 14 agents are aggregated into grid cells (canvas); at zoom 14+ every agent is drawn. Playback steps stored integer days only (1x = 4 frames/s) and waits for a frame rather than skipping or interpolating. Code: `frontend/src/components/SimulationViewer.tsx`, `lib/viewerCore.ts` (pure, unit-tested), `lib/agentLayer.ts`, `api/snapshots.ts`. Tests: `cd frontend && CITYEPI_RUN=<run id> CITYEPI_API=<url> node --experimental-strip-types --test tests/viewerCore.test.ts`.
