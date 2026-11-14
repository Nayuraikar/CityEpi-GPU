"""Configuration: defaults live in config/synthpop_default.json; user configs/overrides are deep-merged on top."""
import copy
import hashlib
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DEFAULT_PATH = os.path.join(ROOT, "config", "synthpop_default.json")
SCHEMA = "synthpop-config-1"
METRIC_CRS = "EPSG:32643"
GEO_CRS = "EPSG:4326"
LAYERS = ["buildings", "landuse", "amenities", "healthcare", "leisure"]
DEST_LAYERS = ["buildings", "amenities", "healthcare", "leisure"]  # landuse is spatial context only


class ConfigError(ValueError):
    pass


def deep_merge(base, over):
    out = copy.deepcopy(base)
    for k, v in over.items():
        if isinstance(v, dict) and isinstance(out.get(k), dict):
            out[k] = deep_merge(out[k], v)
        else:
            out[k] = copy.deepcopy(v)
    return out


def set_path(d, dotted, value):
    keys = dotted.split(".")
    cur = d
    for k in keys[:-1]:
        cur = cur.setdefault(k, {})
    cur[keys[-1]] = value


def load_config(path=None, overrides=None):
    with open(DEFAULT_PATH) as f:
        cfg = json.load(f)
    if path:
        with open(path) as f:
            cfg = deep_merge(cfg, json.load(f))
    if overrides:
        cfg = deep_merge(cfg, overrides)
    validate(cfg)
    return cfg


def _need(cond, msg):
    if not cond:
        raise ConfigError(msg)


def validate(cfg):
    _need(cfg.get("schema") == SCHEMA, f"config schema must be {SCHEMA}")
    _need(isinstance(cfg["n_agents"], int) and 1 <= cfg["n_agents"] < 2**32, "n_agents must be an int in [1, 2^32)")
    _need(isinstance(cfg["seed"], int) and 0 <= cfg["seed"] < 2**64, "seed must be an int in [0, 2^64)")
    r, d, a, dd = cfg["residential"], cfg["destinations"], cfg["assignment"], cfg["dedup"]
    _need(set(r["include_tiers"]) <= {"A", "B", "C"} and r["include_tiers"], "residential.include_tiers must be a non-empty subset of A,B,C")
    _need(0 < r["area_floor_m2"] <= r["area_cap_m2"], "residential area floor must be >0 and <= cap")
    _need(r["alpha"] >= 0 and r["max_agents_per_home"] >= 1, "residential.alpha>=0, max_agents_per_home>=1")
    _need(all(r["tier_factor"].get(t, 0) > 0 for t in r["include_tiers"]), "tier_factor must be >0 for included tiers")
    order = cfg["vocab"]["category_order"]
    _need(d["include_categories"] and set(d["include_categories"]) <= set(order), "destinations.include_categories invalid")
    _need(all(d["category_weight"].get(c, 0) > 0 for c in d["include_categories"]), "category_weight must be >0 for included categories")
    _need(0 < d["area_floor_m2"] <= d["area_cap_m2"] and d["alpha"] >= 0 and d["poi_default_area_m2"] > 0, "destination area parameters invalid")
    _need(d["min_capacity"] >= 1 and d["capacity_slack"] > 0 and 0 < d["max_share_of_population"] <= 1, "capacity parameters invalid")
    _need(dd["name_merge_radius_m"] >= 0 and dd["log_radius_m"] >= 0 and dd["merge_unnamed_same_category_within_m"] >= 0, "dedup radii must be >=0")
    _need(set(dd["layer_priority"]) == set(DEST_LAYERS), f"dedup.layer_priority must list exactly {DEST_LAYERS}")
    k = a["kernel"]
    _need(k["type"] in ("exponential", "power"), "assignment.kernel.type must be exponential or power")
    _need(k["scale_m"] > 0 and k["power_exponent"] > 0 and k["power_min_distance_m"] > 0, "kernel parameters must be >0")
    _need(a["candidate_k"] >= 1 and a["radius_m"] > 0 and a["max_rounds"] >= 1, "assignment parameters invalid")
    _need(all(m > 1 for m in a["fallback_radius_multipliers"]), "fallback_radius_multipliers must be >1")
    _need(all(s > 0 for s in cfg["sensitivity"]["capacity_slack"]), "sensitivity slack values must be >0")


def canonical_json(obj):
    return json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=True)


def config_hash(cfg):
    return hashlib.sha256(canonical_json(cfg).encode()).hexdigest()
