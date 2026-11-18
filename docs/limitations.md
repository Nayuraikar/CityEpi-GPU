# Scientific limitations and synthetic assumptions

CityEpi-GPU is a **parallel-computing and geospatial-modelling project**. It is **not** a calibrated epidemic forecast for Bengaluru and
must not be presented as one.

## 1. What is real and what is synthetic

| Item | Status |
|---|---|
| Bengaluru Urban boundary, buildings, roads, healthcare, amenities, leisure, land use | **Real OpenStreetMap extracts** (processed). Completeness and tagging vary; `building=yes` dominates. |
| Candidate residential buildings ("occupied candidate homes") | **OSM buildings** that received synthetic agents. Not verified households, not surveyed dwellings. |
| Destinations (workplaces/schools/etc.), categories, **capacities** | **Model assumptions** derived from OSM tags and footprint area plus global slack/share parameters. Category weights default to 1. Capacities are placeholders. |
| Agents | **Synthetic.** They are not residents of Bengaluru and do not represent real people. |
| Household-size distribution | **Experimental PMF**, not census data. |
| Home/destination assignment | Distance-kernel model with capacity caps; the resulting commute distances reflect the kernel and caps, not observed travel. |
| Epidemic parameters (β home, β destination, incubation, infectious period) | **Experimental.** Not fitted to any outbreak. |
| OSM population / commuting | OSM contains neither; none is implied. |

## 2. Model limitations

* One home and one destination per agent; no ages, schools vs workplaces, schedules, mobility, or multiple daily activities. The
  simulator sees only HOME/WORK locations; households are a Python-side construct and **do not change the simulator**.
* Compartmental states S/E/I/R with fixed incubation and infectious periods; no interventions, vaccination, reinfection or demography.
* At N = 100,000, most homes host 0–2 agents (≈ 0.5 per candidate home): the population is a sparse sample of the building stock, not a
  full-city model.
* Candidate destinations are limited to the `candidate_k` nearest per stage; features are single points (large polygons are not spread).
* Proximity de-duplication is conservative; unnamed duplicates may remain separate destinations.

## 3. Interpretation limits of the recorded results

* **Legacy vs household.** The two populations also differ in home/destination assignments, so the attack-rate difference (0.802% vs
  34.629%) is **not** a pure causal test of "households". Both are single-seed runs.
* **Transmission sensitivity.** Labels low / baseline / high are recorded; the **β values are not recorded** in the bundle configuration.
  No exact β may be quoted for them.
* **Ten-seed validation.** Seeds 42–51, V0 CPU only, household population only. It quantifies stochastic variability *given one synthetic
  population*; it says nothing about uncertainty in the real city, and it does not include V6.
* **Attack rate ≈ 34.6% / 71.1%** are properties of the experimental parameters, not predictions.

## 4. Visualisation limits

* The map shows agents at their **fixed home locations**. **Nothing moves.** A state change does not show where a transmission occurred
  (it may have happened at the destination) and no transmission links are recorded.
* Below zoom 14 the viewer aggregates agents into grid cells; at zoom ≥ 14 every agent is drawn and agents sharing a home overlap.
* Snapshots exist **only for V0**. V6 live runs are not available on the demo Mac.
* Recorded pages (Overview, Epidemic, Scenarios, Performance Lab) are **recorded results**; only Simulation Studio launches live runs,
  and live results are shown separately and labelled "Your live run".

## 5. Performance-evidence limits

See [`methodology.md` §7](methodology.md) for the full list. In short: Kaggle V3 rows are scalar fallbacks (x86); the OpenACC run was
built without OpenMP; the V6 1M-agent anomaly is unexplained; profile CSVs are aggregated over 100 days; V4 and V5/V6 come from different
sessions; full-NEON V3 is slower than V1 on the M1; no GPU result was produced on the development Mac; V7 (multi-scenario GPU) and V8
(MPI) are **not implemented**.

## 6. Verification limits of this documentation pass

* No fresh CUDA run was made (no NVIDIA GPU on the development machine). GPU claims are quotations of recorded Kaggle artifacts.
* The Playwright suite was run on one machine (Chromium, macOS). Safari/Firefox, screen readers and real touch devices were not tested;
  accessibility checks are structural (names, roles, states, focus outline), not a full WCAG audit.
* Chart colour-contrast and colour-vision-deficiency simulation were not tested.
