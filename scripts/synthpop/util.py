"""Shared small helpers: recorder for exclusions/notes, percentiles, hashing, RNG streams."""
import hashlib

import numpy as np

STREAM_HOME_COUNTS = 1
STREAM_AGENT_ORDER = 2
STREAM_ASSIGN = 3
EXAMPLES_PER_REASON = 10


def rng_for(seed, *stream):
    """Counter-style deterministic generator: independent streams keyed by (seed, *stream)."""
    return np.random.Generator(np.random.Philox(np.random.SeedSequence([int(seed)] + [int(s) for s in stream])))


class Recorder:
    """Collects every exclusion / repair / decision count so that nothing is dropped silently."""

    def __init__(self):
        self.exclusions = {}   # "stage|layer|reason" -> {"count": n, "examples": [...]}
        self.notes = []
        self.counters = {}
        self.timings = {}

    def exclude(self, stage, layer, reason, keys=None, count=None):
        keys = [] if keys is None else list(keys)
        n = len(keys) if count is None else int(count)
        if n == 0:
            return
        e = self.exclusions.setdefault(f"{stage}|{layer}|{reason}", {"stage": stage, "layer": layer, "reason": reason,
                                                                      "count": 0, "examples": []})
        e["count"] += n
        for k in keys[: max(0, EXAMPLES_PER_REASON - len(e["examples"]))]:
            e["examples"].append(str(k))

    def note(self, msg):
        self.notes.append(str(msg))

    def count(self, name, n=1):
        self.counters[name] = self.counters.get(name, 0) + int(n)

    def exclusion_list(self):
        return [self.exclusions[k] for k in sorted(self.exclusions)]


def pct(a, ps=(1, 5, 25, 50, 75, 95, 99)):
    a = np.asarray(a, dtype=float)
    a = a[np.isfinite(a)]
    if a.size == 0:
        return {"n": 0}
    out = {"n": int(a.size), "min": float(a.min()), "mean": float(a.mean())}
    for p, v in zip(ps, np.percentile(a, ps)):
        out[f"p{p}"] = float(v)
    out["max"] = float(a.max())
    return out


def gini(v):
    v = np.sort(np.asarray(v, dtype=float))
    if v.size == 0 or v.sum() == 0:
        return 0.0
    n = v.size
    return float((2 * np.arange(1, n + 1) - n - 1).dot(v) / (n * v.sum()))


def sha256_file(path, chunk=1 << 20):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(chunk), b""):
            h.update(b)
    return h.hexdigest()
