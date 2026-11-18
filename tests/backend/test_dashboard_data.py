"""Phase 4: the read-only dashboard endpoints must agree with the recorded source files exactly."""
import json
import math
from pathlib import Path

import pandas as pd
import pytest
from fastapi.testclient import TestClient

from app.config import BUNDLE, RESULTS, SYN_HH, SYN_LEGACY
from app.main import app

client = TestClient(app)
POP = RESULTS / "epidemic_population_comparison"
SENS = RESULTS / "epidemic_transmission_sensitivity"
SEEDS = RESULTS / "final_10seed_validation"
RUNS = {"legacy": POP, "household": POP, "low": SENS, "baseline": SENS, "high": SENS}


@pytest.fixture(scope="module")
def runs():
    r = client.get("/api/epidemic")
    assert r.status_code == 200
    return r.json()


@pytest.mark.parametrize("key", list(RUNS))
def test_curves_match_recorded_v6_csv(runs, key):
    src = pd.read_csv(RUNS[key] / f"{key}_v6.csv")
    cur = pd.DataFrame(runs[key]["curve"])
    assert len(cur) == len(src) == 101
    for c in "SEIR":
        assert cur[c].tolist() == src[c].tolist()
    n = runs[key]["agents"]
    assert (cur[list("SEIR")].sum(axis=1) == n).all(), "compartments must conserve population"
    s = runs[key]["summary"]
    assert s["peak_infectious"] == int(src["I"].max())
    assert s["attack_rate_pct"] == pytest.approx(100 * (1 - src["S"].iloc[-1] / n), abs=1e-3)
    inc = (src["S"].shift(1) - src["S"]).fillna(0).clip(lower=0)
    assert s["peak_daily_incidence"] == int(inc.max())


@pytest.mark.parametrize("key", list(RUNS))
def test_run_metadata_and_provenance(runs, key):
    meta = json.loads((RUNS[key] / f"{key}.json").read_text())
    r = runs[key]
    assert r["payload_crc32"] == meta["payload_crc32"]
    assert r["daily_checksum"] == meta["v0"]["daily_checksum"] == meta["v6"]["daily_checksum"]
    assert r["dataset_id"] == Path(meta["input"]).parent.name


def test_legacy_and_household_are_different_inputs(runs):
    assert runs["legacy"]["dataset_id"] != runs["household"]["dataset_id"]
    assert runs["legacy"]["payload_crc32"] != runs["household"]["payload_crc32"]
    # baseline transmission is the household run (same input, same checksum)
    assert runs["baseline"]["daily_checksum"] == runs["household"]["daily_checksum"]
    assert runs["baseline"]["dataset_id"] == runs["household"]["dataset_id"]


def test_seed_statistics_match_recorded_csvs():
    d = client.get("/api/epidemic/seeds").json()
    per = pd.read_csv(SEEDS / "all_seed_results.csv")
    summ = pd.read_csv(SEEDS / "summary_statistics.csv").set_index("scenario")
    assert d["n_seeds"] == 10 and d["seed_range"] == [42, 51]
    assert len(d["per_seed"]) == 30
    assert "V0" in d["backend"] and sum(d["v6_runs_present"].values()) == 0
    assert len(d["population_inputs"]) == 1 and d["population_inputs"][0] == SYN_HH.name
    for sc, g in per.groupby("scenario"):
        row = summ.loc[sc]
        assert g.attack_rate_pct.mean() == pytest.approx(row.attack_mean, abs=1e-3)
        assert g.attack_rate_pct.std(ddof=1) == pytest.approx(row.attack_sd, abs=1e-3)   # sample SD
        assert g.attack_rate_pct.min() == pytest.approx(row.attack_min, abs=1e-3)
        assert g.attack_rate_pct.max() == pytest.approx(row.attack_max, abs=1e-3)
        assert g.peak_infectious.std(ddof=1) == pytest.approx(row.peak_sd, abs=1e-2)
        assert g.peak_daily_incidence.mean() == pytest.approx(row.incidence_mean, abs=1e-1)
        assert d["peak_range"][sc] == {"peak_min": int(g.peak_infectious.min()), "peak_max": int(g.peak_infectious.max())}
    assert {s["scenario"] for s in d["summary"]} == {"low", "baseline", "high"}


def test_population_datasets_match_reports():
    d = client.get("/api/population").json()
    by = {x["kind"]: x for x in d["datasets"]}
    for kind, path in (("household", SYN_HH), ("legacy", SYN_LEGACY)):
        rep = json.loads((path / "report.json").read_text())
        x = by[kind]
        assert x["dataset_id"] == path.name
        assert x["agents"] == rep["counts"]["agents"] and x["candidate_homes"] == rep["counts"]["homes"]
        assert x["validation"] == {"passed": rep["validation"]["passed"], "n_checks": rep["validation"]["n_checks"]}
        assert x["cepop_crc32"] == rep["outputs"]["cepop_payload_crc32"]
        assert sum(h["agents"] for h in x["distance_histogram"]) == x["agents"]
    rep = json.loads((SYN_HH / "report.json").read_text())
    assert by["household"]["households"] == rep["households"]["households"]
    assert by["legacy"]["households"] is None
    # household-size histogram sums to household count; occupancy histogram to candidate homes
    assert sum(h["households"] for h in d["households"]["histogram"]) == d["households"]["count"]
    assert sum(h["homes"] for h in d["home_occupancy"]["histogram"]) == d["home_occupancy"]["total_homes"]
    assert d["home_occupancy"]["occupied_homes"] == d["households"]["buildings_with_households"]
    assert sum(c["occupancy"] for c in d["destinations"]["by_category"]) == by["household"]["agents"]
    assert sum(h["agents"] for h in d["assignment"]["distance_histogram"]) == by["household"]["agents"]


def test_overview_status_is_data_driven():
    d = client.get("/api/overview").json()
    text = json.dumps(d["status"])
    assert "not yet built" not in text, "Simulation Studio exists since Phase 3"
    assert "44/44" not in text
    hh = json.loads((SYN_HH / "report.json").read_text())["validation"]["n_checks"]
    assert f"household dataset {hh} checks" in text
    assert d["n_seeds"] == 10
    assert all(not (isinstance(v, float) and math.isnan(v)) for v in d["population"].values() if isinstance(v, float))


def test_geo_endpoints_and_errors():
    cat = client.get("/api/geo/catalog").json()
    for k in ("buildings", "roads", "healthcare", "amenities", "leisure", "landuse", "destinations", "homes", "homes_occupied"):
        assert cat["counts"][k] > 0, k
    assert cat["counts"]["homes_occupied"] == client.get("/api/population").json()["home_occupancy"]["occupied_homes"]
    assert client.get("/api/geo/points/nope").status_code == 404
    assert client.get("/api/geo/features/nope?bbox=0,0,1,1").status_code == 404
    assert client.get("/api/geo/features/roads?bbox=bad").status_code == 400
    # empty viewport (middle of the ocean) → empty, not an error
    f = client.get("/api/geo/features/buildings?bbox=0,0,0.01,0.01&zoom=16").json()
    assert f["features"] == [] and f["total_in_view"] == 0
    pts = client.get("/api/geo/points/homes_occupied").json()
    assert pts["count"] == cat["counts"]["homes_occupied"]
