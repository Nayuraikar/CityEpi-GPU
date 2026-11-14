"""Optional household layer (EXPERIMENTAL synthetic assumption, default OFF).

Households sit between buildings and agents: sizes are drawn from a configured PMF over sizes 1-6, households are
allocated to residential buildings with the existing capped, weight-proportional apportionment, and agents are the
members of their household. Destinations are still assigned per agent (not household-aware in this milestone).

The size PMF is a placeholder, NOT measured Bengaluru or census data.

Algorithm
  1. draw_household_sizes: i.i.d. sizes by inverse-CDF from a dedicated Philox stream (STREAM_HOUSEHOLD_SIZES). The stream is
     consumed as one conceptual infinite sequence (chunked draws concatenate to exactly the same prefix).
  2. Truncate at the first index k where the running total reaches N. The final household takes the remainder
     R = N - (sum of the first k sizes), 1 <= R <= size_k. If R is in the configured support (always so when sizes 1..6
     are all possible) that is the whole adjustment. If R is not in the support (e.g. the PMF forbids size 1), the last
     j = 0,1,2,... drawn households are dropped until the freed total can be written as a sum of supported sizes; that total
     is replaced by the minimum-number-of-parts composition, largest parts first. If N cannot be written with the support at
     all (e.g. support {2,4} and odd N) a ValueError is raised: sizes outside the support are never produced.
  3. Households -> buildings: apportion_homes (unchanged) allocates H households over buildings with weight-proportional
     expectation and hard cap max_households_per_building. Household id h = slot h of that allocation, i.e. ids are ordered
     by building (sorted osm key order), which makes them stable.
  4. Sizes are mapped to slots by a seeded permutation (STREAM_HOUSEHOLD_SLOTS) so size is independent of building order.
  5. Agents: household members are expanded in household order and then shuffled with the legacy STREAM_AGENT_ORDER
     permutation, so agent ids still carry no household or spatial order."""
from math import gcd

import numpy as np

from .assign import apportion_homes
from .util import STREAM_AGENT_ORDER, STREAM_HOUSEHOLD_SIZES, STREAM_HOUSEHOLD_SLOTS, rng_for


def _min_parts(total, support):
    """Minimum-number-of-parts composition of `total` from `support` (largest parts first), or None."""
    INF = 10**9
    dp = [0] + [INF] * total
    for t in range(1, total + 1):
        for s in support:
            if s <= t and dp[t - s] + 1 < dp[t]:
                dp[t] = dp[t - s] + 1
    if dp[total] >= INF:
        return None
    parts, t = [], total
    while t > 0:
        for s in sorted(support, reverse=True):
            if s <= t and dp[t - s] == dp[t] - 1:
                parts.append(s)
                t -= s
                break
    return parts


def draw_household_sizes(n_agents, size_pmf, seed):
    """Household sizes (int64) that sum to exactly n_agents, every size in the PMF support. See module docstring."""
    n_agents = int(n_agents)
    if n_agents < 1:
        raise ValueError("n_agents must be >= 1")
    support = np.array(sorted(s for s, p in size_pmf.items() if p > 0), dtype=np.int64)
    probs = np.array([size_pmf[int(s)] for s in support], dtype=float)
    if len(support) == 0 or abs(probs.sum() - 1.0) > 1e-6:
        raise ValueError("size_pmf must have positive entries summing to 1")
    g = 0
    for s in support:
        g = gcd(g, int(s))
    if n_agents % g:
        raise ValueError(f"cannot split {n_agents} agents into households with sizes {support.tolist()} (gcd {g})")
    cdf = np.cumsum(probs)
    cdf[-1] = 1.0
    mean = float((support * probs).sum())
    rng = rng_for(seed, STREAM_HOUSEHOLD_SIZES)
    chunks, total = [], 0
    while total < n_agents:
        m = int(np.ceil((n_agents - total) / mean * 1.05)) + 16
        idx = np.minimum(np.searchsorted(cdf, rng.random(m), side="right"), len(support) - 1)
        c = support[idx]
        chunks.append(c)
        total += int(c.sum())
    drawn = np.concatenate(chunks)
    cum = np.cumsum(drawn)
    k = int(np.searchsorted(cum, n_agents, side="left"))      # first index with cum >= N
    info = {"drawn_until_index": k, "tail_households_replaced": 0, "final_household_adjusted": False}
    sup = [int(s) for s in support]
    for j in range(k + 1):
        keep = k - j
        prefix_sum = int(cum[keep - 1]) if keep > 0 else 0
        parts = _min_parts(n_agents - prefix_sum, sup)
        if parts is not None:
            sizes = np.concatenate([drawn[:keep], np.array(parts, dtype=np.int64)])
            info["tail_households_replaced"] = j
            info["final_household_adjusted"] = bool(j > 0 or parts != [int(drawn[k])])
            break
    else:  # unreachable once the gcd test passed, kept as a hard guard
        raise ValueError(f"cannot split {n_agents} agents into households with sizes {sup}")
    assert int(sizes.sum()) == n_agents and set(np.unique(sizes).tolist()) <= set(sup)
    return sizes.astype(np.int64), info


def build_households(n_agents, hh_settings, pmf, home_weights, seed):
    """Return dict with household_size[H], household_home[H] (building index), agent_household[N], home_of_agent[N],
    home_counts[B] (agents per building) and stats. Deterministic in (seed, settings, weights)."""
    sizes_drawn, dinfo = draw_household_sizes(n_agents, pmf, seed)
    H = len(sizes_drawn)
    B = len(home_weights)
    caps = np.full(B, int(hh_settings["max_households_per_building"]), dtype=np.int64)
    per_building, ainfo = apportion_homes(home_weights, caps, H, seed)       # households per building (legacy function, unchanged)
    household_home = np.repeat(np.arange(B, dtype=np.int64), per_building)    # slot h -> building (ordered by building)
    slot_perm = rng_for(seed, STREAM_HOUSEHOLD_SLOTS).permutation(H)
    household_size = sizes_drawn[slot_perm]
    rep = np.repeat(np.arange(H, dtype=np.int64), household_size)             # members in household order
    agent_household = rep[rng_for(seed, STREAM_AGENT_ORDER).permutation(n_agents)]
    home_of_agent = household_home[agent_household]
    home_counts = np.bincount(home_of_agent, minlength=B).astype(np.int64)
    stats = {"households": int(H), "mean_household_size": float(n_agents / H), "pmf_mean": float(sum(s * p for s, p in pmf.items())),
             "households_per_building_cap": int(hh_settings["max_households_per_building"]),
             "buildings_with_households": int((per_building > 0).sum()), "buildings_at_household_cap": int((per_building == caps).sum()),
             "draw": dinfo, "apportionment": ainfo}
    return {"household_size": household_size, "household_home": household_home, "agent_household": agent_household,
            "home_of_agent": home_of_agent, "home_counts": home_counts, "households_per_building": per_building, "stats": stats}
