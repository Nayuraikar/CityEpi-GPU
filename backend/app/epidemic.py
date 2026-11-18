"""Epidemic result loaders (actual CSV/JSON from the bundle only)."""
import re
from functools import lru_cache

import pandas as pd

from pathlib import PurePosixPath

from .config import RESULTS, SYN_HH
from .util import clean, read_json, records

POP = RESULTS / "epidemic_population_comparison"
SENS = RESULTS / "epidemic_transmission_sensitivity"
SEEDS = RESULTS / "final_10seed_validation"

RUNS = {
    "legacy": (POP, "legacy", "Legacy population (no households)"),
    "household": (POP, "household", "Household population"),
    "low": (SENS, "low", "Low transmission"),
    "baseline": (SENS, "baseline", "Baseline transmission"),
    "high": (SENS, "high", "High transmission"),
}


def _curve(path) -> pd.DataFrame:
    df = pd.read_csv(path)
    df["incidence"] = (df["S"].shift(1) - df["S"]).fillna(0).clip(lower=0)
    return df


def _summary(df: pd.DataFrame, n: int) -> dict:
    pk = df["I"].idxmax()
    inc = df["incidence"]
    return {
        "attack_rate_pct": round(100 * (1 - df["S"].iloc[-1] / n), 3),
        "recovered_pct": round(100 * df["R"].iloc[-1] / n, 3),
        "peak_infectious": int(df["I"].max()),
        "peak_day": int(df.loc[pk, "day"]),
        "peak_daily_incidence": int(inc.max()),
        "peak_incidence_day": int(df.loc[inc.idxmax(), "day"]),
        "final": {c: int(df[c].iloc[-1]) for c in "SEIR"},
    }


@lru_cache(maxsize=1)
def runs() -> dict:
    out = {}
    for key, (d, stem, label) in RUNS.items():
        meta = read_json(d / f"{stem}.json")
        n = meta["agents"]
        v0 = _curve(d / f"{stem}_v0.csv")
        v6 = _curve(d / f"{stem}_v6.csv")
        out[key] = {
            "key": key,
            "label": label,
            "agents": n,
            "days": meta["days"],
            "seed": meta["seed"],
            "initial_infected": meta["initial_infected"],
            "input": meta["input"],
            "dataset_id": PurePosixPath(meta["input"]).parent.name,
            "payload_crc32": meta["payload_crc32"],
            "v0_seconds": meta["v0"]["seconds"],
            "v6_seconds_total": meta["v6"]["seconds_total"],
            "v6_device": meta["v6"]["device"],
            "daily_checksum": meta["v0"]["daily_checksum"],
            "v0_v6_equal": meta["v0_v6_equal"],
            "curves_identical": bool(v0[list("SEIR")].equals(v6[list("SEIR")])),
            "summary": _summary(v6, n),
            "curve": records(v6[["day", "S", "E", "I", "R", "incidence"]]),
        }
    return out


@lru_cache(maxsize=1)
def seeds() -> dict:
    df = pd.read_csv(SEEDS / "all_seed_results.csv")
    summ = pd.read_csv(SEEDS / "summary_statistics.csv")
    curves: dict[str, dict[int, list]] = {}
    for p in sorted(SEEDS.glob("*_seed*_v0.csv")):
        m = re.match(r"(\w+)_seed(\d+)_v0\.csv", p.name)
        if not m:
            continue
        c = _curve(p)
        curves.setdefault(m.group(1), {})[int(m.group(2))] = records(c[["day", "S", "E", "I", "R", "incidence"]])
    # per-seed JSON presence (V6 is null for CPU-only seeds)
    json_seeds = {}
    for p in SEEDS.glob("*_seed*.json"):
        m = re.match(r"(\w+)_seed(\d+)\.json", p.name)
        j = read_json(p)
        json_seeds.setdefault(m.group(1), {})[int(m.group(2))] = {"v6_present": j.get("v6") is not None}
    # min/max of peak infectious are not in summary_statistics.csv; derived here from the recorded per-seed rows
    pk = df.groupby("scenario")["peak_infectious"].agg(["min", "max"])
    peak_range = {sc: {"peak_min": int(r["min"]), "peak_max": int(r["max"])} for sc, r in pk.iterrows()}
    inputs = {j.get("input") for p in SEEDS.glob("*_seed*.json") for j in [read_json(p)]}
    return {
        "backend": "V0 (CPU reference)",
        "population_inputs": sorted(PurePosixPath(i).parent.name for i in inputs if i),
        "peak_range": peak_range,
        "sd_convention": "sample SD (n−1), verified against all_seed_results.csv",
        "per_seed": records(df),
        "summary": records(summ),
        "curves": {k: {str(s): v for s, v in d.items()} for k, d in curves.items()},
        "curve_seed_counts": {k: len(d) for k, d in curves.items()},
        "n_seeds": int(df["seed"].nunique()),
        "seed_range": [int(df["seed"].min()), int(df["seed"].max())],
        "v6_runs_present": {k: sum(1 for x in d.values() if x["v6_present"]) for k, d in json_seeds.items()},
    }
