"""Home apportionment and deterministic batched distance-sensitive destination assignment (metric coordinates, EPSG:32643).

All randomness comes from counter-style Philox streams keyed by (seed, stream, ...), so results do not depend on
iteration order, process count or batching of unassigned agents."""
import numpy as np
from scipy.spatial import cKDTree

from .util import STREAM_AGENT_ORDER, STREAM_ASSIGN, STREAM_HOME_COUNTS, gini, pct, rng_for


class AssignmentError(RuntimeError):
    def __init__(self, msg, details=None):
        super().__init__(msg)
        self.details = details or {}


# ---------------------------------------------------------------- homes
def apportion_homes(weights, caps, n_agents, seed):
    """Exactly n_agents distributed over homes, expectation proportional to weight, hard per-home cap.

    1) water-filling: homes whose proportional quota exceeds the cap are fixed at the cap and the rest re-solved;
    2) integer parts of the remaining quotas; 3) remaining units by seeded systematic sampling of the fractional
    parts (each home gets +1 with probability == its fractional part; never more than 1)."""
    w = np.asarray(weights, dtype=float)
    caps = np.asarray(caps, dtype=np.int64)
    if caps.sum() < n_agents:
        raise AssignmentError(f"home capacity {int(caps.sum())} < n_agents {n_agents}",
                              {"home_capacity_total": int(caps.sum()), "n_agents": int(n_agents)})
    counts = np.zeros(len(w), dtype=np.int64)
    free = np.ones(len(w), bool)
    remaining = int(n_agents)
    n_capped = 0
    while True:
        q = remaining * w[free] / w[free].sum()
        over = q > caps[free]
        if not over.any():
            break
        fi = np.flatnonzero(free)[over]
        counts[fi] = caps[fi]
        free[fi] = False
        remaining -= int(caps[fi].sum())
        n_capped += len(fi)
        if remaining < 0 or not free.any():
            raise AssignmentError("home apportionment infeasible after capping")
    fi = np.flatnonzero(free)
    base = np.floor(q).astype(np.int64)
    frac = q - base
    extra = remaining - int(base.sum())
    if extra < 0 or extra > len(fi):
        raise AssignmentError("home apportionment arithmetic failure")
    if extra > 0:
        frac = np.clip(frac * (extra / frac.sum()), 0.0, 1.0)
        rng = rng_for(seed, STREAM_HOME_COUNTS)
        perm = rng.permutation(len(fi))
        cum = np.cumsum(frac[perm])
        cum[-1] = max(cum[-1], extra)  # guard against rounding
        points = rng.random() + np.arange(extra)
        pick = np.minimum(np.searchsorted(cum, points, side="right"), len(fi) - 1)
        add = np.bincount(perm[pick], minlength=len(fi))
        base = base + add
    counts[fi] = base
    if counts.sum() != n_agents or (counts > caps).any() or (counts < 0).any():
        raise AssignmentError("home apportionment violated exactness/caps",
                              {"sum": int(counts.sum()), "n_agents": int(n_agents)})
    return counts, {"homes_fixed_at_cap": int(n_capped)}


def agent_homes(home_counts, seed):
    """Agent a -> home index. Agents are shuffled so agent ids carry no spatial order."""
    rep = np.repeat(np.arange(len(home_counts), dtype=np.int64), home_counts)
    return rep[rng_for(seed, STREAM_AGENT_ORDER).permutation(len(rep))]


# ---------------------------------------------------------------- destinations
def destination_caps(weights, n_agents, dcfg, slack=None):
    """cap_d = min( max(ceil(slack*N*share_d), min_capacity), ceil(max_share*N) ), at least 1."""
    slack = dcfg["capacity_slack"] if slack is None else slack
    w = np.asarray(weights, dtype=float)
    share = w / w.sum()
    prop = np.ceil(slack * n_agents * share)
    raised = prop < dcfg["min_capacity"]
    cap = np.maximum(prop, dcfg["min_capacity"])
    share_cap = int(np.ceil(dcfg["max_share_of_population"] * n_agents))
    limited = cap > share_cap
    cap = np.maximum(np.minimum(cap, share_cap), 1).astype(np.int64)
    info = {"slack": float(slack), "min_capacity": int(dcfg["min_capacity"]), "share_cap_agents": share_cap,
            "n_raised_to_min_capacity": int(raised.sum()), "n_limited_by_share_cap": int(limited.sum()),
            "total_capacity": int(cap.sum()), "capacity_over_agents": float(cap.sum() / n_agents)}
    return cap, info


