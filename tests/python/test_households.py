import json
import os
import shutil
from math import gcd

import numpy as np
import pandas as pd
import pytest

pytest.importorskip("geopandas")
pytest.importorskip("pyarrow")
pytest.importorskip("scipy")

import geo_fixtures as F  # noqa: E402
import golden_util  # noqa: E402
from synthpop import assign as A  # noqa: E402
from synthpop import cepop  # noqa: E402
from synthpop import config as C  # noqa: E402
from synthpop import generate as G  # noqa: E402
from synthpop import households as Hh  # noqa: E402
from synthpop import util as U  # noqa: E402
from synthpop import validate as V  # noqa: E402

ROOT = C.ROOT
FULL = {1: 0.15, 2: 0.20, 3: 0.25, 4: 0.25, 5: 0.10, 6: 0.05}
HH_ON = {"residential": {"households": {"enabled": True}}}


@pytest.fixture(scope="session")
def geo(tmp_path_factory):
    return F.build(str(tmp_path_factory.mktemp("hhfixture")))


def cfg_(**over):
    return C.load_config(None, C.deep_merge(F.TEST_OVERRIDES, over))


def hh_cfg(**hh):
    return cfg_(residential={"households": dict({"enabled": True}, **hh)})


# ---------------------------------------------------------------- configuration
def test_defaults_disabled_and_absent_from_default_json():
    assert C.household_settings(C.load_config())["enabled"] is False
    assert "households" not in json.load(open(C.DEFAULT_PATH))["residential"]     # legacy config hash unchanged
    assert C.household_pmf(C.household_settings(C.load_config())) == FULL
    # merely adding the (disabled) block does not enable anything
    assert C.household_settings(C.load_config(None, {"residential": {"households": {"max_households_per_building": 2}}}))["enabled"] is False


@pytest.mark.parametrize("bad", [
    {"size_pmf": {"0": 1.0}}, {"size_pmf": {"7": 1.0}}, {"size_pmf": {"a": 1.0}}, {"size_pmf": {"1.5": 1.0}}, {"size_pmf": {"01": 1.0}},
    {"size_pmf": {"1": -0.1, "2": 1.1}}, {"size_pmf": {"1": 0.5, "2": 0.4}}, {"size_pmf": {"1": 0.7, "2": 0.7}},
    {"size_pmf": {"1": float("nan"), "2": 1.0}}, {"size_pmf": {"1": float("inf")}}, {"size_pmf": {"1": "0.5", "2": 0.5}},
    {"size_pmf": {}}, {"size_pmf": [0.5, 0.5]}, {"size_pmf": {"1": 0.0, "2": 0.0}}, {"size_pmf": {"1": True}},
    {"max_households_per_building": 0}, {"max_households_per_building": -1}, {"max_households_per_building": 1.5},
    {"max_households_per_building": True}, {"max_households_per_building": 1001}, {"max_households_per_building": "4"},
    {"enabled": "yes"}, {"enabled": 1}, {"unknown_key": 1},
    {"max_households_per_building": 5},                       # 5 x 6 = 30 > max_agents_per_home (25)
])
def test_malformed_household_config_rejected(bad):
    with pytest.raises(C.ConfigError):
        C.load_config(None, {"residential": {"households": dict({"enabled": True}, **bad)}})


def test_bad_households_object_and_cap_only_checked_when_enabled():
    with pytest.raises(C.ConfigError):
        C.load_config(None, {"residential": {"households": [1]}})
    with pytest.raises(C.ConfigError):   # structure errors are caught even while disabled
        C.load_config(None, {"residential": {"households": {"size_pmf": {"9": 1.0}}}})
    C.load_config(None, {"residential": {"households": {"max_households_per_building": 5}}})   # disabled: agent-cap coupling not applied
    C.load_config(None, {"residential": {"households": {"enabled": True, "max_households_per_building": 5, "size_pmf": {"1": 0.5, "5": 0.5}}}})


def test_user_pmf_replaces_default_not_merged():
    s = C.household_settings(C.load_config(None, {"residential": {"households": {"size_pmf": {"2": 0.5, "3": 0.5}}}}))
    assert s["size_pmf"] == {"2": 0.5, "3": 0.5}
    # same through the overrides path used by tests/CLI (--set residential.households.size_pmf=...)
    s2 = C.household_settings(C.load_config(None, C.deep_merge({"residential": {"households": {"size_pmf": {"4": 1.0}}}}, {})))
    assert C.household_pmf(s2) == {4: 1.0}


