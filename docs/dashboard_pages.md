# Dashboard pages: data sources and scientific limits (Phase 4)

All pages below are **read-only**. They read files from `ui_data_bundle/` through FastAPI endpoints; nothing is recomputed by a simulation. Only the Simulation Studio (`/api/sim/*`, see `simulation_api.md`) runs live simulations. The population is **synthetic, not census data**; epidemic parameters are experimental.

Global rules: dataset IDs, CRC32s, units and provenance are shown as recorded; numeric transmission parameters (β) are **not recorded** with any result, so scenarios are labelled low/baseline/high only.

## Overview — `/api/overview`
Sources: both datasets' `report.json`, `epidemic_*` and `final_10seed_validation` results, `kaggle_run_record.json`, plus live probes of `/api/health` and `/api/sim/capabilities` (the only non-recorded content, labelled "Live probe").
Shows population, locations, households, validation counts (read from each report, not hardcoded), V0≡V6 equality, seed-42 outcome, architecture summary and links.
Limits: validation checks test internal consistency of generated data, not agreement with Bengaluru.

## GIS Explorer — `/api/geo/*`
Real (OpenStreetMap-derived): boundary, buildings, roads, healthcare, amenities, leisure, land use (`data/processed/geo`).
Synthetic: destinations and "occupied candidate homes" (`locations.geoparquet` of the household dataset). An occupied candidate home is an OSM building that received synthetic agents, **not** a household or surveyed dwelling. Destination categories and capacities are placeholders.
Behaviour by zoom: roads are class-filtered below zoom 15; buildings are a density grid below zoom 15 and footprints from 15; land use ≥ 12, leisure ≥ 13; point hover ≥ 14. Viewport results above the limit are evenly subsampled and say so. Failed loads are reported in the layer row.

## Population Explorer — `/api/population`
Sources: `report.json`, `households.parquet`, `agents.parquet`, `locations.geoparquet` for the household dataset (`..._households_v1`) and, for comparison, the legacy dataset (`bengaluru_urban_N100000_seed42`).
Shows dataset identity (ID, CEPOP CRC32, config SHA-256, validation), household-size distribution vs the configured PMF, home occupancy, destination assignment/capacity, and home→destination distance (haversine, metres) for both datasets and per category.
Limits: the household-size PMF and capacities are placeholders. Legacy "occupied homes" are not households.

## Epidemic Analysis — `/api/epidemic`
Sources: `epidemic_population_comparison/` (legacy, household) and `epidemic_transmission_sensitivity/` (low, baseline, high); curves from the recorded V6 CSVs (daily checksum equals V0). Seed 42, 100 days, 100 initial infectious.
Derived here (not stored): attack rate = 1 − S(100)/N; daily incidence = S(t−1) − S(t); peak day/incidence from those.
Household and baseline are the same recorded configuration (same input, same checksum).
**Caveat:** legacy and household runs use different CEPOP inputs with different home *and* destination assignments, so the comparison is not a controlled experiment isolating household effects.

## Scenario Comparison — `/api/epidemic`, `/api/epidemic/seeds`
Seed-42 overlays for legacy vs household and low/baseline/high, plus the ten-seed validation.
Ten-seed validation is **V0 CPU only** (no V6 runs), household population only, simulation seeds 42–51. Mean, SD (sample, n−1), and attack-rate min/max come from `summary_statistics.csv`; peak-infectious min/max are taken from `all_seed_results.csv` rows (marked `*`). Seeds vary only the model's random draws on one fixed synthetic population; the spread is **not** uncertainty about real Bengaluru, and no ten-seed legacy run exists.

## Tests
`tests/backend/test_dashboard_data.py` checks every endpoint above against the source CSV/JSON/parquet files. Run: `cd backend && .venv/bin/python -m pytest ../tests/backend`.
