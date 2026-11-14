# Synthetic geographic population (Bengaluru Urban OSM)

**What this is.** A reproducible generator that turns OpenStreetMap (OSM) features for Bengaluru Urban into a
*synthetic* population on a real street-level geography, plus a binary file (CEPOP v1) that the V0–V6 simulators load
through their existing external-input APIs.

**What this is not.** It is not census data. The agents, their homes, their activity destinations and the distances
between them are produced by documented, experimental assumptions. They do **not** represent actual Bengaluru
households, household sizes, employment, schooling, healthcare use, demographics or commuting patterns, and results
computed on them must not be presented as such.

Status of this document: describes the implemented code. The generator and C++ integration have been exercised on small
fabricated fixtures only (see [Verification status](#verification-status)); the real-data run and the GPU round trip are
executed on Kaggle and are not claimed here until that has happened.

## 1. Observations vs. assumptions

| OSM observation (from the data) | Synthetic assumption (made by this project) |
|---|---|
| Building footprints, their tags (`building=*`, `amenity`, `shop`, `office`, `healthcare`, `leisure`, …) and locations | A building tagged residential, or `building=yes` inside residential landuse, may host agents (Tier A/B) |
| Residential landuse polygons (244.21 km² in the audit) | Landuse is only spatial context for Tier B; it is never a destination |
| Amenity / healthcare / leisure features and where they lie | A feature in a selected category is a candidate activity destination |
| Footprint area (m², EPSG:32643) | Area is turned into a relative weight with a floor, cap and exponent (not a household count or capacity) |
| Spatial concentration of buildings and POIs | Agents follow the weight distribution; no uniform district-wide assignment |
| — | Each agent has exactly one home and one activity destination, drawn by a distance-decay rule (§5) with hard capacity caps |
| — | Initial state S / timer 0 for everyone; infections are seeded only by the simulation run |

Everything in the right-hand column is configurable in `config/synthpop_default.json` and recorded in each run's
`config.json`. The defaults are placeholders chosen to avoid extreme dominance, not calibrated values.

## 2. Data sources and CRS

Inputs (read-only; never modified):

```
data/processed/geo/{buildings,landuse,amenities,healthcare,leisure}.parquet     (GeoParquet, EPSG:4326)
data/boundaries/bengaluru_urban.geojson                                           (district boundary)
```

* OSM element identity is `(osm_type, id)` — node, way and relation numbers are separate namespaces, so `node/9301` and
  `way/9301` are different elements.
* Stored/exported coordinates stay in **EPSG:4326**. Area, distance, weighting and nearest-neighbour search use
  **EPSG:32643** (UTM 43N). Distances are never computed in degrees.
* Each feature is represented by one point (`point_on_surface` in the metric CRS, transformed back to lon/lat). A feature
  is kept only if that point lies inside the boundary (landuse is not boundary-filtered because it is context only).
* `roads` is not used.

## 3. Residential classification

Mirrors the tiers of `scripts/audit_osm_layers.py` (a test checks the tag vocabularies are identical):

| Tier | Rule | Default |
|---|---|---|
| A | `building` ∈ explicit residential values (`residential, apartments, house, detached, semidetached_house, terrace, dormitory, bungalow, houses, duplex, villa`) | included |
| B | `building=yes`, no activity tag, representative point inside a `landuse=residential` polygon | included |
| C | `building=yes`, no activity tag, elsewhere | **excluded** (`residential.include_tiers`) |
| — | `building=yes` carrying `amenity/shop/office/healthcare/craft/tourism/leisure` | never a home (may be a destination) |
| — | any other `building` value | not a home |

* **No double counting.** Within a layer, exact duplicate `(osm_type, id)` rows collapse to the first row (each dropped
  row is logged). A building lying in several overlapping residential polygons is mapped to **one**: the smallest
  polygon, ties broken by key order. The count of such buildings is reported.
* **Weight.** `w = tier_factor × clip(footprint_m², floor, cap)^alpha` (defaults: floor 20 m², cap 500 m², alpha 1,
  tier factors 1). Optional `use_levels` multiplies by `min(building:levels, levels_cap)` (off). `w` is a *relative
  allocation weight*; building count and footprint are **not** interpreted as households or residents.
* **Per-home cap.** `max_agents_per_home` (default 25) is a hard cap.

## 4. Activity destinations

Categories (priority order when several tags apply): `education, healthcare, industrial, office, commercial_retail,
civic_public, worship, leisure, other_amenity`. Selected by default: all except `worship` and `other_amenity`
(`destinations.include_categories`). Leisure is restricted to `destinations.leisure_values`
(park, garden, sports_centre, stadium, swimming_pool, fitness_centre, playground, recreation_ground).

* Candidates come from `buildings`, `amenities`, `healthcare`, `leisure`. **Landuse polygons are never destinations.**
* A POI whose point lies inside a building polygon is preserved as its own destination (the count is reported); it is
  not merged into the building just because it is inside it.
* Features that are classified but not selected, leisure with other values, features without an activity tag, and rows
  dropped at load are all counted as exclusions in the report, with up to 10 example ids per reason.
* All activity categories are exported as one simulator location type, `WORK`; the category lives only in the metadata.

### Deduplication (every decision is recorded in `dedup_decisions.parquet`)

1. **Exact identity.** Records with the same `(osm_type, id)` — across layers or within one — are merged into one
   destination. The surviving geometry is the largest-footprint record (ties by layer priority
   `healthcare > amenities > leisure > buildings`); category is the highest-priority category among the merged records;
   `source_layers` lists all contributing layers. Decision: `exact_key_merge`.
2. **Evidence-based proximity merge.** Two *different* elements are merged only if they have the **same category AND the
   same non-empty normalised name** (lower-cased, punctuation/whitespace collapsed) **AND** are within
   `dedup.name_merge_radius_m` (default 50 m). Decision: `name_category_proximity_merge`. An optional rule for unnamed
   same-category pairs (`merge_unnamed_same_category_within_m`) exists and is **off** (0).
3. **Never proximity alone.** Distinct pairs within `dedup.log_radius_m` (10 m) that fail the rules above are kept and
   logged as `kept_distinct_close_pair` with the reason (`different category`, `at least one unnamed`, `different names`).

## 5. Assignment (deterministic, distance-sensitive, capacity-constrained)

* **Agents and homes.** Exactly `N` agents (default 100,000; `--n-agents`). Per-home agent counts come from a seeded
  randomized apportionment: capped water-filling, integer part of each quota, remaining units by seeded systematic
  sampling of the fractional parts. Result: exactly `N` agents, per-home caps respected, each home's expected count
  proportional to its weight. (Largest-remainder rounding was rejected: with ~0.5 agents per home it would
  deterministically exclude every low-weight building.) Agents are then shuffled so agent ids carry no spatial order.
* **Destination capacity.** For destination `d` with weight `w_d`:
  `cap_d = min( max( ceil(slack × N × w_d / Σw), min_capacity ), ceil(max_share_of_population × N) )`
  (defaults: slack 3.0, min_capacity 3, max_share 0.5 % of N, i.e. 500 agents at N = 100,000). Destination weight is
  `category_weight × clip(area, 50, 5000)^0.5` (point features use `poi_default_area_m2`). The share cap is the documented
  guard against any single destination dominating; the run **fails** if total capacity < N.
* **Choice rule.** Batched rounds: every unassigned agent draws one destination from its `candidate_k` (30) nearest
  destinations within the stage radius that still have capacity, with probability ∝ `w_d × kernel(distance)`
  (exponential, scale 5 km by default; a power-law kernel is available). Each destination accepts proposals in
  random-priority order up to its remaining capacity; the rest retry. If agents remain, the radius widens in fixed
  stages (15 km → 30 km → 60 km → unlimited). The stage each agent was placed in is exported (`assignment_stage`).
* **Failures are never hidden.** With `fail_on_unassigned` (default true) any unplaced agent fails the run; the failure,
  stage statistics and traceback are written to `report.json` first.
* **Determinism.** Randomness uses counter-style Philox streams keyed by `(seed, stream, stage, round)`, features are
  processed in sorted `(osm_type, id)` order, and ties are broken by index. Identical inputs + config + seed give
  byte-identical `population.cepop` (checked by the pipeline re-run).
* **Cap sensitivity.** The report re-runs the assignment for `capacity_slack ∈ {1.5, 2, 3, 5, 10, 1e9}` and reports
  unassigned agents, distance percentiles, maximum destination occupancy, top-1 % share and Gini.
* Home→destination *distances* are an outcome of the distance-decay rule and capacity caps; they are **not** observed
  commuting distances.

## 6. CEPOP v1 binary format

Little-endian; 64-byte header; six 8-byte-aligned sections; CRC-32 of the payload. Normative spec:
[`docs/cepop_format.md`](cepop_format.md). Codec: `scripts/synthpop/cepop.py` (Python) and
`include/external_population.hpp` / `src/common/external_population.cpp` (C++). The C++ reader checks magic, version,
endian marker, header size, flags, reserved bytes, N/L ranges, exact file size and CRC, decodes byte-wise (host-endian
independent) and then calls `validate_input`. Python and C++ serializers are byte-identical on a golden fixture
(`tests/fixtures/tiny.cepop`).

Arrays: `state u8[N]`, `timer u16[N]`, `home_loc u32[N]`, `work_loc u32[N]`, `loc_type u8[L]` (0 HOME, 1 WORK),
`occupancy u32[L]`. All agents start `S` with timer 0. `occupancy[l]` = number of `home_loc` plus `work_loc` references
to `l`, exactly as `validate_input` requires. Location ids: HOME locations first, then WORK, each sorted by
`(osm_type, id)`. Unused locations are kept (occupancy 0) so ids are stable.

## 7. Output files (`data/synthetic/<run>/`, excluded from Git)

| File | Content |
|---|---|
| `population.cepop` | simulator input (CEPOP v1) |
| `locations.geoparquet` | row *i* = location id *i*; EPSG:4326 point geometry; `loc_type`, `loc_type_name`, `osm_type`, `osm_id`, `source_layers`, `category` (`residential` for homes), `tier`, `name`, `footprint_area_m2`, `weight`, `capacity`, `occupancy`, `landuse_context`, `inside_building`, `n_merged_records`, `lon`, `lat` |
| `agents.parquet` | `agent_id`, `home_loc`, `dest_loc`, `dest_category`, `distance_m`, `assignment_stage` |
| `dedup_decisions.parquet` | one row per dedup decision (see §4) |
| `config.json` | the exact merged configuration |
| `report.json` / `report.md` | classification counts, exclusions, dedup statistics, weights/caps, capacity effects, occupancy and distance distributions, spatial-fidelity check, cap sensitivity, validation results, checksums, inputs |
| `manifest.json` | versions, input and output SHA-256, config hash (contains a timestamp) |
| `validation_independent.json`, `kaggle_run_record.json`, `logs/`, `extpop_*.json`, `daily_*.csv` | written by the Kaggle pipeline |

## 8. Validation

`scripts/synthpop/validate.py` (CLI: `scripts/validate_synthetic_population.py`) reads only the exported files and the
boundary and checks: exact agent/location counts, `location_id` = row order, all-S/timer-0, ids in range, HOME/WORK types,
occupancy recomputed from the agent arrays equals both the CEPOP array and the GeoParquet column, `Σ occupancy = 2N`,
agents file consistent with the CEPOP arrays, no nulls, CRS = EPSG:4326, no missing/empty/invalid geometries, all points
finite and inside the boundary, capacity ≥ 1 and occupancy ≤ capacity, per-home and per-destination caps, categories,
`(osm_type, osm_id, loc_type)` uniqueness, assignment distances recomputed from lon/lat in EPSG:32643, and dedup decision
types. The generator runs it automatically; the pipeline runs it again as a separate process.

## 9. C++ integration: `extpop_run`

```
extpop_run --input population.cepop [--backend v0|v6|both] [--days 100] [--seed 42] [--init 100]
           [--beta-home 0.3] [--beta-work 0.3] [--incubation 3] [--infectious 5]
           [--expect-agents N] [--expect-locations L] [--json out.json] [--daily-csv PREFIX]
           [--v6-mode sync|async|graph] [--v6-graph-days 32] [--v6-block 256]
           [--v6-agg] [--v6-skip-exp] [--v6-skip-rng] [--v6-pred-loads]
```

Loads with `cepop::load` (→ `validate_input`), seeds infections with the existing `seed_infections`, re-validates, runs
`run_simulation` (V0) and/or `run_simulation_v6` through the existing external-input overloads, and checks per backend
that every day conserves the population and day 0 equals the seeded state; with `both` it also compares V0 and V6 daily
counts. It prints timings, final counts and an FNV-1a fingerprint of the daily counts. Exit codes: `0` pass, `1`
error / invalid input / mismatch, `2` backend unavailable (V6 requested in a build without `ENABLE_CUDA_V6`, or without a
GPU that executes a probe kernel). The default backend is `v0`, which works in every build. No simulation algorithm or
kernel was changed; the tool, reader and tests are additive CMake targets (`cityepi_extpop`, `extpop_run`,
`test_extpop_reader`, `test_extpop_integration`).

```
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release                       # V0 (CPU)
cmake -S . -B build-cuda -DCMAKE_BUILD_TYPE=Release -DENABLE_CUDA_V6=ON -DCMAKE_CUDA_ARCHITECTURES=75   # + V6 (T4 = 75)
ctest --test-dir build-cuda -R extpop --output-on-failure
```

Tests: `extpop_reader` (codec, every rejection path, V0–V3 agreement), `extpop_integration` (reader → V0 equals a direct run
on a non-synthetic layout; CLI exit codes and messages; corrupt/truncated/invalid files; V6 part runs only with a V6 build
and a working GPU and otherwise prints `SKIPPED`), and, in a V6 build, `extpop_integration_v6` which runs the same binary
with `--require-gpu` so a missing GPU is a failure rather than a skip.

## 10. Kaggle workflow

Prerequisites: GPU accelerator enabled (T4 → sm_75), repository checked out, the five GeoParquet layers and the boundary
present at the paths above.

```
!pip install -q geopandas pyarrow scipy pyogrio
%cd /kaggle/working/CityEpi-GPU
!python scripts/kaggle_synthpop_pipeline.py --n-agents 100000 --seed 42 --require-gpu
```

`scripts/kaggle_synthpop_pipeline.py` runs, in order: environment capture → generation → independent validation →
determinism re-run (byte comparison of the four data files) → CMake build (V6 enabled iff `nvcc` exists; architecture
from `nvidia-smi` or `--cuda-arch`) → `ctest -R extpop` → `extpop_run --backend v0` → `extpop_run --backend both`.
It writes `kaggle_run_record.json` with: arguments, Python/library/CMake/compiler/`nvcc` versions, GPU name/driver/memory/
compute capability, input SHA-256s, the full configuration and its hash, per-step status/time/log, generator timings,
V0/V6 results (timings, daily-count fingerprints, equality), and SHA-256 of every output file. The verdict is
`ALL_PASSED` only if V6 really ran and passed; `PASSED_V6_NOT_RUN` if everything else passed but V6 was skipped (no GPU
or no `nvcc`; with `--require-gpu` that is `FAILED` instead); `FAILED` otherwise. Individual stages can also be run
directly:

```
python scripts/generate_synthetic_population.py --n-agents 100000 --seed 42 [--config my.json] [--set destinations.capacity_slack=2.0]
python scripts/validate_synthetic_population.py --run-dir data/synthetic/<run>
build-cuda/extpop_run --input data/synthetic/<run>/population.cepop --backend both --days 100 --expect-agents 100000
```

## 11. Verification status

Passed locally (fabricated fixtures only, no Bengaluru data, no GPU): Python tests for the CEPOP codec and the generator
(`pytest tests/python`), C++ tests `extpop_reader` and `extpop_integration` (V0 path), the existing `external_input`/V0–V3
tests, the pipeline script end to end in CPU-only mode (verdict `PASSED_V6_NOT_RUN`), and a syntax-only compile of the
V6-gated code paths.

**Not yet executed (requires Kaggle):** the generator on the real layers (real column types, tier counts versus the
audit's 24,130 / 182,348 / 606,807, runtime and memory at ~800k buildings, whether the default capacities place all
100,000 agents, the cap-sensitivity results), real-data determinism, the V6 build with nvcc, and the GPU round trip
(`extpop_integration_v6`, `extpop_run --backend both`).

## 12. Limitations

* Synthetic by construction; not calibrated to any census, employment, school-enrolment, health-service or travel data.
* OSM completeness and tagging vary; `building=yes` dominates, so Tier B/C membership depends on landuse mapping quality.
  Footprint area is a weak proxy for residents or visitors.
* One home and one destination per agent; no households, ages, workplaces vs. schools, schedules, or multiple activities.
  The simulator sees only HOME/WORK locations.
* Category weights default to 1 and capacities derive from footprint and the global slack/share parameters; both are
  arbitrary knobs, not estimates. At N = 100,000 most homes host 0–2 agents (≈0.5 per candidate home on average), so the
  population is a sparse sample of the building stock, not a full-city model.
* Candidate destinations are limited to the `candidate_k` nearest per stage; a distant large facility can be unreachable
  from a given home within a stage, and the distance distribution reflects the kernel and caps rather than behaviour.
* Features are represented by one point; large polygons (parks, campuses) are not spatially distributed.
* Proximity de-duplication is deliberately conservative: unnamed or differently named duplicates remain separate
  destinations (and are logged). Name normalisation is simple (no transliteration).
* Tier counts are computed inside the boundary after de-duplication and may differ from the audit's.
