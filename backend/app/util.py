import json
import math
from pathlib import Path
from typing import Any

import pandas as pd


def clean(v: Any) -> Any:
    """Make values JSON-safe: NaN/inf/'n/a' -> None, numpy scalars -> python."""
    if isinstance(v, float):
        return None if (math.isnan(v) or math.isinf(v)) else v
    if isinstance(v, str):
        return None if v.strip().lower() in ("n/a", "inf", "nan", "") else v
    if hasattr(v, "item"):
        return clean(v.item())
    if isinstance(v, dict):
        return {k: clean(x) for k, x in v.items()}
    if isinstance(v, (list, tuple)):
        return [clean(x) for x in v]
    return v


def read_json(p: Path) -> Any:
    with open(p) as f:
        return json.load(f)


def read_csv_with_meta(p: Path) -> tuple[pd.DataFrame, dict[str, str]]:
    """CSV whose leading '# key=value' lines are environment metadata."""
    meta: dict[str, str] = {}
    notes: list[str] = []
    with open(p) as f:
        for line in f:
            if not line.startswith("#"):
                break
            body = line[1:].strip()
            if body.startswith("note:"):
                notes.append(body[5:].strip())
            elif body.startswith("kernel_info"):
                meta.setdefault("kernel_info", "")
                meta["kernel_info"] += body + "\n"
            elif "=" in body:
                k, _, v = body.partition("=")
                meta[k.strip()] = v.strip()
    if notes:
        meta["notes"] = " | ".join(notes)
    df = pd.read_csv(p, comment="#", na_values=["n/a", "inf"])
    return df, meta


def records(df: pd.DataFrame) -> list[dict]:
    return [clean(r) for r in df.to_dict(orient="records")]
