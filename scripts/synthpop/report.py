"""Report assembly (report.json / report.md). All content is descriptive of the SYNTHETIC output."""
import json

import numpy as np
import pandas as pd

from .util import pct

DISCLAIMER = [
    "This population is SYNTHETIC. It is not census data and does not represent the actual population, households, "
    "employment, demographics or commuting patterns of Bengaluru.",
    "Residential weights are footprint-based relative allocation weights, not household or occupancy counts.",
    "Destination categories and capacities are placeholders derived from OSM tags/footprints; the simulator treats every "
    "destination as one WORK location type.",
    "All weighting, capacity and distance parameters are experimental and configurable (see config.json in this directory).",
]
BINS = [(0, 0), (1, 1), (2, 2), (3, 3), (4, 4), (5, 5), (6, 10), (11, 20), (21, 50), (51, 10**12)]


def histogram(v):
    v = np.asarray(v)
    return {(f"{a}" if a == b else (f"{a}+" if b >= 10**12 else f"{a}-{b}")): int(((v >= a) & (v <= b)).sum()) for a, b in BINS}


def spatial_fidelity(homes, home_counts, cell_m=2000.0):
    """How well agent homes follow the residential weight distribution at ~2 km cells (EPSG:32643)."""
    cx = np.floor(homes["x"].to_numpy() / cell_m).astype(np.int64)
    cy = np.floor(homes["y"].to_numpy() / cell_m).astype(np.int64)
    df = pd.DataFrame({"c": cx * 1_000_003 + cy, "w": homes["weight"].to_numpy(), "a": home_counts})
    g = df.groupby("c").sum()
    ws, as_ = g["w"] / g["w"].sum(), g["a"] / g["a"].sum()
    r = float(np.corrcoef(ws, as_)[0, 1]) if len(g) > 2 and ws.std() > 0 and as_.std() > 0 else None
    return {"cell_m": cell_m, "n_cells": int(len(g)), "pearson_r_weight_share_vs_agent_share": r,
            "total_variation_distance": float(0.5 * np.abs(ws - as_).sum()),
            "top5pct_cells_weight_share": float(ws.sort_values(ascending=False).head(max(1, len(g) // 20)).sum()),
            "top5pct_cells_agent_share": float(as_.sort_values(ascending=False).head(max(1, len(g) // 20)).sum())}


def distributions(locations, agents, home_counts, dest_occ, dests):
    homes_mask = locations["loc_type"].to_numpy() == 0
    out = {"home_occupancy_histogram": histogram(home_counts), "home_occupancy_nonzero": pct(home_counts[home_counts > 0]),
           "destination_occupancy_histogram": histogram(dest_occ), "destination_occupancy_nonzero": pct(dest_occ[dest_occ > 0]),
           "unused_homes": int((home_counts == 0).sum()), "unused_destinations": int((dest_occ == 0).sum()),
           "agents_by_destination_category": {k: int(v) for k, v in agents["dest_category"].value_counts().sort_index().items()},
           "destinations_by_category": {k: int(v) for k, v in dests["category"].value_counts().sort_index().items()},
           "assignment_distance_m": pct(agents["distance_m"]),
           "assignment_distance_m_by_category": {c: pct(g["distance_m"]) for c, g in agents.groupby("dest_category")},
           "assignment_stage_counts": {int(k): int(v) for k, v in agents["assignment_stage"].value_counts().sort_index().items()}}
    out["homes_by_tier_agents"] = {t: int(home_counts[(locations["tier"].to_numpy()[homes_mask] == t)].sum())
                                   for t in sorted(set(locations["tier"].to_numpy()[homes_mask]))}
    return out


def to_markdown(rep):
    L = []
    a = L.append
    a(f"# Synthetic population report — {rep['status'].upper()}\n")
    for d in rep["disclaimers"]:
        a(f"> {d}\n")
    a(f"- agents: **{rep['config']['n_agents']}**, seed **{rep['config']['seed']}**, config sha256 `{rep['config_sha256'][:16]}…`")
    if "counts" in rep:
        c = rep["counts"]
        a(f"- locations: **{c['locations']}** ({c['homes']} HOME, {c['destinations']} WORK); CEPOP payload CRC `{rep['outputs'].get('cepop_payload_crc32', '')}`")
    v = rep.get("validation")
    if v:
        a(f"- validation: **{'PASS' if v['passed'] else 'FAIL'}** ({v['n_checks']} checks, {len(v['failed'])} failed)")
    if rep.get("failure"):
        a(f"\n## Failure\n\n```\n{json.dumps(rep['failure'], indent=2)}\n```")
    cl = rep.get("classification")
    if cl:
        a("\n## Residential classification")
        a(f"Tier counts (inside boundary, exact-key de-duplicated): `{json.dumps(cl['tier_counts'])}`; other building values: {cl['other_building_values']}")
        a(f"Buildings matching several residential landuse polygons (assigned to one): {cl['buildings_matching_multiple_residential_landuse_polygons']}")
        a(f"Selected homes: {cl['homes_selected']} `{json.dumps(cl['homes_by_tier'])}`; weight floor hits {cl['weight_area_floor_hits']}, cap hits {cl['weight_area_cap_hits']}")
        ref = rep.get("audit_reference_comparison")
        if ref:
            a(f"Audit reference vs this run: `{json.dumps(ref)}`")
    a("\n## Exclusions (stage | layer | reason: count)")
    for e in rep["exclusions"]:
        a(f"- {e['stage']} | {e['layer']} | {e['reason']}: **{e['count']}** (e.g. {', '.join(e['examples'][:3])})")
    dd = rep.get("dedup")
    if dd:
        a("\n## Destination de-duplication")
        a("```\n" + json.dumps(dd, indent=1) + "\n```")
    for title, key in (("Destination candidates", "destinations"), ("Capacity", "capacity"), ("Spatial fidelity of homes", "spatial_fidelity"),
                       ("Distributions", "distributions"), ("Assignment", "assignment"), ("Cap sensitivity", "cap_sensitivity")):
        if key in rep:
            a(f"\n## {title}\n```\n{json.dumps(rep[key], indent=1)}\n```")
    if rep.get("notes"):
        a("\n## Notes\n" + "\n".join(f"- {n}" for n in rep["notes"]))
    a("\n## Checksums")
    for k, v2 in rep.get("checksums", {}).items():
        a(f"- `{k}`: `{v2}`")
    a("\n## Inputs")
    for k, v2 in rep.get("inputs", {}).items():
        a(f"- `{k}`: {json.dumps(v2)}")
    return "\n".join(L) + "\n"
