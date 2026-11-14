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


# Household layer (OPTIONAL, default OFF). EXPERIMENTAL synthetic assumption: the size PMF below is a placeholder that
# makes sizes 1-6 possible. It is NOT measured Bengaluru (or any census) demographic data. The block is deliberately absent
# from config/synthpop_default.json so that legacy configurations, their hashes and their outputs stay unchanged.
HOUSEHOLD_DEFAULTS = {
    "enabled": False,
    "size_pmf": {"1": 0.15, "2": 0.20, "3": 0.25, "4": 0.25, "5": 0.10, "6": 0.05},
    "max_households_per_building": 4,
}
HOUSEHOLD_SIZES = (1, 2, 3, 4, 5, 6)


def household_settings(cfg):
    """Merged household settings (defaults + cfg['residential']['households']); unknown keys are rejected."""
    user = cfg.get("residential", {}).get("households", {})
    if not isinstance(user, dict):
        raise ConfigError("residential.households must be an object")
    unknown = set(user) - set(HOUSEHOLD_DEFAULTS)
    if unknown:
        raise ConfigError(f"unknown residential.households keys: {sorted(unknown)}")
    merged = deep_merge(HOUSEHOLD_DEFAULTS, user)
    if "size_pmf" in user:  # a user PMF REPLACES the placeholder default; it is never blended key-by-key with it
        merged["size_pmf"] = copy.deepcopy(user["size_pmf"])
    return merged


def household_pmf(settings):
    """Validated {size:int -> probability} restricted to sizes with p > 0."""
    raw = settings["size_pmf"]
    if not isinstance(raw, dict) or not raw:
        raise ConfigError("households.size_pmf must be a non-empty object {size: probability}")
    pmf = {}
    for k, v in raw.items():
        try:
            size = int(k)
        except (TypeError, ValueError):
            raise ConfigError(f"households.size_pmf key {k!r} is not an integer size")
        if str(size) != str(k) or size not in HOUSEHOLD_SIZES:
            raise ConfigError(f"households.size_pmf size {k!r} outside supported sizes {HOUSEHOLD_SIZES}")
        if isinstance(v, bool) or not isinstance(v, (int, float)) or v != v or v < 0 or v in (float("inf"),):
            raise ConfigError(f"households.size_pmf[{k}] must be a finite number >= 0")
        pmf[size] = float(v)
    total = sum(pmf.values())
    if abs(total - 1.0) > 1e-6:
        raise ConfigError(f"households.size_pmf must sum to 1 (got {total:.9g}); it is never silently renormalised")
    pmf = {s: p for s, p in sorted(pmf.items()) if p > 0}
    if not pmf:
        raise ConfigError("households.size_pmf has no positive probability")
    return pmf


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
    hh = household_settings(cfg)
    _need(isinstance(hh["enabled"], bool), "residential.households.enabled must be true or false")
    mhb = hh["max_households_per_building"]
    _need(isinstance(mhb, int) and not isinstance(mhb, bool) and 1 <= mhb <= 1000, "households.max_households_per_building must be an int in [1, 1000]")
    pmf = household_pmf(hh)
    if hh["enabled"]:
        _need(mhb * max(pmf) <= r["max_agents_per_home"],
              f"max_households_per_building ({mhb}) x largest household size ({max(pmf)}) exceeds residential.max_agents_per_home ({r['max_agents_per_home']})")
    _need(all(s > 0 for s in cfg["sensitivity"]["capacity_slack"]), "sensitivity slack values must be >0")


def canonical_json(obj):
    return json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=True)


def config_hash(cfg):
    return hashlib.sha256(canonical_json(cfg).encode()).hexdigest()
