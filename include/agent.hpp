#pragma once
#include <cstdint>
#include <vector>

enum State : uint8_t { S = 0, E = 1, I = 2, R = 3 };
enum LocType : uint8_t { LOC_HOME = 0, LOC_WORK = 1 };

// Canonical SoA population.
struct Population {
    std::vector<uint8_t> state;
    std::vector<uint16_t> timer;     // days left in E or I
    std::vector<uint32_t> home_loc;  // global location id
    std::vector<uint32_t> work_loc;  // global location id
    size_t size() const { return state.size(); }
};

// Location table; ids are global. Loadable from OSM later by filling these arrays.
struct Locations {
    std::vector<uint8_t> type;        // LocType
    std::vector<uint32_t> occupancy;  // number of agents assigned
    size_t size() const { return type.size(); }
};

struct Counts { uint32_t s = 0, e = 0, i = 0, r = 0; 
    bool operator==(const Counts& o) const { return s==o.s&&e==o.e&&i==o.i&&r==o.r; } };