def test_pmf_with_zero_entries_defines_support():
    s = C.household_settings(C.load_config(None, {"residential": {"households": {"size_pmf": {"1": 0.0, "2": 0.5, "3": 0.5}}}}))
    assert C.household_pmf(s) == {2: 0.5, 3: 0.5}


# ---------------------------------------------------------------- draw_household_sizes
@pytest.mark.parametrize("seed", [0, 1, 42, 2**63 + 5])
def test_sizes_sum_exactly_for_many_n(seed):
    for n in list(range(1, 80)) + [99, 100, 101, 999, 1000, 4097, 100000]:
        s, info = Hh.draw_household_sizes(n, FULL, seed)
        assert int(s.sum()) == n and s.min() >= 1 and s.max() <= 6 and s.dtype == np.int64


def test_deterministic_same_seed_different_seed():
    a, _ = Hh.draw_household_sizes(5000, FULL, 7)
    b, _ = Hh.draw_household_sizes(5000, FULL, 7)
    c, _ = Hh.draw_household_sizes(5000, FULL, 8)
    assert np.array_equal(a, b) and not np.array_equal(a, c)


def test_sizes_follow_pmf():
    s, _ = Hh.draw_household_sizes(400000, FULL, 3)
    for k, p in FULL.items():
        assert abs((s == k).mean() - p) < 0.01
    assert abs(400000 / len(s) - sum(k * p for k, p in FULL.items())) < 0.02


def test_dedicated_stream_and_chunk_invariance():
    assert len({U.STREAM_HOME_COUNTS, U.STREAM_AGENT_ORDER, U.STREAM_ASSIGN, U.STREAM_HOUSEHOLD_SIZES, U.STREAM_HOUSEHOLD_SLOTS}) == 5
    assert (U.STREAM_HOME_COUNTS, U.STREAM_AGENT_ORDER, U.STREAM_ASSIGN) == (1, 2, 3)           # legacy streams unchanged
    # the size stream equals a manual inverse-CDF draw of the same Philox stream, whatever the chunking
    support = np.array(sorted(FULL)); cdf = np.cumsum([FULL[k] for k in support]); cdf[-1] = 1.0
    u = U.rng_for(11, U.STREAM_HOUSEHOLD_SIZES).random(3000)
    raw = support[np.minimum(np.searchsorted(cdf, u, side="right"), 5)]
    for n in (1, 7, 100, 2500):
        s, info = Hh.draw_household_sizes(n, FULL, 11)
        k = info["drawn_until_index"]
        assert np.array_equal(s[:k], raw[:k])                    # prefix identical to the raw stream
        assert 1 <= s[k] <= raw[k] and s[k] == n - raw[:k].sum()   # final household = remainder, never larger than drawn
    # drawing sizes consumes none of the legacy streams
    before = U.rng_for(11, U.STREAM_ASSIGN).random(3)
    Hh.draw_household_sizes(1000, FULL, 11)
    assert np.array_equal(before, U.rng_for(11, U.STREAM_ASSIGN).random(3))


def test_final_household_boundaries():
    s, info = Hh.draw_household_sizes(1, FULL, 5)
    assert s.tolist() == [1]
    # N equal to a single large household size
    for n in range(1, 7):
        s, _ = Hh.draw_household_sizes(n, {k: (1.0 if k == 6 else 0.0) for k in FULL} if n == 6 else FULL, 2)
        assert s.sum() == n
    s, info = Hh.draw_household_sizes(6, {6: 1.0}, 1)
    assert s.tolist() == [6] and not info["final_household_adjusted"]
    s, info = Hh.draw_household_sizes(12, {6: 1.0}, 1)
    assert s.tolist() == [6, 6]
    # forced adjustment: size-1 impossible, so the remainder must be re-composed from the support
    s, info = Hh.draw_household_sizes(7, {3: 0.5, 4: 0.5}, 1)
    assert sorted(s.tolist()) in ([3, 4],) and int(s.sum()) == 7


