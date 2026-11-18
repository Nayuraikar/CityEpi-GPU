"""Derive summary statistics from a run's real daily S/E/I/R output (same definitions as the recorded-results API)."""
from __future__ import annotations

import csv
from pathlib import Path


def read_daily_csv(path: Path) -> list[list[int]]:
    rows: list[list[int]] = []
    with open(path, newline="") as f:
        r = csv.reader(f)
        header = next(r, None)
        if header != ["day", "S", "E", "I", "R"]:
            raise ValueError("unexpected daily CSV header")
        for row in r:
            rows.append([int(x) for x in row])
    return rows


def with_incidence(rows: list[list[int]]) -> list[dict]:
    out = []
    for i, (d, s, e, i_, r) in enumerate(rows):
        inc = max(rows[i - 1][1] - s, 0) if i else 0   # new infections = S[t-1] - S[t]
        out.append({"day": d, "S": s, "E": e, "I": i_, "R": r, "incidence": inc})
    return out


def summarize(rows: list[list[int]]) -> dict:
    series = with_incidence(rows)
    n = sum(rows[0][1:])
    last = series[-1]
    pk = max(series, key=lambda x: (x["I"], -x["day"]))
    pi = max(series, key=lambda x: (x["incidence"], -x["day"]))
    return {
        "agents": n,
        "days": last["day"],
        "final": {"S": last["S"], "E": last["E"], "I": last["I"], "R": last["R"]},
        "attack_rate_pct": round(100 * (1 - last["S"] / n), 3),
        "recovered_pct": round(100 * last["R"] / n, 3),
        "peak_infectious": pk["I"],
        "peak_day": pk["day"],
        "peak_daily_incidence": pi["incidence"],
        "peak_incidence_day": pi["day"],
    }
