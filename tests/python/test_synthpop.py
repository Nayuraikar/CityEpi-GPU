import copy
import hashlib
import importlib.util
import json
import os
import shutil

import numpy as np
import pandas as pd
import pytest

pytest.importorskip("geopandas")
pytest.importorskip("pyarrow")
pytest.importorskip("scipy")

import geo_fixtures as F  # noqa: E402
from synthpop import assign as A  # noqa: E402
from synthpop import cepop  # noqa: E402
from synthpop import config as C  # noqa: E402
from synthpop import destinations as Dm  # noqa: E402
from synthpop import generate as G  # noqa: E402
from synthpop import load as Ld  # noqa: E402
from synthpop import residential as R  # noqa: E402
from synthpop import validate as V  # noqa: E402
from synthpop.util import Recorder  # noqa: E402

ROOT = C.ROOT


@pytest.fixture(scope="session")
def geo(tmp_path_factory):
    d = tmp_path_factory.mktemp("fixture")
    geo_dir, bpath = F.build(str(d))
    return geo_dir, bpath


def cfg_(**over):
    return C.load_config(None, C.deep_merge(F.TEST_OVERRIDES, over))


def load_all(geo):
    geo_dir, bpath = geo
    rec, dec = Recorder(), []
    b = Ld.load_boundary(bpath)
    layers = {n: Ld.read_layer(n, os.path.join(geo_dir, f"{n}.parquet"), b, rec, dec, filter_boundary=(n != "landuse")) for n in C.LAYERS}
    return layers, rec, dec


