#!/usr/bin/env python3
"""Regenerate tests/fixtures/tiny.cepop: the 12-agent / 7-location layout of tests/external_input_common.hpp
(extin::handmade) with all agents S / timer 0 and occupancy computed. Fabricated, not geographic."""
import os
import sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from synthpop import cepop

LOC_TYPE = [1, 0, 0, 1, 0, 0, 1]
HOME = [1, 1, 1, 2, 2, 4, 4, 4, 5, 5, 1, 2]
WORK = [0, 0, 3, 3, 3, 6, 6, 0, 0, 3, 6, 6]

def arrays():
    n = len(HOME)
    occ = cepop.compute_occupancy(HOME, WORK, len(LOC_TYPE))
    return (np.zeros(n, np.uint8), np.zeros(n, np.uint16), np.array(HOME, np.uint32), np.array(WORK, np.uint32),
            np.array(LOC_TYPE, np.uint8), occ)

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "..", "tests", "fixtures", "tiny.cepop")
    crc = cepop.write_cepop(out, *arrays())
    print(f"wrote {out} payload_crc32=0x{crc:08x}")
