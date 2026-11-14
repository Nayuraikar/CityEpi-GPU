"""Activity destinations: classification, exact + conservative proximity de-duplication, capacity weights.

Landuse polygons are spatial context ONLY and never become destinations. Two features are never merged merely
because they are close: proximity merges additionally require the same category and the same non-empty name."""
import re

import numpy as np
import pandas as pd
import shapely
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import connected_components
from scipy.spatial import cKDTree

from .config import DEST_LAYERS

_PUNCT = re.compile(r"[^\w\s]", re.UNICODE)
_WS = re.compile(r"\s+")


def norm_name(s):
    return _WS.sub(" ", _PUNCT.sub(" ", str(s).lower())).strip() if s else ""


def classify(df, layer_name, cfg):
    """Return (category array, reason-for-no-category array). Priority = vocab.category_order."""
    V = cfg["vocab"]
    t = lambda c: df["tag:" + c].to_numpy(dtype=object)  # noqa: E731
    bld, am, shop, office = t("building"), t("amenity"), t("shop"), t("office")
    hc, leis, mm, craft = t("healthcare"), t("leisure"), t("man_made"), t("craft")
    isin = np.isin
    masks = {
        "education": isin(am, V["edu_amenity"]) | isin(bld, V["edu_building"]),
        "healthcare": isin(am, V["health_amenity"]) | isin(bld, V["health_building"]) | (hc != "") | (layer_name == "healthcare"),
        "industrial": isin(bld, V["ind_building"]) | (mm == "works") | (craft != ""),
        "office": isin(bld, V["office_building"]) | (office != "") | isin(am, V["office_amenity"]),
        "commercial_retail": isin(bld, V["com_building"]) | (shop != "") | isin(am, V["retail_amenity"]),
        "civic_public": isin(am, V["civic_amenity"]) | isin(bld, V["civic_building"]),
        "worship": (am == "place_of_worship") | isin(bld, V["worship_building"]),
        "leisure": (leis != "") | (layer_name == "leisure"),
        "other_amenity": am != "",
    }
    cat = np.full(len(df), "", dtype=object)
    for name in reversed(V["category_order"]):
        cat[masks[name]] = name
    # leisure is restricted to selected values
    bad_leis = (cat == "leisure") & ~isin(leis, cfg["destinations"]["leisure_values"])
    reason = np.full(len(df), "", dtype=object)
    reason[bad_leis] = "leisure_value_not_selected"
    cat[bad_leis] = ""
    reason[(cat == "") & ~bad_leis] = "no_activity_tag"
    return cat, reason


def collect_candidates(layers, cfg, rec):
    """Classify DEST_LAYERS, drop non-selected categories (recorded), return raw candidate frame."""
    sel_cats = set(cfg["destinations"]["include_categories"])
    prio = {n: i for i, n in enumerate(cfg["dedup"]["layer_priority"])}
    frames, stats = [], {"per_layer": {}}
    for name in DEST_LAYERS:
        L = layers.get(name)
        if L is None or len(L.df) == 0:
            continue
        df = L.df
        cat, reason = classify(df, name, cfg)
        keys = df["key"].to_numpy(dtype=object)
        for r in sorted(set(reason[reason != ""])):
            rec.exclude("destinations", name, r, keys[reason == r])
        notsel = (cat != "") & ~np.isin(cat, list(sel_cats))
        for c in sorted(set(cat[notsel])):
            rec.exclude("destinations", name, f"category_not_selected:{c}", keys[cat == c])
        keep = (cat != "") & ~notsel
        stats["per_layer"][name] = {"rows": int(len(df)), "classified_any": int((cat != "").sum()), "kept": int(keep.sum()),
                                    "by_category": {c: int((cat[keep] == c).sum()) for c in sorted(set(cat[keep]))}}
        sub = df[keep]
        frames.append(pd.DataFrame({
            "layer": name, "priority": prio[name], "key": sub["key"].to_numpy(), "osm_type": sub["osm_type"].to_numpy(),
            "osm_id": sub["osm_id"].to_numpy(), "category": cat[keep], "name_raw": sub["name_raw"].to_numpy(),
            "x": sub["x"].to_numpy(), "y": sub["y"].to_numpy(), "lon": sub["lon"].to_numpy(), "lat": sub["lat"].to_numpy(),
            "area_m2": sub["area_m2"].to_numpy()}))
    landuse = layers.get("landuse")
    if landuse is not None:
        rec.exclude("destinations", "landuse", "landuse_is_spatial_context_not_a_destination", count=len(landuse.df))
    if not frames:
        raise ValueError("no destination candidates after classification")
    C = pd.concat(frames, ignore_index=True)
    C["name_norm"] = [norm_name(s) for s in C["name_raw"]]
    stats["candidates_before_dedup"] = int(len(C))
    return C, stats


