#!/usr/bin/env python3
"""Apply the V6 acceptance rule to bench_v6 CSV output (stdout of bench_v6, '#' lines ignored).

Rule: a V6 row is ACCEPTED vs V6_base if its median kernel time improves by more than max(3%, 2*CV%) at >= 2 sizes
and does not regress by more than 2% at any other size (per scenario). CV = larger of the two rows' CV.
Usage: analyze_v6.py results.csv [--scenario default]
"""
import csv, sys
from collections import defaultdict

def main():
    path = sys.argv[1]
    scen = sys.argv[sys.argv.index("--scenario") + 1] if "--scenario" in sys.argv else "default"
    rows = [r for r in csv.DictReader(l for l in open(path) if not l.startswith("#"))]
    data = defaultdict(dict)  # backend -> size -> row
    for r in rows:
        if r["scenario"] == scen:
            data[r["backend"]][int(r["agents"])] = r
    base = data.get("V6_base")
    if not base:
        sys.exit("no V6_base rows for scenario " + scen)
    bad = [r for r in rows if r["identical_v0"] != "yes" or r["identical_v5"] not in ("yes", "n/a")]
    if bad:
        print("WARNING: %d rows not identical to V0/V5 -- results invalid" % len(bad))
    print("| backend | " + " | ".join(str(s) for s in sorted(base)) + " | verdict |")
    print("|---|" + "---|" * (len(base) + 1))
    for name, bysize in data.items():
        if not name.startswith("V6_") or name == "V6_base":
            continue
        wins, regress, cells = 0, 0, []
        for s in sorted(base):
            if s not in bysize:
                cells.append("n/a"); continue
            b, c = base[s], bysize[s]
            gain = 100.0 * (1 - float(c["kernel_median_s"]) / float(b["kernel_median_s"]))
            thr = max(3.0, 2 * max(float(b["kernel_cv_pct"]), float(c["kernel_cv_pct"])))
            win = gain > thr
            wins += win
            regress += gain < -2.0
            cells.append("%+.1f%%%s" % (gain, "*" if win else ""))
        verdict = "ACCEPT" if wins >= 2 and regress == 0 else "reject"
        print("| %s | %s | %s |" % (name, " | ".join(cells), verdict))
    print("\n* = improvement above max(3%, 2xCV) vs V6_base (positive = faster). Regression limit: -2% at any size.")

main()
