"""Small FABRICATED OSM-like GeoParquet layers (EPSG:4326, columns id + osm_type + tags) for local tests.
Coordinates are placed near Bengaluru only so the EPSG:32643 projection is realistic; nothing here is real data."""
import json
import math
import os

import geopandas as gpd
import numpy as np
import pandas as pd
from shapely.geometry import Point, Polygon, box, mapping

LON0, LAT0 = 77.58, 12.97
BOUNDARY = box(77.50, 12.90, 77.70, 13.05)


def sq(lon, lat, size_m):
    dlon = size_m / (111320.0 * math.cos(math.radians(lat)))
    dlat = size_m / 110540.0
    return box(lon - dlon / 2, lat - dlat / 2, lon + dlon / 2, lat + dlat / 2)


def rect_m(lon, lat, w_m, h_m):
    dlon = w_m / (111320.0 * math.cos(math.radians(lat)))
    dlat = h_m / 110540.0
    return box(lon - dlon / 2, lat - dlat / 2, lon + dlon / 2, lat + dlat / 2)


def _frame(rows):
    df = pd.DataFrame(rows)
    return gpd.GeoDataFrame(df, geometry="geometry", crs="EPSG:4326")


def _r(t, i, geom, **tags):
    d = {"osm_type": t, "id": i, "geometry": geom}
    d.update(tags)
    return d