def _row(decision, a, b, dist, reason):
    return dict(decision=decision, key_a=a["key"], key_b=b["key"], layer_a=a["layer"], layer_b=b["layer"],
                category_a=a["category"], category_b=b["category"], name_a=a["name_raw"], name_b=b["name_raw"],
                distance_m=float(dist), reason=reason)


def _winner_order(g):
    return g.sort_values(["area_m2", "priority", "key"], ascending=[False, True, True], kind="mergesort")


def dedup(C, cfg, decisions, rec):
    """Stage 1: exact (osm_type,id) merge. Stage 2: same category + same non-empty name within radius. Logs everything."""
    dc = cfg["dedup"]
    rank = {c: i for i, c in enumerate(cfg["vocab"]["category_order"])}
    lp = dc["layer_priority"]
    st = {"input": int(len(C))}

    # ---- stage 1: exact element identity across (and within) layers
    C = C.sort_values(["osm_type", "osm_id", "priority"], kind="mergesort").reset_index(drop=True)
    sizes = C.groupby("key", sort=False)["key"].transform("size").to_numpy()
    merged = []
    for _, g in C[sizes > 1].groupby("key", sort=False):
        w = _winner_order(g).iloc[0].copy()
        gp = g.sort_values("priority", kind="mergesort")
        w["category"] = sorted(set(g["category"]), key=lambda c: rank[c])[0]
        w["name_raw"] = next((s for s in gp["name_raw"] if s), "")
        w["name_norm"] = norm_name(w["name_raw"])
        w["source_layers"] = "|".join(gp["layer"].tolist())
        w["n_merged"] = len(g)
        w["area_m2"] = float(g["area_m2"].max())
        merged.append(w)
        for _, r in gp.iloc[1:].iterrows():
            decisions.append(_row("exact_key_merge", w, r, 0.0, f"same (osm_type,id) in {w['source_layers']}; category={w['category']}"))
    single = C[sizes == 1].copy()
    single["source_layers"] = single["layer"]
    single["n_merged"] = 1
    M = pd.concat([single, pd.DataFrame(merged)], ignore_index=True) if merged else single
    M = M.sort_values(["osm_type", "osm_id"], kind="mergesort").reset_index(drop=True)
    st["after_exact_key_merge"] = int(len(M))
    st["exact_key_groups_merged"] = len(merged)
    st["exact_key_records_removed"] = int(len(C) - len(M))

    # ---- stage 2: conservative proximity evidence (proximity alone is never enough)
    n = len(M)
    xy = M[["x", "y"]].to_numpy()
    radius = max(dc["name_merge_radius_m"], dc["log_radius_m"], dc["merge_unnamed_same_category_within_m"])
    st.update(pairs_considered=0, merge_by_name_rule=0, merge_by_unnamed_rule=0)
    mi = mj = np.array([], dtype=np.int64)
    log_pairs = []
    if n > 1 and radius > 0:
        pairs = cKDTree(xy).query_pairs(radius, output_type="ndarray")
        st["pairs_considered"] = int(len(pairs))
        if len(pairs):
            i, j = pairs[:, 0], pairs[:, 1]
            d = np.hypot(xy[i, 0] - xy[j, 0], xy[i, 1] - xy[j, 1])
            cat = M["category"].to_numpy(dtype=object)
            nn = M["name_norm"].to_numpy(dtype=object)
            same_cat = cat[i] == cat[j]
            both_named = (nn[i] != "") & (nn[j] != "")
            name_rule = same_cat & both_named & (nn[i] == nn[j]) & (d <= dc["name_merge_radius_m"])
            unnamed_rule = np.zeros(len(i), bool)
            if dc["merge_unnamed_same_category_within_m"] > 0:
                unnamed_rule = same_cat & ~both_named & (d <= dc["merge_unnamed_same_category_within_m"])
            merge = name_rule | unnamed_rule
            mi, mj = i[merge], j[merge]
            st["merge_by_name_rule"], st["merge_by_unnamed_rule"] = int(name_rule.sum()), int(unnamed_rule.sum())
            close = (d <= dc["log_radius_m"]) & ~merge
            log_pairs = list(zip(i[close].tolist(), j[close].tolist(), d[close].tolist()))
    if len(mi):
        _, lab = connected_components(coo_matrix((np.ones(len(mi)), (mi, mj)), shape=(n, n)), directed=False)
    else:
        lab = np.arange(n)
    csize = np.bincount(lab)
    drop = np.zeros(n, bool)
    st["largest_proximity_group"] = int(csize.max()) if n else 0
    for c in np.flatnonzero(csize > 1):
        g = _winner_order(M.iloc[np.flatnonzero(lab == c)])
        w = g.iloc[0]
        for pos, r in g.iloc[1:].iterrows():
            same_name = bool(w["name_norm"]) and w["name_norm"] == r["name_norm"]
            decisions.append(_row("name_category_proximity_merge" if same_name else "unnamed_category_proximity_merge", w, r,
                                  np.hypot(w["x"] - r["x"], w["y"] - r["y"]),
                                  f"same category '{w['category']}', " + ("same normalised name" if same_name else "unnamed") + ", within radius"))
            drop[pos] = True
        wi = g.index[0]
        M.at[wi, "n_merged"] = int(g["n_merged"].sum())
        M.at[wi, "source_layers"] = "|".join(sorted({s for v in g["source_layers"] for s in v.split("|")}, key=lp.index))
        if not M.at[wi, "name_raw"]:
            M.at[wi, "name_raw"] = next((s for s in g["name_raw"] if s), "")
            M.at[wi, "name_norm"] = norm_name(M.at[wi, "name_raw"])
    st["proximity_records_removed"] = int(drop.sum())
    # close-but-distinct pairs (10 m scale): kept, logged with the evidence that was NOT sufficient to merge
    st["close_pairs_kept_distinct"] = 0
    for a, b, dist in log_pairs:
        if lab[a] == lab[b]:
            continue
        ra, rb = M.iloc[a], M.iloc[b]
        if ra["category"] != rb["category"]:
            why = "different category"
        elif not ra["name_norm"] or not rb["name_norm"]:
            why = "same category but at least one unnamed (unnamed merge off or out of its radius)"
        else:
            why = "same category but different names"
        decisions.append(_row("kept_distinct_close_pair", ra, rb, dist, why))
        st["close_pairs_kept_distinct"] += 1
    M = M[~drop].reset_index(drop=True)
    st["output"] = int(len(M))
    return M, st


