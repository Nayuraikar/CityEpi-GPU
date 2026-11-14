#!/usr/bin/env python3
"""Read-only audit of the processed OSM GeoParquet layers for Bengaluru Urban.

Purpose: measure what the data actually contains BEFORE designing the synthetic population generator.
It does not generate a population, and it never writes into the input directories.

Inputs (read-only):
  <geo-dir>/{buildings,landuse,roads,amenities,healthcare,leisure}.parquet
  <boundary>  (GeoJSON district boundary)

Outputs (written only to --out-dir):
  audit_report.json   full machine-readable report (inputs checksums, config, all measurements)
  audit_grid.csv      per-grid-cell counts (cell index, lon/lat centre, residential/activity candidates)
  audit_summary.txt   the same concise summary that is printed to the terminal

All area/distance work is done in EPSG:32643 (UTM 43N). Classification here is an AUDIT heuristic:
tiers are labels for measuring ambiguity, not a statement about real households or occupancy.

Usage (Kaggle):
  python scripts/audit_osm_layers.py --out-dir /kaggle/working/audit_osm
"""
import argparse
import datetime
import hashlib
import json
import math
import os
import platform
import sys
import traceback

import numpy as np
import pandas as pd

try:
    import geopandas as gpd
    import shapely
    from shapely import STRtree
except ImportError as exc:  # pragma: no cover
    sys.exit(f"geopandas/shapely (>=2.0) are required: {exc}")

try:
    from scipy.spatial import cKDTree
except ImportError:  # optional: duplicate-pair and nearest-distance steps are skipped without scipy
    cKDTree = None

METRIC_CRS = "EPSG:32643"
LAYER_NAMES = ["buildings", "landuse", "roads", "amenities", "healthcare", "leisure"]
PCTS = [0, 1, 5, 25, 50, 75, 95, 99, 99.9, 100]
ERRORS = []

# ---- tag vocabularies (audit heuristics; edit here, they are recorded in the report) ------------------
RES_EXPLICIT = {"residential", "apartments", "house", "detached", "semidetached_house", "terrace",
                "dormitory", "bungalow", "houses", "duplex", "villa"}
EDU_AMENITY = {"school", "college", "university", "kindergarten", "language_school", "music_school",
               "driving_school", "training", "research_institute", "childcare"}
EDU_BUILDING = {"school", "college", "university", "kindergarten"}
HEALTH_AMENITY = {"hospital", "clinic", "doctors", "dentist", "pharmacy", "nursing_home", "veterinary"}
HEALTH_BUILDING = {"hospital", "clinic"}
IND_BUILDING = {"industrial", "warehouse", "factory", "manufacture", "storage_tank"}
OFFICE_BUILDING = {"office"}
OFFICE_AMENITY = {"coworking_space"}
COM_BUILDING = {"commercial", "retail", "supermarket", "kiosk", "mall", "shop"}
RETAIL_AMENITY = {"marketplace", "bank", "atm", "restaurant", "cafe", "fast_food", "food_court", "bar", "pub",
                  "cinema", "theatre", "fuel", "car_wash", "car_rental", "bureau_de_change"}
CIVIC_AMENITY = {"townhall", "courthouse", "police", "fire_station", "community_centre", "library",
                 "post_office", "bus_station", "public_building", "government"}
CIVIC_BUILDING = {"civic", "public", "government", "train_station", "transportation"}
WORSHIP_BUILDING = {"religious", "temple", "church", "mosque", "chapel", "shrine", "synagogue"}
ACT_LANDUSE = {"education", "industrial", "commercial", "retail"}
# priority: first match wins when a feature carries several activity tags
ACT_ORDER = ["education", "healthcare", "industrial", "office", "commercial_retail", "civic_public",
             "worship", "leisure", "other_amenity"]

TAG_COLS = ["building", "building:use", "landuse", "amenity", "shop", "office", "healthcare", "leisure",
            "highway", "man_made", "tourism", "craft", "industrial", "public_transport", "railway", "residential"]
COMPLETENESS_COLS = ["name", "building:levels", "height", "addr:housenumber", "addr:street", "addr:city",
                     "operator", "capacity", "building:flats", "start_date"]
ID_COLS = ["osmid", "osm_id", "id", "element_id", "@id"]
TYPE_COLS = ["element_type", "element", "osm_type"]


# ---- small helpers -----------------------------------------------------------------------------------
def note_error(where, exc):
    ERRORS.append({"step": where, "error": f"{type(exc).__name__}: {exc}",
                   "trace_tail": traceback.format_exc().strip().splitlines()[-3:]})


def safe(report, key, fn, *a, **k):
    try:
        report[key] = fn(*a, **k)
    except Exception as exc:  # one failed step must not kill the whole audit
        note_error(key, exc)
        report[key] = {"error": f"{type(exc).__name__}: {exc}"}
    return report[key]


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 22), b""):
            h.update(chunk)
    return h.hexdigest()


def _n(v):
    if isinstance(v, str):
        return v.strip().lower()
    if v is None:
        return ""
    try:
        if pd.isna(v):
            return ""
    except (TypeError, ValueError):
        pass
    return str(v).strip().lower()


def isin(arr, values):
    return pd.Series(arr).isin(list(values)).to_numpy()


def pct(a):
    a = np.asarray(a, dtype=float)
    a = a[np.isfinite(a)]
    if a.size == 0:
        return {"n": 0}
    q = np.percentile(a, PCTS)
    d = {"n": int(a.size), "mean": float(a.mean())}
    d.update({f"p{p:g}": float(v) for p, v in zip(PCTS, q)})
    return d


