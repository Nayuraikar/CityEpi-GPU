"""Geospatial layer service.

Large OSM layers (827k buildings, 240k roads) are never shipped whole to the browser.
Per-layer bounding boxes are computed once (cached in backend/.cache) and then used for
bbox queries, density grids and zoom-aware road filtering.
"""
import json
import threading
from functools import lru_cache

import numpy as np
import pandas as pd
import pyarrow.parquet as pq
import shapely
from shapely import wkb

from .config import BOUNDARY, CACHE_DIR, GEO_DIR, SYN_HH
from .util import clean

POLY_LAYERS = {"buildings": "building", "landuse": "landuse", "leisure": "leisure"}
LINE_LAYERS = {"roads": "highway"}
ROAD_ZOOM_CLASSES = [
    (11, {"motorway", "trunk", "primary"}),
    (13, {"motorway", "trunk", "primary", "secondary", "motorway_link", "trunk_link", "primary_link"}),
    (15, {"motorway", "trunk", "primary", "secondary", "tertiary", "motorway_link", "trunk_link",
          "primary_link", "secondary_link", "tertiary_link", "unclassified"}),
]
_lock = threading.Lock()


class VectorLayer:
    def __init__(self, name: str):
        self.name = name
        self.path = GEO_DIR / f"{name}.parquet"
        kind = POLY_LAYERS.get(name) or LINE_LAYERS.get(name)
        cols = ["geometry"] + ([kind] if kind else [])
        if "name" in pq.ParquetFile(self.path).schema_arrow.names and name != "roads":
            cols.append("name")
        t = pq.read_table(self.path, columns=cols)
        self.wkb = t["geometry"].to_numpy(zero_copy_only=False)
        self.kind = t[kind].to_pandas().fillna("").astype(str).to_numpy() if kind else None
        self.names = t["name"].to_pandas().fillna("").astype(str).to_numpy() if "name" in cols else None
        cache = CACHE_DIR / f"{name}_bounds.npy"
        if cache.exists() and cache.stat().st_mtime > self.path.stat().st_mtime:
            self.bounds = np.load(cache)
        else:
            geoms = shapely.from_wkb(self.wkb)
            self.bounds = shapely.bounds(geoms).astype("float64")
            np.save(cache, self.bounds)
        self.cx = (self.bounds[:, 0] + self.bounds[:, 2]) / 2
        self.cy = (self.bounds[:, 1] + self.bounds[:, 3]) / 2

    def mask(self, bbox):
        w, s, e, n = bbox
        b = self.bounds
        return (b[:, 2] >= w) & (b[:, 0] <= e) & (b[:, 3] >= s) & (b[:, 1] <= n)


@lru_cache(maxsize=None)
def layer(name: str) -> VectorLayer:
    with _lock:
        return VectorLayer(name)


def features(name: str, bbox, zoom: int, limit: int) -> dict:
    L = layer(name)
    m = L.mask(bbox)
    if name == "roads":
        keep = None
        for z, classes in ROAD_ZOOM_CLASSES:
            if zoom < z:
                keep = classes
                break
        if keep is not None:
            m &= np.isin(L.kind, list(keep))
    idx = np.nonzero(m)[0]
    total = int(len(idx))
    truncated = total > limit
    if truncated:
        idx = idx[np.linspace(0, total - 1, limit).astype(int)]  # deterministic even subsample
    feats = []
    tol = 0.00001 if zoom < 17 else 0
    for i in idx:
        g = wkb.loads(L.wkb[i])
        if tol:
            g = g.simplify(tol, preserve_topology=False)
            if g.is_empty:
                continue
        props = {}
        if L.kind is not None:
            props["kind"] = L.kind[i]
        if L.names is not None and L.names[i]:
            props["name"] = L.names[i]
        feats.append({"type": "Feature", "properties": props,
                      "geometry": json.loads(shapely.to_geojson(shapely.set_precision(g, 1e-6)))})
    return {"type": "FeatureCollection", "features": feats, "total_in_view": total, "truncated": truncated}


def density(name: str, cell_deg: float) -> dict:
    """Square-cell counts over the whole layer extent (for low-zoom rendering)."""
    if name in ("homes", "homes_occupied", "destinations"):
        df = _locations()
        sel = {"homes": df.loc_type_name == "HOME", "homes_occupied": (df.loc_type_name == "HOME") & (df.occupancy > 0),
               "destinations": df.loc_type_name == "WORK"}[name]
        x, y = df.lon[sel].to_numpy(), df.lat[sel].to_numpy()
    else:
        L = layer(name)
        x, y = L.cx, L.cy
    ix = np.floor(x / cell_deg).astype(np.int64)
    iy = np.floor(y / cell_deg).astype(np.int64)
    keys, counts = np.unique(np.stack([ix, iy], 1), axis=0, return_counts=True)
    return {"cell_deg": cell_deg, "cells": [[float(k[0] * cell_deg), float(k[1] * cell_deg), int(c)]
                                            for k, c in zip(keys, counts)], "max": int(counts.max()), "total": int(len(x))}


@lru_cache(maxsize=1)
def _locations() -> pd.DataFrame:
    return pd.read_parquet(
        SYN_HH / "locations.geoparquet",
        columns=["location_id", "loc_type_name", "category", "name", "capacity", "occupancy", "lon", "lat", "tier"],
    )


@lru_cache(maxsize=None)
def points(name: str) -> dict:
    """Compact point payloads: {'columns': [...], 'rows': [[...]]}."""
    if name == "destinations":
        d = _locations()
        d = d[d.loc_type_name == "WORK"]
        cols = ["lon", "lat", "category", "occupancy", "capacity", "name", "location_id"]
    elif name == "homes_occupied":
        d = _locations()
        d = d[(d.loc_type_name == "HOME") & (d.occupancy > 0)]
        cols = ["lon", "lat", "occupancy", "capacity", "location_id"]
    elif name in ("healthcare", "amenities"):
        t = pq.read_table(GEO_DIR / f"{name}.parquet", columns=["geometry", "name", "amenity"]).to_pandas()
        g = shapely.from_wkb(t["geometry"].to_numpy())
        c = shapely.centroid(g)
        t["lon"], t["lat"] = shapely.get_x(c), shapely.get_y(c)
        t = t.rename(columns={"amenity": "kind"})
        d, cols = t, ["lon", "lat", "kind", "name"]
    else:
        raise KeyError(name)
    d = d[cols].copy()
    d["lon"], d["lat"] = d["lon"].round(6), d["lat"].round(6)
    return {"columns": cols, "rows": [clean(list(r)) for r in d.itertuples(index=False, name=None)],
            "count": int(len(d))}


@lru_cache(maxsize=1)
def boundary() -> dict:
    return json.loads(BOUNDARY.read_text())


@lru_cache(maxsize=1)
def layer_catalog() -> dict:
    rows = {}
    for n in ("buildings", "roads", "healthcare", "amenities", "leisure", "landuse"):
        rows[n] = int(pq.ParquetFile(GEO_DIR / f"{n}.parquet").metadata.num_rows)
    loc = _locations()
    rows["destinations"] = int((loc.loc_type_name == "WORK").sum())
    rows["homes"] = int((loc.loc_type_name == "HOME").sum())
    rows["homes_occupied"] = int(((loc.loc_type_name == "HOME") & (loc.occupancy > 0)).sum())
    b = boundary()["geometry"]
    xs = [p[0] for p in b["coordinates"][0]]
    ys = [p[1] for p in b["coordinates"][0]]
    return {"counts": rows, "bounds": [min(ys), min(xs), max(ys), max(xs)],
            "boundary_props": boundary()["properties"]}
