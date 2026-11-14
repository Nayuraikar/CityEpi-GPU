import os
import sys
import zlib

import numpy as np
import pytest

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts"))
from synthpop import cepop  # noqa: E402
from synthpop.make_golden_fixture import arrays  # noqa: E402

FIXTURE = os.path.join(ROOT, "tests", "fixtures", "tiny.cepop")


def test_golden_fixture_is_current():
    assert open(FIXTURE, "rb").read() == cepop.encode(*arrays())


def test_crc_check_value():
    assert zlib.crc32(b"123456789") & 0xFFFFFFFF == 0xCBF43926


def test_roundtrip_and_padding():
    n, nl = 13, 5
    rng = np.random.default_rng(1)
    typ = np.array([0, 1, 0, 1, 1], np.uint8)
    home = rng.choice([0, 2], n).astype(np.uint32)
    work = rng.choice([1, 3, 4], n).astype(np.uint32)
    occ = cepop.compute_occupancy(home, work, nl)
    st = (np.arange(n) % 4).astype(np.uint8)
    tm = np.where((st == 1) | (st == 2), 1000, 0).astype(np.uint16)
    data = cepop.encode(st, tm, home, work, typ, occ)
    assert len(data) == cepop.layout(n, nl)[1] and len(data) % 8 == 0
    out = cepop.decode(data)
    for k, v in dict(state=st, timer=tm, home_loc=home, work_loc=work, loc_type=typ, occupancy=occ).items():
        assert np.array_equal(out[k], v) and out[k].dtype.itemsize == v.dtype.itemsize


def test_deterministic_bytes():
    assert cepop.encode(*arrays()) == cepop.encode(*arrays())


@pytest.mark.parametrize("mut", ["magic", "version", "endian", "trailing", "truncated", "crc", "reserved"])
def test_decode_rejects(mut):
    b = bytearray(open(FIXTURE, "rb").read())
    if mut == "magic": b[0] = 0
    elif mut == "version": b[8] = 2
    elif mut == "endian": b[12:16] = b"\x01\x02\x03\x04"
    elif mut == "trailing": b += b"\0"
    elif mut == "truncated": b = b[:-8]
    elif mut == "crc": b[100] ^= 1
    elif mut == "reserved": b[60] = 1
    with pytest.raises(ValueError):
        cepop.decode(bytes(b))


def test_encode_range_checks():
    a = list(arrays())
    a[1] = np.array([70000] * 12)
    with pytest.raises(ValueError):
        cepop.encode(*a)