def gini(v):
    v = np.sort(np.asarray(v, dtype=float))
    if v.size == 0 or v.sum() == 0:
        return None
    n = v.size
    return float((2 * np.arange(1, n + 1) - n - 1).dot(v) / (n * v.sum()))


def clean(o):
    """Make the report strict JSON (no NaN/inf, numpy scalars converted)."""
    if isinstance(o, dict):
        return {str(k): clean(v) for k, v in o.items()}
    if isinstance(o, (list, tuple)):
        return [clean(v) for v in o]
    if isinstance(o, (np.integer,)):
        return int(o)
    if isinstance(o, (np.floating, float)):
        return None if (math.isnan(o) or math.isinf(o)) else float(o)
    if isinstance(o, np.bool_):
        return bool(o)
    if isinstance(o, np.ndarray):
        return clean(o.tolist())
    if isinstance(o, set):
        return sorted(o)
    return o


def top_counts(values, k):
    s = pd.Series(values)
    s = s[s != ""]
    vc = s.value_counts()
    items = sorted(vc.items(), key=lambda kv: (-kv[1], str(kv[0])))[:k]
    return [{"value": str(a), "count": int(b)} for a, b in items]


# ---- layer wrapper -----------------------------------------------------------------------------------
class Layer:
    def __init__(self, name, path, boundary):
        self.name = name
        gdf = gpd.read_parquet(path)  # read-only
        if isinstance(gdf.index, pd.MultiIndex) or gdf.index.name is not None:
            try:
                gdf = gdf.reset_index()
            except ValueError:
                gdf = gdf.reset_index(drop=True)
        else:
            gdf = gdf.reset_index(drop=True)
        self.n = len(gdf)
        self.all_columns = [str(c) for c in gdf.columns]
        self.raw_crs = gdf.crs.to_string() if gdf.crs else None
        self.raw_epsg = gdf.crs.to_epsg() if gdf.crs else None
        self.crs_assumed = gdf.crs is None
        if self.crs_assumed:
            gdf = gdf.set_crs("EPSG:4326")
        raw_bounds = [float(b) for b in gdf.total_bounds] if self.n else None
        self.raw_bounds = raw_bounds
        gm = gdf if self.raw_epsg == 32643 else gdf.to_crs(METRIC_CRS)
        self.geoms = np.asarray(gm.geometry.values, dtype=object)
        self.geom_type_counts = {str(k): int(v) for k, v in gdf.geom_type.fillna("None").value_counts().items()}
        keep = set(TAG_COLS) | set(COMPLETENESS_COLS) | set(ID_COLS) | set(TYPE_COLS)
        self.df = pd.DataFrame({c: gdf[c] for c in gdf.columns if c in keep}).reset_index(drop=True)
        del gdf, gm
        g = self.geoms
        self.missing = shapely.is_missing(g)
        self.empty = shapely.is_empty(g)
        tid = shapely.get_type_id(g)
        self.is_poly = np.isin(tid, (3, 6))
        self.is_line = np.isin(tid, (1, 2, 5))
        self.valid = shapely.is_valid(g)
        try:
            pts = shapely.point_on_surface(g)
        except Exception:
            pts = shapely.centroid(g)
        self.x = shapely.get_x(pts)
        self.y = shapely.get_y(pts)
        self.ok = (~self.missing) & (~self.empty) & np.isfinite(self.x) & np.isfinite(self.y)
        self.inside = np.zeros(self.n, dtype=bool)
        if boundary is not None and self.ok.any():
            self.inside[self.ok] = shapely.contains_xy(boundary, self.x[self.ok], self.y[self.ok])
        self._tags = {}
        self.id_key, self.id_info = self._build_ids()
        self.res_tier = np.full(self.n, "", dtype=object)
        self.act_cls = np.full(self.n, "", dtype=object)
        self.act_zone = np.zeros(self.n, dtype=bool)

    def tag(self, col):
        if col not in self._tags:
            if col in self.df.columns:
                self._tags[col] = self.df[col].map(_n).to_numpy(dtype=object)
            else:
                self._tags[col] = np.full(self.n, "", dtype=object)
        return self._tags[col]

    def has(self, col):
        return col in self.df.columns

    def _build_ids(self):
        df = self.df
        idcol = next((c for c in ID_COLS if c in df.columns), None)
        typecol = None
        for c in TYPE_COLS:
            if c in df.columns:
                vals = set(df[c].dropna().astype(str).str.lower().unique()[:50])
                if vals and vals <= {"node", "way", "relation", "n", "w", "r"}:
                    typecol = c
                    break
        info = {"id_column": idcol, "type_column": typecol}
        if idcol is None:
            return None, info

        def fmt(v):
            try:
                if pd.isna(v):
                    return ""
            except (TypeError, ValueError):
                pass
            if isinstance(v, (int, np.integer)) or (isinstance(v, (float, np.floating)) and float(v).is_integer()):
                return str(int(v))
            return str(v)

        key = df[idcol].map(fmt).to_numpy(dtype=object)
        if typecol:
            t = df[typecol].map(_n).to_numpy(dtype=object)
            key = np.where(key == "", "", t + "/" + key).astype(object)
        info["n_missing_id"] = int((key == "").sum())
        return key, info


