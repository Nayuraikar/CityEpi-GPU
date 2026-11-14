"""Residential classification (Tier A/B/C) and footprint-based allocation weights.

Tiers mirror scripts/audit_osm_layers.py:
  A = explicit residential building value (overrides everything)
  B = building=yes, no activity tag, representative point inside a landuse=residential polygon
  C = building=yes, no activity tag, elsewhere (excluded by default)
  YES_ACTIVITY_TAGGED = building=yes carrying amenity/shop/office/... (never a home; may be a destination)
Weights are RELATIVE allocation weights, not household or occupancy counts."""
import re

import numpy as np
import pandas as pd
import shapely

from .config import config_hash  # noqa: F401  (re-exported convenience)

_NUM = re.compile(r"^\s*(\d+(?:\.\d+)?)")


def _levels(arr):
    out = np.ones(len(arr))
    for i, v in enumerate(arr):
        m = _NUM.match(v) if v else None
        if m:
            out[i] = max(1.0, float(m.group(1)))
    return out


def assign_landuse_context(B, LU, rec):
    """Map every building to AT MOST ONE residential-landuse polygon (smallest area, then lowest key order)."""
    n = len(B.df)
    idx = np.full(n, -1, dtype=np.int64)
    multi = np.zeros(n, dtype=bool)
    lu_keys = np.array([], dtype=object)
    if LU is None or len(LU.df) == 0:
        rec.note("no landuse layer rows: no building can be Tier B")
        return idx, multi, lu_keys
    m = (LU.df["tag:landuse"].to_numpy() == "residential") & np.isin(LU.df["geom_type_id"].to_numpy(), (3, 6))
    polys = LU.geoms[m]
    lu_keys = LU.df["key"].to_numpy(dtype=object)[m]
    rec.counters["landuse_residential_polygons"] = int(m.sum())
    if not m.any():
        return idx, multi, lu_keys
    tree = shapely.STRtree(polys)
    pts = shapely.points(B.df["x"].to_numpy(), B.df["y"].to_numpy())
    pi, ti = tree.query(pts, predicate="within")
    if len(pi):
        area = shapely.area(polys)[ti]
        o = np.lexsort((ti, area, pi))
        pi_s, ti_s = pi[o], ti[o]
        first = np.r_[True, pi_s[1:] != pi_s[:-1]]
        idx[pi_s[first]] = ti_s[first]
        multi = np.bincount(pi, minlength=n) > 1
    return idx, multi, lu_keys


def build_homes(B, LU, cfg, rec):
    """Return (homes DataFrame sorted by key, classification stats)."""
    rc, V = cfg["residential"], cfg["vocab"]
    df = B.df
    n = len(df)
    bv = df["tag:building"].to_numpy(dtype=object)
    explicit = np.isin(bv, V["res_explicit"])
    yes = bv == "yes"
    act = np.zeros(n, dtype=bool)
    for c in V["act_tag_cols"]:
        act |= df["tag:" + c].to_numpy(dtype=object) != ""
    lu_idx, multi, lu_keys = assign_landuse_context(B, LU, rec)
    in_res = lu_idx >= 0

    tier = np.full(n, "", dtype=object)
    tier[yes & ~act & in_res] = "B"
    tier[yes & ~act & ~in_res] = "C"
    tier[yes & act] = "YES_ACTIVITY_TAGGED"
    tier[explicit] = "A"
    stats = {"buildings_considered_inside_boundary": int(n),
             "tier_counts": {t: int((tier == t).sum()) for t in ("A", "B", "C", "YES_ACTIVITY_TAGGED")},
             "other_building_values": int((tier == "").sum()),
             "buildings_matching_multiple_residential_landuse_polygons": int(multi.sum()),
             "buildings_in_residential_landuse": int(in_res.sum()),
             "note": "tier counts are within the district boundary and after exact-key de-duplication; "
                     "they are labels, not household or occupancy counts"}
    other = pd.Series(bv[tier == ""]).value_counts().head(25)
    stats["other_building_values_top"] = {str(k): int(v) for k, v in other.items()}
    keys = df["key"].to_numpy(dtype=object)
    for t, reason in (("C", "tier_C_building_yes_outside_residential_landuse"),
                      ("YES_ACTIVITY_TAGGED", "building_yes_with_activity_tag_not_a_home"),
                      ("A", "tier_A_not_in_include_tiers"), ("B", "tier_B_not_in_include_tiers")):
        if t not in rc["include_tiers"]:
            rec.exclude("residential", "buildings", reason, keys[tier == t])
    rec.exclude("residential", "buildings", "not_residential_building_value", keys[tier == ""])

    sel = np.isin(tier, rc["include_tiers"])
    area = df["area_m2"].to_numpy()[sel]
    clipped = np.clip(area, rc["area_floor_m2"], rc["area_cap_m2"])
    stats["weight_area_floor_hits"] = int((area < rc["area_floor_m2"]).sum())
    stats["weight_area_cap_hits"] = int((area > rc["area_cap_m2"]).sum())
    factor = np.array([rc["tier_factor"].get(t, 1.0) for t in tier[sel]])
    w = factor * clipped ** rc["alpha"]
    if rc["use_levels"]:
        w = w * np.minimum(_levels(df["tag:building:levels"].to_numpy(dtype=object)[sel]), rc["levels_cap"])
    homes = pd.DataFrame({
        "osm_type": df["osm_type"].to_numpy()[sel], "osm_id": df["osm_id"].to_numpy()[sel], "key": keys[sel],
        "lon": df["lon"].to_numpy()[sel], "lat": df["lat"].to_numpy()[sel],
        "x": df["x"].to_numpy()[sel], "y": df["y"].to_numpy()[sel], "area_m2": area, "tier": tier[sel],
        "landuse_key": np.where(lu_idx[sel] >= 0, lu_keys[np.clip(lu_idx[sel], 0, max(0, len(lu_keys) - 1))] if len(lu_keys) else "", ""),
        "name_raw": df["name_raw"].to_numpy()[sel], "weight": w,
    }).reset_index(drop=True)
    homes["capacity"] = rc["max_agents_per_home"]
    stats["homes_selected"] = int(len(homes))
    stats["homes_by_tier"] = {t: int((homes["tier"] == t).sum()) for t in rc["include_tiers"]}
    if len(homes) == 0:
        raise ValueError("no residential candidates selected")
    return homes, stats
