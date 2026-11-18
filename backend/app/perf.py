"""PAGP Performance Lab data: CPU (Apple M1) and Kaggle OpenACC benchmark artifacts plus correctness evidence.

Read-only. Every number returned here is parsed from a recorded file; nothing is computed beyond what the
source columns allow, and nothing is extrapolated. V5/V6 data is served by benchmarks.py (/api/benchmarks).
"""
from __future__ import annotations

import re
from functools import lru_cache
from pathlib import Path

import pandas as pd

from .config import REPO_ROOT, RESULTS
from .util import clean, read_csv_with_meta, records

LOCAL_RESULTS = REPO_ROOT / "bench" / "results"


def _find(rel: str) -> Path | None:
    """Locate a result file in the UI bundle first, then in the repository's bench/results."""
    for root in (RESULTS, LOCAL_RESULTS):
        p = root / rel
        if p.is_file():
            return p
    return None


def _text(rel: str) -> str | None:
    p = _find(rel)
    return p.read_text(errors="replace") if p else None


def _tail(rel: str, n: int) -> list[str]:
    """Last n lines of a (possibly huge) log without loading it all."""
    p = _find(rel)
    if not p:
        return []
    with open(p, "rb") as f:
        f.seek(0, 2)
        size = f.tell()
        f.seek(max(0, size - 64 * 1024))
        data = f.read().decode(errors="replace")
    return data.splitlines()[-n:]


def _csv(rel: str) -> dict | None:
    p = _find(rel)
    if not p:
        return None
    df, meta = read_csv_with_meta(p)
    return {"file": f"bench/results/{rel}", "meta": meta, "rows": records(df)}


def _kv(text: str | None) -> dict[str, str]:
    out: dict[str, str] = {}
    for line in (text or "").splitlines():
        if ":" in line:
            k, _, v = line.partition(":")
            out[k.strip()] = v.strip()
    return out


@lru_cache(maxsize=1)
def perf() -> dict:
    v2 = _csv("v2_results.csv")
    v3 = _csv("v3_results.csv")
    v3h = _csv("v3_hybrid_results.csv")
    v4 = _csv("kaggle_v4/v4_gpu_results.csv")
    v5 = _csv("kaggle_v5/v5_benchmark.csv")
    v6 = _csv("kaggle_v6/v6_benchmark_all.csv")

    # Equivalence evidence counted from the recorded CSV columns (no inference).
    def ident(rows, *cols):
        n = ok = 0
        for r in rows or []:
            for c in cols:
                if c in r and r[c] is not None:
                    n += 1
                    ok += r[c] == "yes"
        return {"checked": n, "identical": ok}

    v4_tail = _tail("kaggle_v4/v4_gpu_test.log", 6)
    v6_log = _text("kaggle_v6/test_v6.log") or ""
    m = re.search(r"(\d+) V6 comparisons on (.+?); V6 OK", v6_log)
    skip = re.search(r"E3 skip_exp: (.+)", v6_log)
    fp6 = re.search(r"1-exp\(-x\) device vs host.*?: (\d+)/(\d+) bitwise differences, max rel diff (\S+)", v6_log)
    fp4 = next((re.search(r"(\d+)/(\d+) bitwise differences, max rel diff (\S+)", l) for l in v4_tail if "bitwise differences" in l), None)
    m4 = next((re.search(r"(\d+) V4 comparisons \[(.+?)\]; V4 OK", l) for l in v4_tail if "V4 comparisons" in l), None)

    return clean({
        "apple_m1": {
            "env": {"v2": _kv(_text("v2_env.txt")), "v3": _text("v3_env.txt")},
            "v2": v2, "v3": v3, "v3_hybrid": v3h,
        },
        "kaggle_v4": {"results": v4, "test_tail": v4_tail},
        "kaggle_v5": v5 and {"file": v5["file"], "meta": v5["meta"]},
        "kaggle_v6": v6 and {"file": v6["file"], "meta": v6["meta"]},
        "correctness": {
            "v2_v3_cpu_rows": {"v2_csv": ident(v2 and v2["rows"], "identical"),
                               "v3_csv": ident(v3 and v3["rows"], "identical"),
                               "v3_hybrid_csv": ident(v3h and v3h["rows"], "identical")},
            "v4": {"rows": ident(v4 and v4["rows"], "identical"),
                   "test_comparisons": int(m4.group(1)) if m4 else None, "test_target": m4.group(2) if m4 else None,
                   "fp": {"differ": int(fp4.group(1)), "of": int(fp4.group(2)), "max_rel": fp4.group(3)} if fp4 else None},
            "v5": {"rows": ident(v5 and v5["rows"], "identical")},
            "v6": {"rows": ident(v6 and v6["rows"], "identical_v0", "identical_v5"),
                   "test_comparisons": int(m.group(1)) if m else None, "test_device": m.group(2) if m else None,
                   "skip_exp": skip.group(1).strip() if skip else None,
                   "fp": {"differ": int(fp6.group(1)), "of": int(fp6.group(2)), "max_rel": fp6.group(3)} if fp6 else None,
                   "test_log": v6_log.strip().splitlines()[:5]},
        },
    })
