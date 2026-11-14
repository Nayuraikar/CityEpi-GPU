#!/usr/bin/env python3
"""Independent validation of an exported synthetic-population run directory (reads files only; recomputes occupancy,
distances and boundary containment). Exit 0 = all checks passed, 1 = a check failed, 2 = could not run.

  python scripts/validate_synthetic_population.py --run-dir data/synthetic/<run> --boundary data/boundaries/bengaluru_urban.geojson
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from synthpop import validate as V  # noqa: E402


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--run-dir", required=True)
    ap.add_argument("--boundary", default="data/boundaries/bengaluru_urban.geojson")
    ap.add_argument("--json", help="write the full check list here (default: <run-dir>/validation_independent.json)")
    a = ap.parse_args(argv)
    try:
        with open(os.path.join(a.run_dir, "config.json")) as f:
            cfg = json.load(f)
        checks = V.validate_outputs(a.run_dir, a.boundary, cfg)
    except Exception as e:  # noqa: BLE001
        print(f"could not validate: {type(e).__name__}: {e}", file=sys.stderr)
        return 2
    res = V.summarize(checks)
    with open(a.json or os.path.join(a.run_dir, "validation_independent.json"), "w") as f:
        json.dump(res, f, indent=2)
    for c in checks:
        print(("PASS " if c["passed"] else "FAIL ") + c["name"] + (f"  [{c['detail']}]" if c["detail"] and not c["passed"] else ""))
    print(f"{'ALL PASSED' if res['passed'] else 'FAILED'}: {res['n_checks']} checks, {len(res['failed'])} failed")
    return 0 if res["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
