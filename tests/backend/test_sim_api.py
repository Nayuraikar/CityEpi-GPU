"""Phase 2 tests for the simulation execution API. Real-executable tests need build-sim/extpop_run (see docs/simulation_api.md).
Failure-mode tests use a scripted stand-in executable so timeouts/cancellation are deterministic."""
import csv
import json
import os
import stat
import time
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.sim import api as sim_api, config, registry
from app.sim.runs import RunManager

ROOT = Path(__file__).resolve().parents[2]
HH = "bengaluru_urban_N100000_seed42_households_v1"
REAL_EXE = ROOT / "build-sim" / "extpop_run"
needs_real = pytest.mark.skipif(not REAL_EXE.exists(), reason="build-sim/extpop_run not built")

FAKE = """#!/bin/sh
# stand-in for extpop_run. Probe (tiny fixture) always succeeds; other behaviour is chosen by the MODE file beside this script.
for a in "$@"; do case "$a" in *tiny.cepop) exit 0;; esac; done
MODE=$(cat "$(dirname "$0")/MODE")
echo "PROGRESS day=0 total=100 S=99 E=0 I=1 R=0 elapsed=0.0000"
case "$MODE" in
  sleep) sleep 60 ;;
  fail) echo "extpop_run: cannot load 'x': boom" >&2; exit 1 ;;
  badout) echo RESULT: PASS; exit 0 ;;
esac
"""


@pytest.fixture(autouse=True)
def fresh(tmp_path, monkeypatch):
    registry._probe_cache.clear()
    monkeypatch.setattr(config, "RUNS_DIR", tmp_path / "runs")
    mgr = RunManager(tmp_path / "runs", max_concurrent=3)
    monkeypatch.setattr(sim_api, "_manager", mgr)
    yield mgr
    mgr.shutdown()
    registry._probe_cache.clear()


@pytest.fixture
def client():
    from app.main import app
    with TestClient(app) as c:
        yield c


@pytest.fixture
def fake(tmp_path, monkeypatch):
    d = tmp_path / "fake"
    d.mkdir()
    exe = d / "extpop_run"
    exe.write_text(FAKE)
    exe.chmod(exe.stat().st_mode | stat.S_IXUSR)
    monkeypatch.setenv("CITYEPI_EXTPOP_RUN", str(exe))
    registry._probe_cache.clear()
    def mode(m): (d / "MODE").write_text(m)
    return mode


def wait(client, rid, states, timeout=60):
    t0 = time.time()
    while time.time() - t0 < timeout:
        r = client.get(f"/api/sim/runs/{rid}").json()
        if r["state"] in states:
            return r
        time.sleep(0.05)
    raise AssertionError(f"run stayed {r['state']}")


TERMINAL = ("completed", "failed", "cancelled")
def body(**kw): return {"dataset": HH, "backend": "v0", **kw}


# ------------------------------------------------------------------ capabilities & validation
@needs_real
def test_capabilities(client):
    c = client.get("/api/sim/capabilities").json()
    ids = {b["id"]: b for b in c["backends"]}
    assert set(ids) == {"v0", "v6"}                       # V1-V3 deliberately not exposed
    assert ids["v0"]["available"] and ids["v0"]["progress_per_day"]
    assert not ids["v6"]["available"] and ids["v6"]["reason"]
    d = {x["id"]: x for x in c["datasets"]}
    assert d[HH]["agents"] == 100000 and d[HH]["locations"] == 238841 and "path" not in d[HH]


