"""Pipeline orchestration: load -> classify -> dedup -> apportion -> assign -> export -> validate -> report."""
import datetime
import json
import os
import platform
import sys
import time
import traceback

import numpy as np
import pandas as pd

from . import assign as A
from . import destinations as Dm
from . import export as E
from . import residential as R
from . import validate as V
from .config import DEST_LAYERS, LAYERS, canonical_json, config_hash
from .load import load_boundary, read_layer
from .report import DISCLAIMER, distributions, spatial_fidelity, to_markdown
from .util import Recorder, sha256_file

TOOL_VERSION = "synthpop-1"
OUTPUT_FILES = ["population.cepop", "locations.geoparquet", "agents.parquet", "dedup_decisions.parquet"]


def check_out_dir(out_dir, geo_dir, allow_outside=False, overwrite=False):
    out = os.path.abspath(out_dir)
    geo = os.path.abspath(geo_dir)
    if out == geo or out.startswith(geo + os.sep) or geo.startswith(out + os.sep):
        raise ValueError("output directory must not be (inside/above) the source geo directory")
    parts = out.split(os.sep)
    ok = any(parts[i] == "data" and parts[i + 1] == "synthetic" for i in range(len(parts) - 1))
    if not ok and not allow_outside:
        raise ValueError(f"output directory {out} must be under data/synthetic/ (use allow_outside only for scratch/Kaggle paths)")
    if os.path.isdir(out) and os.listdir(out) and not overwrite:
        raise ValueError(f"output directory {out} is not empty (use overwrite)")
    return out


class _Timer:
    def __init__(self, rec, name):
        self.rec, self.name = rec, name

    def __enter__(self):
        self.t = time.perf_counter()

    def __exit__(self, *a):
        self.rec.timings[self.name] = round(time.perf_counter() - self.t, 3)


def _write_json(path, obj):
    with open(path, "w") as f:
        json.dump(obj, f, indent=2, sort_keys=False, default=_json_default)
        f.write("\n")


def _json_default(o):
    if isinstance(o, (np.integer,)):
        return int(o)
    if isinstance(o, (np.floating,)):
        return float(o)
    if isinstance(o, np.ndarray):
        return o.tolist()
    raise TypeError(type(o))


