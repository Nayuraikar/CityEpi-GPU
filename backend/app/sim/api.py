"""HTTP surface for simulation execution (/api/sim/*). Independent of the read-only recorded-results endpoints."""
from __future__ import annotations

import csv
import io
import json
from functools import lru_cache

import numpy as np
from fastapi import APIRouter, Body, HTTPException, Query
from fastapi.responses import JSONResponse, Response

from . import config, registry, snapshots
from .models import validate_request
from .runs import RunError, RunManager

router = APIRouter(prefix="/api/sim", tags=["simulation"])
_manager: RunManager | None = None


def manager() -> RunManager:
    global _manager
    if _manager is None:
        _manager = RunManager()
    return _manager


def shutdown() -> None:
    if _manager is not None:
        _manager.shutdown()


def _err(e: RunError):
    return JSONResponse(status_code=e.status, content={"detail": e.message, "errors": e.errors})


@router.get("/capabilities")
def capabilities(refresh: bool = False):
    ds = registry.datasets()
    return {
        "datasets": [registry.public_dataset(d) for d in ds.values()],
        "backends": registry.backends(refresh),
        "limits": {k: list(v) for k, v in config.LIMITS.items()},
        "defaults": {"days": 100, "seed": 42, "initial_infected": 100, "beta_home": 0.3, "beta_work": 0.3,
                     "incubation_days": 3, "infectious_days": 5, "timeout_seconds": config.DEFAULT_TIMEOUT_S},
        "max_concurrent_runs": config.MAX_CONCURRENT,
        "snapshot_max_days": config.SNAPSHOT_MAX_DAYS,
        "host": registry.host_info(),
        "model_notes": [
            "Agents have one fixed home and one fixed work/destination location; there is no movement model.",
            "Transmission parameters are per-day forces of infection at the home (beta_home) and the destination (beta_work).",
            "The population is synthetic, not census data; epidemic parameters are experimental assumptions.",
        ],
    }


@router.post("/validate")
def validate(body: dict = Body(...)):
    req, errors, warnings, ds = validate_request(body)
    return {"valid": req is not None, "errors": errors, "warnings": warnings,
            "normalized": req.model_dump() if req else None}


@router.post("/runs", status_code=202)
def create_run(body: dict = Body(...)):
    try:
        return manager().submit(body)
    except RunError as e:
        return _err(e)


@router.get("/runs")
def list_runs():
    return {"runs": manager().list()}


def _wrap(fn, *a, **k):
    try:
        return fn(*a, **k)
    except RunError as e:
        raise HTTPException(e.status, e.message)


@router.get("/runs/{run_id}")
def get_run(run_id: str):
    return _wrap(lambda: manager().get(run_id).snapshot())


@router.post("/runs/{run_id}/cancel")
def cancel_run(run_id: str):
    return _wrap(manager().cancel, run_id)


@router.delete("/runs/{run_id}", status_code=204)
def delete_run(run_id: str):
    _wrap(manager().delete, run_id)
    return Response(status_code=204)


@router.get("/runs/{run_id}/series")
def run_series(run_id: str, since: int = Query(-1, ge=-1)):
    return _wrap(manager().series, run_id, since)


@router.get("/runs/{run_id}/log")
def run_log(run_id: str, stream: str = Query("stderr", pattern="^(stdout|stderr)$"), tail: int = Query(200, ge=1, le=2000)):
    run = _wrap(manager().get, run_id)
    p = run.dir / f"{stream}.log"
    lines = p.read_text(errors="replace").splitlines()[-tail:] if p.exists() else []
    return {"stream": stream, "lines": lines}


@router.get("/runs/{run_id}/export.{fmt}")
def export_run(run_id: str, fmt: str):
    if fmt not in ("csv", "json"):
        raise HTTPException(404, "format must be csv or json")
    meta = _wrap(manager().result, run_id)
    rows = manager().series(run_id)["rows"]
    if fmt == "csv":
        buf = io.StringIO()
        w = csv.writer(buf)
        w.writerow(["day", "S", "E", "I", "R", "new_infections"])
        for r in rows:
            w.writerow([r["day"], r["S"], r["E"], r["I"], r["R"], r["incidence"]])
        return Response(buf.getvalue(), media_type="text/csv",
                        headers={"Content-Disposition": f'attachment; filename="{run_id}.csv"'})
    payload = {k: meta[k] for k in ("id", "label", "created_at", "started_at", "finished_at", "request", "dataset", "backend", "host", "result", "output")}
    payload["daily"] = rows
    return Response(json.dumps(payload, indent=2), media_type="application/json",
                    headers={"Content-Disposition": f'attachment; filename="{run_id}.json"'})


