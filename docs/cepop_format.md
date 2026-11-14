# CEPOP v1 — external population binary format

Carries exactly the arrays the V0–V6 external-input APIs consume (`Population` + `Locations`, see
`include/agent.hpp`). Geographic metadata is **not** stored here; it lives in a separate GeoParquet whose row *i*
describes location id *i*. The data is synthetic and does not represent a census population or commuting pattern.

All integers are **little-endian**. All offsets are bytes from the start of the file.

## Header (64 bytes)

| offset | size | field            | value / rule                                              |
|-------:|-----:|------------------|-----------------------------------------------------------|
| 0      | 8    | magic            | `43 45 50 4F 50 76 31 00` = `"CEPOPv1\0"`                 |
| 8      | 4    | version          | `u32` = 1                                                 |
| 12     | 4    | endian_marker    | `u32` = `0x01020304` (bytes `04 03 02 01` on disk)        |
| 16     | 8    | n_agents         | `u64`, 1 ≤ N ≤ 2^32−1                                     |
| 24     | 8    | n_locations      | `u64`, 1 ≤ L ≤ 2^32−1                                     |
| 32     | 4    | header_size      | `u32` = 64                                                |
| 36     | 4    | flags            | `u32` = 0 (non-zero rejected in v1)                       |
| 40     | 4    | payload_crc32    | `u32`, CRC-32 (zlib/IEEE, poly 0xEDB88320) of bytes [64, file_size) including padding |
| 44     | 20   | reserved         | all zero (non-zero rejected)                              |

## Payload (starts at 64; every section starts 8-byte aligned, padding bytes are zero)

| order | array      | type     | count | bytes     |
|------:|------------|----------|------:|-----------|
| 1     | state      | `u8`     | N     | N         |
| 2     | timer      | `u16`    | N     | 2N        |
| 3     | home_loc   | `u32`    | N     | 4N        |
| 4     | work_loc   | `u32`    | N     | 4N        |
| 5     | loc_type   | `u8`     | L     | L         |
| 6     | occupancy  | `u32`    | L     | 4L        |

`section_offset[k+1] = align8(section_offset[k] + section_bytes[k])`, and the file size is
`align8(section_offset[6] + 4L)` (the last section is also padded to a multiple of 8).
File size is therefore exactly determined by (N, L); any other size is rejected.

Semantics: `loc_type` 0 = HOME, 1 = WORK (`LocType`); `home_loc`/`work_loc` are global location ids;
`occupancy[l]` = number of `home_loc` plus `work_loc` references to `l` (exactly what `validate_input` checks).
The generator additionally guarantees state = S (0) and timer = 0 for all agents; the format itself carries
any state/timer that `validate_input` accepts.

## Reader obligations (`cepop::load`)

1. File size ≥ 64; magic, version, endian marker, header_size, flags, reserved match.
2. N, L non-zero and ≤ uint32 max; file size equals the size computed from (N, L) exactly.
3. CRC-32 of the payload matches.
4. Arrays are decoded byte-wise (host-endian independent), then `validate_input(pop, locs)` is called.

Format errors and validation failures throw `std::invalid_argument`; I/O failures throw `std::runtime_error`.