@pytest.mark.parametrize("pmf", [{3: 0.5, 4: 0.5}, {2: 0.3, 5: 0.7}, {2: 0.5, 3: 0.5}, {4: 0.2, 6: 0.8}, {5: 1.0}])
def test_support_is_never_violated_or_clean_error(pmf):
    g = 0
    for k in pmf:
        g = gcd(g, k)
    ok = 0
    for n in range(1, 120):
        try:
            s, _ = Hh.draw_household_sizes(n, pmf, n)
        except ValueError:
            assert n % g != 0 or n < 12 * max(pmf)      # only non-multiples of the gcd or tiny totals may be unrepresentable
            continue
        ok += 1
        assert int(s.sum()) == n and set(s.tolist()) <= set(pmf)
    for n in range(12 * max(pmf), 12 * max(pmf) + 60):   # every large multiple of the gcd must succeed
        if n % g == 0:
            s, _ = Hh.draw_household_sizes(n, pmf, 3)
            assert int(s.sum()) == n and set(s.tolist()) <= set(pmf)
            ok += 1
    assert ok > 5


def test_infeasible_totals_raise():
    with pytest.raises(ValueError):
        Hh.draw_household_sizes(3, {4: 0.5, 5: 0.5}, 1)      # smaller than any supported size
    with pytest.raises(ValueError):
        Hh.draw_household_sizes(7, {2: 0.5, 4: 0.5}, 1)      # odd total, even sizes
    with pytest.raises(ValueError):
        Hh.draw_household_sizes(5, {3: 0.5, 4: 0.5}, 1)      # not representable
    with pytest.raises(ValueError):
        Hh.draw_household_sizes(0, FULL, 1)
    with pytest.raises(ValueError):
        Hh.draw_household_sizes(10, {1: 0.4, 2: 0.4}, 1)     # pmf does not sum to 1


# ---------------------------------------------------------------- building assignment
def toy_build(n=3000, nb=1500, seed=5, cap=4, pmf=FULL):
    w = np.random.default_rng(1).lognormal(0, 1.0, nb)
    return w, Hh.build_households(n, {"max_households_per_building": cap}, pmf, w, seed)


def test_build_households_invariants():
    w, r = toy_build()
    size, hh_home, ah, home, cnt = r["household_size"], r["household_home"], r["agent_household"], r["home_of_agent"], r["home_counts"]
    H = len(size)
    assert int(size.sum()) == 3000 and len(ah) == 3000 and len(home) == 3000
    assert np.array_equal(np.bincount(ah, minlength=H), size)                    # every agent in exactly one household
    assert np.array_equal(home, hh_home[ah])                                      # every household maps to exactly one home
    assert np.array_equal(cnt, np.bincount(hh_home, weights=size, minlength=len(w)).astype(int))   # occupancy = sum of sizes
    assert (np.bincount(hh_home, minlength=len(w)) <= 4).all()
    assert (np.diff(hh_home) >= 0).all()                                          # ids ordered by building: stable
    assert cnt.max() <= 4 * 6
    assert r["stats"]["mean_household_size"] == pytest.approx(3000 / H)


def test_build_households_deterministic_and_seed_sensitive():
    _, a = toy_build(seed=9)
    _, b = toy_build(seed=9)
    _, c = toy_build(seed=10)
    for k in ("household_size", "household_home", "agent_household", "home_of_agent"):
        assert np.array_equal(a[k], b[k])
    assert not np.array_equal(a["home_of_agent"], c["home_of_agent"])


def test_household_cap_binding_and_infeasible_cases():
    w = np.random.default_rng(1).lognormal(0, 1.0, 300)
    r = Hh.build_households(3000, {"max_households_per_building": 4}, FULL, w, 5)     # ~970 households, capacity 1200 -> binds often
    per = r["households_per_building"]
    assert per.max() <= 4 and r["stats"]["buildings_at_household_cap"] >= 1 and r["stats"]["apportionment"]["homes_fixed_at_cap"] >= 1
    with pytest.raises(A.AssignmentError):
        Hh.build_households(3000, {"max_households_per_building": 1}, FULL, w, 5)     # 300 slots < households