def build(dirpath, n_res=400, n_poi=60, seed=7):
    """Write the five layers + boundary to dirpath/geo and dirpath/boundary.geojson. Returns (geo_dir, boundary_path)."""
    rng = np.random.default_rng(seed)
    geo = os.path.join(dirpath, "geo")
    os.makedirs(geo, exist_ok=True)

    # landuse (context only)
    L1 = box(77.55, 12.95, 77.60, 13.00)          # large residential
    L2 = box(77.575, 12.97, 77.60, 13.00)         # smaller residential, overlaps L1
    landuse = _frame([
        _r("way", 1001, L1, landuse="residential"), _r("way", 1002, L2, landuse="residential"),
        _r("way", 1003, box(77.62, 12.95, 77.65, 12.98), landuse="commercial"),
        _r("way", 1004, box(77.62, 13.00, 77.66, 13.03), landuse="industrial"),
        _r("way", 1005, box(77.51, 12.91, 77.52, 12.92), landuse="forest"),
    ])

    rows = []
    def pt_in(box_):  # random point inside lon/lat box
        return rng.uniform(box_.bounds[0] + 0.001, box_.bounds[2] - 0.001), rng.uniform(box_.bounds[1] + 0.001, box_.bounds[3] - 0.001)
    nid = 10000
    for _ in range(int(n_res * 0.55)):   # tier B candidates (building=yes inside L1)
        lon, lat = pt_in(L1)
        rows.append(_r("way", nid, sq(lon, lat, float(rng.lognormal(2.8, 0.5))), building="yes")); nid += 1
    for _ in range(int(n_res * 0.2)):    # tier A
        lon, lat = pt_in(box(77.52, 12.92, 77.65, 13.02))
        rows.append(_r("way", nid, sq(lon, lat, float(rng.lognormal(3.0, 0.5))), building=str(rng.choice(["house", "apartments", "residential"])),
                       **{"building:levels": str(int(rng.integers(1, 12)))})); nid += 1
    for _ in range(int(n_res * 0.25)):   # tier C (building=yes outside residential landuse)
        lon, lat = pt_in(box(77.62, 12.92, 77.69, 12.99))
        rows.append(_r("way", nid, sq(lon, lat, float(rng.lognormal(2.8, 0.5))), building="yes")); nid += 1
    for _ in range(6):
        lon, lat = pt_in(L1)
        rows.append(_r("way", nid, sq(lon, lat, 14), building=str(rng.choice(["industrial", "warehouse", "office", "commercial"])))); nid += 1
    rows += [
        _r("way", 9001, sq(77.590, 12.985, 12), building="yes"),                        # inside L1 and L2 (multi-match)
        _r("way", 9002, sq(77.560, 12.960, 230), building="apartments"),                # huge footprint (cap)
        _r("way", 9003, sq(77.565, 12.965, 1.4), building="house"),                     # tiny footprint (floor)
        _r("way", 9004, sq(77.800, 12.980, 12), building="yes"),                        # outside boundary
        _r("way", 9005, sq(77.585, 12.975, 12), building="yes", amenity="cafe"),        # yes + activity tag: not a home
        _r("way", 9006, sq(77.640, 12.970, 40), building="school"),                     # education building, unnamed
        _r("way", 9007, sq(77.645, 12.960, 40), building="commercial"),                 # contains the clinic POI
        _r("way", 9008, sq(77.580, 12.990, 12), building="bridge"),                     # other building value
        _r("way", 9010, sq(77.5601, 12.9601, 10), building="yes"),                      # duplicated below
    ]
    first = rows[-1]
    rows.append(dict(first))                                                            # exact duplicate row (same key)
    rows.append(_r("way", 9009, None, building="yes"))                                  # missing geometry
    buildings = _frame(rows)

    am = [
        _r("node", 9101, Point(77.640, 12.970), amenity="school", name="Greenwood School"),    # inside way/9006
        _r("node", 9102, Point(77.645, 12.960), amenity="clinic", name="Dr X Clinic"),          # inside way/9007, distinct
        _r("node", 9201, Point(77.6200, 12.9700), amenity="cafe", name="Chai Point"),
        _r("node", 9202, Point(77.62003, 12.9700), amenity="cafe", name="  chai   POINT "),     # ~3 m: name+category merge
        _r("node", 9203, Point(77.6300, 12.9700), amenity="restaurant", name="Foo"),
        _r("node", 9204, Point(77.63002, 12.9700), amenity="school", name="Foo"),               # ~2 m diff category: kept
        _r("node", 9205, Point(77.6310, 12.9800), amenity="fast_food"),
        _r("node", 9206, Point(77.63103, 12.9800), amenity="fast_food"),                         # unnamed pair: kept
        _r("node", 9301, Point(77.6000, 12.9300), amenity="hospital", name="City Hospital"),    # also in healthcare layer
        _r("node", 9401, Point(77.6100, 12.9300), amenity="place_of_worship", name="Temple"),   # category not selected
        _r("node", 9402, Point(77.6110, 12.9300), amenity="bench"),                              # other_amenity not selected
        _r("node", 9403, Point(77.9, 12.9), amenity="school", name="Outside"),                  # outside boundary
    ]
    cats = ["school", "college", "bank", "restaurant", "cafe", "library", "marketplace", "bus_station"]
    for k in range(n_poi):
        lon, lat = pt_in(box(77.52, 12.92, 77.68, 13.03))
        am.append(_r("node", 20000 + k, Point(lon, lat), amenity=cats[k % len(cats)], name=f"POI {k}" if k % 3 else None))
    amenities = _frame(am)
    hc = [_r("node", 9301, Point(77.6000, 12.9300), healthcare="hospital", amenity="hospital", name="City Hospital"),
          _r("way", 9301, sq(77.5400, 13.0200, 30), healthcare="clinic", name="Way Clinic")]       # same number, different type
    for k in range(8):
        lon, lat = pt_in(box(77.52, 12.92, 77.68, 13.03))
        hc.append(_r("node", 30000 + k, Point(lon, lat), healthcare="clinic" if k % 2 else "doctor", name=f"Clinic {k}"))
    healthcare = _frame(hc)
    le = [_r("way", 9501, sq(77.5500, 13.0000, 120), leisure="park", name="Test Park"),
          _r("node", 9502, Point(77.5600, 13.0100), leisure="pitch"),                              # value not selected
          _r("node", 9503, Point(77.5700, 13.0100), leisure="playground", name="Swing")]
    for k in range(5):
        lon, lat = pt_in(box(77.52, 12.92, 77.68, 13.03))
        le.append(_r("way", 40000 + k, sq(lon, lat, 60), leisure="park", name=f"Park {k}"))
    leisure = _frame(le)

    for name, gdf in dict(buildings=buildings, landuse=landuse, amenities=amenities, healthcare=healthcare, leisure=leisure).items():
        gdf.to_parquet(os.path.join(geo, f"{name}.parquet"), index=False)
    bpath = os.path.join(dirpath, "boundary.geojson")
    with open(bpath, "w") as f:
        json.dump({"type": "FeatureCollection", "features": [{"type": "Feature", "properties": {"name": "fixture"},
                                                              "geometry": mapping(BOUNDARY)}]}, f)
    return geo, bpath


TEST_OVERRIDES = {"n_agents": 300, "destinations": {"max_share_of_population": 1.0, "min_capacity": 3},
                  "assignment": {"candidate_k": 15, "radius_m": 4000.0},
                  "sensitivity": {"enabled": False}}
