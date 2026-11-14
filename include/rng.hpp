#pragma once
#include <cstdint>

// RNG slots: independent streams per purpose.
enum RngSlot : uint32_t { SLOT_INIT = 0, SLOT_ASSIGN_HOME = 1, SLOT_ASSIGN_WORK = 2,
                          SLOT_EXPOSE_HOME = 3, SLOT_EXPOSE_WORK = 4 };

// Stateless counter-based RNG: uniform double in [0,1). Deterministic for any thread layout.
double rand01(uint64_t seed, uint32_t agent_id, uint32_t day, uint32_t slot);