def test_size_independent_of_building_slot():
    w, r = toy_build(n=60000, nb=30000, seed=2)
    first = r["household_size"][: len(r["household_size"]) // 2].mean()
    second = r["household_size"][len(r["household_size"]) // 2:].mean()
    assert abs(first - second) < 0.06


# ---------------------------------------------------------------- end to end
@pytest.fixture(scope="module")
def run_on(geo, tmp_path_factory):
    base = tmp_path_factory.mktemp("hhruns")
    out = str(base / "data" / "synthetic" / "on")
    return out, G.run(hh_cfg(), geo[0], geo[1], out)


def test_enabled_run_valid_and_files(run_on):
    out, rep = run_on
    assert rep["status"] == "ok", rep["validation"]["failed"]
    names = {c["name"] for c in rep["validation"]["checks"]}
    for n in ["household sizes sum to N", "household sizes within configured support", "every agent has exactly one valid household",
              "every household maps to exactly one valid HOME location", "home occupancy equals sum of member household sizes",
              "households per building <= max_households_per_building", "each agent's home_loc equals its household's home_loc"]:
        assert n in names and next(c for c in rep["validation"]["checks"] if c["name"] == n)["passed"]
    ag = pd.read_parquet(os.path.join(out, "agents.parquet"))
    hh = pd.read_parquet(os.path.join(out, "households.parquet"))
    assert list(ag.columns) == ["agent_id", "home_loc", "dest_loc", "dest_category", "distance_m", "assignment_stage", "household_id"]
    assert len(ag) == 300 and int(hh["size"].sum()) == 300 and hh["size"].between(1, 6).all()
    arr = cepop.read_cepop(os.path.join(out, "population.cepop"))
    assert len(arr["state"]) == 300 and not arr["state"].any()
    assert rep["households"]["assumption"].startswith("EXPERIMENTAL")
    hist = rep["households"]["household_size_histogram"]
    assert sum(hist.values()) == rep["households"]["households_total"] and sum(int(k) * v for k, v in hist.items()) == 300
    assert "home_occupancy_histogram" in rep["households"] and "households_per_building_histogram" in rep["households"]
    assert "Households (experimental" in open(os.path.join(out, "report.md")).read()
    # destinations remain per agent: household members are not forced to share a destination
    assert (ag.groupby("household_id")["dest_loc"].nunique() > 1).any()
    # household mode produces multi-agent homes (the point of the change)
    assert (pd.read_parquet(os.path.join(out, "locations.geoparquet")).query("loc_type == 0")["occupancy"] >= 3).any()


def test_enabled_deterministic_and_seed_sensitive(geo, run_on, tmp_path):
    out1, _ = run_on
    out2 = str(tmp_path / "data" / "synthetic" / "again")
    G.run(hh_cfg(), geo[0], geo[1], out2)
    for f in ["population.cepop", "agents.parquet", "households.parquet", "locations.geoparquet", "config.json"]:
        assert open(os.path.join(out1, f), "rb").read() == open(os.path.join(out2, f), "rb").read(), f
    out3 = str(tmp_path / "data" / "synthetic" / "seed")
    G.run(C.load_config(None, C.deep_merge(hh_cfg(), {"seed": 99})), geo[0], geo[1], out3)
    assert open(os.path.join(out1, "population.cepop"), "rb").read() != open(os.path.join(out3, "population.cepop"), "rb").read()


def test_enabled_changes_only_what_it_should(geo, run_on, tmp_path):
    """Household mode alters home assignment; the config says so explicitly and the hash differs from the legacy one."""
    out_leg = str(tmp_path / "data" / "synthetic" / "leg")
    rep_leg = G.run(cfg_(), geo[0], geo[1], out_leg)
    _, rep_on = run_on
    assert rep_leg["config_sha256"] != rep_on["config_sha256"]
    a = pd.read_parquet(os.path.join(out_leg, "agents.parquet"))
    b = pd.read_parquet(os.path.join(run_on[0], "agents.parquet"))
    assert not np.array_equal(a["home_loc"], b["home_loc"])


# ---------------------------------------------------------------- legacy (disabled) compatibility
GOLD = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "golden_legacy.json")))


def _env_matches():
    import geopandas, pyarrow, scipy, shapely
    cur = {"numpy": np.__version__, "shapely": shapely.__version__, "geopandas": geopandas.__version__, "scipy": scipy.__version__,
           "pyarrow": pyarrow.__version__}
    return all(cur[k].split(".")[:2] == GOLD["_env"][k].split(".")[:2] for k in ("numpy", "shapely", "scipy"))


def test_disabled_matches_pre_household_golden(geo, tmp_path):
    """Golden fingerprints were captured from the code BEFORE the household layer existed (see golden_legacy.json)."""
    if not _env_matches():
        pytest.skip("library versions differ from the golden capture; compare via the equivalence test below instead")
    out = str(tmp_path / "data" / "synthetic" / "gold")
    rep = G.run(cfg_(), geo[0], geo[1], out)
    assert rep["config_sha256"] == GOLD["config_sha256"]          # config hash unchanged: the household block is absent
    fp = golden_util.fingerprints(out)
    for k in ("population.cepop_sha256", "agents_columns", "agents_content", "locations_columns", "locations_content", "dedup_content"):
        assert fp[k] == GOLD[k], k