# ---- per-layer summary -------------------------------------------------------------------------------
def layer_summary(L, top_k):
    out = {"n_rows": L.n, "columns": L.all_columns, "raw_crs": L.raw_crs, "raw_epsg": L.raw_epsg,
           "crs_missing_assumed_4326": L.crs_assumed, "raw_bounds_native_crs": L.raw_bounds,
           "geometry_types": L.geom_type_counts, "id_info": L.id_info}
    out["geometry_quality"] = {
        "missing_geometry": int(L.missing.sum()), "empty_geometry": int(L.empty.sum()),
        "invalid_geometry": int((~L.valid & ~L.missing & ~L.empty).sum()),
        "unusable_for_spatial_ops": int((~L.ok).sum()),
        "invalid_reason_examples": [str(shapely.is_valid_reason(g)) for g in
                                    L.geoms[(~L.valid & ~L.missing & ~L.empty)][:5]],
    }
    out["inside_district_boundary"] = {"n_inside": int(L.inside.sum()), "n_outside": int((L.ok & ~L.inside).sum()),
                                       "share_inside_of_usable": float(L.inside.sum() / max(1, L.ok.sum()))}
    if L.is_poly.any():
        a = shapely.area(L.geoms[L.is_poly & L.ok])
        out["polygon_area_m2"] = pct(a)
        out["polygon_area_flags"] = {"lt_10m2": int((a < 10).sum()), "lt_20m2": int((a < 20).sum()),
                                     "gt_1000m2": int((a > 1000).sum()), "gt_5000m2": int((a > 5000).sum()),
                                     "gt_10000m2": int((a > 10000).sum())}
    if L.is_line.any():
        out["line_length_m"] = pct(shapely.length(L.geoms[L.is_line & L.ok]))
    out["tag_distributions"] = {}
    for c in TAG_COLS:
        if L.has(c):
            arr = L.tag(c)
            ne = int((arr != "").sum())
            out["tag_distributions"][c] = {"n_nonempty": ne, "share_nonempty": ne / max(1, L.n),
                                           "n_unique": int(pd.Series(arr[arr != ""]).nunique()),
                                           "top": top_counts(arr, top_k)}
    out["attribute_completeness"] = {c: float((L.tag(c) != "").mean()) for c in COMPLETENESS_COLS if L.has(c)}
    out["missing_expected_tag_columns"] = [c for c in TAG_COLS if not L.has(c)]
    return out


def within_layer_duplicates(L):
    out = {}
    if L.id_key is not None:
        k = pd.Series(L.id_key[L.id_key != ""])
        dup = k.duplicated(keep=False)
        out["duplicate_id_rows"] = int(dup.sum())
        out["distinct_ids_duplicated"] = int(k[k.duplicated()].nunique())
        out["duplicate_id_examples"] = [str(v) for v in sorted(k[k.duplicated()].unique())[:5]]
    else:
        out["duplicate_id_rows"] = None
        out["note"] = "no OSM id column found"
    m = L.ok
    wkb = pd.Series(shapely.to_wkb(L.geoms[m]))
    out["exact_duplicate_geometry_rows"] = int(wkb.duplicated().sum())
    rp = pd.Series(np.round(L.x[m], 1).astype(str)) + "," + pd.Series(np.round(L.y[m], 1).astype(str))
    out["same_point_within_0.1m_extra_rows"] = int(rp.duplicated().sum())
    return out


# ---- containment helper ------------------------------------------------------------------------------
def contained_in(x, y, ok, poly_geoms):
    """For points (x,y): is each inside any of poly_geoms; first matching polygon index (-1); number of matches."""
    n = len(x)
    mask = np.zeros(n, dtype=bool)
    first = np.full(n, -1, dtype=np.int64)
    cnt = np.zeros(n, dtype=np.int64)
    if len(poly_geoms) == 0 or not ok.any():
        return mask, first, cnt
    tree = STRtree(poly_geoms)
    idx = np.flatnonzero(ok)
    pts = shapely.points(x[idx], y[idx])
    pi, ti = tree.query(pts, predicate="within")
    if len(pi):
        gi = idx[pi]
        mask[gi] = True
        cnt = np.bincount(gi, minlength=n)
        first[gi[::-1]] = ti[::-1]  # reversed so the lowest tree index wins
    return mask, first, cnt