def sha(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()


# ------------------------------------------------------------------ config
def test_config_defaults_valid_and_hash_stable():
    c = C.load_config()
    assert c["n_agents"] == 100000 and C.config_hash(c) == C.config_hash(C.load_config())
    assert C.config_hash(c) != C.config_hash(C.load_config(None, {"seed": 43}))


@pytest.mark.parametrize("bad", [{"n_agents": 0}, {"seed": -1}, {"residential": {"include_tiers": []}},
                                 {"residential": {"area_floor_m2": 600.0}}, {"assignment": {"kernel": {"type": "gauss"}}},
                                 {"destinations": {"include_categories": ["nonsense"]}}, {"dedup": {"layer_priority": ["buildings"]}}])
def test_config_rejects_bad(bad):
    with pytest.raises(C.ConfigError):
        C.load_config(None, bad)


def test_vocab_matches_audit_script():
    spec = importlib.util.spec_from_file_location("audit", os.path.join(ROOT, "scripts", "audit_osm_layers.py"))
    audit = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(audit)
    except SystemExit:
        pytest.skip("audit script deps unavailable")
    v = C.load_config()["vocab"]
    pairs = {"res_explicit": audit.RES_EXPLICIT, "edu_amenity": audit.EDU_AMENITY, "edu_building": audit.EDU_BUILDING,
             "health_amenity": audit.HEALTH_AMENITY, "health_building": audit.HEALTH_BUILDING, "ind_building": audit.IND_BUILDING,
             "office_building": audit.OFFICE_BUILDING, "office_amenity": audit.OFFICE_AMENITY, "com_building": audit.COM_BUILDING,
             "retail_amenity": audit.RETAIL_AMENITY, "civic_amenity": audit.CIVIC_AMENITY, "civic_building": audit.CIVIC_BUILDING,
             "worship_building": audit.WORSHIP_BUILDING}
    for k, s in pairs.items():
        assert set(v[k]) == set(s), k
    assert v["category_order"] == audit.ACT_ORDER


# ------------------------------------------------------------------ load
def test_load_records_exclusions(geo):
    layers, rec, dec = load_all(geo)
    ex = {(e["layer"], e["reason"]): e["count"] for e in rec.exclusion_list()}
    assert ex[("buildings", "missing_geometry")] == 1
    assert ex[("buildings", "outside_boundary")] == 1
    assert ex[("buildings", "exact_key_duplicate_same_layer")] == 1
    assert ex[("amenities", "outside_boundary")] == 1
    assert any(d["decision"] == "exact_key_duplicate_same_layer" and d["key_a"] == "way/9010" for d in dec)
    for L in layers.values():
        assert L.df["key"].is_unique and len(L.df) == len(L.geoms)
    # deterministic order by (osm_type, osm_id)
    d = layers["buildings"].df
    assert list(d.sort_values(["osm_type", "osm_id"]).index) == list(d.index)


def test_loader_rejects_wrong_schema(tmp_path, geo):
    import geopandas as gpd
    from shapely.geometry import Point
    g = gpd.GeoDataFrame({"id": [1], "geometry": [Point(77.6, 12.97)]}, crs="EPSG:4326")  # no osm_type
    p = tmp_path / "x.parquet"; g.to_parquet(p)
    with pytest.raises(ValueError, match="osm_type"):
        Ld.read_layer("x", str(p), Ld.load_boundary(geo[1]), Recorder(), [])
    g2 = gpd.GeoDataFrame({"id": [1], "osm_type": ["node"], "geometry": [Point(77.6, 12.97)]})  # no CRS
    g2.to_parquet(p)
    with pytest.raises(ValueError, match="CRS"):
        Ld.read_layer("x", str(p), Ld.load_boundary(geo[1]), Recorder(), [])


# ------------------------------------------------------------------ residential
def test_residential_tiers_weights_and_landuse(geo):
    layers, rec, _ = load_all(geo)
    cfg = cfg_()
    homes, st = R.build_homes(layers["buildings"], layers["landuse"], cfg, rec)
    assert set(homes["tier"]) <= {"A", "B"} and "C" not in set(homes["tier"])
    assert st["tier_counts"]["C"] > 0 and st["tier_counts"]["YES_ACTIVITY_TAGGED"] == 1
    assert st["buildings_matching_multiple_residential_landuse_polygons"] >= 1
    h = homes.set_index("key")
    assert h.loc["way/9001", "landuse_key"] == "way/1002"          # smallest containing polygon wins, counted once
    assert homes["key"].is_unique
    assert "way/9005" not in h.index and "way/9008" not in h.index and "way/9004" not in h.index
    r = cfg["residential"]
    assert h.loc["way/9002", "weight"] == pytest.approx(r["area_cap_m2"])        # cap
    assert h.loc["way/9003", "weight"] == pytest.approx(r["area_floor_m2"])      # floor
    assert st["weight_area_cap_hits"] >= 1 and st["weight_area_floor_hits"] >= 1
    ex = {(e["reason"]): e["count"] for e in rec.exclusion_list() if e["stage"] == "residential"}
    assert ex["tier_C_building_yes_outside_residential_landuse"] == st["tier_counts"]["C"]


def test_tier_c_optional_and_levels(geo):
    layers, rec, _ = load_all(geo)
    h1, s1 = R.build_homes(layers["buildings"], layers["landuse"], cfg_(), Recorder())
    h2, s2 = R.build_homes(layers["buildings"], layers["landuse"], cfg_(residential={"include_tiers": ["A", "B", "C"]}), Recorder())
    assert len(h2) == len(h1) + s1["tier_counts"]["C"] and "C" in set(h2["tier"])
    h3, _ = R.build_homes(layers["buildings"], layers["landuse"], cfg_(residential={"use_levels": True}), Recorder())
    a = h3[h3["tier"] == "A"].set_index("key")["weight"]
    b = h1[h1["tier"] == "A"].set_index("key")["weight"]
    assert (a >= b.reindex(a.index) - 1e-9).all() and (a > b.reindex(a.index)).any()


# ------------------------------------------------------------------ destinations
def dedup_run(geo, **over):
    layers, rec, dec = load_all(geo)
    cfg = cfg_(**over)
    Cn, _ = Dm.collect_candidates(layers, cfg, rec)
    M, st = Dm.dedup(Cn, cfg, dec, rec)
    return layers, rec, dec, cfg, Cn, M, st


def test_destination_dedup_rules(geo):
    layers, rec, dec, cfg, Cn, M, st = dedup_run(geo)
    keys = set(M["key"])
    d = pd.DataFrame(dec)
    # exact key across layers merged; node/9301 vs way/9301 NOT merged (type is part of identity)
    assert "node/9301" in keys and "way/9301" in keys
    m = M.set_index("key").loc["node/9301"]
    assert m["n_merged"] == 2 and m["source_layers"] == "healthcare|amenities" and m["category"] == "healthcare"
    assert ((d["decision"] == "exact_key_merge") & (d["key_a"] == "node/9301")).sum() == 1
    # same category + same normalised name within radius -> merged (one survives)
    assert ("node/9201" in keys) != ("node/9202" in keys)
    assert (d["decision"] == "name_category_proximity_merge").sum() == 1
    # close but different category / unnamed -> kept distinct and logged, never merged on proximity alone
    assert {"node/9203", "node/9204", "node/9205", "node/9206"} <= keys
    kd = d[d["decision"] == "kept_distinct_close_pair"]
    assert any({r.key_a, r.key_b} == {"node/9203", "node/9204"} and r.reason == "different category" for r in kd.itertuples())
    assert any({r.key_a, r.key_b} == {"node/9205", "node/9206"} and "unnamed" in r.reason for r in kd.itertuples())
    assert M["key"].is_unique
    # POIs inside buildings kept as distinct facilities
    assert {"node/9101", "node/9102", "way/9006", "way/9007"} <= keys
    stat = Dm.add_inside_building(M, layers["buildings"], rec)
    ib = M.set_index("key")["inside_building"]
    assert ib["node/9101"] and ib["node/9102"] and not ib["way/9006"]
    assert stat["destinations_inside_other_building_preserved"] >= 2
    # category selection / exclusions recorded; landuse never a destination
    ex = {(e["layer"], e["reason"]) for e in rec.exclusion_list()}
    assert ("amenities", "category_not_selected:worship") in ex and ("amenities", "category_not_selected:other_amenity") in ex
    assert ("leisure", "leisure_value_not_selected") in ex
    assert ("landuse", "landuse_is_spatial_context_not_a_destination") in ex
    assert not any(k.startswith("way/100") for k in keys)
    assert "way/9005" in keys                       # building=yes + amenity=cafe is a legitimate destination
    assert set(M["category"]) <= set(cfg["destinations"]["include_categories"])


def test_unnamed_merge_optional(geo):
    *_, dec, cfg, Cn, M, st = dedup_run(geo, dedup={"merge_unnamed_same_category_within_m": 10.0})
    d = pd.DataFrame(dec)
    assert (d["decision"] == "unnamed_category_proximity_merge").sum() >= 1
    assert not ({"node/9205", "node/9206"} <= set(M["key"]))


def test_dedup_deterministic(geo):
    a = dedup_run(geo)
    b = dedup_run(geo)
    pd.testing.assert_frame_equal(a[5], b[5])
    assert a[2] == b[2]


def test_capacity_weights(geo):
    *_, cfg, Cn, M, st = dedup_run(geo)
    info = Dm.add_capacity_weights(M, cfg)
    d = cfg["destinations"]
    assert (M["weight"] > 0).all() and info["point_features_using_default_area"] > 0
    assert M["weight"].max() <= max(d["category_weight"].values()) * d["area_cap_m2"] ** d["alpha"] + 1e-9


# ------------------------------------------------------------------ apportionment and assignment
def test_apportion_exact_caps_deterministic():
    rng = np.random.default_rng(0)
    w = rng.lognormal(0, 1.5, 5000)
    caps = np.full(5000, 5)
    c1, _ = A.apportion_homes(w, caps, 3000, 11)
    c2, _ = A.apportion_homes(w, caps, 3000, 11)
    c3, _ = A.apportion_homes(w, caps, 3000, 12)
    assert c1.sum() == 3000 and (c1 <= 5).all() and np.array_equal(c1, c2) and not np.array_equal(c1, c3)
    # expectation follows weights (loose: heavy-weight half holds clearly more agents)
    order = np.argsort(w)
    assert c1[order[-2500:]].sum() > 1.5 * c1[order[:2500]].sum()


def test_apportion_water_filling_and_infeasible():
    w = np.array([1000.0, 1, 1, 1])
    c, info = A.apportion_homes(w, np.array([10, 10, 10, 10]), 20, 1)
    assert c[0] == 10 and c.sum() == 20 and info["homes_fixed_at_cap"] >= 1
    with pytest.raises(A.AssignmentError):
        A.apportion_homes(w, np.array([1, 1, 1, 1]), 5, 1)


def toy_assign(n=400, nd=60, seed=3, **acfg):
    rng = np.random.default_rng(seed)
    ax = rng.uniform(0, 10000, (n, 2)); dx = rng.uniform(0, 10000, (nd, 2))
    w = rng.uniform(1, 5, nd)
    cap = np.full(nd, int(np.ceil(3 * n / nd)))
    cfg = C.load_config()["assignment"]; cfg.update(acfg)
    return ax, dx, w, cap, cfg


def test_assignment_complete_caps_deterministic():
    ax, dx, w, cap, cfg = toy_assign(candidate_k=10, radius_m=3000.0)
    r1 = A.assign_destinations(ax, dx, w, cap, cfg, 5)
    r2 = A.assign_destinations(ax, dx, w, cap, cfg, 5)
    r3 = A.assign_destinations(ax, dx, w, cap, cfg, 6)
    assert r1["n_unassigned"] == 0 and (r1["dest"] >= 0).all()
    assert (np.bincount(r1["dest"], minlength=len(cap)) <= cap).all()
    assert np.array_equal(r1["dest"], r2["dest"]) and not np.array_equal(r1["dest"], r3["dest"])
    assert np.allclose(r1["distance_m"], np.hypot(*(ax - dx[r1["dest"]]).T))


def test_assignment_is_distance_sensitive():
    ax, dx, w, cap, _ = toy_assign(n=300, nd=80)
    cap = np.full(80, 300)
    near = A.assign_destinations(ax, dx, w, cap, dict(C.load_config()["assignment"], kernel={"type": "exponential", "scale_m": 500.0, "power_exponent": 2, "power_min_distance_m": 100}), 1)
    far = A.assign_destinations(ax, dx, w, cap, dict(C.load_config()["assignment"], kernel={"type": "exponential", "scale_m": 50000.0, "power_exponent": 2, "power_min_distance_m": 100}), 1)
    assert np.nanmean(near["distance_m"]) < 0.7 * np.nanmean(far["distance_m"])
    pw = A.assign_destinations(ax, dx, w, cap, dict(C.load_config()["assignment"], kernel={"type": "power", "scale_m": 1, "power_exponent": 3.0, "power_min_distance_m": 100}), 1)
    assert pw["n_unassigned"] == 0 and np.nanmean(pw["distance_m"]) < np.nanmean(far["distance_m"])


def test_assignment_fallback_stages_and_failure():
    ax, dx, w, cap, cfg = toy_assign(n=300, nd=30, candidate_k=3, radius_m=300.0)   # tiny radius forces widening
    r = A.assign_destinations(ax, dx, w, cap, cfg, 2)
    assert r["n_unassigned"] == 0 and r["stage"].max() >= 1
    assert sum(s["placed"] for s in r["stages"]) == 300
    with pytest.raises(A.AssignmentError, match="capacity"):
        A.assign_destinations(ax, dx, w, np.full(30, 5), cfg, 2)
    # max_rounds exhausted in every stage -> failures are reported, not hidden
    r2 = A.assign_destinations(ax, dx, w, np.full(30, 10), dict(cfg, max_rounds=1, fallback_radius_multipliers=[2.0]), 2)
    assert r2["n_unassigned"] == int((r2["dest"] < 0).sum()) > 0


def test_destination_caps_bounds():
    w = np.r_[np.full(99, 1.0), 1000.0]
    d = C.load_config()["destinations"]
    cap, info = A.destination_caps(w, 100000, d)
    assert cap.max() == int(np.ceil(0.005 * 100000)) and info["n_limited_by_share_cap"] >= 1
    assert cap.min() >= d["min_capacity"]
    capu, _ = A.destination_caps(w, 100, dict(d, max_share_of_population=1.0), slack=1e9)
    assert capu.max() <= 100


# ------------------------------------------------------------------ end to end
@pytest.fixture(scope="module")
def run_dir(geo, tmp_path_factory):
    base = tmp_path_factory.mktemp("runs")
    out = str(base / "data" / "synthetic" / "run1")
    rep = G.run(cfg_(), geo[0], geo[1], out)
    return out, rep


def test_full_run_outputs_and_validation(run_dir):
    out, rep = run_dir
    assert rep["status"] == "ok", rep["validation"]["failed"]
    for f in ["population.cepop", "locations.geoparquet", "agents.parquet", "dedup_decisions.parquet", "manifest.json",
              "report.json", "report.md", "config.json"]:
        assert os.path.isfile(os.path.join(out, f)), f
    arr = cepop.read_cepop(os.path.join(out, "population.cepop"))
    assert len(arr["state"]) == 300 and not arr["state"].any() and not arr["timer"].any()
    assert len(arr["loc_type"]) == rep["counts"]["locations"]
    assert rep["validation"]["passed"] and rep["validation"]["n_checks"] >= 30
    j = json.load(open(os.path.join(out, "report.json")))
    for k in ("exclusions", "dedup", "classification", "capacity", "assignment", "distributions", "checksums", "spatial_fidelity",
              "audit_reference_comparison", "disclaimers", "inputs"):
        assert k in j, k
    assert "SYNTHETIC" in open(os.path.join(out, "report.md")).read()
    man = json.load(open(os.path.join(out, "manifest.json")))
    assert man["files"]["population.cepop"]["sha256"] == sha(os.path.join(out, "population.cepop"))
    loc = pd.read_parquet(os.path.join(out, "locations.geoparquet"))
    assert {"location_id", "osm_type", "osm_id", "source_layers", "category", "loc_type", "lon", "lat", "occupancy", "capacity"} <= set(loc.columns)
    assert loc["occupancy"].sum() == 600


def test_determinism_and_seed_sensitivity(geo, run_dir, tmp_path):
    out1, _ = run_dir
    out2 = str(tmp_path / "data" / "synthetic" / "run2")
    G.run(cfg_(), geo[0], geo[1], out2)
    for f in ["population.cepop", "agents.parquet", "locations.geoparquet", "dedup_decisions.parquet", "config.json"]:
        assert sha(os.path.join(out1, f)) == sha(os.path.join(out2, f)), f
    out3 = str(tmp_path / "data" / "synthetic" / "run3")
    G.run(cfg_(seed=43), geo[0], geo[1], out3)
    assert sha(os.path.join(out1, "population.cepop")) != sha(os.path.join(out3, "population.cepop"))


def test_agent_count_and_default():
    assert C.load_config()["n_agents"] == 100000
    assert cfg_(n_agents=123)["n_agents"] == 123


def test_sensitivity_section(geo, tmp_path):
    out = str(tmp_path / "data" / "synthetic" / "s")
    rep = G.run(cfg_(sensitivity={"enabled": True, "capacity_slack": [1.5, 3.0, 1e9]}), geo[0], geo[1], out)
    assert len(rep["cap_sensitivity"]) == 3 and all("capacity" in s for s in rep["cap_sensitivity"])


def test_assignment_failure_recorded_in_report(geo, tmp_path):
    out = str(tmp_path / "data" / "synthetic" / "f")
    with pytest.raises(A.AssignmentError):
        G.run(cfg_(destinations={"max_share_of_population": 0.001, "min_capacity": 1, "capacity_slack": 0.1}), geo[0], geo[1], out)
    rep = json.load(open(os.path.join(out, "report.json")))
    assert rep["status"] == "failed" and rep["failure"]["type"] == "AssignmentError" and "capacity" in rep["failure"]["message"]
    assert os.path.isfile(os.path.join(out, "manifest.json"))


def test_sources_not_modified(geo, tmp_path):
    files = [os.path.join(geo[0], f"{n}.parquet") for n in C.LAYERS] + [geo[1]]
    before = [sha(f) for f in files]
    G.run(cfg_(), geo[0], geo[1], str(tmp_path / "data" / "synthetic" / "m"))
    assert before == [sha(f) for f in files]


def test_out_dir_guards(geo, tmp_path):
    with pytest.raises(ValueError, match="data/synthetic"):
        G.check_out_dir(str(tmp_path / "elsewhere"), geo[0])
    G.check_out_dir(str(tmp_path / "elsewhere"), geo[0], allow_outside=True)
    with pytest.raises(ValueError, match="source geo"):
        G.check_out_dir(os.path.join(geo[0], "data", "synthetic", "x"), geo[0])
    busy = tmp_path / "data" / "synthetic" / "busy"; busy.mkdir(parents=True); (busy / "f").write_text("x")
    with pytest.raises(ValueError, match="not empty"):
        G.check_out_dir(str(busy), geo[0])
    G.check_out_dir(str(busy), geo[0], overwrite=True)


# ------------------------------------------------------------------ validator catches corruption
def _copy(run_dir, tmp_path):
    dst = tmp_path / "c"
    shutil.copytree(run_dir[0], dst)
    return str(dst)


def _failed(d, geo):
    return {c["name"] for c in V.validate_outputs(d, geo[1], cfg_()) if not c["passed"]}


def test_validator_detects_corruption(run_dir, geo, tmp_path):
    d = _copy(run_dir, tmp_path)
    assert not _failed(d, geo)
    arr = cepop.read_cepop(os.path.join(d, "population.cepop"))

    def rewrite(**kw):
        a = dict(arr); a.update(kw)
        cepop.write_cepop(os.path.join(d, "population.cepop"), a["state"], a["timer"], a["home_loc"], a["work_loc"], a["loc_type"], a["occupancy"])

    occ = arr["occupancy"].copy(); occ[0] += 1
    rewrite(occupancy=occ)
    assert "occupancy recomputed == cepop occupancy" in _failed(d, geo)
    rewrite()
    w = arr["work_loc"].copy(); w[0] = arr["home_loc"][0]
    rewrite(work_loc=w, occupancy=cepop.compute_occupancy(arr["home_loc"], w, len(arr["loc_type"])))
    assert "home_loc -> HOME, work_loc -> WORK" in _failed(d, geo)
    rewrite()
    st = arr["state"].copy(); st[0] = 2
    rewrite(state=st)
    assert "all agents start S with timer 0" in _failed(d, geo)
    rewrite()
    assert not _failed(d, geo)
    # move a point outside the boundary
    import geopandas as gpd
    from shapely.geometry import Point
    loc = gpd.read_parquet(os.path.join(d, "locations.geoparquet"))
    loc.loc[0, "geometry"] = Point(78.5, 12.9); loc.loc[0, "lon"] = 78.5
    loc.to_parquet(os.path.join(d, "locations.geoparquet"), index=False)
    f = _failed(d, geo)
    assert "all coordinates inside Bengaluru Urban boundary" in f
    # truncated cepop
    data = open(os.path.join(d, "population.cepop"), "rb").read()
    open(os.path.join(d, "population.cepop"), "wb").write(data[:-8])
    assert "cepop format (magic/version/size/CRC)" in _failed(d, geo)
