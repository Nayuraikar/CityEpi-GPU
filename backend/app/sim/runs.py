"""Run lifecycle: queued -> running -> completed | failed | cancelled.

* Every run has a unique id and its own directory (<RUNS_DIR>/<id>/); nothing is shared between runs.
* Each run executes `extpop_run` in a child process (own process group) from a worker thread, never on the event loop.
* Progress is parsed from the executable's own `PROGRESS` lines (one per really simulated day); it is never estimated.
* Timeout / cancel kill the whole process group (SIGTERM, then SIGKILL).
"""
from __future__ import annotations

import json
import os
import re
import shutil
import signal
import subprocess
import threading
import time
import uuid
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from . import config, registry, results, snapshots
from .models import RunRequest, build_args, validate_request

QUEUED, RUNNING, COMPLETED, FAILED, CANCELLED = "queued", "running", "completed", "failed", "cancelled"
TERMINAL = {COMPLETED, FAILED, CANCELLED}
_ID_RE = re.compile(r"^r\d{14}-[0-9a-f]{8}$")
_PROGRESS_RE = re.compile(r"^PROGRESS day=(\d+) total=(\d+) S=(\d+) E=(\d+) I=(\d+) R=(\d+) elapsed=([0-9.]+)$")
_KV_RE = re.compile(r"^([A-Za-z0-9_]+)=(.*)$")
KILL_GRACE_S = 5


def _now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds")


class Run:
    def __init__(self, meta: dict, dir_: Path):
        self.meta = meta
        self.dir = dir_
        self.lock = threading.Lock()
        self.series: list[list[int]] = []        # [day,S,E,I,R] of really completed days (live runs)
        self.proc: subprocess.Popen | None = None
        self.cancel_requested = False
        self.kill_reason: str | None = None

    @property
    def id(self) -> str:
        return self.meta["id"]

    @property
    def state(self) -> str:
        return self.meta["state"]

    def save(self) -> None:
        tmp = self.dir / "meta.json.tmp"
        tmp.write_text(json.dumps(self.meta, indent=2))
        os.replace(tmp, self.dir / "meta.json")      # atomic: readers never see a half-written file

    def snapshot(self) -> dict:
        with self.lock:
            return json.loads(json.dumps(self.meta))


class RunError(Exception):
    def __init__(self, status: int, message: str, errors: list | None = None):
        super().__init__(message)
        self.status, self.message, self.errors = status, message, errors or []


