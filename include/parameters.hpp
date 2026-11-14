#pragma once
#include <cstdint>

struct Params {
    uint32_t n_agents = 100000;
    uint32_t n_homes = 20000;
    uint32_t n_works = 2000;
    uint32_t days = 100;
    uint64_t seed = 42;
    double beta_home = 0.3;  // per-day force of infection at home
    double beta_work = 0.3;  // per-day force of infection at work
    uint32_t initial_infected = 100;
    uint16_t incubation_days = 3;   // E duration (>=1)
    uint16_t infectious_days = 5;   // I duration (>=1)
};
inline uint16_t at_least1(uint16_t x) { return x ? x : 1; }  // guards timer underflow