# ---- residential audit -------------------------------------------------------------------------------
def residential_audit(layers, top_k):
    B = layers.get("buildings")
    if B is None:
        return {"error": "buildings layer unavailable"}
    LU = layers.get("landuse")
    out = {"vocabulary_explicit_residential": sorted(RES_EXPLICIT)}
    bv = B.tag("building")
    out["building_value_distribution"] = top_counts(bv, 80)
    out["n_buildings_missing_building_tag"] = int((bv == "").sum())
    explicit = isin(bv, RES_EXPLICIT) & B.ok
    yes = (bv == "yes") & B.ok
    act_tag = np.zeros(B.n, dtype=bool)
    for c in ("amenity", "shop", "office", "healthcare", "craft", "tourism", "leisure"):
        act_tag |= B.tag(c) != ""
    out["explicit_by_value"] = {v: int(((bv == v) & B.ok).sum()) for v in sorted(RES_EXPLICIT)}

    # residential land-use polygons (made valid in memory only)
    res_polys = np.array([], dtype=object)
    if LU is not None:
        m = (LU.tag("landuse") == "residential") & LU.is_poly & LU.ok
        res_polys = shapely.make_valid(LU.geoms[m])
        out["landuse_residential_polygons"] = {
            "n": int(m.sum()), "area_m2": pct(shapely.area(res_polys)) if m.any() else {"n": 0},
            "total_area_km2": float(shapely.area(res_polys).sum() / 1e6) if m.any() else 0.0}
        if m.any():
            union_area = float(shapely.area(shapely.unary_union(res_polys)))
            tot = float(shapely.area(res_polys).sum())
            out["landuse_residential_polygons"]["union_area_km2"] = union_area / 1e6
            out["landuse_residential_polygons"]["self_overlap_ratio_sum_over_union"] = tot / union_area if union_area else None
            pts = shapely.points(B.x[B.ok], B.y[B.ok])
            tree = STRtree(pts)
            pi, ti = tree.query(res_polys, predicate="contains")
            has_b = np.zeros(len(res_polys), dtype=bool)
            has_b[pi] = True
            a = shapely.area(res_polys)
            out["landuse_residential_polygons"]["n_with_zero_building_points"] = int((~has_b).sum())
            out["landuse_residential_polygons"]["area_share_without_buildings"] = float(a[~has_b].sum() / a.sum())
    in_res, _, _ = contained_in(B.x, B.y, B.ok, res_polys)

    tier = np.full(B.n, "", dtype=object)
    tier[yes & ~act_tag & in_res] = "B"           # building=yes inside residential landuse
    tier[yes & ~act_tag & ~in_res] = "C"          # building=yes elsewhere (ambiguous, excluded by default)
    tier[yes & act_tag] = "YES_ACTIVITY_TAGGED"   # building=yes carrying shop/office/amenity... tag
    tier[explicit] = "A"                          # explicit residential building value (overrides)
    B.res_tier = tier
    out["tiers"] = {t: int((tier == t).sum()) for t in ("A", "B", "C", "YES_ACTIVITY_TAGGED")}
    out["tiers"]["building_yes_total"] = int(yes.sum())
    out["tiers"]["explicit_residential_with_activity_tag"] = int((explicit & act_tag).sum())
    out["tiers"]["explicit_residential_inside_residential_landuse"] = int((explicit & in_res).sum())
    out["tiers"]["share_building_yes_inside_residential_landuse"] = float((yes & in_res).sum() / max(1, yes.sum()))
    out["tiers"]["note"] = ("A=explicit residential value; B=building=yes inside landuse=residential (centroid test, no activity tag); "
                            "C=building=yes elsewhere; these are audit labels, not occupancy or household counts.")
    out["tier_area_m2"] = {t: pct(shapely.area(B.geoms[(tier == t) & B.is_poly])) for t in ("A", "B", "C")}
    out["tier_inside_district_boundary"] = {t: int(((tier == t) & B.inside).sum()) for t in ("A", "B", "C")}
    out["tier_with_levels_tag"] = {t: int(((tier == t) & (B.tag("building:levels") != "")).sum()) for t in ("A", "B", "C")}

    # which landuse polygons contain buildings (all landuse values, first match per building)
    if LU is not None:
        lp = LU.is_poly & LU.ok
        lg = shapely.make_valid(LU.geoms[lp])
        lv = LU.tag("landuse")[lp]
        mask, first, cnt = contained_in(B.x, B.y, B.ok, lg)
        cont = np.where(first >= 0, lv[np.clip(first, 0, max(0, len(lv) - 1))] if len(lv) else "", "(none)")
        cont = np.where(mask, cont, "(none)")
        out["building_tier_by_containing_landuse"] = {}
        for t in ("A", "B", "C"):
            sel = tier == t
            out["building_tier_by_containing_landuse"][t] = top_counts(cont[sel], 15) if sel.any() else []
        out["buildings_matching_multiple_landuse_polygons"] = int((cnt > 1).sum())
        out["buildings_in_any_landuse_polygon_share"] = float(mask.sum() / max(1, B.ok.sum()))
    return out


# ---- activity audit ----------------------------------------------------------------------------------
def classify_activity(L):
    n = L.n
    cls = np.full(n, "", dtype=object)
    bld, am, shop = L.tag("building"), L.tag("amenity"), L.tag("shop")
    office, hc, leis = L.tag("office"), L.tag("healthcare"), L.tag("leisure")
    lu, mm, craft = L.tag("landuse"), L.tag("man_made"), L.tag("craft")
    masks = {
        "education": isin(am, EDU_AMENITY) | isin(bld, EDU_BUILDING) | (lu == "education"),
        "healthcare": isin(am, HEALTH_AMENITY) | isin(bld, HEALTH_BUILDING) | (hc != "") | (L.name == "healthcare"),
        "industrial": isin(bld, IND_BUILDING) | (lu == "industrial") | (mm == "works") | (craft != ""),
        "office": isin(bld, OFFICE_BUILDING) | (office != "") | isin(am, OFFICE_AMENITY),
        "commercial_retail": isin(bld, COM_BUILDING) | (shop != "") | isin(am, RETAIL_AMENITY) | isin(lu, {"commercial", "retail"}),
        "civic_public": isin(am, CIVIC_AMENITY) | isin(bld, CIVIC_BUILDING),
        "worship": (am == "place_of_worship") | isin(bld, WORSHIP_BUILDING),
        "leisure": (leis != "") | (L.name == "leisure"),
        "other_amenity": am != "",
    }
    for name in reversed(ACT_ORDER):  # earlier classes overwrite later ones
        cls[masks[name]] = name
    if L.name == "roads":
        cls[:] = ""
    if L.name == "landuse":
        keep = isin(lu, ACT_LANDUSE)
        cls[~keep] = ""
        L.act_zone = keep & L.is_poly
    cls[~L.ok] = ""
    L.act_cls = cls
    return cls


