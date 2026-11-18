"""CityEpi-GPU API. Recorded-results endpoints are read-only (files from ui_data_bundle); /api/sim/* launches the C++ simulator."""
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware

from . import benchmarks, epidemic, geo, perf, population
from .sim import api as sim_api
from .config import BUNDLE, SYN_HH, SYN_LEGACY
from .util import clean, read_json

@asynccontextmanager
async def lifespan(_app):
    yield
    sim_api.shutdown()      # terminate any still-running simulation processes


app = FastAPI(title="CityEpi-GPU Dashboard API", version="0.1.0", lifespan=lifespan)
app.add_middleware(GZipMiddleware, minimum_size=1024)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["GET", "POST", "DELETE"], allow_headers=["*"])
app.include_router(sim_api.router)          # simulation execution: /api/sim/* (separate from the read-only endpoints below)


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
    hh = population.report()["validation"]
    lg = read_json(SYN_LEGACY / "report.json")["validation"]
    runs = epidemic.runs()
    n_eq = sum(1 for r in runs.values() if r["v0_v6_equal"])
    return [
        {"item": "Synthetic population generation (geographic + household)", "state": "complete" if hh["passed"] and lg["passed"] else "partial",
         "detail": f"Independent validation: household dataset {hh['n_checks']} checks, legacy dataset {lg['n_checks']} checks (recorded in each report.json)"},
        {"item": "V0 CPU reference ↔ V6 CUDA equivalence", "state": "complete" if n_eq == len(runs) else "partial",
         "detail": f"Daily-checksum equal on {n_eq}/{len(runs)} recorded scenarios"},
        {"item": "V5 / V6 CUDA benchmarks", "state": "complete",
         "detail": f"Recorded on Kaggle Tesla T4, commit {(b['git_commit'] or '')[:7]}"},
        {"item": "Multi-seed validation", "state": "complete",
         "detail": f"{epidemic.seeds()['n_seeds']} seeds × 3 transmission scenarios, V0 CPU reference only (no V6 runs in these artifacts); household population only"},
        {"item": "Transmission parameters (β)", "state": "gap",
         "detail": "Numeric β values are not recorded with these results; scenarios are labelled low/baseline/high only"},
        {"item": "Simulation Studio (live runs)", "state": "complete",
         "detail": "Launches the C++ extpop_run on this host (V0 CPU; V6 only where a CUDA build is available). Live runs are separate from recorded results"},
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


@app.get("/api/perf")
def perf_lab():
    """CPU (Apple M1) + OpenACC (Kaggle) benchmark artifacts and correctness evidence for the PAGP Performance Lab."""
    return perf.perf()


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