def add_inside_building(D, buildings, rec):
    """Flag destinations whose point lies inside ANOTHER building polygon (kept as distinct facilities)."""
    inside = np.zeros(len(D), bool)
    poly = np.isin(buildings.df["geom_type_id"].to_numpy(), (3, 6))
    if poly.any() and len(D):
        tree = shapely.STRtree(buildings.geoms[poly])
        bkeys = buildings.df["key"].to_numpy(dtype=object)[poly]
        pi, ti = tree.query(shapely.points(D["x"].to_numpy(), D["y"].to_numpy()), predicate="within")
        other = bkeys[ti] != D["key"].to_numpy(dtype=object)[pi]
        inside[np.unique(pi[other])] = True
    D["inside_building"] = inside
    return {"destinations_inside_other_building_preserved": int(inside.sum()),
            "by_category": {c: int((inside & (D["category"] == c).to_numpy()).sum()) for c in sorted(set(D["category"]))}}


def add_capacity_weights(D, cfg):
    dc = cfg["destinations"]
    area = np.where(D["area_m2"].to_numpy() > 0, D["area_m2"].to_numpy(), dc["poi_default_area_m2"])
    clipped = np.clip(area, dc["area_floor_m2"], dc["area_cap_m2"])
    cw = np.array([dc["category_weight"][c] for c in D["category"]])
    D["weight"] = cw * clipped ** dc["alpha"]
    return {"area_floor_hits": int((area < dc["area_floor_m2"]).sum()), "area_cap_hits": int((area > dc["area_cap_m2"]).sum()),
            "point_features_using_default_area": int((D["area_m2"].to_numpy() <= 0).sum())}
