"""CEPOP v1 reference codec (see docs/cepop_format.md). numpy only; little-endian, byte-exact."""
import struct
import zlib

import numpy as np

MAGIC = b"CEPOPv1\x00"
VERSION = 1
ENDIAN_MARKER = 0x01020304
HEADER_SIZE = 64
U32_MAX = 2**32 - 1
_HDR = struct.Struct("<8sIIQQIII20s")
assert _HDR.size == HEADER_SIZE


def _align8(x):
    return (x + 7) & ~7


def layout(n_agents, n_locations):
    """Return ([(name, dtype, count, offset)], file_size) for the given sizes."""
    spec = [("state", "<u1", n_agents), ("timer", "<u2", n_agents), ("home_loc", "<u4", n_agents),
            ("work_loc", "<u4", n_agents), ("loc_type", "<u1", n_locations), ("occupancy", "<u4", n_locations)]
    off, out = HEADER_SIZE, []
    for name, dt, cnt in spec:
        out.append((name, dt, cnt, off))
        off = _align8(off + np.dtype(dt).itemsize * cnt)
    return out, off


def compute_occupancy(home_loc, work_loc, n_locations):
    occ = np.bincount(np.asarray(home_loc, dtype=np.int64), minlength=n_locations)
    occ = occ + np.bincount(np.asarray(work_loc, dtype=np.int64), minlength=n_locations)
    return occ.astype(np.uint32)


def encode(state, timer, home_loc, work_loc, loc_type, occupancy):
    n, nl = len(state), len(loc_type)
    if not (len(timer) == len(home_loc) == len(work_loc) == n) or len(occupancy) != nl:
        raise ValueError("array sizes inconsistent")
    if not (1 <= n <= U32_MAX and 1 <= nl <= U32_MAX):
        raise ValueError("N and L must be in [1, 2^32-1]")
    arrays = dict(state=state, timer=timer, home_loc=home_loc, work_loc=work_loc, loc_type=loc_type, occupancy=occupancy)
    secs, size = layout(n, nl)
    payload = bytearray(size - HEADER_SIZE)
    for name, dt, cnt, off in secs:
        a = np.asarray(arrays[name])
        if a.size and (a.min() < 0 or a.max() > np.iinfo(np.dtype(dt)).max):
            raise ValueError(f"{name} values out of range for {dt}")
        raw = a.astype(dt, copy=False).tobytes()
        payload[off - HEADER_SIZE: off - HEADER_SIZE + len(raw)] = raw
    crc = zlib.crc32(bytes(payload)) & 0xFFFFFFFF
    hdr = _HDR.pack(MAGIC, VERSION, ENDIAN_MARKER, n, nl, HEADER_SIZE, 0, crc, b"\x00" * 20)
    return hdr + bytes(payload)


def write_cepop(path, *arrays):
    data = encode(*arrays)
    with open(path, "wb") as f:
        f.write(data)
    return zlib.crc32(data[HEADER_SIZE:]) & 0xFFFFFFFF


def decode(data):
    """Strict decode mirroring the C++ reader's format checks (no semantic validation)."""
    if len(data) < HEADER_SIZE:
        raise ValueError("file smaller than header")
    magic, ver, endian, n, nl, hsz, flags, crc, rsv = _HDR.unpack_from(data)
    if magic != MAGIC: raise ValueError("bad magic")
    if ver != VERSION: raise ValueError("unsupported version")
    if endian != ENDIAN_MARKER: raise ValueError("bad endian marker")
    if hsz != HEADER_SIZE: raise ValueError("bad header_size")
    if flags != 0: raise ValueError("unsupported flags")
    if rsv != b"\x00" * 20: raise ValueError("reserved bytes non-zero")
    if not (1 <= n <= U32_MAX and 1 <= nl <= U32_MAX): raise ValueError("bad N/L")
    secs, size = layout(n, nl)
    if len(data) != size: raise ValueError(f"file size {len(data)} != expected {size}")
    if zlib.crc32(data[HEADER_SIZE:]) & 0xFFFFFFFF != crc: raise ValueError("payload CRC mismatch")
    return {name: np.frombuffer(data, dtype=dt, count=cnt, offset=off).copy() for name, dt, cnt, off in secs}


def read_cepop(path):
    with open(path, "rb") as f:
        return decode(f.read())
