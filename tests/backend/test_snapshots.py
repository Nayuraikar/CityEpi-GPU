"""Phase 4 tests: per-agent daily state snapshots (CESNAP v1, V0 only). See docs/snapshot_format.md.
Real-executable tests need build-sim/extpop_run. The pure-Python tests use an independent writer that mirrors the spec."""
import csv
import os
import stat
import struct
import subprocess
import time
import zlib
from pathlib import Path

import numpy as np
import pytest
from fastapi.testclient import TestClient

from app.sim import api as sim_api, config, registry, snapshots
from app.sim.runs import RunManager
from app.sim.snapshots import SnapshotError, SnapshotReader

ROOT = Path(__file__).resolve().parents[2]
HH = "bengaluru_urban_N100000_seed42_households_v1"
HH_CEPOP = ROOT / "data" / "synthetic" / HH / "population.cepop"
TINY = ROOT / "tests" / "fixtures" / "tiny.cepop"
EXE = ROOT / "build-sim" / "extpop_run"
needs_real = pytest.mark.skipif(not EXE.exists(), reason="build-sim/extpop_run not built")
needs_hh = pytest.mark.skipif(not (EXE.exists() and HH_CEPOP.exists()), reason="household dataset / executable missing")


# ------------------------------------------------------------------ independent reference writer (spec mirror)
def pad8(b: bytes) -> bytes:
    return b + b"\0" * (-len(b) % 8)


def write_snap(path, states, home_loc, seed=7, dataset_crc=0, tamper=None):
    """states: (frames, N) uint8 array."""
    frames, n = states.shape
    fb = (n + 3) // 4
    packed = np.zeros((frames, fb * 4), dtype=np.uint8)
    packed[:, :n] = states
    p4 = packed.reshape(frames, fb, 4)
    pk = (p4[:, :, 0] | (p4[:, :, 1] << 2) | (p4[:, :, 2] << 4) | (p4[:, :, 3] << 6)).astype(np.uint8)
    counts = np.stack([(states == k).sum(1) for k in range(4)], 1).astype("<u4")
    payload = pad8(np.asarray(home_loc, "<u4").tobytes())
    payload = pad8(payload + pk.tobytes()) + counts.tobytes()
    if tamper:
        payload = tamper(payload)
    h = bytearray(64)
    h[:8] = b"CESNAP1\0"
    struct.pack_into("<IIQQ", h, 8, 1, 0x01020304, n, frames)
    struct.pack_into("<IIIIII", h, 32, 64, 2, fb, 0, dataset_crc, 0)
    struct.pack_into("<Q", h, 56, seed)
    footer = struct.pack("<II", zlib.crc32(payload), 0) + b"CESNAPE\0"
    Path(path).write_bytes(bytes(h) + payload + footer)
    return counts


def rand_states(frames, n, seed=1):
    return np.random.default_rng(seed).integers(0, 4, size=(frames, n), dtype=np.uint8)


# ------------------------------------------------------------------ round trip & malformed (pure Python)
@pytest.mark.parametrize("n", [1, 3, 4, 5, 7, 8, 1001])
def test_round_trip(tmp_path, n):
    st = rand_states(6, n, seed=n)
    hl = np.arange(n, dtype="<u4")[::-1].copy()
    counts = write_snap(tmp_path / "s.cesnap", st, hl, seed=99, dataset_crc=0xDEADBEEF)
    r = SnapshotReader(tmp_path / "s.cesnap")
    assert (r.n_agents, r.n_frames, r.n_days, r.seed, r.dataset_crc32) == (n, 6, 5, 99, 0xDEADBEEF)
    for d in range(6):
        assert np.array_equal(r.frame(d), st[d])
        assert r.frame_counts(d) == tuple(int(x) for x in counts[d])
    assert np.array_equal(r.home_loc(), hl) and np.array_equal(r.counts_table(), counts)
    rows = [[d, *map(int, counts[d])] for d in range(6)]
    rep = r.validate(rows, hl)
    assert rep["frames_checked"] == 6 and rep["matches_daily_csv"] and rep["matches_dataset_home_loc"]
    assert r.info()["state_encoding"] == {"S": 0, "E": 1, "I": 2, "R": 3}
    with pytest.raises(SnapshotError):
        r.frame(6)
    with pytest.raises(SnapshotError):
        r.frame(-1)
    r.close()