# ----------------------------------------------------------------------------- per-agent snapshots (V0 only)
SNAPSHOT_NOTES = [
    "Snapshots are currently V0-only. V6 (CUDA) does not produce or support them.",
    "Agents have fixed home coordinates (their home_loc). No movement is simulated; positions are never interpolated.",
    "An agent's state is the real V0 state at the end of each day. A state change does NOT tell you where the infection happened: "
    "transmission can occur at home or at the destination location, and the files record neither the source nor the place.",
    "No transmission links are recorded; none can be derived from snapshots.",
]


def _snapshot_reader(run_id: str) -> snapshots.SnapshotReader:
    """Open a run's snapshot only if the run completed and its snapshot passed validation (recorded in meta by the run manager)."""
    run = _wrap(manager().get, run_id)
    meta = run.snapshot()
    snap = meta.get("snapshots") or {}
    if meta["state"] != "completed":
        raise HTTPException(409, f"run is {meta['state']}; snapshots exist only for completed runs")
    if not snap.get("requested"):
        raise HTTPException(404, "this run did not request snapshots (snapshots=true, V0 only)")
    if not snap.get("available"):
        raise HTTPException(404, "snapshots are not available for this run (not validated)")
    try:
        return snapshots.SnapshotReader(run.dir / "snapshots" / snapshots.FILE_NAME)
    except snapshots.SnapshotError as e:
        raise HTTPException(404, f"snapshot file unavailable: {e}")


@router.get("/runs/{run_id}/snapshots")
def run_snapshots(run_id: str):
    r = _snapshot_reader(run_id)
    try:
        info = r.info()
    finally:
        r.close()
    return {"available": True, "validated": True, "supported_backends": ["v0"], "info": info, "notes": SNAPSHOT_NOTES,
            "endpoints": {"frame": "/snapshots/frames/{day}", "home_positions": "/snapshots/home-positions"}}


@router.get("/runs/{run_id}/snapshots/frames/{day}")
def run_snapshot_frame(run_id: str, day: int):
    """Raw bytes: one uint8 per agent (0=S,1=E,2=I,3=R) in agent-id order at the end of `day`."""
    r = _snapshot_reader(run_id)
    try:
        try:
            data = r.frame(day).tobytes()
        except snapshots.SnapshotError as e:
            raise HTTPException(404, str(e))
        n = r.n_agents
    finally:
        r.close()
    return Response(data, media_type="application/octet-stream",
                    headers={"X-Agents": str(n), "X-Day": str(day), "X-State-Encoding": "S=0,E=1,I=2,R=3", "Cache-Control": "no-store"})


@lru_cache(maxsize=4)
def _location_lonlat(parquet_path: str) -> tuple[np.ndarray, np.ndarray]:
    import pyarrow.parquet as pq
    t = pq.read_table(parquet_path, columns=["location_id", "lon", "lat"])
    ids = t.column("location_id").to_numpy()
    if not np.array_equal(ids, np.arange(len(ids))):
        raise ValueError("locations parquet rows are not in location-id order")
    return t.column("lon").to_numpy().astype("<f4"), t.column("lat").to_numpy().astype("<f4")


@router.get("/runs/{run_id}/snapshots/home-positions")
def run_snapshot_home_positions(run_id: str):
    """Raw little-endian float32 pairs [lon, lat] per agent (agent-id order): the coordinates of each agent's actual home_loc."""
    r = _snapshot_reader(run_id)
    try:
        hl = r.home_loc()
        n = r.n_agents
    finally:
        r.close()
    ds = registry.datasets().get(_wrap(manager().get, run_id).meta["dataset"]["id"])
    pq_path = ds["path"].parent / "locations.geoparquet" if ds else None
    if pq_path is None or not pq_path.is_file():
        raise HTTPException(404, "dataset location coordinates are not available")
    lon, lat = _location_lonlat(str(pq_path))
    if len(lon) <= int(hl.max()):
        raise HTTPException(500, "home_loc refers to a location outside the coordinate table")
    out = np.empty((n, 2), dtype="<f4")
    out[:, 0], out[:, 1] = lon[hl], lat[hl]
    return Response(out.tobytes(), media_type="application/octet-stream",
                    headers={"X-Agents": str(n), "X-Layout": "float32 lon,lat per agent", "X-Position-Semantics": "fixed home location; not infection location"})
