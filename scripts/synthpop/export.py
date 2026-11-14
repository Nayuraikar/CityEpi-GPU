"""Writers for population.cepop (existing CEPOP v1 codec), locations.geoparquet, agents.parquet, dedup_decisions.parquet."""
import os

import numpy as np
import pandas as pd

from . import cepop

DEDUP_COLS = ["decision_id", "decision", "key_a", "key_b", "layer_a", "layer_b", "category_a", "category_b", "name_a", "name_b",
              "distance_m", "reason"]


def build_locations(homes, dests, home_counts, dest_occ):
    import geopandas as gpd
    H, D = len(homes), len(dests)
    ids = np.arange(H + D, dtype=np.uint32)
    df = pd.DataFrame({
        "location_id": ids,
        "loc_type": np.r_[np.zeros(H), np.ones(D)].astype(np.uint8),
        "loc_type_name": np.r_[np.full(H, "HOME", dtype=object), np.full(D, "WORK", dtype=object)],
        "osm_type": np.r_[homes["osm_type"].to_numpy(dtype=object), dests["osm_type"].to_numpy(dtype=object)],
        "osm_id": np.r_[homes["osm_id"].to_numpy(), dests["osm_id"].to_numpy()].astype(np.int64),
        "source_layers": np.r_[np.full(H, "buildings", dtype=object), dests["source_layers"].to_numpy(dtype=object)],
        "category": np.r_[np.full(H, "residential", dtype=object), dests["category"].to_numpy(dtype=object)],
        "tier": np.r_[homes["tier"].to_numpy(dtype=object), np.full(D, "", dtype=object)],
        "name": np.r_[homes["name_raw"].to_numpy(dtype=object), dests["name_raw"].to_numpy(dtype=object)],
        "footprint_area_m2": np.r_[homes["area_m2"].to_numpy(), dests["area_m2"].to_numpy()].astype(np.float64),
        "weight": np.r_[homes["weight"].to_numpy(), dests["weight"].to_numpy()].astype(np.float64),
        "capacity": np.r_[homes["capacity"].to_numpy(), dests["capacity"].to_numpy()].astype(np.int64),
        "occupancy": np.r_[home_counts, dest_occ].astype(np.int64),
        "landuse_context": np.r_[homes["landuse_key"].to_numpy(dtype=object), np.full(D, "", dtype=object)],
        "inside_building": np.r_[np.zeros(H, bool), dests["inside_building"].to_numpy()],
        "n_merged_records": np.r_[np.ones(H), dests["n_merged"].to_numpy()].astype(np.int32),
        "lon": np.r_[homes["lon"].to_numpy(), dests["lon"].to_numpy()].astype(np.float64),
        "lat": np.r_[homes["lat"].to_numpy(), dests["lat"].to_numpy()].astype(np.float64),
    })
    return gpd.GeoDataFrame(df, geometry=gpd.points_from_xy(df["lon"], df["lat"]), crs="EPSG:4326")


def write_all(out_dir, locations, home_of_agent, dest_of_agent, distance, stage, dest_category_of_agent, decisions):
    """Return {filename: payload crc / path info}. Occupancy for CEPOP is recomputed from the agent arrays."""
    n, nl = len(home_of_agent), len(locations)
    state = np.zeros(n, np.uint8)
    timer = np.zeros(n, np.uint16)
    loc_type = locations["loc_type"].to_numpy(np.uint8)
    occ = cepop.compute_occupancy(home_of_agent, dest_of_agent, nl)
    if not np.array_equal(occ.astype(np.int64), locations["occupancy"].to_numpy()):
        raise AssertionError("locations.occupancy disagrees with recomputed occupancy")
    crc = cepop.write_cepop(os.path.join(out_dir, "population.cepop"), state, timer,
                            home_of_agent.astype(np.uint32), dest_of_agent.astype(np.uint32), loc_type, occ)
    locations.to_parquet(os.path.join(out_dir, "locations.geoparquet"), index=False, compression="snappy")
    pd.DataFrame({"agent_id": np.arange(n, dtype=np.uint32), "home_loc": home_of_agent.astype(np.uint32),
                  "dest_loc": dest_of_agent.astype(np.uint32), "dest_category": dest_category_of_agent,
                  "distance_m": distance.astype(np.float64), "assignment_stage": stage.astype(np.int16)}
                 ).to_parquet(os.path.join(out_dir, "agents.parquet"), index=False, compression="snappy")
    d = pd.DataFrame(decisions, columns=DEDUP_COLS[1:]) if decisions else pd.DataFrame({c: pd.Series(dtype=object) for c in DEDUP_COLS[1:]})
    d.insert(0, "decision_id", np.arange(len(d), dtype=np.int64))
    d["distance_m"] = d["distance_m"].astype(np.float64)
    d.to_parquet(os.path.join(out_dir, "dedup_decisions.parquet"), index=False, compression="snappy")
    return {"cepop_payload_crc32": f"0x{crc:08x}"}