def activity_audit(layers):
    out = {"vocabulary_priority_order": ACT_ORDER, "per_layer": {}}
    for name, L in layers.items():
        cls = classify_activity(L)
        sel = cls != ""
        d = {"n_candidates": int(sel.sum()), "n_zone_polygons": int(L.act_zone.sum()),
             "by_class": {c: int((cls == c).sum()) for c in ACT_ORDER if (cls == c).any()},
             "by_class_inside_boundary": {c: int(((cls == c) & L.inside).sum()) for c in ACT_ORDER if (cls == c).any()}}
        if L.is_poly.any() and sel.any():
            d["area_m2_by_class"] = {c: pct(shapely.area(L.geoms[(cls == c) & L.is_poly]))
                                     for c in ACT_ORDER if ((cls == c) & L.is_poly).any()}
        out["per_layer"][name] = d
    tot = {}
    for L in layers.values():
        sel = (L.act_cls != "") & ~L.act_zone
        for c in ACT_ORDER:
            tot[c] = tot.get(c, 0) + int(((L.act_cls == c) & ~L.act_zone).sum())
    out["destination_candidates_total_excluding_landuse_zones"] = tot
    B = layers.get("buildings")
    if B is not None:
        both = (B.res_tier == "A") & (B.act_cls != "")
        out["explicit_residential_buildings_that_also_carry_activity_class"] = int(both.sum())
    return out


# ---- duplicates --------------------------------------------------------------------------------------
def cross_layer_duplicates(layers, tol_m):
    cand = []
    for name, L in layers.items():
        if name in ("roads", "landuse"):
            continue
        sel = (L.act_cls != "") & ~L.act_zone & L.ok
        if sel.any():
            cand.append(pd.DataFrame({"layer": name, "cls": L.act_cls[sel], "x": L.x[sel], "y": L.y[sel],
                                      "key": L.id_key[sel] if L.id_key is not None else "",
                                      "name": L.tag("name")[sel]}))
    out = {"tolerance_m": tol_m}
    if not cand:
        return {"error": "no activity candidates"}
    C = pd.concat(cand, ignore_index=True)
    out["n_candidates_considered"] = int(len(C))
    # same OSM id in several layers
    ids = C[C["key"] != ""]
    if len(ids):
        g = ids.groupby("key")["layer"].nunique()
        out["same_osm_key_in_multiple_layers"] = int((g > 1).sum())
        out["id_key_caveat"] = ("keys include element type only if the layer has a type column; without it a node and a way "
                                "with the same number would be conflated")
    if cKDTree is None:
        out["spatial_pairs"] = "skipped: scipy not available"
    else:
        layer_names = sorted(C["layer"].unique())
        lc = C["layer"].map({n: i for i, n in enumerate(layer_names)}).to_numpy()
        tree = cKDTree(np.c_[C["x"].to_numpy(), C["y"].to_numpy()])
        pairs = tree.query_pairs(tol_m, output_type="ndarray")
        pairs = pairs[lc[pairs[:, 0]] != lc[pairs[:, 1]]] if len(pairs) else pairs
        sp = {"cross_layer_pairs_within_tol": int(len(pairs))}
        if len(pairs):
            i, j = pairs[:, 0], pairs[:, 1]
            cn, nm = C["cls"].to_numpy(), C["name"].to_numpy()
            sp["share_pairs_same_class"] = float((cn[i] == cn[j]).mean())
            named = (nm[i] != "") & (nm[j] != "")
            sp["pairs_both_named"] = int(named.sum())
            sp["share_named_pairs_same_name"] = float((nm[i][named] == nm[j][named]).mean()) if named.any() else None
            lp = pd.Series([f"{layer_names[min(a, b)]}|{layer_names[max(a, b)]}" for a, b in zip(lc[i], lc[j])])
            sp["pairs_by_layer_pair"] = {k: int(v) for k, v in lp.value_counts().sort_index().items()}
            involved = np.unique(np.r_[i, j])
            sp["features_with_cross_layer_neighbour_by_layer"] = {
                layer_names[k]: int(((lc[involved] == k)).sum()) for k in range(len(layer_names))}
        sp["candidates_by_layer"] = {n: int((C["layer"] == n).sum()) for n in layer_names}
        out["spatial_pairs"] = sp
    return out


def activity_inside_buildings(layers):
    B = layers.get("buildings")
    if B is None:
        return {"error": "buildings layer unavailable"}
    pm = B.is_poly & B.ok & B.valid
    pidx = np.flatnonzero(pm)
    if len(pidx) == 0:
        return {"error": "no valid building polygons"}
    tree = STRtree(B.geoms[pidx])
    out = {}
    for name in ("amenities", "healthcare", "leisure"):
        L = layers.get(name)
        if L is None:
            continue
        sel = (L.act_cls != "") & ~L.act_zone & L.ok
        idx = np.flatnonzero(sel)
        d = {"n_candidates": int(len(idx))}
        if len(idx):
            pts = shapely.points(L.x[idx], L.y[idx])
            pi, ti = tree.query(pts, predicate="within")
            first = np.full(len(idx), -1)
            first[pi[::-1]] = pidx[ti[::-1]]
            hit = first >= 0
            d["inside_any_building_polygon"] = int(hit.sum())
            bt = B.res_tier[first[hit]]
            d["inside_building_by_residential_tier"] = {t: int((bt == t).sum()) for t in ("A", "B", "C", "YES_ACTIVITY_TAGGED")}
            d["inside_building_with_activity_class"] = int((B.act_cls[first[hit]] != "").sum())
            d["inside_building_class_top"] = top_counts(B.tag("building")[first[hit]], 10)
        out[name] = d
    return out