def run(cfg, geo_dir, boundary_path, out_dir, allow_outside=False, overwrite=False):
    out_dir = check_out_dir(out_dir, geo_dir, allow_outside, overwrite)
    os.makedirs(out_dir, exist_ok=True)
    rec = Recorder()
    decisions = []
    n_agents, seed = cfg["n_agents"], cfg["seed"]
    rep = {"status": "running", "tool_version": TOOL_VERSION, "disclaimers": DISCLAIMER, "config": cfg,
           "config_sha256": config_hash(cfg)}
    _write_json(os.path.join(out_dir, "config.json"), cfg)
    try:
        with _Timer(rec, "load"):
            boundary = load_boundary(boundary_path)
            paths = {n: os.path.join(geo_dir, f"{n}.parquet") for n in LAYERS}
            layers, inputs = {}, {"boundary": {"file": os.path.basename(boundary_path), "sha256": sha256_file(boundary_path)}}
            for n in LAYERS:
                if not os.path.isfile(paths[n]):
                    raise FileNotFoundError(paths[n])
                layers[n] = read_layer(n, paths[n], boundary, rec, decisions, filter_boundary=(n != "landuse"))
                inputs[n] = dict(layers[n].stats, sha256=sha256_file(paths[n]))
            rep["inputs"] = inputs
        with _Timer(rec, "residential"):
            homes, cl = R.build_homes(layers["buildings"], layers["landuse"], cfg, rec)
            rep["classification"] = cl
            ref = cfg.get("audit_reference") or {}
            rep["audit_reference_comparison"] = {f"tier_{t}": {"audit": ref.get(f"tier_{t}"), "this_run": cl["tier_counts"][t]}
                                                 for t in ("A", "B", "C") if f"tier_{t}" in ref}
        with _Timer(rec, "destinations"):
            C, dstat = Dm.collect_candidates(layers, cfg, rec)
            M, dd = Dm.dedup(C, cfg, decisions, rec)
            dstat["inside_building"] = Dm.add_inside_building(M, layers["buildings"], rec)
            dstat["capacity_weights"] = Dm.add_capacity_weights(M, cfg)
            dstat["destinations_final"] = int(len(M))
            dstat["by_category"] = {c: int((M["category"] == c).sum()) for c in sorted(set(M["category"]))}
            rep["destinations"], rep["dedup"] = dstat, dd
            if len(M) == 0:
                raise ValueError("no destinations")
        homes = homes.sort_values(["osm_type", "osm_id"], kind="mergesort").reset_index(drop=True)
        M = M.sort_values(["osm_type", "osm_id"], kind="mergesort").reset_index(drop=True)
        with _Timer(rec, "assignment"):
            home_counts, hinfo = A.apportion_homes(homes["weight"].to_numpy(), homes["capacity"].to_numpy(), n_agents, seed)
            home_of_agent = A.agent_homes(home_counts, seed)
            dcap, cinfo = A.destination_caps(M["weight"].to_numpy(), n_agents, cfg["destinations"])
            M["capacity"] = dcap
            rep["capacity"] = {"homes": dict(hinfo, max_agents_per_home=cfg["residential"]["max_agents_per_home"]),
                               "destinations": cinfo}
            H = len(homes)
            hxy = homes[["x", "y"]].to_numpy()
            dxy = M[["x", "y"]].to_numpy()
            agent_xy = hxy[home_of_agent]
            res = A.assign_destinations(agent_xy, dxy, M["weight"].to_numpy(), dcap, cfg["assignment"], seed)
            rep["assignment"] = A.assignment_summary(res, dcap, M["weight"].to_numpy())
            if res["n_unassigned"] and cfg["assignment"]["fail_on_unassigned"]:
                raise A.AssignmentError(f"{res['n_unassigned']} agents could not be assigned a destination",
                                        {"n_unassigned": res["n_unassigned"], "stages": res["stages"]})
        sens = None
        if cfg["sensitivity"]["enabled"]:
            with _Timer(rec, "cap_sensitivity"):
                sens = []
                for slack in cfg["sensitivity"]["capacity_slack"]:
                    cp, ci = A.destination_caps(M["weight"].to_numpy(), n_agents, cfg["destinations"], slack=slack)
                    if cp.sum() < n_agents:
                        sens.append({"slack": slack, "capacity": ci, "infeasible": True})
                        continue
                    r2 = A.assign_destinations(agent_xy, dxy, M["weight"].to_numpy(), cp, cfg["assignment"], seed)
                    sens.append({"slack": slack, "capacity": ci, "result": A.assignment_summary(r2, cp, M["weight"].to_numpy())})
                rep["cap_sensitivity"] = sens
        rep["spatial_fidelity"] = spatial_fidelity(homes, home_counts)

        dest_of_agent = (H + res["dest"]).astype(np.int64)
        dest_occ = np.bincount(res["dest"], minlength=len(M))
        loc = E.build_locations(homes, M, home_counts, dest_occ)
        with _Timer(rec, "export"):
            outs = E.write_all(out_dir, loc, home_of_agent, dest_of_agent, res["distance_m"], res["stage"],
                               M["category"].to_numpy(dtype=object)[res["dest"]], decisions)
        rep["outputs"] = outs
        rep["counts"] = {"agents": int(n_agents), "homes": int(H), "destinations": int(len(M)), "locations": int(H + len(M))}
        ag = pd.read_parquet(os.path.join(out_dir, "agents.parquet"))
        rep["distributions"] = distributions(loc, ag, home_counts, dest_occ, M)
        with _Timer(rec, "validate"):
            checks = V.validate_outputs(out_dir, boundary_path, cfg)
        rep["validation"] = V.summarize(checks)
        rep["status"] = "ok" if rep["validation"]["passed"] else "validation_failed"
    except Exception as e:  # record the failure in the report, then re-raise
        rep["status"] = "failed"
        rep["failure"] = {"type": type(e).__name__, "message": str(e), "details": getattr(e, "details", None),
                          "traceback": traceback.format_exc()}
        _finish(rep, rec, out_dir, cfg)
        raise
    _finish(rep, rec, out_dir, cfg)
    return rep


def _finish(rep, rec, out_dir, cfg):
    rep["exclusions"] = rec.exclusion_list()
    rep["notes"] = rec.notes
    rep["counters"] = rec.counters
    rep["timings_s"] = rec.timings
    rep["checksums"] = {f: sha256_file(os.path.join(out_dir, f)) for f in OUTPUT_FILES if os.path.isfile(os.path.join(out_dir, f))}
    rep["deterministic_artifacts"] = OUTPUT_FILES + ["config.json"]
    _write_json(os.path.join(out_dir, "report.json"), rep)
    with open(os.path.join(out_dir, "report.md"), "w") as f:
        f.write(to_markdown(rep))
    import geopandas, pyarrow, scipy, shapely
    man = {"tool_version": TOOL_VERSION, "created_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
           "status": rep["status"], "seed": cfg["seed"], "n_agents": cfg["n_agents"], "config_sha256": rep["config_sha256"],
           "note": "created_utc and timings vary between runs; the deterministic artifacts are listed in report.json",
           "versions": {"python": sys.version.split()[0], "platform": platform.platform(), "numpy": np.__version__,
                        "pandas": pd.__version__, "geopandas": geopandas.__version__, "shapely": shapely.__version__,
                        "pyarrow": pyarrow.__version__, "scipy": scipy.__version__},
           "inputs": {k: {"sha256": v.get("sha256"), "n_raw": v.get("n_raw")} for k, v in rep.get("inputs", {}).items()},
           "files": {f: {"sha256": sha256_file(os.path.join(out_dir, f)), "bytes": os.path.getsize(os.path.join(out_dir, f))}
                     for f in sorted(os.listdir(out_dir)) if os.path.isfile(os.path.join(out_dir, f)) and f != "manifest.json"}}
    _write_json(os.path.join(out_dir, "manifest.json"), man)