def test_disabled_explicit_false_equals_absent_byte_for_byte(geo, tmp_path):
    out_a = str(tmp_path / "data" / "synthetic" / "a")
    out_b = str(tmp_path / "data" / "synthetic" / "b")
    G.run(cfg_(), geo[0], geo[1], out_a)
    G.run(cfg_(residential={"households": {"enabled": False}}), geo[0], geo[1], out_b)
    for f in ["population.cepop", "agents.parquet", "locations.geoparquet", "dedup_decisions.parquet"]:
        assert open(os.path.join(out_a, f), "rb").read() == open(os.path.join(out_b, f), "rb").read(), f
    for d in (out_a, out_b):
        assert not os.path.exists(os.path.join(d, "households.parquet"))
        assert list(pd.read_parquet(os.path.join(d, "agents.parquet")).columns) == GOLD["agents_columns"]
        assert "households" not in json.load(open(os.path.join(d, "report.json")))
    assert "households" not in json.load(open(os.path.join(out_a, "config.json")))["residential"]     # absent block stays absent


def test_disabled_uses_legacy_functions_only(geo, monkeypatch, tmp_path):
    called = []
    monkeypatch.setattr(Hh, "build_households", lambda *a, **k: called.append(1))
    monkeypatch.setattr(Hh, "draw_household_sizes", lambda *a, **k: called.append(1))
    G.run(cfg_(), geo[0], geo[1], str(tmp_path / "data" / "synthetic" / "x"))
    assert not called


# ---------------------------------------------------------------- independent validator catches household corruption
def _copy(run_on, tmp_path):
    dst = tmp_path / "c"
    shutil.copytree(run_on[0], dst)
    return str(dst)


def _failed(d, geo):
    cfg = json.load(open(os.path.join(d, "config.json")))
    return {c["name"] for c in V.validate_outputs(d, geo[1], cfg) if not c["passed"]}


def test_validator_detects_household_corruption(run_on, geo, tmp_path):
    d = _copy(run_on, tmp_path)
    assert not _failed(d, geo)
    hp, ap = os.path.join(d, "households.parquet"), os.path.join(d, "agents.parquet")
    hh0, ag0 = pd.read_parquet(hp), pd.read_parquet(ap)

    hh = hh0.copy(); hh.loc[0, "size"] = hh.loc[0, "size"] + 1; hh.to_parquet(hp, index=False)
    f = _failed(d, geo)
    assert "household sizes sum to N" in f and "household member counts equal household sizes" in f

    hh = hh0.copy(); hh.loc[0, "size"] = 7; hh.to_parquet(hp, index=False)
    assert "household sizes within configured support" in _failed(d, geo)

    hh = hh0.copy(); hh.loc[0, "home_loc"] = int(hh0.loc[1:, "home_loc"].max()) if hh0.loc[0, "home_loc"] == hh0["home_loc"].max() else int(hh0["home_loc"].max()); hh.to_parquet(hp, index=False)
    f = _failed(d, geo)
    assert "each agent's home_loc equals its household's home_loc" in f or "home occupancy equals sum of member household sizes" in f

    hh = hh0.copy(); hh.loc[0, "home_loc"] = 10**6; hh.to_parquet(hp, index=False)
    assert "every household maps to exactly one valid HOME location" in _failed(d, geo)

    hh = hh0.copy(); big = hh0["home_loc"].iloc[0]; hh["home_loc"] = big; hh.to_parquet(hp, index=False)   # everyone in one building
    assert "households per building <= max_households_per_building" in _failed(d, geo)
    hh0.to_parquet(hp, index=False)

    ag = ag0.copy(); ag.loc[0, "household_id"] = 10**6; ag.to_parquet(ap, index=False)
    assert "every agent has exactly one valid household" in _failed(d, geo)
    ag = ag0.copy(); ag["household_id"] = ag["household_id"].to_numpy()[::-1]; ag.to_parquet(ap, index=False)
    assert _failed(d, geo)
    ag0.to_parquet(ap, index=False)
    assert not _failed(d, geo)
    os.remove(hp)
    assert "households.parquet and agents.household_id present" in _failed(d, geo)


def test_validator_flags_stray_household_artifacts_when_disabled(geo, run_on, tmp_path):
    out = str(tmp_path / "data" / "synthetic" / "dis")
    G.run(cfg_(), geo[0], geo[1], out)
    shutil.copy(os.path.join(run_on[0], "households.parquet"), os.path.join(out, "households.parquet"))
    assert "household layer disabled: no household artifacts" in _failed(out, geo)