# ---- spatial grid ------------------------------------------------------------------------------------
def grid_audit(layers, boundary, cell_m, out_csv):
    minx, miny, maxx, maxy = boundary.bounds
    x0, y0 = math.floor(minx / cell_m) * cell_m, math.floor(miny / cell_m) * cell_m
    nx, ny = int(math.ceil((maxx - x0) / cell_m)), int(math.ceil((maxy - y0) / cell_m))
    if nx * ny > 2_000_000:
        raise ValueError(f"grid too large ({nx}x{ny}); increase --grid-m")
    ix, iy = np.meshgrid(np.arange(nx), np.arange(ny))
    ix, iy = ix.ravel(), iy.ravel()
    boxes = shapely.box(x0 + ix * cell_m, y0 + iy * cell_m, x0 + (ix + 1) * cell_m, y0 + (iy + 1) * cell_m)
    inter = shapely.intersects(boxes, boundary)
    area_in = np.zeros(len(boxes))
    area_in[inter] = shapely.area(shapely.intersection(boxes[inter], boundary))
    cols = {"ix": ix, "iy": iy, "area_in_boundary_km2": area_in / 1e6}
    try:
        from pyproj import Transformer
        t = Transformer.from_crs(METRIC_CRS, "EPSG:4326", always_xy=True)
        lon, lat = t.transform(x0 + (ix + 0.5) * cell_m, y0 + (iy + 0.5) * cell_m)
        cols["center_lon"], cols["center_lat"] = lon, lat
    except Exception as exc:
        note_error("grid_center_lonlat", exc)

    def count(mask, L):
        m = mask & L.ok & L.inside
        cx = np.floor((L.x[m] - x0) / cell_m).astype(np.int64)
        cy = np.floor((L.y[m] - y0) / cell_m).astype(np.int64)
        good = (cx >= 0) & (cx < nx) & (cy >= 0) & (cy < ny)
        return np.bincount(cy[good] * nx + cx[good], minlength=nx * ny)

    for name, L in layers.items():
        cols[f"n_{name}"] = count(np.ones(L.n, dtype=bool), L)
    z = np.zeros(nx * ny, dtype=np.int64)
    B = layers.get("buildings")
    for t in ("A", "B", "C"):
        cols[f"res_{t}"] = count(B.res_tier == t, B) if B is not None else z
    LU = layers.get("landuse")
    cols["res_landuse_polygons"] = count((LU.tag("landuse") == "residential") & LU.is_poly, LU) if LU is not None else z
    act_total = z.copy()
    for c in ACT_ORDER:
        v = z.copy()
        for L in layers.values():
            v = v + count((L.act_cls == c) & ~L.act_zone, L)
        cols[f"act_{c}"] = v
        act_total = act_total + v
    cols["act_total"] = act_total
    df = pd.DataFrame(cols)
    df.to_csv(out_csv, index=False)

    res_primary = (df["res_A"] + df["res_B"]).to_numpy()
    res_any = res_primary + df["res_C"].to_numpy()
    out = {"cell_size_m": cell_m, "grid_shape_nx_ny": [nx, ny], "origin_epsg32643": [x0, y0],
           "boundary_area_km2": float(shapely.area(boundary) / 1e6), "boundary_bounds_epsg32643": [minx, miny, maxx, maxy]}
    for label, sel in (("cells_intersecting_boundary", inter),
                       ("cells_at_least_half_inside", area_in >= 0.5 * cell_m * cell_m)):
        rp, ra, rany = res_primary[sel], act_total[sel], res_any[sel]
        d = {"n_cells": int(sel.sum()),
             "cells_with_residential_AB": int((rp > 0).sum()), "cells_with_residential_any_tier": int((rany > 0).sum()),
             "cells_with_activity": int((ra > 0).sum()),
             "cells_with_both_AB_and_activity": int(((rp > 0) & (ra > 0)).sum()),
             "cells_residential_AB_without_activity": int(((rp > 0) & (ra == 0)).sum()),
             "cells_activity_without_residential_AB": int(((rp == 0) & (ra > 0)).sum()),
             "cells_with_neither": int(((rp == 0) & (ra == 0)).sum()),
             "residential_AB_per_cell": pct(rp), "activity_per_cell": pct(ra),
             "gini_residential_AB": gini(rp), "gini_activity": gini(ra)}
        if rp.sum():
            s = np.sort(rp)[::-1]
            d["share_residential_AB_in_top10pct_cells"] = float(s[:max(1, len(s) // 10)].sum() / s.sum())
        if ra.sum():
            s = np.sort(ra)[::-1]
            d["share_activity_in_top10pct_cells"] = float(s[:max(1, len(s) // 10)].sum() / s.sum())
        out[label] = d
    top = df.assign(_r=res_primary).sort_values(["_r", "ix", "iy"], ascending=[False, True, True]).head(10)
    out["top10_cells_by_residential_AB"] = top[["ix", "iy", "res_A", "res_B", "act_total"]].to_dict("records")
    return out


def nearest_distances(layers, sample_n, seed):
    if cKDTree is None:
        return {"error": "scipy not available"}
    B = layers.get("buildings")
    if B is None:
        return {"error": "buildings layer unavailable"}
    pool = np.flatnonzero(np.isin(B.res_tier, ["A", "B"]) & B.ok & B.inside)
    if len(pool) == 0:
        return {"error": "no residential A/B candidates inside boundary"}
    rng = np.random.default_rng(seed)
    pick = np.sort(rng.choice(pool, size=min(sample_n, len(pool)), replace=False))
    q = np.c_[B.x[pick], B.y[pick]]
    groups = {"education": {"education"}, "healthcare": {"healthcare"},
              "workplace_commercial_office_industrial": {"commercial_retail", "office", "industrial"}}
    out = {"sample_size": int(len(pick)), "seed": seed, "note": "straight-line distance in metres, EPSG:32643"}
    for g, classes in groups.items():
        xs, ys = [], []
        for L in layers.values():
            m = np.isin(L.act_cls, list(classes)) & ~L.act_zone & L.ok
            xs.append(L.x[m])
            ys.append(L.y[m])
        xs, ys = np.concatenate(xs), np.concatenate(ys)
        if len(xs) == 0:
            out[g] = {"n_destinations": 0}
            continue
        d, _ = cKDTree(np.c_[xs, ys]).query(q)
        out[g] = {"n_destinations": int(len(xs)), "nearest_distance_m": pct(d)}
    return out


# ---- reporting ---------------------------------------------------------------------------------------
def summary_text(rep):
    L = []
    add = L.append
    add("=== OSM layer audit: Bengaluru Urban ===")
    for name, s in rep.get("layers", {}).items():
        if "error" in s:
            add(f"[{name}] ERROR {s['error']}")
            continue
        q = s["geometry_quality"]
        add(f"[{name}] rows={s['n_rows']:,} crs={s['raw_crs']} types={s['geometry_types']} "
            f"empty={q['empty_geometry']} invalid={q['invalid_geometry']} inside_boundary={s['inside_district_boundary']['n_inside']:,}")
        if "polygon_area_m2" in s and "p50" in s["polygon_area_m2"]:
            a = s["polygon_area_m2"]
            add(f"      area m2 p5={a['p5']:.0f} p50={a['p50']:.0f} p95={a['p95']:.0f} p99={a['p99']:.0f} max={a['p100']:.0f}")
    r = rep.get("residential", {})
    if "tiers" in r:
        t = r["tiers"]
        add(f"Residential: A(explicit)={t['A']:,}  B(yes in resid. landuse)={t['B']:,}  C(yes elsewhere)={t['C']:,}  "
            f"yes+activity-tag={t['YES_ACTIVITY_TAGGED']:,}  building=yes total={t['building_yes_total']:,} "
            f"({t['share_building_yes_inside_residential_landuse']:.1%} inside residential landuse)")
    lr = r.get("landuse_residential_polygons")
    if lr and "n" in lr:
        add(f"Residential landuse polygons={lr['n']:,} area={lr['total_area_km2']:.1f} km2 "
            f"overlap_ratio={lr.get('self_overlap_ratio_sum_over_union')} without_buildings={lr.get('n_with_zero_building_points')}")
    a = rep.get("activity", {})
    if "destination_candidates_total_excluding_landuse_zones" in a:
        add(f"Activity candidates (excl. landuse zones): {a['destination_candidates_total_excluding_landuse_zones']}")
    d = rep.get("cross_layer_duplicates", {})
    if "spatial_pairs" in d and isinstance(d["spatial_pairs"], dict):
        add(f"Cross-layer pairs within {d['tolerance_m']} m: {d['spatial_pairs']['cross_layer_pairs_within_tol']:,}; "
            f"same OSM key in several layers: {d.get('same_osm_key_in_multiple_layers')}")
    g = rep.get("grid", {})
    if "cells_at_least_half_inside" in g:
        c = g["cells_at_least_half_inside"]
        add(f"Grid {g['cell_size_m']} m: cells(>=50% inside)={c['n_cells']} res_AB>0={c['cells_with_residential_AB']} "
            f"activity>0={c['cells_with_activity']} both={c['cells_with_both_AB_and_activity']} "
            f"res_without_activity={c['cells_residential_AB_without_activity']} neither={c['cells_with_neither']}")
    nd = rep.get("nearest_activity_distance", {})
    for k in ("education", "healthcare", "workplace_commercial_office_industrial"):
        if k in nd and "nearest_distance_m" in nd[k]:
            x = nd[k]["nearest_distance_m"]
            add(f"Nearest {k}: median={x['p50']:.0f} m p95={x['p95']:.0f} m")
    if ERRORS:
        add(f"!! {len(ERRORS)} step(s) failed, see report['errors']")
    return "\n".join(L)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--geo-dir", default="data/processed/geo")
    ap.add_argument("--boundary", default="data/boundaries/bengaluru_urban.geojson")
    ap.add_argument("--out-dir", default="audit_output/osm_layers")
    ap.add_argument("--grid-m", type=float, default=2000.0, help="grid cell size in metres (EPSG:32643)")
    ap.add_argument("--dup-tol-m", type=float, default=10.0, help="cross-layer duplicate distance tolerance")
    ap.add_argument("--top-k", type=int, default=40, help="top-k tag values per column")
    ap.add_argument("--sample-n", type=int, default=100000, help="residential sample for nearest-destination distances")
    ap.add_argument("--seed", type=int, default=12345)
    args = ap.parse_args()

    if int(shapely.__version__.split(".")[0]) < 2:
        sys.exit("shapely >= 2.0 required")
    geo_dir, boundary_path = os.path.abspath(args.geo_dir), os.path.abspath(args.boundary)
    out_dir = os.path.abspath(args.out_dir)
    for protected in (geo_dir, os.path.dirname(boundary_path)):
        if out_dir == protected or out_dir.startswith(protected + os.sep):
            sys.exit(f"refusing to write into the input directory: {out_dir}")
    os.makedirs(out_dir, exist_ok=True)

    config = {"geo_dir": args.geo_dir, "boundary": args.boundary, "metric_crs": METRIC_CRS, "grid_m": args.grid_m,
              "dup_tol_m": args.dup_tol_m, "top_k": args.top_k, "sample_n": args.sample_n, "seed": args.seed,
              "vocabularies": {"RES_EXPLICIT": sorted(RES_EXPLICIT), "EDU_AMENITY": sorted(EDU_AMENITY),
                               "EDU_BUILDING": sorted(EDU_BUILDING), "HEALTH_AMENITY": sorted(HEALTH_AMENITY),
                               "IND_BUILDING": sorted(IND_BUILDING), "COM_BUILDING": sorted(COM_BUILDING),
                               "RETAIL_AMENITY": sorted(RETAIL_AMENITY), "CIVIC_AMENITY": sorted(CIVIC_AMENITY),
                               "ACT_LANDUSE": sorted(ACT_LANDUSE), "ACT_ORDER": ACT_ORDER}}
    rep = {"config": config, "inputs": {}, "layers": {}}
    meta = {"generated_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(), "python": sys.version,
            "platform": platform.platform(),
            "versions": {"numpy": np.__version__, "pandas": pd.__version__, "geopandas": gpd.__version__,
                         "shapely": shapely.__version__}}
    try:
        import scipy
        meta["versions"]["scipy"] = scipy.__version__
    except ImportError:
        meta["versions"]["scipy"] = None

    # input checksums
    paths = {n: os.path.join(geo_dir, f"{n}.parquet") for n in LAYER_NAMES}
    paths["boundary"] = boundary_path
    for n, p in paths.items():
        if os.path.isfile(p):
            rep["inputs"][n] = {"path": p, "bytes": os.path.getsize(p), "sha256": sha256_file(p)}
        else:
            rep["inputs"][n] = {"path": p, "missing": True}

    # boundary
    boundary = None
    if not rep["inputs"]["boundary"].get("missing"):
        try:
            bg = gpd.read_file(boundary_path)
            if bg.crs is None:
                bg = bg.set_crs("EPSG:4326")
                rep["boundary_crs_missing_assumed_4326"] = True
            bg = bg.to_crs(METRIC_CRS)
            geoms = shapely.make_valid(np.asarray(bg.geometry.values, dtype=object))
            boundary = shapely.make_valid(shapely.unary_union(geoms))
            shapely.prepare(boundary)
            rep["boundary"] = {"n_features": int(len(bg)), "area_km2": float(shapely.area(boundary) / 1e6),
                               "geom_type": str(shapely.get_type_id(boundary)), "bounds_epsg32643": list(boundary.bounds)}
        except Exception as exc:
            note_error("boundary", exc)
            rep["boundary"] = {"error": str(exc)}
    if boundary is None:
        rep["errors"] = ERRORS
        print("Boundary unavailable; cannot continue.", file=sys.stderr)
        with open(os.path.join(out_dir, "audit_report.json"), "w") as f:
            json.dump(clean({**rep, "meta": meta}), f, indent=2)
        sys.exit(2)

    layers = {}
    for n in LAYER_NAMES:
        if rep["inputs"][n].get("missing"):
            rep["layers"][n] = {"error": "file missing"}
            continue
        try:
            layers[n] = Layer(n, paths[n], boundary)
            rep["layers"][n] = layer_summary(layers[n], args.top_k)
            safe(rep["layers"][n], "within_layer_duplicates", within_layer_duplicates, layers[n])
        except Exception as exc:
            note_error(f"layer:{n}", exc)
            rep["layers"][n] = {"error": f"{type(exc).__name__}: {exc}"}

    safe(rep, "residential", residential_audit, layers, args.top_k)
    safe(rep, "activity", activity_audit, layers)
    safe(rep, "cross_layer_duplicates", cross_layer_duplicates, layers, args.dup_tol_m)
    safe(rep, "activity_points_inside_building_polygons", activity_inside_buildings, layers)
    safe(rep, "grid", grid_audit, layers, boundary, args.grid_m, os.path.join(out_dir, "audit_grid.csv"))
    safe(rep, "nearest_activity_distance", nearest_distances, layers, args.sample_n, args.seed)
    rep["errors"] = ERRORS

    body = clean(rep)
    # digest of everything except meta/timestamps: identical inputs + config + library versions => identical digest
    digest = hashlib.sha256(json.dumps({**body, "_versions": meta["versions"]}, sort_keys=True).encode()).hexdigest()
    full = {**body, "meta": {**meta, "content_sha256": digest}}
    with open(os.path.join(out_dir, "audit_report.json"), "w") as f:
        json.dump(full, f, indent=2, sort_keys=False)
    text = summary_text(body) + f"\nreport digest: {digest}\noutputs: {out_dir}"
    with open(os.path.join(out_dir, "audit_summary.txt"), "w") as f:
        f.write(text + "\n")
    print(text)


if __name__ == "__main__":
    main()
