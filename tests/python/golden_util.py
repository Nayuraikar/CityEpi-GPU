"""Content fingerprints of a run directory, independent of Parquet container bytes (which depend on the pyarrow build)."""
import hashlib
import os

import numpy as np
import pandas as pd


def _h(*parts):
    m = hashlib.sha256()
    for p in parts:
        a = np.asarray(p)
        m.update(a.astype("U").tobytes() if a.dtype == object or a.dtype.kind in "US" else np.ascontiguousarray(a).tobytes())
    return m.hexdigest()


def fingerprints(d):
    ag = pd.read_parquet(os.path.join(d, "agents.parquet"))
    lo = pd.read_parquet(os.path.join(d, "locations.geoparquet"))
    dd = pd.read_parquet(os.path.join(d, "dedup_decisions.parquet"))
    return {
        "population.cepop_sha256": hashlib.sha256(open(os.path.join(d, "population.cepop"), "rb").read()).hexdigest(),
        "agents_columns": list(ag.columns),
        "agents_content": _h(*[ag[c].to_numpy() for c in ag.columns]),
        "locations_columns": list(lo.columns),
        "locations_content": _h(*[lo[c].to_numpy() for c in lo.columns if c != "geometry"]),
        "dedup_content": _h(*[dd[c].to_numpy() for c in dd.columns]),
    }