def _base(tmp_path):
    p = tmp_path / "s.cesnap"
    st = rand_states(4, 10)
    write_snap(p, st, np.arange(10))
    return p, bytearray(p.read_bytes())


def _open_validate(p, **kw):
    r = SnapshotReader(p)
    try:
        return r.validate(**kw)
    finally:
        r.close()


def test_valid_baseline(tmp_path):
    p, _ = _base(tmp_path)
    assert _open_validate(p)["frames_checked"] == 4


def test_malformed_files(tmp_path):
    p, raw = _base(tmp_path)

    def bad(data, msg, validate=False):
        q = tmp_path / "bad.cesnap"
        q.write_bytes(bytes(data))
        with pytest.raises(SnapshotError, match=msg):
            _open_validate(q) if validate else SnapshotReader(q)

    bad(b"", "too small")
    bad(raw[:40], "too small")
    bad(raw[:-1], "size")                                   # truncated by one byte
    bad(raw[:len(raw) // 2], "size")
    bad(raw + b"\0", "size")                                # trailing garbage
    x = bytearray(raw); x[:8] = b"NOTASNAP"; bad(x, "magic")
    x = bytearray(raw); x[8] = 2; bad(x, "version")
    x = bytearray(raw); x[12] = 0; bad(x, "endian")
    x = bytearray(raw); x[36] = 8; bad(x, "bits")
    x = bytearray(raw); x[52] = 6; bad(x, "backend")        # e.g. a claimed V6 snapshot is refused
    x = bytearray(raw); struct.pack_into("<Q", x, 24, 5); bad(x, "size")      # frame count lies
    x = bytearray(raw); struct.pack_into("<Q", x, 16, 0); bad(x, "implausible")
    x = bytearray(raw); x[-1] = 0x58; bad(x, "end-of-file magic", validate=True)
    x = bytearray(raw); x[-16] ^= 0xFF; bad(x, "CRC", validate=True)          # footer CRC wrong
    x = bytearray(raw); x[64 + 40 + 8] ^= 0x01; bad(x, "CRC", validate=True)  # a flipped state bit in a frame
    x = bytearray(raw); x[80] ^= 0xFF; bad(x, "CRC", validate=True)           # corrupted home_loc


def test_inconsistent_counts_and_padding_detected_even_with_valid_crc(tmp_path):
    # Re-sign the CRC so only the semantic checks can catch these.
    st = rand_states(3, 10)
    p = tmp_path / "c.cesnap"
    write_snap(p, st, np.arange(10), tamper=lambda pl: pl[:-4] + struct.pack("<I", struct.unpack("<I", pl[-4:])[0] + 1))
    with pytest.raises(SnapshotError, match="stored counts"):
        _open_validate(p)
    # non-zero padding bits in the last byte of frame 0 (n=10 -> 2 used slots in byte 2)
    frames_off = 64 + 48                                     # align8(64 + 40) = 104 -> recompute below
    frames_off = (64 + 4 * 10 + 7) & ~7
    def pad_tamper(pl):
        b = bytearray(pl); b[frames_off - 64 + 2] |= 0b11000000; return bytes(b)
    write_snap(p, st, np.arange(10), tamper=pad_tamper)
    with pytest.raises(SnapshotError):
        _open_validate(p)


def test_state_count_consistency_against_csv(tmp_path):
    st = rand_states(4, 10)
    p = tmp_path / "s.cesnap"
    counts = write_snap(p, st, np.arange(10))
    rows = [[d, *map(int, counts[d])] for d in range(4)]
    assert _open_validate(p, daily_rows=rows)["matches_daily_csv"]
    wrong = [list(r) for r in rows]; wrong[2][1] += 1; wrong[2][2] -= 1
    with pytest.raises(SnapshotError, match="day 2"):
        _open_validate(p, daily_rows=wrong)
    with pytest.raises(SnapshotError, match="frames"):
        _open_validate(p, daily_rows=rows[:3])
    with pytest.raises(SnapshotError, match="home_loc"):
        _open_validate(p, expect_home_loc=np.arange(10)[::-1].copy())


def test_missing_snapshot():
    with pytest.raises(SnapshotError, match="not found"):
        SnapshotReader("/nonexistent/states.cesnap")


# ------------------------------------------------------------------ the real C++ writer
def run_cli(tmp_path, *extra, cepop=TINY, days=12, tag="a"):
    out = tmp_path / tag
    out.mkdir(exist_ok=True)
    cmd = [str(EXE), "--input", str(cepop), "--days", str(days), "--seed", "42", "--init", "5" if cepop == TINY else "100",
           "--beta-home", "0.3", "--beta-work", "0.3", "--incubation", "3", "--infectious", "5", "--daily-csv", str(out / "daily"), *extra]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
    return r, out


def kv(stdout):
    return dict(l.split("=", 1) for l in stdout.splitlines() if "=" in l and not l.startswith("PROGRESS"))


def read_csv(p):
    with open(p) as f:
        return [[int(x) for x in row] for row in list(csv.reader(f))[1:]]


@needs_real
def test_cli_snapshots_do_not_change_results(tmp_path):
    r0, o0 = run_cli(tmp_path, tag="plain")
    r1, o1 = run_cli(tmp_path, "--snapshots", str(tmp_path / "snap"), tag="snap")
    r2, o2 = run_cli(tmp_path, "--progress", "--snapshots", str(tmp_path / "snap2"), tag="snapprog")
    assert r0.returncode == r1.returncode == r2.returncode == 0, (r1.stderr, r2.stderr)
    for k in ("v0_daily_checksum", "v0_final", "v0_population_conserved", "v0_days_recorded"):
        assert kv(r0.stdout)[k] == kv(r1.stdout)[k] == kv(r2.stdout)[k]
    assert (o0 / "daily_v0.csv").read_bytes() == (o1 / "daily_v0.csv").read_bytes() == (o2 / "daily_v0.csv").read_bytes()
    assert "snapshots_status" not in r0.stdout and not (tmp_path / "plain" / "snapshots").exists()
    k = kv(r1.stdout)
    assert k["snapshots_status"] == "ok" and k["snapshots_backend"] == "v0" and k["snapshots_frames"] == "13"
    f = tmp_path / "snap" / "states.cesnap"
    assert f.stat().st_size == int(k["snapshots_bytes"]) == snapshots.expected_size(f.stat().st_size and SnapshotReader(f).n_agents, 13)
    assert not list((tmp_path / "snap").glob("*.partial"))
    assert f.read_bytes() == (tmp_path / "snap2" / "states.cesnap").read_bytes()      # progress mode does not alter it
    rd = SnapshotReader(f)
    rows = read_csv(o1 / "daily_v0.csv")
    rep = rd.validate(rows, snapshots.read_cepop_home_loc(TINY))
    assert rep["payload_crc32"] == k["snapshots_payload_crc32"] and rd.backend == "v0" and rd.seed == 42
    assert [rd.frame_counts(d) for d in range(13)] == [tuple(r[1:]) for r in rows]
    rd.close()


@needs_real
def test_cli_snapshot_failures(tmp_path):
    r, _ = run_cli(tmp_path, "--backend", "v6", "--snapshots", str(tmp_path / "x"))
    assert r.returncode == 1 and "V0" in r.stderr and not (tmp_path / "x").exists()
    r, _ = run_cli(tmp_path, "--backend", "both", "--snapshots", str(tmp_path / "x"))
    assert r.returncode == 1
    blocker = tmp_path / "file"
    blocker.write_text("x")
    r, _ = run_cli(tmp_path, "--snapshots", str(blocker / "sub"))               # cannot create directory
    assert r.returncode == 1


# ------------------------------------------------------------------ household V0 reference run (user-validated metrics)
@needs_hh
def test_household_snapshots_match_validated_run(tmp_path):
    r, o = run_cli(tmp_path, "--snapshots", str(tmp_path / "snap"), cepop=HH_CEPOP, days=100, tag="hh")
    assert r.returncode == 0, r.stderr
    assert kv(r.stdout)["v0_daily_checksum"] == "b213860e1d97b2c8"
    rows = read_csv(o / "daily_v0.csv")
    assert rows[-1][1:] == [65371, 1257, 2343, 31029]
    assert round(100 * (1 - rows[-1][1] / 100000), 2) == 34.63
    assert max(x[3] for x in rows) == 2891 and max(rows, key=lambda x: (x[3], -x[0]))[0] == 78
    assert max(rows[i - 1][1] - rows[i][1] for i in range(1, len(rows))) == 598
    rd = SnapshotReader(tmp_path / "snap" / "states.cesnap")
    rd.validate(rows, snapshots.read_cepop_home_loc(HH_CEPOP))
    assert rd.n_agents == 100000 and rd.n_frames == 101
    assert [rd.frame_counts(d) for d in range(101)] == [tuple(x[1:]) for x in rows]
    # agents only move forward through S->E->I->R (never backwards) in the snapshots
    prev = rd.frame(0)
    for d in range(1, 101):
        cur = rd.frame(d)
        assert (cur >= prev).all() and ((cur - prev) <= 3).all()
        prev = cur
    rd.close()


# ------------------------------------------------------------------ API
@pytest.fixture(autouse=True)
def fresh(tmp_path, monkeypatch):
    registry._probe_cache.clear()
    monkeypatch.setattr(config, "RUNS_DIR", tmp_path / "runs")
    mgr = RunManager(tmp_path / "runs", max_concurrent=2)
    monkeypatch.setattr(sim_api, "_manager", mgr)
    yield mgr
    mgr.shutdown()
    registry._probe_cache.clear()


@pytest.fixture
def client():
    from app.main import app
    with TestClient(app) as c:
        yield c


def wait(client, rid, timeout=120):
    t0 = time.time()
    while time.time() - t0 < timeout:
        r = client.get(f"/api/sim/runs/{rid}").json()
        if r["state"] in ("completed", "failed", "cancelled"):
            return r
        time.sleep(0.05)
    raise AssertionError("timeout")


def hh(**kw):
    return {"dataset": HH, "backend": "v0", **kw}


@needs_hh
def test_api_snapshot_run_end_to_end(client):
    rid = client.post("/api/sim/runs", json=hh(snapshots=True)).json()["id"]
    done = wait(client, rid)
    assert done["state"] == "completed", done["error"]
    assert done["result"]["daily_checksum"] == "b213860e1d97b2c8"
    assert done["result"]["final"] == {"S": 65371, "E": 1257, "I": 2343, "R": 31029}
    s = done["snapshots"]
    assert s["requested"] and s["available"] and s["validation"]["matches_daily_csv"] and s["validation"]["matches_dataset_home_loc"]
    assert (config.RUNS_DIR / rid / "snapshots" / "states.cesnap").is_file()       # isolated in the run directory
    meta = client.get(f"/api/sim/runs/{rid}/snapshots").json()
    assert meta["info"]["n_agents"] == 100000 and meta["info"]["n_frames"] == 101 and meta["supported_backends"] == ["v0"]
    assert any("V0-only" in n for n in meta["notes"]) and any("NOT tell you where the infection happened" in n for n in meta["notes"])
    series = client.get(f"/api/sim/runs/{rid}/series").json()["rows"]
    for day in (0, 1, 50, 78, 100):                                                # API frames agree with the daily rows
        fr = client.get(f"/api/sim/runs/{rid}/snapshots/frames/{day}")
        st = np.frombuffer(fr.content, dtype=np.uint8)
        assert len(st) == 100000 and fr.headers["x-day"] == str(day)
        assert [int((st == k).sum()) for k in range(4)] == [series[day][c] for c in "SEIR"]
    assert client.get(f"/api/sim/runs/{rid}/snapshots/frames/101").status_code == 404
    assert client.get(f"/api/sim/runs/{rid}/snapshots/frames/-1").status_code == 404
    pos = client.get(f"/api/sim/runs/{rid}/snapshots/home-positions")
    xy = np.frombuffer(pos.content, dtype="<f4").reshape(-1, 2)
    assert xy.shape == (100000, 2) and "not infection location" in pos.headers["x-position-semantics"]
    import pyarrow.parquet as pq
    loc = pq.read_table(HH_CEPOP.parent / "locations.geoparquet", columns=["lon", "lat"]).to_pandas()
    hl = snapshots.read_cepop_home_loc(HH_CEPOP)
    for a in (0, 1234, 99999):                                                     # actual home_loc coordinates
        assert np.allclose(xy[a], [loc.lon[hl[a]], loc.lat[hl[a]]], atol=1e-5)
    # a damaged file is never served
    f = config.RUNS_DIR / rid / "snapshots" / "states.cesnap"
    f.write_bytes(f.read_bytes()[:-5])
    assert client.get(f"/api/sim/runs/{rid}/snapshots").status_code == 404
    f.unlink()
    assert client.get(f"/api/sim/runs/{rid}/snapshots/frames/0").status_code == 404
    client.delete(f"/api/sim/runs/{rid}")
    assert not (config.RUNS_DIR / rid).exists()


@needs_hh
def test_api_run_without_snapshots_has_none_and_is_default_off(client):
    assert "snapshots" not in str(client.post("/api/sim/validate", json=hh()).json()["errors"])
    assert client.post("/api/sim/validate", json=hh()).json()["normalized"]["snapshots"] is False
    rid = client.post("/api/sim/runs", json=hh(days=5)).json()["id"]
    done = wait(client, rid)
    assert done["state"] == "completed" and done["snapshots"]["available"] is False and not done["snapshots"]["requested"]
    assert not (config.RUNS_DIR / rid / "snapshots").exists()
    assert client.get(f"/api/sim/runs/{rid}/snapshots").status_code == 404
    assert client.get("/api/sim/runs/r20250101000000-deadbeef/snapshots").status_code == 404


@needs_hh
def test_api_snapshot_validation_rules(client):
    r = client.post("/api/sim/validate", json=hh(snapshots="yes")).json()
    assert not r["valid"]
    r = client.post("/api/sim/validate", json=hh(snapshots=True, days=config.SNAPSHOT_MAX_DAYS + 1)).json()
    assert not r["valid"] and "snapshots" in {e["field"] for e in r["errors"]}
    r = client.post("/api/sim/validate", json=hh(backend="v6", snapshots=True)).json()
    msgs = " ".join(e["message"] for e in r["errors"] if e["field"] == "snapshots")
    assert not r["valid"] and "V0-only" in msgs
    caps = client.get("/api/sim/capabilities").json()["backends"]
    assert {b["id"]: b["supports_snapshots"] for b in caps} == {"v0": True, "v6": False}


@needs_hh
def test_api_corrupt_snapshot_fails_the_run_and_is_not_exposed(client, tmp_path, monkeypatch):
    wrapper = tmp_path / "wrap" / "extpop_run"
    wrapper.parent.mkdir()
    wrapper.write_text(f'#!/bin/sh\n"{EXE}" "$@" || exit $?\nwhile [ $# -gt 0 ]; do [ "$1" = "--snapshots" ] && truncate -s -3 "$2/states.cesnap"; shift; done\n')
    wrapper.chmod(wrapper.stat().st_mode | stat.S_IXUSR)
    monkeypatch.setenv("CITYEPI_EXTPOP_RUN", str(wrapper))
    registry._probe_cache.clear()
    rid = client.post("/api/sim/runs", json=hh(days=10, snapshots=True)).json()["id"]
    done = wait(client, rid)
    assert done["state"] == "failed" and done["error"]["code"] == "invalid_output" and "snapshot" in done["error"]["message"].lower()
    assert done["snapshots"]["available"] is False
    assert not (config.RUNS_DIR / rid / "snapshots").exists()
    assert client.get(f"/api/sim/runs/{rid}/snapshots").status_code == 409
