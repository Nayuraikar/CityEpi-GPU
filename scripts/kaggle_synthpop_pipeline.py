#!/usr/bin/env python3
"""Reproducible end-to-end run for Kaggle (also runs locally on any data directory):

  1. record environment (python/libs, CPU, GPU, nvcc, cmake)        5. build extpop_run + tests (V6 only if nvcc is present)
  2. generate the synthetic population from the GeoParquet layers   6. ctest (reader, integration, V6 integration)
  3. independent validation of the exported files                   7. extpop_run: CEPOP load -> validate_input -> V0 (and V6)
  4. determinism re-run (second generation, byte comparison)        8. write kaggle_run_record.json with checksums + verdict

Everything is written under data/synthetic/<run>/ (excluded from Git). Nothing is reported as passed unless the step
actually ran and passed; a V6 step that could not run is recorded as SKIPPED with the reason, and the verdict says so.

Kaggle notebook cells (GPU accelerator on, repo at /kaggle/working/CityEpi-GPU, data present as described in
docs/synthetic_population.md):
  !pip install -q geopandas pyarrow scipy pyogrio
  %cd /kaggle/working/CityEpi-GPU
  !python scripts/kaggle_synthpop_pipeline.py --n-agents 100000 --seed 42 --require-gpu
"""
import argparse
import datetime
import hashlib
import json
import os
import platform
import shutil
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DATA_FILES = ["population.cepop", "locations.geoparquet", "agents.parquet", "dedup_decisions.parquet", "households.parquet"]  # last one only exists with the household layer


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def sh(cmd, log_path=None, cwd=None, timeout=None):
    """Run a command, tee stdout+stderr into log_path, return (returncode, text, seconds)."""
    t = time.perf_counter()
    try:
        p = subprocess.run(cmd, cwd=cwd or ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=timeout)
        rc, out = p.returncode, p.stdout
    except FileNotFoundError as e:
        rc, out = 127, str(e)
    except subprocess.TimeoutExpired as e:
        rc, out = 124, (e.stdout or "") + "\nTIMEOUT"
    dt = time.perf_counter() - t
    if log_path:
        with open(log_path, "w") as f:
            f.write("$ " + " ".join(map(str, cmd)) + "\n" + out)
    return rc, out, dt


def tool_version(cmd):
    rc, out, _ = sh(cmd)
    return out.strip().splitlines()[0] if rc == 0 and out.strip() else None


def environment():
    env = {"python": sys.version.split()[0], "platform": platform.platform(), "machine": platform.machine(),
           "cpu_count": os.cpu_count(), "cmake": tool_version(["cmake", "--version"]), "cxx": tool_version(["c++", "--version"]),
           "nvcc": tool_version(["nvcc", "--version"]) if shutil.which("nvcc") else None, "libs": {}}
    for m in ("numpy", "pandas", "geopandas", "shapely", "pyarrow", "scipy", "pyproj", "pyogrio"):
        try:
            env["libs"][m] = __import__(m).__version__
        except Exception as e:  # noqa: BLE001
            env["libs"][m] = f"MISSING ({type(e).__name__})"
    try:
        with open("/proc/meminfo") as f:
            env["mem_total_kb"] = int(next(l for l in f if l.startswith("MemTotal")).split()[1])
    except Exception:  # noqa: BLE001
        env["mem_total_kb"] = None
    gpu = None
    if shutil.which("nvidia-smi"):
        rc, out, _ = sh(["nvidia-smi", "--query-gpu=name,driver_version,memory.total,compute_cap", "--format=csv,noheader"])
        if rc == 0 and out.strip():
            gpu = [x.strip() for x in out.strip().splitlines()[0].split(",")]
    env["gpu"] = ({"name": gpu[0], "driver": gpu[1], "memory": gpu[2], "compute_cap": gpu[3] if len(gpu) > 3 else None} if gpu else None)
    return env


