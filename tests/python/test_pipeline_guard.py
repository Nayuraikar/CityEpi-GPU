"""Output-directory safety of scripts/kaggle_synthpop_pipeline.py: an existing non-empty directory must produce a clean
failure BEFORE the environment step and before finish(), without creating or modifying anything inside it."""
import hashlib
import os

import pytest

import kaggle_synthpop_pipeline as P


def snapshot(root):
    """Everything observable about a directory tree: names, sizes, mtimes (ns), content hashes."""
    out = {}
    for d, dirs, files in os.walk(root):
        for n in sorted(dirs + files):
            p = os.path.join(d, n)
            st = os.stat(p)
            out[os.path.relpath(p, root)] = (st.st_size, st.st_mtime_ns,
                                             hashlib.sha256(open(p, "rb").read()).hexdigest() if os.path.isfile(p) else "dir")
    out["."] = (os.stat(root).st_mtime_ns,)   # a created/removed entry changes the directory mtime
    return out


@pytest.fixture
def tripwires(monkeypatch):
    calls = []
    monkeypatch.setattr(P, "environment", lambda: calls.append("environment") or {"python": "x", "libs": {"numpy": "MISSING (test)"},
                                                                                  "gpu": None, "nvcc": None})
    monkeypatch.setattr(P, "sh", lambda *a, **k: calls.append("sh") or (0, "", 0.0))
    return calls


def args(out, *extra):
    return ["--geo-dir", "nope", "--boundary", "nope", "--out-dir", str(out), *extra]


def make_legacy(tmp_path):
    d = tmp_path / "data" / "synthetic" / "legacy"
    (d / "logs").mkdir(parents=True)
    (d / "population.cepop").write_bytes(b"precious legacy bytes")
    (d / "kaggle_run_record.json").write_text('{"verdict": "ALL_PASSED"}')
    (d / "logs" / "generate.log").write_text("old log")
    return d


def test_non_empty_dir_fails_cleanly_and_is_untouched(tmp_path, tripwires, capsys):
    d = make_legacy(tmp_path)
    before = snapshot(d)
    assert P.main(args(d)) == 1
    assert snapshot(d) == before                        # nothing created, modified, deleted or re-timestamped
    assert not (d / "logs" / "generate_rerun.log").exists()
    assert tripwires == []                              # guard ran before the environment step and before any subprocess
    cap = capsys.readouterr()
    assert "FAILED" in cap.err and "nothing was written" in cap.err and str(d) in cap.err
    assert "VERDICT" not in cap.out


def test_guard_runs_before_environment_failure_path(tmp_path, tripwires):
    """The original hazard: a failing environment step reached finish(), which wrote a record into the existing directory."""
    d = make_legacy(tmp_path)
    before = snapshot(d)
    P.main(args(d, "--no-determinism-check", "--require-gpu"))
    assert snapshot(d) == before
    assert json_text(d / "kaggle_run_record.json") == '{"verdict": "ALL_PASSED"}'


def json_text(p):
    return open(p).read()


def test_existing_file_path_is_refused_untouched(tmp_path, tripwires):
    f = tmp_path / "data" / "synthetic" / "afile"
    f.parent.mkdir(parents=True)
    f.write_text("not a directory")
    mt = f.stat().st_mtime_ns
    assert P.main(args(f)) == 1
    assert f.read_text() == "not a directory" and f.stat().st_mtime_ns == mt and tripwires == []


def test_nonexistent_dir_is_not_created_by_failed_environment(tmp_path, tripwires):
    d = tmp_path / "data" / "synthetic" / "fresh"
    assert P.main(args(d)) == 1                         # environment fake reports a missing library
    assert tripwires == ["environment"]                 # the guard let a fresh path through ...
    assert not d.exists()                               # ... and finish() still creates nothing for a path that does not exist


def test_empty_existing_dir_still_allowed_and_gets_record(tmp_path, tripwires):
    d = tmp_path / "data" / "synthetic" / "empty"
    d.mkdir(parents=True)
    assert P.main(args(d)) == 1                         # fails at the (fake) missing library, as before the fix
    assert tripwires == ["environment"]
    rec = json_text(d / "kaggle_run_record.json")       # pre-fix behaviour preserved for an empty directory
    assert '"verdict": "FAILED"' in rec


def test_overwrite_flag_still_bypasses_guard(tmp_path, tripwires):
    d = make_legacy(tmp_path)
    assert P.main(args(d, "--overwrite")) == 1
    assert tripwires == ["environment"]                 # guard did not block; existing behaviour with --overwrite preserved
    assert '"verdict": "FAILED"' in json_text(d / "kaggle_run_record.json")
