"""Reader / validator for CESNAP v1 per-agent daily state snapshots (spec: docs/snapshot_format.md). V0 only.

Memory is bounded: the file is memory-mapped and one frame (N/4 bytes packed, N bytes unpacked) is materialised at a time.
Nothing here simulates anything; it only decodes what the C++ `extpop_run --snapshots` wrote.

CLI:  python -m app.sim.snapshots FILE.cesnap [--csv daily_v0.csv]
"""
from __future__ import annotations

import struct
import sys
import zlib
from pathlib import Path

import numpy as np

MAGIC = b"CESNAP1\x00"
END_MAGIC = b"CESNAPE\x00"
VERSION = 1
ENDIAN = 0x01020304
HEADER = 64
STATE_NAMES = ("S", "E", "I", "R")           # encoding: S=0 E=1 I=2 R=3 (2 bits per agent)
STATE_ENCODING = {"S": 0, "E": 1, "I": 2, "R": 3}
FILE_NAME = "states.cesnap"
BACKENDS = {0: "v0"}
_CRC_CHUNK = 1 << 22


class SnapshotError(ValueError):
    """Raised for any malformed, truncated, inconsistent or missing snapshot."""


def _align8(x: int) -> int:
    return (x + 7) & ~7


def expected_size(n_agents: int, n_frames: int) -> int:
    frames_off = _align8(HEADER + 4 * n_agents)
    counts_off = _align8(frames_off + n_frames * ((n_agents + 3) // 4))
    return counts_off + n_frames * 16 + 16


class SnapshotReader:
    """Open with SnapshotReader(path); call .validate() before trusting the content (the API does)."""

    def __init__(self, path: str | Path):
        self.path = Path(path)
        if not self.path.is_file():
            raise SnapshotError(f"snapshot file not found: {self.path.name}")
        size = self.path.stat().st_size
        if size < HEADER + 16:
            raise SnapshotError(f"file too small to be a snapshot ({size} bytes)")
        with open(self.path, "rb") as f:
            h = f.read(HEADER)
        if h[:8] != MAGIC:
            raise SnapshotError("bad magic: not a CESNAP v1 file")
        version, endian = struct.unpack_from("<II", h, 8)
        if version != VERSION:
            raise SnapshotError(f"unsupported snapshot version {version}")
        if endian != ENDIAN:
            raise SnapshotError("bad endianness marker")
        n_agents, n_frames = struct.unpack_from("<QQ", h, 16)
        header_size, bits, frame_bytes, flags, dataset_crc, backend = struct.unpack_from("<IIIIII", h, 32)
        (seed,) = struct.unpack_from("<Q", h, 56)
        if header_size != HEADER:
            raise SnapshotError(f"unexpected header size {header_size}")
        if bits != 2:
            raise SnapshotError(f"unsupported bits per agent {bits}")
        if flags != 0:
            raise SnapshotError("unsupported flags")
        if backend not in BACKENDS:
            raise SnapshotError(f"unknown backend id {backend} (snapshots are V0-only)")
        if not (1 <= n_agents < 2**32) or n_frames < 1 or n_frames > 1_000_001:
            raise SnapshotError("implausible agent or frame count")
        if frame_bytes != (n_agents + 3) // 4:
            raise SnapshotError("frame_bytes does not match agent count")
        if size != expected_size(n_agents, n_frames):
            raise SnapshotError(f"file size {size} != expected {expected_size(n_agents, n_frames)} (truncated or padded)")
        self.n_agents, self.n_frames, self.frame_bytes = int(n_agents), int(n_frames), int(frame_bytes)
        self.dataset_crc32, self.seed, self.backend = int(dataset_crc), int(seed), BACKENDS[backend]
        self.size = size
        self._home_off = HEADER
        self._frames_off = _align8(HEADER + 4 * self.n_agents)
        self._counts_off = _align8(self._frames_off + self.n_frames * self.frame_bytes)
        self._footer_off = self._counts_off + 16 * self.n_frames
        self._mm = np.memmap(self.path, dtype=np.uint8, mode="r")
        self._validated = False

    # ------------------------------------------------------------------ metadata
    @property
    def n_days(self) -> int:
        return self.n_frames - 1

    def info(self) -> dict:
        return {"format": "CESNAP", "version": VERSION, "backend": self.backend, "n_agents": self.n_agents,
                "n_frames": self.n_frames, "n_days": self.n_days, "bits_per_agent": 2,
                "state_encoding": STATE_ENCODING, "frame_semantics": "frame d = state at the end of simulated day d (frame 0 = seeded state)",
                "file_bytes": self.size, "seed": self.seed, "dataset_payload_crc32": f"0x{self.dataset_crc32:08x}"}

    # ------------------------------------------------------------------ data access
    def home_loc(self) -> np.ndarray:
        """home_loc[agent_id] (agent id = array index = CEPOP agent order)."""
        return np.frombuffer(self._mm[self._home_off:self._home_off + 4 * self.n_agents], dtype="<u4").copy()

    def counts_table(self) -> np.ndarray:
        """(n_frames, 4) array of S,E,I,R as recorded by the writer."""
        raw = self._mm[self._counts_off:self._footer_off]
        return np.frombuffer(raw, dtype="<u4").reshape(self.n_frames, 4).copy()

    def _check_day(self, day: int) -> None:
        if not isinstance(day, (int, np.integer)) or not (0 <= day < self.n_frames):
            raise SnapshotError(f"day {day} out of range [0, {self.n_frames - 1}]")

    def packed_frame(self, day: int) -> np.ndarray:
        self._check_day(day)
        a = self._frames_off + day * self.frame_bytes
        return np.asarray(self._mm[a:a + self.frame_bytes])

    def frame(self, day: int) -> np.ndarray:
        """Unpacked uint8 state per agent (0=S,1=E,2=I,3=R) at the end of `day`."""
        p = self.packed_frame(day)
        out = np.empty(self.frame_bytes * 4, dtype=np.uint8)
        out[0::4], out[1::4], out[2::4], out[3::4] = p & 3, (p >> 2) & 3, (p >> 4) & 3, (p >> 6) & 3
        return out[: self.n_agents]

    def frame_counts(self, day: int) -> tuple[int, int, int, int]:
        """S,E,I,R recomputed from the packed states (independent of the stored counts table)."""
        st = self.frame(day)
        b = np.bincount(st, minlength=4)
        return int(b[0]), int(b[1]), int(b[2]), int(b[3])

    # ------------------------------------------------------------------ validation
    def validate(self, daily_rows: list[list[int]] | None = None, expect_home_loc: np.ndarray | None = None) -> dict:
        """Full integrity check; raises SnapshotError. Returns a small report.

        Checks: footer magic, payload CRC-32, zero padding in the frame tail bits, every frame's recomputed S/E/I/R == stored
        counts table, population conserved, and (if given) == the run's daily CSV rows [day,S,E,I,R] and == the dataset's home_loc.
        """
        footer = bytes(self._mm[self._footer_off:self._footer_off + 16])
        if footer[8:] != END_MAGIC:
            raise SnapshotError("missing end-of-file magic (incomplete write)")
        (crc_stored,) = struct.unpack_from("<I", footer, 0)
        crc = 0
        for a in range(HEADER, self._footer_off, _CRC_CHUNK):
            crc = zlib.crc32(self._mm[a:min(a + _CRC_CHUNK, self._footer_off)], crc)
        if crc != crc_stored:
            raise SnapshotError(f"payload CRC mismatch (stored 0x{crc_stored:08x}, computed 0x{crc:08x})")
        table = self.counts_table()
        if daily_rows is not None and len(daily_rows) != self.n_frames:
            raise SnapshotError(f"snapshot has {self.n_frames} frames but the daily CSV has {len(daily_rows)} rows")
        tail = self.n_agents % 4
        for d in range(self.n_frames):
            counts = self.frame_counts(d)
            if tuple(int(x) for x in table[d]) != counts:
                raise SnapshotError(f"day {d}: stored counts {tuple(table[d])} != counts decoded from agent states {counts}")
            if sum(counts) != self.n_agents:
                raise SnapshotError(f"day {d}: population not conserved")
            if tail and int(self.packed_frame(d)[-1]) >> (2 * tail):
                raise SnapshotError(f"day {d}: non-zero padding bits in the last frame byte")
            if daily_rows is not None:
                row = daily_rows[d]
                if row[0] != d or tuple(row[1:5]) != counts:
                    raise SnapshotError(f"day {d}: snapshot counts {counts} != daily CSV row {tuple(row[1:5])}")
        if expect_home_loc is not None and not np.array_equal(self.home_loc(), expect_home_loc):
            raise SnapshotError("home_loc table does not match the dataset's home_loc for the same agent order")
        self._validated = True
        return {"frames_checked": self.n_frames, "payload_crc32": f"0x{crc:08x}", "matches_daily_csv": daily_rows is not None,
                "matches_dataset_home_loc": expect_home_loc is not None}

    def close(self) -> None:
        mm = getattr(self._mm, "_mmap", None)
        if mm is not None:
            mm.close()


def read_cepop_home_loc(path: str | Path) -> np.ndarray:
    """home_loc section of a CEPOP v1 file (layout: docs/cepop_format.md). Reads only that section."""
    with open(path, "rb") as f:
        h = f.read(64)
        if len(h) < 64 or h[:8] != b"CEPOPv1\x00":
            raise SnapshotError("not a CEPOP v1 file")
        n = struct.unpack_from("<Q", h, 16)[0]
        off = _align8(_align8(_align8(64 + n) + 2 * n))  # state(u8), then timer(u16), then home_loc starts
        f.seek(off)
        raw = f.read(4 * n)
    if len(raw) != 4 * n:
        raise SnapshotError("CEPOP file truncated")
    return np.frombuffer(raw, dtype="<u4").copy()


def main(argv: list[str]) -> int:
    if not argv:
        print(__doc__)
        return 2
    rows = None
    if "--csv" in argv:
        from .results import read_daily_csv
        rows = read_daily_csv(Path(argv[argv.index("--csv") + 1]))
    r = SnapshotReader(argv[0])
    rep = r.validate(rows)
    print({**r.info(), **rep})
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except SnapshotError as e:
        print(f"invalid snapshot: {e}", file=sys.stderr)
        sys.exit(1)