def _probs(w, d, valid, kernel):
    """Row-wise probabilities over candidates: w * kernel(d), normalised by the nearest valid distance for stability."""
    dm = np.where(valid, d, np.inf)
    dmin = dm.min(axis=1, keepdims=True)
    dmin = np.where(np.isfinite(dmin), dmin, 0.0)
    with np.errstate(over="ignore", invalid="ignore"):
        if kernel["type"] == "exponential":
            f = np.exp(-(np.where(valid, d, 0.0) - dmin) / kernel["scale_m"])
        else:
            eps = kernel["power_min_distance_m"]
            f = ((np.where(valid, d, 0.0) + eps) / (dmin + eps)) ** (-kernel["power_exponent"])
    return np.where(valid, w * f, 0.0)


def assign_destinations(agent_xy, dest_xy, dest_w, dest_cap, acfg, seed):
    """Batched rounds: every unassigned agent proposes one destination drawn from its k nearest destinations (within
    the stage radius) that still have capacity, P ∝ weight*kernel(distance); each destination accepts proposals in
    random-priority order up to its remaining capacity. Unplaced agents retry; radius widens in fixed stages."""
    n = len(agent_xy)
    dest = np.full(n, -1, dtype=np.int64)
    stage_of = np.full(n, -1, dtype=np.int16)
    remaining = np.asarray(dest_cap, dtype=np.int64).copy()
    if remaining.sum() < n:
        raise AssignmentError(f"destination capacity {int(remaining.sum())} < n_agents {n}",
                              {"destination_capacity_total": int(remaining.sum()), "n_agents": int(n)})
    radii = [acfg["radius_m"]] + [acfg["radius_m"] * m for m in acfg["fallback_radius_multipliers"]] + [np.inf]
    stages = []
    for si, rad in enumerate(radii):
        todo = np.flatnonzero(dest < 0)
        if len(todo) == 0:
            break
        active = np.flatnonzero(remaining > 0)
        if len(active) == 0:
            break
        tree = cKDTree(dest_xy[active])
        k = min(acfg["candidate_k"], len(active))
        d, idx = tree.query(agent_xy[todo], k=k, distance_upper_bound=rad)
        d, idx = d.reshape(len(todo), k), idx.reshape(len(todo), k)
        present = idx < len(active)
        cand = active[np.minimum(idx, len(active) - 1)]
        d = np.where(present, d, 0.0)
        rows = np.arange(len(todo))
        rounds, placed = 0, 0
        for rnd in range(acfg["max_rounds"]):
            rows = rows[dest[todo[rows]] < 0]
            if len(rows) == 0:
                break
            valid = present[rows] & (remaining[cand[rows]] > 0)
            p = _probs(dest_w[cand[rows]], d[rows], valid, acfg["kernel"])
            cum = np.cumsum(p, axis=1)
            tot = cum[:, -1]
            has = tot > 0
            if not has.any():
                break
            rows, p, cum, tot = rows[has], p[has], cum[has], tot[has]
            u = rng_for(seed, STREAM_ASSIGN, si, rnd).random((2, n))
            ag = todo[rows]
            j = np.minimum((cum <= (u[0][ag] * tot)[:, None]).sum(axis=1), k - 1)
            prop = cand[rows, j]
            order = np.lexsort((ag, u[1][ag], prop))
            sp, sa, srow = prop[order], ag[order], rows[order]
            start = np.r_[True, sp[1:] != sp[:-1]]
            first = np.maximum.accumulate(np.where(start, np.arange(len(sp)), 0))
            ok = (np.arange(len(sp)) - first) < remaining[sp]
            dest[sa[ok]] = sp[ok]
            stage_of[sa[ok]] = si
            np.subtract.at(remaining, sp[ok], 1)
            placed += int(ok.sum())
            rounds += 1
        stages.append({"stage": si, "radius_m": None if not np.isfinite(rad) else float(rad), "rounds": rounds,
                       "placed": placed, "unassigned_after": int((dest < 0).sum())})
    n_fail = int((dest < 0).sum())
    dist = np.full(n, np.nan)
    got = dest >= 0
    dist[got] = np.hypot(agent_xy[got, 0] - dest_xy[dest[got], 0], agent_xy[got, 1] - dest_xy[dest[got], 1])
    return {"dest": dest, "distance_m": dist, "stage": stage_of, "stages": stages, "n_unassigned": n_fail,
            "remaining_capacity": remaining}


def assignment_summary(res, dest_cap, dest_w):
    got = res["dest"] >= 0
    occ = np.bincount(res["dest"][got], minlength=len(dest_cap))
    share = np.sort(occ)[::-1]
    top = max(1, int(np.ceil(0.01 * len(occ))))
    return {"n_unassigned": res["n_unassigned"], "distance_m": pct(res["distance_m"][got]),
            "max_destination_occupancy": int(occ.max()) if len(occ) else 0,
            "destinations_used": int((occ > 0).sum()), "destinations_total": int(len(occ)),
            "destinations_at_capacity": int((occ == dest_cap).sum()),
            "top1pct_destinations_agent_share": float(share[:top].sum() / max(1, occ.sum())),
            "occupancy_gini": gini(occ), "stages": res["stages"]}
