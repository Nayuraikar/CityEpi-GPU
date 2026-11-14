"""Load OSM GeoParquet layers (read-only). Source CRS EPSG:4326; metric work in EPSG:32643.

Every dropped row is recorded in the Recorder (stage 'load'); same-layer exact duplicates are also written to the
dedup-decision list. Identity is (osm_type, id)."""
import numpy as np
import pandas as pd
import shapely
from pyproj import Transformer

from .config import GEO_CRS, METRIC_CRS

TAG_COLS = ["building", "building:use", "landuse", "amenity", "shop", "office", "healthcare", "leisure", "highway",
            "man_made", "tourism", "craft", "industrial", "public_transport", "railway", "residential",
            "building:levels", "name"]
OSM_TYPES = {"node", "way", "relation"}
POLY_IDS = (3, 6)


class LayerData:
    def __init__(self, name, df, geoms_m, stats):
        self.name, self.df, self.geoms, self.stats = name, df, geoms_m, stats

    def __len__(self):
        return len(self.df)


def load_boundary(path):
    import geopandas as gpd
    g = gpd.read_file(path)
    if g.crs is None:
        raise ValueError("boundary has no CRS")
    if g.crs.to_epsg() != 4326:
        g = g.to_crs(GEO_CRS)
    geom = shapely.union_all(np.asarray(g.geometry.values, dtype=object))
    if not shapely.is_valid(geom):
        geom = shapely.make_valid(geom)
    shapely.prepare(geom)
    return geom


def _norm_str(series):
    return series.astype("string").str.strip().str.lower().fillna("").to_numpy(dtype=object)


def read_layer(name, path, boundary, rec, decisions, filter_boundary=True):
    import geopandas as gpd
    gdf = gpd.read_parquet(path)  # read-only
    st = {"path_name": str(path).split("/")[-1], "n_raw": int(len(gdf)), "columns": [str(c) for c in gdf.columns]}
    if gdf.crs is None:
        raise ValueError(f"{name}: layer has no CRS (expected EPSG:4326)")
    if gdf.crs.to_epsg() != 4326:
        rec.note(f"{name}: source CRS {gdf.crs.to_string()} reprojected to EPSG:4326")
        gdf = gdf.to_crs(GEO_CRS)
    for c in ("id", "osm_type"):
        if c not in gdf.columns:
            raise ValueError(f"{name}: required column '{c}' missing")
    gdf = gdf.reset_index(drop=True)
    typ = _norm_str(gdf["osm_type"])
    bad = ~np.isin(typ, list(OSM_TYPES))
    if bad.any():
        raise ValueError(f"{name}: unrecognised osm_type values {sorted(set(typ[bad]))[:5]}")
    ids = pd.to_numeric(gdf["id"], errors="coerce")
    miss_id = ids.isna().to_numpy()
    ids = ids.fillna(-1).astype("int64").to_numpy()
    key = np.array([f"{t}/{i}" for t, i in zip(typ, ids)], dtype=object)

    g = np.asarray(gdf.geometry.values, dtype=object)
    missing = shapely.is_missing(g)
    empty = np.zeros(len(g), bool)
    empty[~missing] = shapely.is_empty(g[~missing])
    keep = ~missing & ~empty & ~miss_id
    rec.exclude("load", name, "missing_geometry", key[missing])
    rec.exclude("load", name, "empty_geometry", key[empty & ~missing])
    rec.exclude("load", name, "missing_id", [f"row{i}" for i in np.flatnonzero(miss_id)])
    st["missing_geometry"], st["empty_geometry"], st["missing_id"] = int(missing.sum()), int(empty.sum()), int(miss_id.sum())

    tags = {c: (_norm_str(gdf[c]) if c in gdf.columns else np.full(len(gdf), "", dtype=object)) for c in TAG_COLS}
    st["missing_tag_columns"] = [c for c in TAG_COLS if c not in gdf.columns]
    name_raw = (gdf["name"].astype("string").str.strip().fillna("").to_numpy(dtype=object) if "name" in gdf.columns
                else np.full(len(gdf), "", dtype=object))
    sub = gdf.loc[keep, ["geometry"]]
    gm = np.asarray(sub.to_crs(METRIC_CRS).geometry.values, dtype=object)
    inv = ~shapely.is_valid(gm)
    st["invalid_repaired"] = int(inv.sum())
    if inv.any():
        gm[inv] = shapely.make_valid(gm[inv])
        rec.note(f"{name}: {int(inv.sum())} invalid geometries repaired with make_valid (kept)")
    still_empty = shapely.is_empty(gm)
    pts = shapely.point_on_surface(gm)
    x, y = shapely.get_x(pts), shapely.get_y(pts)
    finite = np.isfinite(x) & np.isfinite(y) & ~still_empty
    idx = np.flatnonzero(keep)
    rec.exclude("load", name, "unrepairable_or_non_finite_geometry", key[idx[~finite]])
    x = np.where(finite, x, 0.0); y = np.where(finite, y, 0.0)
    lon, lat = Transformer.from_crs(METRIC_CRS, GEO_CRS, always_xy=True).transform(x, y)
    lon, lat = np.asarray(lon), np.asarray(lat)

    ok = finite.copy()
    if filter_boundary:
        inside = np.zeros(len(ok), bool)
        inside[ok] = shapely.contains_xy(boundary, lon[ok], lat[ok])
        rec.exclude("load", name, "outside_boundary", key[idx[ok & ~inside]])
        st["outside_boundary"] = int((ok & ~inside).sum())
        ok &= inside
    sel = idx[ok]
    gm_sel = gm[ok]
    df = pd.DataFrame({"layer": name, "osm_type": typ[sel], "osm_id": ids[sel], "key": key[sel],
                       "lon": lon[ok], "lat": lat[ok], "x": x[ok], "y": y[ok],
                       "area_m2": shapely.area(gm_sel), "geom_type_id": shapely.get_type_id(gm_sel),
                       "name_raw": name_raw[sel]})
    for c in TAG_COLS:
        df["tag:" + c] = tags[c][sel]
    # exact same-layer duplicates: keep first in file order, record each dropped row
    dup = df.duplicated("key", keep="first").to_numpy()
    if dup.any():
        first_pos = df.reset_index().drop_duplicates("key").set_index("key")["index"]
        for i in np.flatnonzero(dup):
            k = df["key"].iat[i]
            decisions.append(dict(decision="exact_key_duplicate_same_layer", key_a=k, key_b=k, layer_a=name, layer_b=name,
                                  category_a="", category_b="", name_a=df["name_raw"].iat[int(first_pos[k])],
                                  name_b=df["name_raw"].iat[i], distance_m=0.0,
                                  reason="same (osm_type,id) twice in one layer; first row kept"))
        rec.exclude("load", name, "exact_key_duplicate_same_layer", df["key"][dup])
    st["exact_key_duplicates_same_layer"] = int(dup.sum())
    keepd = ~dup
    df, gm_sel = df[keepd], gm_sel[keepd]
    order = np.lexsort((df["osm_id"].to_numpy(), df["osm_type"].to_numpy().astype(str)))  # deterministic order
    df = df.iloc[order].reset_index(drop=True)
    gm_sel = gm_sel[order]
    st["n_kept"] = int(len(df))
    st["geometry_types"] = {str(k): int(v) for k, v in pd.Series(df["geom_type_id"]).value_counts().sort_index().items()}
    return LayerData(name, df, gm_sel, st)
