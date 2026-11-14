"""Independent validation of an exported run directory. Reads only the files (CEPOP, GeoParquet, Parquet) plus the
boundary; recomputes occupancy, distances and containment itself rather than trusting generator-side values."""
import json
import os

import numpy as np
import pandas as pd

from . import cepop
from .config import GEO_CRS, METRIC_CRS

ALLOWED_DECISIONS = {"exact_key_merge", "exact_key_duplicate_same_layer", "name_category_proximity_merge",
                     "unnamed_category_proximity_merge", "kept_distinct_close_pair"}
FILES = ["population.cepop", "locations.geoparquet", "agents.parquet", "dedup_decisions.parquet"]


def validate_outputs(out_dir, boundary_path, cfg, n_expected=None):
    import geopandas as gpd
    import shapely
    from pyproj import Transformer

    checks = []

    def add(name, ok, detail=""):
        checks.append({"name": name, "passed": bool(ok), "detail": str(detail)})
        return bool(ok)

    n_expected = cfg["n_agents"] if n_expected is None else n_expected
    missing = [f for f in FILES if not os.path.isfile(os.path.join(out_dir, f))]
    if not add("output files present", not missing, missing or "ok"):
        return checks
    try:
        arr = cepop.read_cepop(os.path.join(out_dir, "population.cepop"))
        add("cepop format (magic/version/size/CRC)", True)
    except ValueError as e:
        add("cepop format (magic/version/size/CRC)", False, e)
        return checks
    loc = gpd.read_parquet(os.path.join(out_dir, "locations.geoparquet"))
    ag = pd.read_parquet(os.path.join(out_dir, "agents.parquet"))
    dd = pd.read_parquet(os.path.join(out_dir, "dedup_decisions.parquet"))
    n, nl = len(arr["state"]), len(arr["loc_type"])

    add("agent count == requested N", n == n_expected, f"{n} vs {n_expected}")
    add("array sizes consistent", all(len(arr[k]) == n for k in ("timer", "home_loc", "work_loc")) and len(arr["occupancy"]) == nl)
    add("agents.parquet rows == N", len(ag) == n, len(ag))
    add("locations rows == cepop locations", len(loc) == nl, f"{len(loc)} vs {nl}")
    add("location_id is 0..L-1 in row order", np.array_equal(loc["location_id"].to_numpy(), np.arange(nl)))
    add("all agents start S with timer 0", not arr["state"].any() and not arr["timer"].any())
    h, w, lt = arr["home_loc"].astype(np.int64), arr["work_loc"].astype(np.int64), arr["loc_type"]
    in_range = (h.min() >= 0 and h.max() < nl and w.min() >= 0 and w.max() < nl) if n else False
    add("home/work ids in range", in_range)
    if not in_range:
        return checks
    add("location types are 0/1", bool(np.isin(lt, (0, 1)).all()))
    add("home_loc -> HOME, work_loc -> WORK", bool((lt[h] == 0).all() and (lt[w] == 1).all()))
    add("cepop loc_type == locations.loc_type", np.array_equal(lt, loc["loc_type"].to_numpy()))
    occ = np.bincount(h, minlength=nl) + np.bincount(w, minlength=nl)
    add("occupancy recomputed == cepop occupancy", np.array_equal(occ, arr["occupancy"].astype(np.int64)))
    add("occupancy recomputed == locations.occupancy", np.array_equal(occ, loc["occupancy"].to_numpy()))
    add("sum(occupancy) == 2N", int(occ.sum()) == 2 * n)
    add("agents.parquet matches cepop (ids, home, destination)",
        np.array_equal(ag["agent_id"].to_numpy(), np.arange(n)) and np.array_equal(ag["home_loc"].to_numpy(), h)
        and np.array_equal(ag["dest_loc"].to_numpy(), w))
    add("no nulls in agents.parquet", not ag.isna().any().any())

    geom = np.asarray(loc.geometry.values, dtype=object)
    add("locations CRS is EPSG:4326", loc.crs is not None and loc.crs.to_epsg() == 4326)
    add("no missing/empty geometries", not (shapely.is_missing(geom).any() or shapely.is_empty(geom).any()))
    add("all geometries are valid points", bool((shapely.get_type_id(geom) == 0).all() and shapely.is_valid(geom).all()))
    lon, lat = shapely.get_x(geom), shapely.get_y(geom)
    add("coordinates finite", bool(np.isfinite(lon).all() and np.isfinite(lat).all()))
    add("lon/lat columns equal geometry", bool(np.allclose(lon, loc["lon"], atol=1e-9) and np.allclose(lat, loc["lat"], atol=1e-9)))
    b = gpd.read_file(boundary_path)
    b = b.to_crs(GEO_CRS) if b.crs is not None and b.crs.to_epsg() != 4326 else b
    bg = shapely.union_all(np.asarray(b.geometry.values, dtype=object))
    outside = ~shapely.contains_xy(bg, lon, lat)
    add("all coordinates inside Bengaluru Urban boundary", not outside.any(), f"{int(outside.sum())} outside")

    cap, ocl = loc["capacity"].to_numpy(), loc["occupancy"].to_numpy()
    add("capacity >= 1 everywhere", bool((cap >= 1).all()))
    add("occupancy <= capacity everywhere", bool((ocl <= cap).all()), f"{int((ocl > cap).sum())} violations")
    homes = lt == 0
    add("home occupancy <= max_agents_per_home", bool((ocl[homes] <= cfg["residential"]["max_agents_per_home"]).all()))
    share_cap = int(np.ceil(cfg["destinations"]["max_share_of_population"] * n_expected))
    add("no destination above max_share_of_population", bool((ocl[~homes] <= share_cap).all()), f"cap {share_cap}")
    cats = loc["category"].to_numpy(dtype=object)
    add("home category 'residential', destination categories configured",
        bool((cats[homes] == "residential").all() and np.isin(cats[~homes], cfg["destinations"]["include_categories"]).all()))
    add("(osm_type, osm_id, loc_type) unique", not pd.DataFrame({"t": loc["osm_type"], "i": loc["osm_id"], "l": lt}).duplicated().any())
    add("osm_id integer dtype", pd.api.types.is_integer_dtype(loc["osm_id"]))

    tr = Transformer.from_crs(GEO_CRS, METRIC_CRS, always_xy=True)
    X, Y = tr.transform(lon, lat)
    dist = np.hypot(X[h] - X[w], Y[h] - Y[w])
    add("assignment distance recomputed from EPSG:4326 coords == stored (<=0.01 m)",
        bool(np.all(np.abs(dist - ag["distance_m"].to_numpy()) <= 0.01)), f"max abs diff {np.abs(dist - ag['distance_m'].to_numpy()).max():.6f} m")
    add("distances finite and >= 0", bool(np.isfinite(ag["distance_m"]).all() and (ag["distance_m"] >= 0).all()))
    bad = set(dd["decision"]) - ALLOWED_DECISIONS if len(dd) else set()
    add("dedup decision types recognised", not bad, sorted(bad))
    return checks


def summarize(checks):
    return {"passed": all(c["passed"] for c in checks), "n_checks": len(checks),
            "failed": [c for c in checks if not c["passed"]], "checks": checks}
