"""CityEpi-GPU dashboard API. Read-only: serves files from ui_data_bundle, runs no simulation."""
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware

from . import benchmarks, epidemic, geo, population
from .config import BUNDLE, SYN_HH, SYN_LEGACY
from .util import clean, read_json

app = FastAPI(title="CityEpi-GPU Dashboard API", version="0.1.0")
app.add_middleware(GZipMiddleware, minimum_size=1024)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["GET"], allow_headers=["*"])


@app.get("/api/health")
def health():
    return {"status": "ok", "bundle": str(BUNDLE), "bundle_exists": BUNDLE.exists()}


@app.get("/api/overview")
def overview():
    rep = population.report()
    runs = epidemic.runs()
    seeds = epidemic.seeds()
    rec = read_json(SYN_HH / "kaggle_run_record.json")
    cfg = rep["config"]
    legacy = read_json(SYN_LEGACY / "report.json")
    return clean({
        "population": {
            "agents": rep["counts"]["agents"], "locations": rep["counts"]["locations"],
            "homes": rep["counts"]["homes"], "destinations": rep["counts"]["destinations"],
            "households": rep["households"]["households"],
            "mean_household_size": rep["households"]["mean_household_size"],
            "mean_commute_m": rep["assignment"]["distance_m"]["mean"],
            "validation": {"passed": rep["validation"]["passed"], "n_checks": rep["validation"]["n_checks"]},
            "legacy_validation": {"passed": legacy["validation"]["passed"], "n_checks": legacy["validation"]["n_checks"]},
            "disclaimers": rep["disclaimers"],
            "tool_version": rep["tool_version"],
            "cepop_crc32": rep["outputs"]["cepop_payload_crc32"],
        },
        "configuration": {
            "seed": rep["config"]["seed"], "n_agents": cfg["n_agents"],
            "sim_days": runs["household"]["days"], "sim_seed": runs["household"]["seed"],
            "initial_infected": runs["household"]["initial_infected"],
            "household_size_pmf": cfg["residential"]["households"]["size_pmf"],
            "max_households_per_building": cfg["residential"]["households"]["max_households_per_building"],
            "residential_tiers": cfg["residential"]["include_tiers"],
            "destination_categories": cfg["destinations"]["include_categories"],
            "assignment_kernel": cfg["assignment"]["kernel"],
            "candidate_k": cfg["assignment"]["candidate_k"],
            "radius_m": cfg["assignment"]["radius_m"],
            "capacity_slack": cfg["destinations"]["capacity_slack"],
            "config_sha256": rep["config_sha256"],
        },
        "epidemic": {k: {"label": r["label"], **r["summary"], "v0_v6_equal": r["v0_v6_equal"]} for k, r in runs.items()},
        "ten_seed": seeds["summary"],
        "n_seeds": seeds["n_seeds"],
        "run_environment": {"gpu": runs["household"]["v6_device"], "verdict": rec.get("verdict"),
                            "generated_utc": rec.get("started_utc")},
        "status": project_status(),
    })


def project_status():
    b = benchmarks.benchmarks()
    return [
        {"item": "Synthetic population generation (geographic + household)", "state": "complete",
         "detail": "44/44 independent validation checks passed"},
        {"item": "V0 CPU reference ↔ V6 CUDA equivalence", "state": "complete",
         "detail": "Daily-checksum equal on all 5 recorded scenarios"},
        {"item": "V5 / V6 CUDA benchmarks", "state": "complete",
         "detail": f"Tesla T4, commit {(b['git_commit'] or '')[:7]}"},
        {"item": "Multi-seed validation", "state": "complete",
         "detail": f"{epidemic.seeds()['n_seeds']} seeds × 3 scenarios recorded with V0 CPU reference only (no V6 runs in these artifacts)"},
        {"item": "Transmission parameters (β)", "state": "gap",
         "detail": "Numeric β values are not recorded in the bundle; scenarios are labelled low/baseline/high only"},
        {"item": "Dashboard-triggered simulation", "state": "not-implemented",
         "detail": "Intentionally absent: dashboard visualises recorded results only"},
    ]


@app.get("/api/epidemic")
def epidemic_runs():
    return epidemic.runs()


@app.get("/api/epidemic/seeds")
def epidemic_seeds():
    return epidemic.seeds()


@app.get("/api/population")
def population_explorer():
    return population.explorer()


@app.get("/api/benchmarks")
def bench():
    return benchmarks.benchmarks()


# ---------------- GIS ----------------
@app.get("/api/geo/catalog")
def geo_catalog():
    return geo.layer_catalog()


@app.get("/api/geo/boundary")
def geo_boundary():
    return geo.boundary()


def _bbox(s: str):
    try:
        w, so, e, n = (float(x) for x in s.split(","))
    except Exception:
        raise HTTPException(400, "bbox must be west,south,east,north")
    return w, so, e, n


@app.get("/api/geo/features/{name}")
def geo_features(name: str, bbox: str, zoom: int = 14, limit: int = Query(6000, le=15000)):
    if name not in ("buildings", "roads", "landuse", "leisure"):
        raise HTTPException(404, "unknown vector layer")
    return geo.features(name, _bbox(bbox), zoom, limit)


@app.get("/api/geo/density/{name}")
def geo_density(name: str, cell: float = Query(0.004, ge=0.0005, le=0.05)):
    if name not in ("buildings", "roads", "homes", "homes_occupied", "destinations", "amenities", "healthcare"):
        raise HTTPException(404, "unknown layer")
    return geo.density(name, round(cell, 5))


@app.get("/api/geo/points/{name}")
def geo_points(name: str):
    try:
        return geo.points(name)
    except KeyError:
        raise HTTPException(404, "unknown point layer")
