"""Population explorer data derived from the household-population bundle."""
from functools import lru_cache

import numpy as np
import pandas as pd

from .config import SYN_HH, SYN_LEGACY
from .util import clean, read_json


@lru_cache(maxsize=1)
def report() -> dict:
    return read_json(SYN_HH / "report.json")


@lru_cache(maxsize=1)
def explorer() -> dict:
    rep = report()
    agents = pd.read_parquet(SYN_HH / "agents.parquet")
    hh = pd.read_parquet(SYN_HH / "households.parquet")
    loc = pd.read_parquet(
        SYN_HH / "locations.geoparquet",
        columns=["location_id", "loc_type_name", "category", "capacity", "occupancy", "name"],
    )
    hh_sizes = hh["size"].value_counts().sort_index()
    pmf = rep["households"]["size_pmf"]
    household_hist = [
        {
            "size": int(s),
            "households": int(c),
            "observed_share": float(c / len(hh)),
            "configured_pmf": float(pmf.get(str(int(s)), 0)),
        }
        for s, c in hh_sizes.items()
    ]

    # Home occupancy histogram straight from locations.occupancy
    homes = loc[loc.loc_type_name == "HOME"]
    occ = homes["occupancy"]
    home_occ = [{"bucket": str(k), "homes": int(v)} for k, v in rep["distributions"]["home_occupancy_histogram"].items()]

    dests = loc[loc.loc_type_name == "WORK"]
    by_cat = (
        dests.groupby("category")
        .agg(destinations=("location_id", "size"), capacity=("capacity", "sum"), occupancy=("occupancy", "sum"))
        .reset_index()
    )
    by_cat["used"] = dests[dests.occupancy > 0].groupby("category").size().reindex(by_cat["category"]).fillna(0).astype(int).values
    by_cat["utilisation_pct"] = (100 * by_cat["occupancy"] / by_cat["capacity"]).round(2)

    dist = agents["distance_m"].to_numpy()
    edges = [0, 100, 250, 500, 750, 1000, 1500, 2000, 3000, 5000, 10000, np.inf]
    cnt, _ = np.histogram(dist, bins=edges)
    dist_hist = [
        {"bin": f"{int(edges[i])}–{int(edges[i+1]) if np.isfinite(edges[i+1]) else '∞'} m", "agents": int(cnt[i])}
        for i in range(len(cnt))
    ]
    dist_cat = (
        agents.groupby("dest_category")["distance_m"]
        .describe(percentiles=[0.5, 0.95])[["count", "mean", "50%", "95%", "max"]]
        .round(1)
        .reset_index()
        .rename(columns={"50%": "median", "95%": "p95", "dest_category": "category"})
    )
    stage = agents["assignment_stage"].value_counts().sort_index()
    stage_meta = {s["stage"]: s for s in rep["assignment"]["stages"]}
    stages = [
        {"stage": int(s), "agents": int(c), "radius_m": stage_meta.get(int(s), {}).get("radius_m")}
        for s, c in stage.items()
    ]
    top = dests.sort_values("occupancy", ascending=False).head(15)
    top_dest = [
        {
            "location_id": int(r.location_id),
            "name": r.name if isinstance(r.name, str) else None,
            "category": r.category,
            "occupancy": int(r.occupancy),
            "capacity": int(r.capacity),
        }
        for r in top.itertuples()
    ]
    dest_occ_hist = [{"bucket": k, "destinations": int(v)} for k, v in rep["distributions"]["destination_occupancy_histogram"].items()]
    val = report()["validation"]
    return clean(
        {
            "counts": rep["counts"],
            "households": {
                "count": rep["households"]["households"],
                "mean_size": rep["households"]["mean_household_size"],
                "pmf_mean": rep["households"]["pmf_mean"],
                "assumption": rep["households"]["assumption"],
                "buildings_with_households": rep["households"]["buildings_with_households"],
                "histogram": household_hist,
            },
            "home_occupancy": {
                "histogram": home_occ,
                "nonzero": rep["distributions"]["home_occupancy_nonzero"],
                "unused_homes": rep["distributions"]["unused_homes"],
                "total_homes": int(len(homes)),
                "occupied_homes": int((occ > 0).sum()),
            },
            "destinations": {
                "by_category": by_cat.to_dict(orient="records"),
                "occupancy_histogram": dest_occ_hist,
                "nonzero": rep["distributions"]["destination_occupancy_nonzero"],
                "unused_destinations": rep["distributions"]["unused_destinations"],
                "top": top_dest,
            },
            "assignment": {
                "distance_summary_m": rep["assignment"]["distance_m"],
                "distance_histogram": dist_hist,
                "distance_by_category": dist_cat.to_dict(orient="records"),
                "stages": stages,
                "gini": rep["assignment"]["occupancy_gini"],
                "destinations_at_capacity": rep["assignment"]["destinations_at_capacity"],
                "destinations_used": rep["assignment"]["destinations_used"],
                "top1pct_share": rep["assignment"]["top1pct_destinations_agent_share"],
                "kernel": rep["config"]["assignment"]["kernel"],
            },
            "spatial_fidelity": rep["spatial_fidelity"],
            "validation": {"passed": val["passed"], "n_checks": val["n_checks"], "failed": val["failed"]},
            "disclaimers": rep["disclaimers"],
        }
    )
