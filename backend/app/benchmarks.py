"""GPU / backend benchmark loaders (V5 and V6 Kaggle artifacts)."""
from functools import lru_cache

import pandas as pd

from .config import RESULTS
from .util import read_csv_with_meta, read_header_meta, records

V5 = RESULTS / "kaggle_v5"
V6 = RESULTS / "kaggle_v6"


def _txt(p):
    return p.read_text().strip() if p.exists() else None


@lru_cache(maxsize=1)
def benchmarks() -> dict:
    v5, v5meta = read_csv_with_meta(V5 / "v5_benchmark.csv")
    if not v5meta and (V5 / "v5_benchmark.log").exists():   # the V5 CSV has no header; its provenance is echoed in the log
        v5meta = read_header_meta(V5 / "v5_benchmark.log")
    v6, v6meta = read_csv_with_meta(V6 / "v6_benchmark.csv")
    v6all, _ = read_csv_with_meta(V6 / "v6_benchmark_all.csv")
    prof = pd.read_csv(V6 / "v6_profile.csv")
    prof_all = pd.read_csv(V6 / "v6_profile_all.csv")
    gpu = _txt(V6 / "gpu_info.txt")
    return {
        "v5": {"rows": records(v5), "meta": v5meta},
        "v6": {"rows": records(v6), "meta": v6meta},
        "v6_all_scenarios": {"rows": records(v6all)},
        "v6_profile": records(prof),
        "v6_profile_all": records(prof_all),
        "git_commit": _txt(V6 / "git_commit.txt"),
        "gpu_info_head": (gpu or "").splitlines()[:3],
        "cuda_version": _txt(V6 / "cuda_version.txt"),
    }
