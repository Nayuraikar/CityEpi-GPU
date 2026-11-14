"""Paths for the UI data bundle. Override with CITYEPI_DATA_DIR."""
import os
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
BUNDLE = Path(os.environ.get("CITYEPI_DATA_DIR", REPO_ROOT / "ui_data_bundle")).resolve()

RESULTS = BUNDLE / "bench" / "results"
GEO_DIR = BUNDLE / "data" / "processed" / "geo"
BOUNDARY = BUNDLE / "data" / "boundaries" / "bengaluru_urban.geojson"
SYN_HH = BUNDLE / "data" / "synthetic" / "bengaluru_urban_N100000_seed42_households_v1"
SYN_LEGACY = BUNDLE / "data" / "synthetic" / "bengaluru_urban_N100000_seed42"
CACHE_DIR = Path(__file__).resolve().parents[1] / ".cache"
CACHE_DIR.mkdir(exist_ok=True)