@needs_real
@pytest.mark.parametrize("patch,field", [
    ({"days": 0}, "days"), ({"days": 100000}, "days"), ({"days": 5.5}, "days"), ({"days": True}, "days"), ({"days": "7"}, "days"),
    ({"seed": -1}, "seed"), ({"seed": 2**60}, "seed"), ({"initial_infected": 100001}, "initial_infected"),
    ({"beta_home": -0.1}, "beta_home"), ({"beta_work": "nan"}, "beta_work"), ({"beta_work": 1e9}, "beta_work"),
    ({"incubation_days": 0}, "incubation_days"), ({"infectious_days": 366}, "infectious_days"),
    ({"dataset": "../../etc"}, "dataset"), ({"dataset": "nope"}, "dataset"),
    ({"backend": "v1"}, "backend"), ({"backend": "v0; rm -rf /"}, "backend"), ({"backend": "v6"}, "backend"),
    ({"timeout_seconds": 1}, "timeout_seconds"), ({"evil": 1}, "evil"),
])
def test_validation_rejects(client, patch, field):
    r = client.post("/api/sim/validate", json=body(**patch)).json()
    assert not r["valid"] and field in {e["field"] for e in r["errors"]}, r
    resp = client.post("/api/sim/runs", json=body(**patch))
    assert resp.status_code == 422 and resp.json()["errors"]
    assert client.get("/api/sim/runs").json()["runs"] == []     # nothing was started or created


@needs_real
def test_validation_ok_and_warnings(client):
    r = client.post("/api/sim/validate", json=body(beta_home=0, beta_work=0)).json()
    assert r["valid"] and r["warnings"]
    assert client.post("/api/sim/validate", json=[1]).status_code == 422


# ------------------------------------------------------------------ real simulation
@needs_real
def test_real_run_matches_recorded(client):
    r = client.post("/api/sim/runs", json=body(days=100, seed=42, initial_infected=100, label=" baseline ")).json()
    assert r["state"] in ("queued", "running") and r["label"] == "baseline"
    done = wait(client, r["id"], TERMINAL)
    assert done["state"] == "completed", done["error"]
    res = done["result"]
    # identical to the recorded Kaggle V0/V6 household run (checksum b213860e1d97b2c8, final S/E/I/R)
    assert res["daily_checksum"] == "b213860e1d97b2c8"
    assert res["final"] == {"S": 65371, "E": 1257, "I": 2343, "R": 31029}
    assert done["progress"]["fraction"] == 1.0 and done["progress"]["day"] == 100
    ser = client.get(f"/api/sim/runs/{r['id']}/series").json()["rows"]
    rec = ROOT / "ui_data_bundle/bench/results/epidemic_population_comparison/household_v0.csv"
    with open(rec) as f:
        recorded = [[int(x) for x in row] for row in list(csv.reader(f))[1:]]
    assert [[x["day"], x["S"], x["E"], x["I"], x["R"]] for x in ser] == recorded
    assert client.get(f"/api/sim/runs/{r['id']}/series?since=95").json()["rows"][0]["day"] == 96
    csv_txt = client.get(f"/api/sim/runs/{r['id']}/export.csv").text
    assert csv_txt.splitlines()[0] == "day,S,E,I,R,new_infections" and len(csv_txt.splitlines()) == 102
    j = client.get(f"/api/sim/runs/{r['id']}/export.json").json()
    assert j["result"]["attack_rate_pct"] == res["attack_rate_pct"] and len(j["daily"]) == 101


@needs_real
def test_concurrent_runs_are_isolated(client):
    seeds = [1, 2, 3, 42, 42]
    ids = [client.post("/api/sim/runs", json=body(days=60, seed=s)).json()["id"] for s in seeds]
    assert len(set(ids)) == len(ids)
    runs = [wait(client, i, TERMINAL) for i in ids]
    assert all(r["state"] == "completed" for r in runs)
    dirs = {sim_api.manager().get(i).dir for i in ids}
    assert len(dirs) == len(ids)
    # same seed -> identical result even when run concurrently; different seeds differ
    assert runs[3]["result"]["daily_checksum"] == runs[4]["result"]["daily_checksum"]
    assert len({r["result"]["daily_checksum"] for r in runs[:4]}) == 4
    for r, s in zip(runs, seeds):
        assert r["request"]["seed"] == s


