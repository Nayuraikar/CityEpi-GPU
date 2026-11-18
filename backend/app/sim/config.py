"""Paths and limits for simulation execution. Everything is overridable by environment variable."""
import os
from pathlib import Path

from ..config import BUNDLE, REPO_ROOT

# Where each run gets its own isolated directory: <RUNS_DIR>/<run_id>/
RUNS_DIR = Path(os.environ.get("CITYEPI_RUNS_DIR", REPO_ROOT / "backend" / ".runs")).resolve()

# Population datasets that may be launched: sub-directories of these roots that contain population.cepop.
# Clients send only the directory name (a dataset id); they can never supply a filesystem path.
DATASET_ROOTS = [BUNDLE / "data" / "synthetic"]

# Smoke-test population used to probe that an executable (and, for V6, a GPU) really works.
PROBE_FIXTURE = REPO_ROOT / "tests" / "fixtures" / "tiny.cepop"

SNAPSHOT_MAX_DAYS = 400   # bounds snapshot disk use (100k agents x 401 frames ~ 10 MB)
MAX_CONCURRENT = int(os.environ.get("CITYEPI_SIM_MAX_CONCURRENT", "2"))
DEFAULT_TIMEOUT_S = 1800
MAX_TIMEOUT_S = 6 * 3600
PROBE_TTL_S = 60

# Input limits (validated on the server; the executable validates again).
LIMITS = {
    "days": (1, 1000),
    "seed": (0, 2**53 - 1),          # JSON numbers are doubles; larger seeds would silently lose precision in the browser
    "initial_infected": (0, 10_000_000),
    "beta": (0.0, 100.0),
    "incubation_days": (1, 365),
    "infectious_days": (1, 365),
    "timeout_seconds": (10, MAX_TIMEOUT_S),
}
