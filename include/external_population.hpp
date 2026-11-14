#pragma once
// CEPOP v1 external-population reader/serializer (format spec: docs/cepop_format.md).
// Produces the (Population, Locations) pair accepted by every run_simulation*(p, pop, locs, ...) overload (V0-V6).
// Does not touch any simulation algorithm.
#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>
#include "agent.hpp"

namespace cepop {

constexpr uint32_t kVersion = 1;
constexpr uint32_t kEndianMarker = 0x01020304u;
constexpr size_t kHeaderSize = 64;

struct Info {
    uint32_t version = 0;
    uint64_t n_agents = 0, n_locations = 0;
    uint32_t payload_crc32 = 0;
    uint64_t file_bytes = 0;
};

uint32_t crc32(const uint8_t* data, size_t n);                         // zlib/IEEE CRC-32
uint64_t expected_file_size(uint64_t n_agents, uint64_t n_locations);  // exact size for (N, L)

// Parse + format-check + validate_input. Throws std::invalid_argument on any format/validation problem.
void parse(const uint8_t* data, size_t size, Population& pop, Locations& locs, Info* info = nullptr);
// Reads the whole file then parse(). Throws std::runtime_error on I/O failure.
void load(const std::string& path, Population& pop, Locations& locs, Info* info = nullptr);
// Serialize (no validation of semantics; sizes must be consistent). Byte-identical to the Python writer.
std::vector<uint8_t> serialize(const Population& pop, const Locations& locs);

}  // namespace cepop