# ------------------------------------------------------------------ lifecycle with scripted executable
def test_cancel_running_kills_process_and_cleans(client, fake):
    fake("sleep")
    r = client.post("/api/sim/runs", json=body(days=100)).json()
    wait(client, r["id"], ("running",))
    run = sim_api.manager().get(r["id"])
    t0 = time.time()
    while run.proc is None and time.time() - t0 < 5: time.sleep(0.02)
    pid = run.proc.pid
    c = client.post(f"/api/sim/runs/{r['id']}/cancel").json()
    done = wait(client, r["id"], TERMINAL)
    assert done["state"] == "cancelled" and done["error"]["code"] == "cancelled"
    with pytest.raises(ProcessLookupError):
        os.killpg(pid, 0)                                  # whole process group is gone
    assert not list(run.dir.glob("daily_*.csv"))
    assert client.post(f"/api/sim/runs/{r['id']}/cancel").status_code == 409
    assert client.delete(f"/api/sim/runs/{r['id']}").status_code == 204
    assert not run.dir.exists()


def test_timeout(client, fake, monkeypatch):
    monkeypatch.setitem(config.LIMITS, "timeout_seconds", (1, 100))
    fake("sleep")
    r = client.post("/api/sim/runs", json=body(timeout_seconds=1)).json()
    done = wait(client, r["id"], TERMINAL, timeout=20)
    assert done["state"] == "failed" and done["error"]["code"] == "timeout"


def test_failure_reports_stderr_and_exit_code(client, fake):
    fake("fail")
    r = client.post("/api/sim/runs", json=body()).json()
    done = wait(client, r["id"], TERMINAL)
    assert done["state"] == "failed" and done["exit_code"] == 1 and "boom" in done["error"]["message"]
    assert "boom" in " ".join(client.get(f"/api/sim/runs/{r['id']}/log").json()["lines"])


def test_zero_exit_without_valid_output_is_not_completed(client, fake):
    fake("badout")
    r = client.post("/api/sim/runs", json=body()).json()
    done = wait(client, r["id"], TERMINAL)
    assert done["state"] == "failed" and done["error"]["code"] == "invalid_output"


def test_queued_state_and_cancel_while_queued(tmp_path, client, fake, monkeypatch):
    mgr = RunManager(tmp_path / "q", max_concurrent=1)
    monkeypatch.setattr(sim_api, "_manager", mgr)
    fake("sleep")
    a = client.post("/api/sim/runs", json=body()).json()["id"]
    b = client.post("/api/sim/runs", json=body()).json()["id"]
    wait(client, a, ("running",))
    assert client.get(f"/api/sim/runs/{b}").json()["state"] == "queued"
    assert client.post(f"/api/sim/runs/{b}/cancel").json()["state"] == "cancelled"
    assert client.get(f"/api/sim/runs/{b}").json()["started_at"] is None
    assert client.delete(f"/api/sim/runs/{a}").status_code == 409     # active runs cannot be deleted
    client.post(f"/api/sim/runs/{a}/cancel")
    assert wait(client, a, TERMINAL)["state"] == "cancelled"
    mgr.shutdown()


def test_live_progress_is_real(client, fake):
    fake("sleep")
    r = client.post("/api/sim/runs", json=body()).json()
    t0 = time.time()
    while time.time() - t0 < 10:
        p = client.get(f"/api/sim/runs/{r['id']}").json()["progress"]
        if p["day"] is not None: break
        time.sleep(0.05)
    assert p["day"] == 0 and p["fraction"] == 0.0 and p["I"] == 1       # exactly what the process printed
    s = client.get(f"/api/sim/runs/{r['id']}/series").json()
    assert s["state"] == "running" and len(s["rows"]) == 1
    client.post(f"/api/sim/runs/{r['id']}/cancel")
    wait(client, r["id"], TERMINAL)


def test_missing_executable_is_reported_before_start(client, monkeypatch):
    monkeypatch.setenv("CITYEPI_EXTPOP_RUN", "/nonexistent/extpop_run")
    registry._probe_cache.clear()
    monkeypatch.setattr(registry, "BACKENDS", {**registry.BACKENDS, "v0": registry.BackendSpec(
        "v0", "V0", "", "v0", "CITYEPI_EXTPOP_RUN", ("does/not/exist",), True, "cpu")})
    r = client.post("/api/sim/runs", json=body())
    assert r.status_code == 422 and "not available" in json.dumps(r.json()["errors"])