class RunManager:
    def __init__(self, runs_dir: Path = config.RUNS_DIR, max_concurrent: int = config.MAX_CONCURRENT):
        self.runs_dir = runs_dir
        self.runs_dir.mkdir(parents=True, exist_ok=True)
        self._runs: dict[str, Run] = {}
        self._lock = threading.Lock()
        self._pool = ThreadPoolExecutor(max_workers=max(1, max_concurrent), thread_name_prefix="sim")
        self._closed = False
        self._recover()

    # ------------------------------------------------------------------ startup recovery
    def _recover(self) -> None:
        for d in sorted(self.runs_dir.iterdir()):
            mf = d / "meta.json"
            if not (d.is_dir() and _ID_RE.match(d.name) and mf.is_file()):
                continue
            try:
                meta = json.loads(mf.read_text())
            except Exception:  # noqa: BLE001
                continue
            run = Run(meta, d)
            if meta.get("state") not in TERMINAL:      # the server died while this run was queued/running
                meta["state"] = FAILED
                meta["finished_at"] = _now()
                meta["error"] = {"code": "interrupted", "message": "The API server restarted while this run was active; the run was abandoned."}
                run.save()
            self._runs[meta["id"]] = run

    # ------------------------------------------------------------------ public API
    def submit(self, raw: Any) -> dict:
        if self._closed:
            raise RunError(503, "server is shutting down")
        req, errors, _warn, ds = validate_request(raw)
        if req is None:
            raise RunError(422, "invalid simulation configuration", errors)
        spec = registry.BACKENDS[req.backend]
        status = registry.backend_status(spec)
        run_id = f"r{datetime.now(timezone.utc):%Y%m%d%H%M%S}-{uuid.uuid4().hex[:8]}"
        d = self.runs_dir / run_id
        d.mkdir(parents=True, exist_ok=False)          # unique: refuses to reuse an existing directory
        exe = Path(status["executable"])
        args = build_args(req, spec, ds["path"], d / "daily", d / "result.json", d / "snapshots")
        meta = {
            "id": run_id, "state": QUEUED, "label": req.label,
            "created_at": _now(), "started_at": None, "finished_at": None,
            "request": req.model_dump(exclude={"label"}),
            "dataset": {"id": ds["id"], "label": ds["label"], "agents": ds["agents"], "locations": ds["locations"], "households": ds["households"]},
            "backend": {"id": spec.id, "label": spec.label, "hardware": spec.hardware, "device": status.get("device")},
            "host": registry.host_info(),
            "executable": str(exe), "command": [str(exe), *args],
            "timeout_seconds": req.timeout_seconds,
            "progress": {"supported": spec.progress_per_day, "day": None, "total_days": req.days, "fraction": None,
                         "S": None, "E": None, "I": None, "R": None, "sim_elapsed_seconds": None},
            "exit_code": None, "error": None, "output": None, "result": None,
            # "available" becomes true only after the snapshot file passed full validation (see _execute_inner)
            "snapshots": {"requested": req.snapshots, "available": False, "backend_support": "v0-only", "info": None, "validation": None},
        }
        run = Run(meta, d)
        run.save()
        with self._lock:
            self._runs[run_id] = run
        self._pool.submit(self._execute, run)
        return run.snapshot()

    def get(self, run_id: str) -> Run:
        run = self._runs.get(run_id) if _ID_RE.match(run_id or "") else None
        if run is None:
            raise RunError(404, f"unknown run '{run_id}'")
        return run

    def list(self) -> list[dict]:
        with self._lock:
            runs = list(self._runs.values())
        runs.sort(key=lambda r: r.meta["created_at"], reverse=True)
        out = []
        for r in runs:
            m = r.snapshot()
            m.pop("command", None)
            out.append(m)
        return out

    def cancel(self, run_id: str) -> dict:
        run = self.get(run_id)
        with run.lock:
            if run.state in TERMINAL:
                raise RunError(409, f"run is already {run.state}")
            run.cancel_requested = True
            queued = run.state == QUEUED
        if queued:
            self._finish_cancelled_queued(run)
        else:
            self._kill(run, "cancel")
        return run.snapshot()

    def delete(self, run_id: str) -> None:
        run = self.get(run_id)
        if run.state not in TERMINAL:
            raise RunError(409, f"run is {run.state}; cancel it before deleting")
        with self._lock:
            self._runs.pop(run_id, None)
        shutil.rmtree(run.dir, ignore_errors=True)

    def series(self, run_id: str, since: int = -1) -> dict:
        """Daily rows (with new-infection counts) strictly after day `since`."""
        run = self.get(run_id)
        with run.lock:
            live = list(run.series)
            state = run.state
        if state == COMPLETED or (not live and (run.dir / "daily_v0.csv").exists()):
            try:
                rows = results.read_daily_csv(next(run.dir.glob("daily_*.csv")))
            except Exception:  # noqa: BLE001
                rows = live
        else:
            rows = live
        full = results.with_incidence(rows)
        return {"state": state, "rows": [r for r in full if r["day"] > since], "n_days_available": len(full)}

    def result(self, run_id: str) -> dict:
        run = self.get(run_id)
        if run.state != COMPLETED:
            raise RunError(409, f"run is {run.state}; results exist only for completed runs")
        return run.snapshot()

    def shutdown(self) -> None:
        self._closed = True
        for run in list(self._runs.values()):
            with run.lock:
                if run.state in TERMINAL:
                    continue
                run.cancel_requested = True
                queued = run.state == QUEUED
            if queued:
                self._finish_cancelled_queued(run)
            else:
                self._kill(run, "shutdown")
        self._pool.shutdown(wait=True, cancel_futures=True)

    # ------------------------------------------------------------------ internals
    def _finish_cancelled_queued(self, run: Run) -> None:
        with run.lock:
            if run.state != QUEUED:
                return
            run.meta["state"] = CANCELLED
            run.meta["finished_at"] = _now()
            run.meta["error"] = {"code": "cancelled", "message": "Cancelled while queued; the simulation never started."}
            run.save()

    def _kill(self, run: Run, reason: str) -> None:
        with run.lock:
            proc = run.proc
            if proc is None:
                return
            if proc.poll() is not None:
                # Leader already gone. Only continue if we are cleaning up after our own kill, or enforcing a timeout on a
                # group whose stray members still hold the stdout pipe open; a normal finished run must not be re-labelled.
                if run.kill_reason is None and reason != "timeout":
                    return
            run.kill_reason = run.kill_reason or reason
        pgid = proc.pid
        try:
            os.killpg(pgid, signal.SIGTERM)
        except ProcessLookupError:
            return

        def _group_alive() -> bool:
            try:
                os.killpg(pgid, 0)
                return True
            except ProcessLookupError:
                return False
            except PermissionError:
                return False      # pgid recycled by an unrelated process: not ours

        def _escalate():
            # Wait for the WHOLE process group, not just the leader. A child forked while SIGTERM was in flight survives the
            # signal, becomes an orphan and keeps the stdout pipe open, which blocks the worker thread forever.
            deadline = time.monotonic() + KILL_GRACE_S
            while time.monotonic() < deadline:
                if proc.poll() is None:
                    try:
                        proc.wait(timeout=0.05)
                    except subprocess.TimeoutExpired:
                        continue
                if not _group_alive():
                    return
                time.sleep(0.02)
            try:
                os.killpg(pgid, signal.SIGKILL)
            except (ProcessLookupError, PermissionError):
                pass
        threading.Thread(target=_escalate, daemon=True).start()

    def _fail(self, run: Run, state: str, code: str, message: str, exit_code: int | None = None) -> None:
        with run.lock:
            run.meta["state"] = state
            run.meta["finished_at"] = _now()
            run.meta["exit_code"] = exit_code
            run.meta["error"] = {"code": code, "message": message}
            run.save()
        # a failed/cancelled run must not leave output that looks like a valid result
        for p in list(run.dir.glob("daily_*.csv")) + [run.dir / "result.json"]:
            p.unlink(missing_ok=True)
        shutil.rmtree(run.dir / "snapshots", ignore_errors=True)

    def _execute(self, run: Run) -> None:
        try:
            self._execute_inner(run)
        except Exception as e:  # noqa: BLE001  (never leave a run stuck in 'running')
            if run.state not in TERMINAL:
                self._fail(run, FAILED, "internal_error", f"{type(e).__name__}: {e}")

    def _execute_inner(self, run: Run) -> None:
        # ONE critical section for "still queued?" + "cancel requested?" + QUEUED->RUNNING. Previously these were separate
        # lock acquisitions, so a cancel() landing in between marked the run cancelled and the worker then overwrote it
        # with RUNNING and started the process anyway (reproduced ~1/400 with an immediate submit+cancel stress loop).
        with run.lock:
            if run.state != QUEUED:                    # already cancelled while queued
                return
            if not run.cancel_requested:
                run.meta["state"] = RUNNING
                run.meta["started_at"] = _now()
                run.save()
                cancelled = False
            else:
                cancelled = True
        if cancelled:
            self._finish_cancelled_queued(run)
            return
        spec = registry.BACKENDS[run.meta["backend"]["id"]]
        stderr_path = run.dir / "stderr.log"
        stdout_path = run.dir / "stdout.log"
        with open(stderr_path, "wb") as errf, open(stdout_path, "w") as outf, open(run.dir / "progress.csv", "w") as progf:
            progf.write("day,S,E,I,R\n")
            try:
                proc = subprocess.Popen(run.meta["command"], stdout=subprocess.PIPE, stderr=errf, stdin=subprocess.DEVNULL,
                                        cwd=run.dir, text=True, bufsize=1, start_new_session=True)
            except OSError as e:
                self._fail(run, FAILED, "spawn_failed", f"could not start the simulation executable: {e}")
                return
            with run.lock:
                run.proc = proc
                cancel_now = run.cancel_requested
            if cancel_now:
                self._kill(run, "cancel")
            timer = threading.Timer(run.meta["timeout_seconds"], self._kill, args=(run, "timeout"))
            timer.daemon = True
            timer.start()
            kv: dict[str, str] = {}
            try:
                for line in proc.stdout:               # blocks until output or EOF (EOF also when the group is killed)
                    outf.write(line)
                    line = line.rstrip("\n")
                    m = _PROGRESS_RE.match(line)
                    if m:
                        day, total, s, e, i, r = (int(x) for x in m.groups()[:6])
                        row = [day, s, e, i, r]
                        progf.write(f"{day},{s},{e},{i},{r}\n")
                        progf.flush()
                        with run.lock:
                            run.series.append(row)
                            run.meta["progress"].update({
                                "day": day, "total_days": total, "fraction": day / total if total else None,
                                "S": s, "E": e, "I": i, "R": r, "sim_elapsed_seconds": float(m.group(7))})
                            run.save()
                        continue
                    if line.startswith("RESULT: "):
                        kv["RESULT"] = line[8:].strip()
                        continue
                    km = _KV_RE.match(line)
                    if km:
                        kv[km.group(1)] = km.group(2)
                rc = proc.wait()
            finally:
                timer.cancel()
                if proc.poll() is None:                # belt and braces: never leak a child
                    try:
                        os.killpg(proc.pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
                    proc.wait()
                try:
                    proc.stdout.close()
                except Exception:  # noqa: BLE001
                    pass

        stderr_tail = self._tail(stderr_path)
        reason = run.kill_reason
        if reason == "cancel":
            self._fail(run, CANCELLED, "cancelled", "Cancelled by user; the simulation process was terminated.", rc)
            return
        if reason == "shutdown":
            self._fail(run, CANCELLED, "server_shutdown", "The API server shut down; the simulation process was terminated.", rc)
            return
        if reason == "timeout":
            self._fail(run, FAILED, "timeout", f"Exceeded the {run.meta['timeout_seconds']}s time limit and was terminated.", rc)
            return
        if rc == 2:
            self._fail(run, FAILED, "backend_unavailable", stderr_tail or "The requested backend is unavailable.", rc)
            return
        if rc != 0:
            msg = stderr_tail or (f"killed by signal {-rc}" if rc < 0 else f"executable exited with status {rc}")
            self._fail(run, FAILED, "executable_error", msg, rc)
            return

        # ---- success path: verify the output really is a complete, consistent run before calling it completed
        try:
            tag = spec.cli_backend
            csv_path = run.dir / f"daily_{tag}.csv"
            rows = results.read_daily_csv(csv_path)
            req = run.meta["request"]
            if len(rows) != req["days"] + 1:
                raise ValueError(f"expected {req['days'] + 1} daily rows, found {len(rows)}")
            if kv.get(f"{tag}_population_conserved") != "yes" or kv.get("RESULT") != "PASS":
                raise ValueError("executable did not report PASS / population conservation")
            if run.series and run.series[-1] != rows[-1]:
                raise ValueError("final progress line disagrees with the daily CSV")
            summary = results.summarize(rows)
            summary["runtime_seconds"] = float(kv.get(f"{tag}_seconds", kv.get(f"{tag}_seconds_total", "nan")))
            summary["daily_checksum"] = kv.get(f"{tag}_daily_checksum")
            snap_meta = None
            if req.get("snapshots"):
                try:
                    snap_meta = self._validate_snapshots(run, rows, kv)
                except Exception as se:  # noqa: BLE001
                    raise ValueError(f"snapshot validation failed: {se}") from se
        except Exception as e:  # noqa: BLE001
            self._fail(run, FAILED, "invalid_output", f"The simulation finished but its output failed verification: {e}", rc)
            return
        with run.lock:
            run.meta["state"] = COMPLETED
            run.meta["finished_at"] = _now()
            run.meta["exit_code"] = rc
            run.meta["output"] = kv
            run.meta["result"] = summary
            if snap_meta is not None:
                run.meta["snapshots"].update(snap_meta)
            if run.meta["backend"]["device"] is None and kv.get("v6_device"):
                run.meta["backend"]["device"] = kv["v6_device"]
            run.meta["progress"].update({"day": req["days"], "fraction": 1.0 if spec.progress_per_day else None})
            run.save()

    def _validate_snapshots(self, run: Run, rows: list[list[int]], kv: dict) -> dict:
        """Full validation of the run's snapshot file against its own daily CSV and the dataset's home_loc. Raises on any problem."""
        if kv.get("snapshots_status") != "ok":
            raise ValueError("executable did not report snapshots_status=ok")
        path = run.dir / "snapshots" / snapshots.FILE_NAME
        ds = registry.datasets().get(run.meta["dataset"]["id"])
        if ds is None:
            raise ValueError("dataset disappeared; cannot verify snapshot home_loc")
        reader = snapshots.SnapshotReader(path)
        try:
            report = reader.validate(rows, snapshots.read_cepop_home_loc(ds["path"]))
            info = reader.info()
        finally:
            reader.close()
        if f"0x{int(report['payload_crc32'], 16):08x}" != kv.get("snapshots_payload_crc32"):
            raise ValueError("snapshot CRC differs from the one the executable reported")
        (run.dir / "snapshots" / "snapshot_meta.json").write_text(json.dumps({"info": info, "validation": report}, indent=2))
        return {"available": True, "info": info, "validation": report}

    @staticmethod
    def _tail(p: Path, n: int = 600) -> str:
        try:
            data = p.read_bytes()[-4000:].decode("utf-8", "replace").strip().splitlines()
            return " ".join(data)[-n:]
        except OSError:
            return ""
