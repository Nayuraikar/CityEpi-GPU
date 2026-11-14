#!/usr/bin/env python3
"""Generate a SYNTHETIC geographic population from the Bengaluru Urban OSM GeoParquet layers.

Outputs (under data/synthetic/<run>/): population.cepop, locations.geoparquet, agents.parquet, dedup_decisions.parquet,
config.json, report.json, report.md, manifest.json. Source Parquet files are only read.

Kaggle example:
  python scripts/generate_synthetic_population.py --geo-dir data/processed/geo \
      --boundary data/boundaries/bengaluru_urban.geojson --n-agents 100000 --seed 42
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from synthpop import config as C  # noqa: E402
from synthpop import generate as G  # noqa: E402


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--geo-dir", default="data/processed/geo")
    ap.add_argument("--boundary", default="data/boundaries/bengaluru_urban.geojson")
    ap.add_argument("--n-agents", type=int)
    ap.add_argument("--seed", type=int)
    ap.add_argument("--config", help="JSON file deep-merged over config/synthpop_default.json")
    ap.add_argument("--set", action="append", default=[], metavar="KEY.PATH=JSON",
                    help="override one config value, e.g. --set destinations.capacity_slack=2.0")
    ap.add_argument("--out-dir", help="default: data/synthetic/bengaluru_urban_N<n>_seed<s>_<confighash8>")
    ap.add_argument("--allow-outside-synthetic", action="store_true", help="permit an --out-dir not under data/synthetic/")
    ap.add_argument("--overwrite", action="store_true")
    ap.add_argument("--no-sensitivity", action="store_true")
    a = ap.parse_args(argv)
    ov = {}
    if a.n_agents is not None:
        ov["n_agents"] = a.n_agents
    if a.seed is not None:
        ov["seed"] = a.seed
    if a.no_sensitivity:
        C.set_path(ov, "sensitivity.enabled", False)
    for item in a.set:
        k, _, v = item.partition("=")
        C.set_path(ov, k, json.loads(v))
    cfg = C.load_config(a.config, ov)
    out = a.out_dir or os.path.join("data", "synthetic", f"bengaluru_urban_N{cfg['n_agents']}_seed{cfg['seed']}_{C.config_hash(cfg)[:8]}")
    try:
        rep = G.run(cfg, a.geo_dir, a.boundary, out, a.allow_outside_synthetic, a.overwrite)
    except Exception as e:
        print(f"FAILED: {type(e).__name__}: {e}", file=sys.stderr)
        if os.path.isfile(os.path.join(out, "report.json")):
            print(f"(failure report written to {out}/report.json)", file=sys.stderr)
        return 1
    print(f"status={rep['status']} out={out}")
    print(f"agents={rep['counts']['agents']} homes={rep['counts']['homes']} destinations={rep['counts']['destinations']}")
    v = rep["validation"]
    print(f"validation: {'PASS' if v['passed'] else 'FAIL'} ({v['n_checks']} checks)")
    for c in v["failed"]:
        print(f"  FAILED: {c['name']} {c['detail']}")
    return 0 if rep["status"] == "ok" else 2


if __name__ == "__main__":
    sys.exit(main())