def test_restart_marks_interrupted_runs_failed(tmp_path):
    d = tmp_path / "rr" / "r20250101000000-deadbeef"
    d.mkdir(parents=True)
    (d / "meta.json").write_text(json.dumps({"id": d.name, "state": "running", "created_at": "x", "error": None}))
    mgr = RunManager(tmp_path / "rr", max_concurrent=1)
    m = mgr.get(d.name).snapshot()
    assert m["state"] == "failed" and m["error"]["code"] == "interrupted"
    mgr.shutdown()


def test_run_id_traversal_is_rejected(client):
    for bad in ("..", "r1", "../../etc/passwd"):
        assert client.get(f"/api/sim/runs/{bad}").status_code in (404, 405)
    assert client.get("/api/sim/runs/%2e%2e%2f%2e%2e").status_code == 404


# ------------------------------------------------------------------ existing dashboard untouched
def test_recorded_endpoints_still_work(client):
    assert client.get("/api/health").json()["status"] == "ok"
    e = client.get("/api/epidemic").json()
    assert set(e) == {"legacy", "household", "low", "baseline", "high"}
    assert client.get("/api/overview").status_code == 200
    assert client.get("/api/population").status_code == 200
    assert client.get("/api/benchmarks").status_code == 200


# ------------------------------------------------------------------ regression: Phase 4 intermittent failure (root-caused in Phase 5)
def test_immediate_cancel_never_resurrects_run(fresh, fake):
    """Race: cancel() between the worker's 'still queued?' check and its QUEUED->RUNNING write used to be overwritten by RUNNING
    (and the process started anyway). Stress submit+immediate cancel; every run must end cancelled."""
    fake("sleep")
    for i in range(150):
        rid = fresh.submit({"dataset": HH, "backend": "v0"})["id"]
        time.sleep(0.0005 * (i % 20))
        fresh.cancel(rid)
        run = fresh.get(rid)
        t0 = time.time()
        while run.state not in TERMINAL and time.time() - t0 < 10:
            time.sleep(0.005)
        assert run.state == "cancelled", (i, run.snapshot()["state"])
        time.sleep(0.005)
        assert run.state == "cancelled"                     # and stays cancelled (not flipped back to running)


GROUPFAKE = """#!/bin/sh
for a in "$@"; do case "$a" in *tiny.cepop) exit 0;; esac; done
echo "PROGRESS day=0 total=100 S=99 E=0 I=1 R=0 elapsed=0.0000"
# leader ignores SIGTERM-induced exit ordering: spawn a grandchild that survives the leader and holds stdout open
trap '' TERM
(trap '' TERM; sleep 30) &
wait
"""


def test_cancel_kills_orphaned_group_members(client, fake, tmp_path, monkeypatch):
    """A group member that survives SIGTERM and holds the stdout pipe must be SIGKILLed; the run must not hang."""
    monkeypatch.setattr("app.sim.runs.KILL_GRACE_S", 1)
    d = tmp_path / "fake"
    (d / "extpop_run").write_text(GROUPFAKE)
    registry._probe_cache.clear()
    r = client.post("/api/sim/runs", json=body()).json()
    wait(client, r["id"], ("running",))
    run = sim_api.manager().get(r["id"])
    t0 = time.time()
    while (run.proc is None or not run.series) and time.time() - t0 < 5: time.sleep(0.02)
    pgid = run.proc.pid
    client.post(f"/api/sim/runs/{r['id']}/cancel")
    done = wait(client, r["id"], TERMINAL, timeout=10)
    assert done["state"] == "cancelled"
    time.sleep(0.1)
    with pytest.raises(ProcessLookupError):
        os.killpg(pgid, 0)                                  # no member of the group survives
