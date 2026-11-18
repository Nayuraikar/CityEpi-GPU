"""Dataset discovery, backend availability probing and host information."""
from __future__ import annotations

import os
import platform
import re
import struct
import subprocess
import threading
import time
from dataclasses import dataclass, field
from pathlib import Path

from ..config import REPO_ROOT
from . import config

_ID_RE = re.compile(r"^[A-Za-z0-9._-]{1,128}$")


# ----------------------------------------------------------------------------- datasets
def read_cepop_header(path: Path) -> dict:
    """Parse only the 64-byte CEPOP v1 header. The executable does the full CRC/validation at run time."""
    with open(path, "rb") as f:
        h = f.read(64)
    if len(h) < 64 or h[:8] != b"CEPOPv1\x00":
        raise ValueError("not a CEPOP v1 file")
    version, _endian = struct.unpack_from("<II", h, 8)
    n_agents, n_locations = struct.unpack_from("<QQ", h, 16)
    return {"version": version, "agents": n_agents, "locations": n_locations, "file_bytes": path.stat().st_size}


def datasets() -> dict[str, dict]:
    out: dict[str, dict] = {}
    for root in config.DATASET_ROOTS:
        if not root.is_dir():
            continue
        for d in sorted(root.iterdir()):
            f = d / "population.cepop"
            if not (d.is_dir() and f.is_file() and _ID_RE.match(d.name)):
                continue
            try:
                hdr = read_cepop_header(f)
            except Exception:
                continue
            households = "households" in d.name
            out[d.name] = {
                "id": d.name,
                "label": ("Household population" if households else "Legacy population (no households)")
                + f" · {hdr['agents']:,} agents",
                "households": households,
                "path": f.resolve(),
                **hdr,
            }
    return out


def public_dataset(d: dict) -> dict:
    return {k: v for k, v in d.items() if k != "path"}


# ----------------------------------------------------------------------------- backends
@dataclass(frozen=True)
class BackendSpec:
    """One selectable simulation backend. To add another backend later, add a spec here (and verify it first)."""
    id: str
    label: str
    description: str
    cli_backend: str                 # value passed to extpop_run --backend
    env_var: str                     # overrides the executable path
    candidates: tuple[str, ...]      # executable locations tried in order (relative to repo root)
    progress_per_day: bool           # does the executable report real per-day progress for this backend?
    hardware: str                    # "cpu" | "gpu"
    needs_gpu: bool = False
    supports_snapshots: bool = False  # per-agent daily state snapshots (extpop_run --snapshots); V0 only for now
    extra_args: tuple[str, ...] = field(default_factory=tuple)


# V1-V3 are intentionally NOT registered: they are not exposed by extpop_run and have not been verified against V0 for external
# populations. V4/V5 likewise. A backend only appears once it is compiled in, reachable through extpop_run and checksum-verified.
BACKENDS: dict[str, BackendSpec] = {
    "v0": BackendSpec("v0", "V0 · CPU reference", "Sequential CPU reference implementation (source of truth).", "v0",
                      "CITYEPI_EXTPOP_RUN", ("build-sim/extpop_run",), True, "cpu", supports_snapshots=True),
    "v6": BackendSpec("v6", "V6 · CUDA", "Optimised CUDA kernels. Needs an NVIDIA GPU and a -DENABLE_CUDA_V6=ON build.", "v6",
                      "CITYEPI_EXTPOP_RUN_V6", ("build-cuda/extpop_run",), False, "gpu", needs_gpu=True),
}


def resolve_executable(spec: BackendSpec) -> Path | None:
    env = os.environ.get(spec.env_var)
    for c in ([env] if env else []) + list(spec.candidates):
        p = Path(c)
        p = p if p.is_absolute() else REPO_ROOT / p
        if p.is_file() and os.access(p, os.X_OK):
            return p.resolve()
    return None


_probe_lock = threading.Lock()
_probe_cache: dict[str, tuple[float, dict]] = {}


def _probe(spec: BackendSpec) -> dict:
    exe = resolve_executable(spec)
    if exe is None:
        return {"available": False, "reason": f"executable not found (looked for {', '.join(spec.candidates)}"
                + (f" or ${spec.env_var}" if spec.env_var else "") + ")", "executable": None}
    if not config.PROBE_FIXTURE.is_file():
        return {"available": False, "reason": "probe fixture tests/fixtures/tiny.cepop is missing", "executable": str(exe)}
    try:
        r = subprocess.run([str(exe), "--input", str(config.PROBE_FIXTURE), "--backend", spec.cli_backend, "--days", "1", "--init", "1"],
                           capture_output=True, text=True, timeout=60, stdin=subprocess.DEVNULL)
    except Exception as e:  # noqa: BLE001
        return {"available": False, "reason": f"probe failed to run: {e}", "executable": str(exe)}
    if r.returncode == 0:
        info = dict(re.findall(r"^(v6_device|v6_options)=(.*)$", r.stdout, flags=re.M))
        return {"available": True, "reason": None, "executable": str(exe), "device": info.get("v6_device")}
    why = (r.stderr.strip().splitlines() or ["no diagnostic output"])[-1]
    return {"available": False, "reason": why[:300], "executable": str(exe)}


def backend_status(spec: BackendSpec, refresh: bool = False) -> dict:
    with _probe_lock:
        hit = _probe_cache.get(spec.id)
        if hit and not refresh and time.time() - hit[0] < config.PROBE_TTL_S:
            return hit[1]
        res = _probe(spec)
        _probe_cache[spec.id] = (time.time(), res)
        return res


def backends(refresh: bool = False) -> list[dict]:
    out = []
    for s in BACKENDS.values():
        st = backend_status(s, refresh)
        out.append({"id": s.id, "label": s.label, "description": s.description, "hardware": s.hardware,
                    "progress_per_day": s.progress_per_day, "supports_snapshots": s.supports_snapshots, **st})
    return out


# ----------------------------------------------------------------------------- host
_host_cache: dict | None = None


def host_info() -> dict:
    global _host_cache
    if _host_cache is None:
        cpu = platform.processor() or platform.machine()
        try:
            if platform.system() == "Darwin":
                cpu = subprocess.run(["sysctl", "-n", "machdep.cpu.brand_string"], capture_output=True, text=True, timeout=5).stdout.strip() or cpu
            elif Path("/proc/cpuinfo").exists():
                m = re.search(r"model name\s*:\s*(.+)", Path("/proc/cpuinfo").read_text())
                cpu = m.group(1).strip() if m else cpu
        except Exception:  # noqa: BLE001
            pass
        _host_cache = {"platform": platform.platform(), "machine": platform.machine(), "cpu": cpu, "cpu_count": os.cpu_count()}
    return _host_cache