class Record:
    def __init__(self):
        self.steps = {}

    def add(self, name, status, **kw):
        assert status in ("passed", "failed", "skipped")
        self.steps[name] = dict(status=status, **kw)
        tag = {"passed": "PASS", "failed": "FAIL", "skipped": "SKIP"}[status]
        extra = kw.get("reason") or (f"{kw['seconds']:.1f}s" if "seconds" in kw else "")
        print(f"[{tag}] {name} {extra}", flush=True)
        return status == "passed"


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--geo-dir", default="data/processed/geo")
    ap.add_argument("--boundary", default="data/boundaries/bengaluru_urban.geojson")
    ap.add_argument("--n-agents", type=int, default=100000)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--config", help="optional JSON config deep-merged over config/synthpop_default.json")
    ap.add_argument("--set", action="append", default=[], metavar="KEY.PATH=JSON", help="forwarded to the generator")
    ap.add_argument("--out-dir", help="default data/synthetic/bengaluru_urban_N<n>_seed<s>")
    ap.add_argument("--overwrite", action="store_true")
    ap.add_argument("--days", type=int, default=100, help="simulation days for extpop_run")
    ap.add_argument("--sim-seed", type=int, default=42)
    ap.add_argument("--init", type=int, default=100, help="initially infected agents (seeded by extpop_run)")
    ap.add_argument("--build-dir", default="build-extpop")
    ap.add_argument("--cuda-arch", help="CMAKE_CUDA_ARCHITECTURES; default: from nvidia-smi compute_cap, else 75 (T4)")
    ap.add_argument("--no-cuda", action="store_true", help="do not build V6 even if nvcc exists")
    ap.add_argument("--require-gpu", action="store_true", help="fail (instead of skipping) if the V6 round trip cannot run")
    ap.add_argument("--no-determinism-check", action="store_true")
    ap.add_argument("--allow-outside-synthetic", action="store_true")
    a = ap.parse_args(argv)

    t_start = time.perf_counter()
    out = a.out_dir or os.path.join("data", "synthetic", f"bengaluru_urban_N{a.n_agents}_seed{a.seed}")
    out = os.path.abspath(out)
    # Safety guard FIRST: nothing below (environment capture, finish(), logs) may touch an existing non-empty directory.
    if os.path.exists(out) and (not os.path.isdir(out) or (os.listdir(out) and not a.overwrite)):
        print(f"FAILED: output path {out} already exists and is not an empty directory (use --overwrite only if you mean to "
              f"reuse it); nothing was written", file=sys.stderr)
        return 1
    logs = os.path.join(out, "logs")
    rec = Record()
    record = {"started_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"), "args": vars(a), "steps": rec.steps}

    def finish(verdict, code):
        record["verdict"] = verdict
        record["total_seconds"] = round(time.perf_counter() - t_start, 2)
        if os.path.isdir(out):
            record["output_checksums"] = {os.path.relpath(os.path.join(d, f), out): sha256(os.path.join(d, f))
                                          for d, _, fs in os.walk(out) for f in sorted(fs) if f != "kaggle_run_record.json"}
            with open(os.path.join(out, "kaggle_run_record.json"), "w") as f:
                json.dump(record, f, indent=2)
        print(f"\nVERDICT: {verdict}" + (f"  (record: {out}/kaggle_run_record.json)" if os.path.isdir(out) else ""))
        return code

    # ---- 1. environment
    env = environment()
    record["environment"] = env
    print(f"python {env['python']}  gpu={env['gpu']}  nvcc={'yes' if env['nvcc'] else 'no'}", flush=True)
    for m, v in env["libs"].items():
        if str(v).startswith("MISSING") and m in ("geopandas", "pyarrow", "scipy", "shapely", "numpy", "pandas", "pyproj"):
            rec.add("environment", "failed", reason=f"required library missing: {m}")
            return finish("FAILED", 1)
    rec.add("environment", "passed")
    os.makedirs(logs, exist_ok=True)

    # ---- 2. generate
    gen_cmd = [sys.executable, os.path.join(HERE, "generate_synthetic_population.py"), "--geo-dir", a.geo_dir, "--boundary", a.boundary,
               "--n-agents", str(a.n_agents), "--seed", str(a.seed), "--out-dir", out, "--overwrite"]
    if a.config:
        gen_cmd += ["--config", a.config]
    if a.allow_outside_synthetic:
        gen_cmd += ["--allow-outside-synthetic"]
    for s in a.set:
        gen_cmd += ["--set", s]
    rc, text, dt = sh(gen_cmd, os.path.join(logs, "generate.log"))
    if not rec.add("generate", "passed" if rc == 0 else "failed", seconds=dt, returncode=rc, log="logs/generate.log"):
        print(text[-2000:])
        return finish("FAILED", 1)
    try:
        report = json.load(open(os.path.join(out, "report.json")))
        record["config_sha256"] = report["config_sha256"]
        record["config"] = report["config"]
        record["input_checksums"] = {k: v.get("sha256") for k, v in report["inputs"].items()}
        record["counts"] = report["counts"]
        record["generator_validation"] = {"passed": report["validation"]["passed"], "n_checks": report["validation"]["n_checks"]}
        record["generator_timings_s"] = report.get("timings_s")
    except Exception as e:  # noqa: BLE001
        rec.add("read_report", "failed", reason=str(e))
        return finish("FAILED", 1)

    # ---- 3. independent validation
    rc, text, dt = sh([sys.executable, os.path.join(HERE, "validate_synthetic_population.py"), "--run-dir", out, "--boundary", a.boundary],
                      os.path.join(logs, "validate_independent.log"))
    if not rec.add("independent_validation", "passed" if rc == 0 else "failed", seconds=dt, returncode=rc, log="logs/validate_independent.log"):
        print(text[-2000:])
        return finish("FAILED", 1)

    # ---- 4. determinism
    if a.no_determinism_check:
        rec.add("determinism_rerun", "skipped", reason="--no-determinism-check")
    else:
        out2 = out + "_rerun"
        shutil.rmtree(out2, ignore_errors=True)
        cmd2 = [c for c in gen_cmd]
        cmd2[cmd2.index("--out-dir") + 1] = out2
        cmd2 += ["--no-sensitivity"]  # sensitivity runs do not influence the exported files
        rc, text, dt = sh(cmd2, os.path.join(logs, "generate_rerun.log"))
        if rc != 0:
            rec.add("determinism_rerun", "failed", seconds=dt, reason="rerun generation failed", log="logs/generate_rerun.log")
            return finish("FAILED", 1)
        same = {f: sha256(os.path.join(out, f)) == sha256(os.path.join(out2, f)) for f in DATA_FILES
                if os.path.exists(os.path.join(out, f)) or os.path.exists(os.path.join(out2, f))}
        shutil.rmtree(out2, ignore_errors=True)
        ok = rec.add("determinism_rerun", "passed" if all(same.values()) else "failed", seconds=dt, identical=same)
        if not ok:
            return finish("FAILED", 1)

    # ---- 5. build
    have_nvcc = bool(env["nvcc"]) and not a.no_cuda
    arch = a.cuda_arch
    if have_nvcc and not arch:
        cc = (env["gpu"] or {}).get("compute_cap")
        arch = cc.replace(".", "") if cc and cc.replace(".", "").isdigit() else "75"
    bdir = os.path.join(ROOT, a.build_dir)
    cfg_cmd = ["cmake", "-S", ROOT, "-B", bdir, "-DCMAKE_BUILD_TYPE=Release"] + (["-DENABLE_CUDA_V6=ON", f"-DCMAKE_CUDA_ARCHITECTURES={arch}"] if have_nvcc else [])
    rc, text, dt = sh(cfg_cmd, os.path.join(logs, "cmake_configure.log"))
    if rc == 0:
        rc, text, dt2 = sh(["cmake", "--build", bdir, "-j", str(os.cpu_count() or 2), "--target", "extpop_run", "test_extpop_reader",
                            "test_extpop_integration"], os.path.join(logs, "cmake_build.log"))
        dt += dt2
    record["build"] = {"v6_enabled": have_nvcc, "cuda_arch": arch if have_nvcc else None, "configure": cfg_cmd}
    if not rec.add("build", "passed" if rc == 0 else "failed", seconds=dt, returncode=rc, log="logs/cmake_build.log"):
        print(text[-3000:])
        return finish("FAILED", 1)

    # ---- 6. ctest
    rc, text, dt = sh(["ctest", "--test-dir", bdir, "-R", "extpop", "--output-on-failure"], os.path.join(logs, "ctest_extpop.log"))
    skipped_v6_in_tests = "SKIPPED: V6" in text
    rec.add("ctest_extpop", "passed" if rc == 0 else "failed", seconds=dt, returncode=rc, log="logs/ctest_extpop.log",
            v6_part_skipped=skipped_v6_in_tests, tests_run=[l.split(":")[1].strip().split(" ")[0] for l in text.splitlines() if "Test #" in l])
    if rc != 0:
        print(text[-3000:])
        return finish("FAILED", 1)

    # ---- 7. extpop_run
    exe = os.path.join(bdir, "extpop_run")
    cepop_path = os.path.join(out, "population.cepop")
    common = ["--input", cepop_path, "--days", str(a.days), "--seed", str(a.sim_seed), "--init", str(a.init),
              "--expect-agents", str(a.n_agents)]
    if "locations" in record["counts"]:
        common += ["--expect-locations", str(record["counts"]["locations"])]
    j0 = os.path.join(out, "extpop_v0.json")
    rc, text, dt = sh([exe] + common + ["--backend", "v0", "--json", j0, "--daily-csv", os.path.join(out, "daily")], os.path.join(logs, "extpop_v0.log"))
    v0ok = rec.add("extpop_run_v0", "passed" if rc == 0 else "failed", seconds=dt, returncode=rc, log="logs/extpop_v0.log")
    if v0ok:
        record["extpop_v0"] = json.load(open(j0))
    else:
        print(text[-2000:])
        return finish("FAILED", 1)
    v6_ran = False
    if not have_nvcc:
        reason = "built without V6: nvcc not found" if not a.no_cuda else "--no-cuda"
        rec.add("extpop_run_v0_v6", "failed" if a.require_gpu else "skipped", reason=reason)
        if a.require_gpu:
            return finish("FAILED", 1)
    else:
        j6 = os.path.join(out, "extpop_v0_v6.json")
        rc, text, dt = sh([exe] + common + ["--backend", "both", "--json", j6, "--daily-csv", os.path.join(out, "daily")], os.path.join(logs, "extpop_v0_v6.log"))
        if rc == 0:
            v6_ran = rec.add("extpop_run_v0_v6", "passed", seconds=dt, returncode=rc, log="logs/extpop_v0_v6.log")
            record["extpop_v0_v6"] = json.load(open(j6))
        elif rc == 2 and not a.require_gpu:
            rec.add("extpop_run_v0_v6", "skipped", reason="no usable GPU (extpop_run exit 2)", log="logs/extpop_v0_v6.log")
        else:
            rec.add("extpop_run_v0_v6", "failed", seconds=dt, returncode=rc, log="logs/extpop_v0_v6.log")
            print(text[-3000:])
            return finish("FAILED", 1)
    if a.require_gpu and skipped_v6_in_tests:
        rec.add("v6_in_ctest", "failed", reason="V6 integration test was skipped although --require-gpu was given")
        return finish("FAILED", 1)

    verdict = "ALL_PASSED" if v6_ran and not skipped_v6_in_tests else "PASSED_V6_NOT_RUN"
    return finish(verdict, 0)


if __name__ == "__main__":
    sys.exit(main())
