#include "simulation.hpp"

void apply_transitions(const Params& p, Population& pop, const std::vector<uint8_t>& newly_exposed) {
    for (size_t a = 0; a < pop.size(); ++a) {
        switch (pop.state[a]) {
            case S:
                if (newly_exposed[a]) { pop.state[a] = E; pop.timer[a] = at_least1(p.incubation_days); }
                break;
            case E:
                if (--pop.timer[a] == 0) { pop.state[a] = I; pop.timer[a] = at_least1(p.infectious_days); }
                break;
            case I:
                if (--pop.timer[a] == 0) pop.state[a] = R;
                break;
            default: break;
        }
    }
}
