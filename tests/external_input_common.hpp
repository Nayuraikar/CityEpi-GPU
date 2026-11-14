#pragma once
// Shared helpers for external-population tests (header only, plain C++ so V4-V6 tests can use it too).
#include <stdexcept>
#include <vector>
#include "simulation.hpp"

namespace extin {

// Hand-built population that is NOT laid out like the synthetic generator: work locations come first,
// ids interleave, agents share homes/works unevenly. 12 agents, 7 locations.
//   loc: 0=WORK 1=HOME 2=HOME 3=WORK 4=HOME 5=HOME 6=WORK
inline void handmade(Population& pop, Locations& locs) {
    locs.type = {LOC_WORK, LOC_HOME, LOC_HOME, LOC_WORK, LOC_HOME, LOC_HOME, LOC_WORK};
    const uint32_t home[12] = {1, 1, 1, 2, 2, 4, 4, 4, 5, 5, 1, 2};
    const uint32_t work[12] = {0, 0, 3, 3, 3, 6, 6, 0, 0, 3, 6, 6};
    pop.state.assign(12, S);
    pop.timer.assign(12, 0);
    pop.home_loc.assign(home, home + 12);
    pop.work_loc.assign(work, work + 12);
    pop.state[0] = I; pop.timer[0] = 4;
    pop.state[5] = E; pop.timer[5] = 2;
    pop.state[9] = R;
    locs.occupancy.assign(locs.type.size(), 0);
    for (size_t a = 0; a < 12; ++a) { ++locs.occupancy[home[a]]; ++locs.occupancy[work[a]]; }
}

inline bool daily_equal(const Result& a, const Result& b) {
    if (a.daily.size() != b.daily.size()) return false;
    for (size_t i = 0; i < a.daily.size(); ++i) if (!(a.daily[i] == b.daily[i])) return false;
    return true;
}

template <class F>
inline bool throws_invalid(F&& f) {
    try { f(); } catch (const std::invalid_argument&) { return true; } catch (...) { return false; }
    return false;
}

}  // namespace extin
