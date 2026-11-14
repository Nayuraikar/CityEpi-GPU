#pragma once
// extpop_run implementation (header-only so tools/extpop_run.cpp and tests/test_extpop_integration.cpp share it).
// Loads a CEPOP v1 file with the existing reader (which calls validate_input), seeds infections through the existing
// public seed_infections(), runs V0 and/or V6 through the existing external-input APIs and checks the results.
// V6 support exists only when compiled with CITYEPI_WITH_V6 (CMake: -DENABLE_CUDA_V6=ON).
//
// Exit codes: 0 all requested checks passed | 1 error, invalid input or result mismatch | 2 backend unavailable
// (V6 requested without a V6 build or without a usable GPU).
#include <cerrno>
#include <chrono>
#include <climits>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <exception>
#include <string>
#include <vector>
#include "external_population.hpp"
#include "simulation.hpp"
#ifdef CITYEPI_WITH_V6
#include "v6_simulation.hpp"
#endif

namespace extpop {

// FNV-1a 64 over (S,E,I,R) of every day as little-endian u32: a compact fingerprint for run records.
inline uint64_t daily_checksum(const Result& r) {
    uint64_t h = 1469598103934665603ull;
    for (const Counts& c : r.daily)
        for (uint32_t v : {c.s, c.e, c.i, c.r})
            for (int b = 0; b < 4; ++b) { h ^= (uint8_t)(v >> (8 * b)); h *= 1099511628211ull; }
    return h;
}

inline bool daily_equal(const Result& a, const Result& b, size_t* first_diff = nullptr) {
    const size_t n = a.daily.size() < b.daily.size() ? a.daily.size() : b.daily.size();
    for (size_t i = 0; i < n; ++i)
        if (!(a.daily[i] == b.daily[i])) { if (first_diff) *first_diff = i; return false; }
    if (a.daily.size() != b.daily.size()) { if (first_diff) *first_diff = n; return false; }
    return true;
}

struct Cli {
    std::string input, json, csv_prefix;
    bool run_v0 = true, run_v6 = false;
    Params p;
    uint64_t expect_agents = 0, expect_locations = 0;
    bool v6_opts_given = false;
    bool v6_agg = false, v6_skip_exp = false, v6_skip_rng = false, v6_pred = false;
    std::string v6_mode = "sync";
    uint32_t v6_graph_days = 32, v6_block = 256;
};

inline bool parse_u64(const char* s, uint64_t lo, uint64_t hi, uint64_t& out) {
    if (!s || !*s || *s == '-') return false;
    errno = 0; char* end = nullptr;
    unsigned long long v = strtoull(s, &end, 10);
    if (errno || *end || v < lo || v > hi) return false;
    out = v; return true;
}
inline bool parse_dbl(const char* s, double lo, double& out) {
    if (!s || !*s) return false;
    errno = 0; char* end = nullptr;
    double v = strtod(s, &end);
    if (errno || *end || !(v >= lo) || v > 1e12) return false;
    out = v; return true;
}

inline void usage(FILE* e) {
    fprintf(e,
        "usage: extpop_run --input FILE.cepop [--backend v0|v6|both] [--days N] [--seed S] [--init K]\n"
        "                  [--beta-home B] [--beta-work B] [--incubation D] [--infectious D]\n"
        "                  [--expect-agents N] [--expect-locations L] [--json OUT.json] [--daily-csv PREFIX]\n"
        "                  [--v6-mode sync|async|graph] [--v6-graph-days N] [--v6-block B] [--v6-agg]\n"
        "                  [--v6-skip-exp] [--v6-skip-rng] [--v6-pred-loads]\n"
        "default backend is v0 (works in every build). v6 needs a -DENABLE_CUDA_V6=ON build and a usable GPU.\n"
        "exit: 0 ok, 1 error/mismatch/invalid input, 2 requested backend unavailable\n");
}

inline int run_cli(int argc, char** argv, FILE* out, FILE* err) {
    Cli c;
    c.p.days = 100; c.p.seed = 42; c.p.initial_infected = 100;
    auto bad = [&](const std::string& m) { fprintf(err, "extpop_run: error: %s\n", m.c_str()); usage(err); return 1; };
    for (int i = 1; i < argc; ++i) {
        const std::string k = argv[i];
        auto val = [&]() -> const char* { return (i + 1 < argc) ? argv[++i] : nullptr; };
        uint64_t u = 0; double d = 0;
        if (k == "--v6-agg") { c.v6_agg = c.v6_opts_given = true; continue; }
        if (k == "--v6-skip-exp") { c.v6_skip_exp = c.v6_opts_given = true; continue; }
        if (k == "--v6-skip-rng") { c.v6_skip_rng = c.v6_opts_given = true; continue; }
        if (k == "--v6-pred-loads") { c.v6_pred = c.v6_opts_given = true; continue; }
        const char* v = val();
        if (!v) return bad("option " + k + " needs a value");
        if (k == "--input") c.input = v;
        else if (k == "--json") c.json = v;
        else if (k == "--daily-csv") c.csv_prefix = v;
        else if (k == "--backend") {
            const std::string b = v;
            if (b == "v0") { c.run_v0 = true; c.run_v6 = false; }
            else if (b == "v6") { c.run_v0 = false; c.run_v6 = true; }
            else if (b == "both") { c.run_v0 = c.run_v6 = true; }
            else return bad("--backend must be v0, v6 or both");
        }
        else if (k == "--days") { if (!parse_u64(v, 1, 100000, u)) return bad("--days must be in [1,100000]"); c.p.days = (uint32_t)u; }
        else if (k == "--seed") { if (!parse_u64(v, 0, ~0ull, u)) return bad("--seed must be an unsigned 64-bit integer"); c.p.seed = u; }
        else if (k == "--init") { if (!parse_u64(v, 0, UINT32_MAX, u)) return bad("--init must be in [0,2^32-1]"); c.p.initial_infected = (uint32_t)u; }
        else if (k == "--incubation") { if (!parse_u64(v, 1, 65535, u)) return bad("--incubation must be in [1,65535]"); c.p.incubation_days = (uint16_t)u; }
        else if (k == "--infectious") { if (!parse_u64(v, 1, 65535, u)) return bad("--infectious must be in [1,65535]"); c.p.infectious_days = (uint16_t)u; }
        else if (k == "--beta-home") { if (!parse_dbl(v, 0.0, d)) return bad("--beta-home must be a number >= 0"); c.p.beta_home = d; }
        else if (k == "--beta-work") { if (!parse_dbl(v, 0.0, d)) return bad("--beta-work must be a number >= 0"); c.p.beta_work = d; }
        else if (k == "--expect-agents") { if (!parse_u64(v, 1, UINT32_MAX, u)) return bad("--expect-agents invalid"); c.expect_agents = u; }
        else if (k == "--expect-locations") { if (!parse_u64(v, 1, UINT32_MAX, u)) return bad("--expect-locations invalid"); c.expect_locations = u; }
        else if (k == "--v6-mode") { c.v6_mode = v; c.v6_opts_given = true;
            if (c.v6_mode != "sync" && c.v6_mode != "async" && c.v6_mode != "graph") return bad("--v6-mode must be sync, async or graph"); }
        else if (k == "--v6-graph-days") { if (!parse_u64(v, 1, 100000, u)) return bad("--v6-graph-days must be >= 1"); c.v6_graph_days = (uint32_t)u; c.v6_opts_given = true; }
        else if (k == "--v6-block") { if (!parse_u64(v, 1, 1024, u)) return bad("--v6-block invalid"); c.v6_block = (uint32_t)u; c.v6_opts_given = true; }
        else return bad("unknown option " + k);
    }
    if (c.input.empty()) return bad("--input is required");
    if (c.v6_opts_given && !c.run_v6) return bad("--v6-* options require --backend v6 or both");

    // ---- backend availability: fail before doing any work
#ifdef CITYEPI_WITH_V6
    V6Opts v6o;
    if (c.run_v6) {
        v6o.agg_counts = c.v6_agg; v6o.skip_exp = c.v6_skip_exp; v6o.skip_rng = c.v6_skip_rng; v6o.pred_loads = c.v6_pred;
        v6o.mode = c.v6_mode == "sync" ? V6Mode::kSync : c.v6_mode == "async" ? V6Mode::kAsync : V6Mode::kGraph;
        v6o.graph_days = c.v6_graph_days; v6o.block = c.v6_block;
        bool ok_block = false;
        for (uint32_t b : v6_supported_blocks()) ok_block |= (b == v6o.block);
        if (!ok_block) return bad("--v6-block must be one of 64,128,256,512,1024");
    }
    V6Info gpu;
    if (c.run_v6) {
        gpu = v6_probe();
        if (!gpu.gpu_ok) {
            fprintf(err, "extpop_run: V6 requested but no usable GPU: %s (devices=%d)\n", gpu.error.c_str(), gpu.num_devices);
            return 2;
        }
    }
#else
    if (c.run_v6) {
        fprintf(err, "extpop_run: V6 requested but this binary was built without V6 (reconfigure with -DENABLE_CUDA_V6=ON)\n");
        return 2;
    }
#endif

    // ---- load (format checks + CRC + validate_input inside the reader)
    Population pop;
    Locations locs;
    cepop::Info info;
    try {
        cepop::load(c.input, pop, locs, &info);
    } catch (const std::exception& e) {
        fprintf(err, "extpop_run: cannot load '%s': %s\n", c.input.c_str(), e.what());
        return 1;
    }
    if (c.expect_agents && info.n_agents != c.expect_agents) {
        fprintf(err, "extpop_run: expected %llu agents, file has %llu\n", (unsigned long long)c.expect_agents, (unsigned long long)info.n_agents);
        return 1;
    }
    if (c.expect_locations && info.n_locations != c.expect_locations) {
        fprintf(err, "extpop_run: expected %llu locations, file has %llu\n", (unsigned long long)c.expect_locations, (unsigned long long)info.n_locations);
        return 1;
    }
    fprintf(out, "input=%s\nformat=CEPOP v%u\nagents=%llu\nlocations=%llu\nfile_bytes=%llu\npayload_crc32=0x%08x\n", c.input.c_str(), info.version,
            (unsigned long long)info.n_agents, (unsigned long long)info.n_locations, (unsigned long long)info.file_bytes, info.payload_crc32);
    try {
        const Counts loaded = count_states(pop);
        fprintf(out, "loaded_states=S%u/E%u/I%u/R%u\n", loaded.s, loaded.e, loaded.i, loaded.r);
        seed_infections(c.p, pop);  // existing public API; external input is otherwise used as supplied
        validate_input(pop, locs);  // explicit re-validation of the exact pair handed to the backends
        const Counts start = count_states(pop);
        fprintf(out, "seeded_initial=S%u/E%u/I%u/R%u (seed=%llu init=%u days=%u)\nvalidate_input=ok\n", start.s, start.e, start.i, start.r,
                (unsigned long long)c.p.seed, c.p.initial_infected, c.p.days);

        const uint64_t N = info.n_agents;
        bool all_ok = true;
        Result r0, r6;
        double v6_total = 0, v6_events = 0;
        (void)r6; (void)v6_total; (void)v6_events;
        auto conserved = [&](const Result& r, const char* tag) {
            bool ok = r.daily.size() == (size_t)c.p.days + 1 && r.daily.front() == start;
            for (const Counts& d : r.daily) ok = ok && ((uint64_t)d.s + d.e + d.i + d.r == N);
            fprintf(out, "%s_population_conserved=%s\n%s_days_recorded=%zu\n", tag, ok ? "yes" : "NO", tag, r.daily.size());
            return ok;
        };
        auto write_csv = [&](const Result& r, const char* tag) {
            if (c.csv_prefix.empty()) return;
            const std::string path = c.csv_prefix + "_" + tag + ".csv";
            FILE* f = fopen(path.c_str(), "w");
            if (!f) { fprintf(err, "extpop_run: cannot write %s\n", path.c_str()); all_ok = false; return; }
            fprintf(f, "day,S,E,I,R\n");
            for (size_t d = 0; d < r.daily.size(); ++d) fprintf(f, "%zu,%u,%u,%u,%u\n", d, r.daily[d].s, r.daily[d].e, r.daily[d].i, r.daily[d].r);
            fclose(f);
        };
        if (c.run_v0) {
            r0 = run_simulation(c.p, pop, locs);
            all_ok &= conserved(r0, "v0");
            fprintf(out, "v0_status=ok\nv0_seconds=%.4f\nv0_final=S%u/E%u/I%u/R%u\nv0_daily_checksum=%016llx\n", r0.seconds, r0.daily.back().s,
                    r0.daily.back().e, r0.daily.back().i, r0.daily.back().r, (unsigned long long)daily_checksum(r0));
            write_csv(r0, "v0");
        }
#ifdef CITYEPI_WITH_V6
        if (c.run_v6) {
            V6Config cfg;
            cfg.opts = v6o;
            fprintf(out, "v6_device=%s cc%d.%d sms=%d driver=%d runtime=%d\nv6_options=%s\n", gpu.device_name.c_str(), gpu.cc_major,
                    gpu.cc_minor, gpu.sm_count, gpu.driver_version, gpu.runtime_version, v6_describe(v6o).c_str());
            V6Result v6 = run_simulation_v6(c.p, pop, locs, cfg);
            r6 = v6; v6_total = v6.seconds_total; v6_events = v6.seconds_events;
            all_ok &= conserved(r6, "v6");
            fprintf(out, "v6_status=ok\nv6_seconds_day_loop=%.4f\nv6_seconds_total=%.4f\nv6_final=S%u/E%u/I%u/R%u\nv6_daily_checksum=%016llx\n",
                    v6.seconds, v6.seconds_total, r6.daily.back().s, r6.daily.back().e, r6.daily.back().i, r6.daily.back().r,
                    (unsigned long long)daily_checksum(r6));
            write_csv(r6, "v6");
        }
#endif
        bool equal = true;
        if (c.run_v0 && c.run_v6) {
            size_t fd = 0;
            equal = daily_equal(r0, r6, &fd);
            fprintf(out, "v0_v6_daily_equal=%s\n", equal ? "yes" : "NO");
            if (!equal) {
                const Counts a = fd < r0.daily.size() ? r0.daily[fd] : Counts{}, b = fd < r6.daily.size() ? r6.daily[fd] : Counts{};
                fprintf(out, "first_divergence_day=%zu v0=S%u/E%u/I%u/R%u v6=S%u/E%u/I%u/R%u\n", fd, a.s, a.e, a.i, a.r, b.s, b.e, b.i, b.r);
                all_ok = false;
            }
        }
        if (!c.json.empty()) {
            FILE* f = fopen(c.json.c_str(), "w");
            if (!f) { fprintf(err, "extpop_run: cannot write %s\n", c.json.c_str()); return 1; }
            auto esc = [](const std::string& s) { std::string o; for (char ch : s) { if (ch == '"' || ch == '\\') o += '\\'; o += ch; } return o; };
            fprintf(f, "{\n  \"input\": \"%s\",\n  \"agents\": %llu,\n  \"locations\": %llu,\n  \"payload_crc32\": \"0x%08x\",\n", esc(c.input).c_str(),
                    (unsigned long long)N, (unsigned long long)info.n_locations, info.payload_crc32);
            fprintf(f, "  \"seed\": %llu,\n  \"days\": %u,\n  \"initial_infected\": %u,\n", (unsigned long long)c.p.seed, c.p.days, c.p.initial_infected);
            fprintf(f, "  \"v0\": ");
            if (c.run_v0) fprintf(f, "{\"seconds\": %.6f, \"daily_checksum\": \"%016llx\", \"final\": [%u,%u,%u,%u]}", r0.seconds,
                                  (unsigned long long)daily_checksum(r0), r0.daily.back().s, r0.daily.back().e, r0.daily.back().i, r0.daily.back().r);
            else fprintf(f, "null");
            fprintf(f, ",\n  \"v6\": ");
#ifdef CITYEPI_WITH_V6
            if (c.run_v6) fprintf(f, "{\"device\": \"%s\", \"options\": \"%s\", \"seconds_total\": %.6f, \"seconds_events\": %.6f, \"daily_checksum\": \"%016llx\", \"final\": [%u,%u,%u,%u]}",
                                  esc(gpu.device_name).c_str(), esc(v6_describe(v6o)).c_str(), v6_total, v6_events, (unsigned long long)daily_checksum(r6),
                                  r6.daily.back().s, r6.daily.back().e, r6.daily.back().i, r6.daily.back().r);
            else
#endif
            fprintf(f, "null");
            fprintf(f, ",\n  \"v0_v6_equal\": %s,\n  \"pass\": %s\n}\n", (c.run_v0 && c.run_v6) ? (equal ? "true" : "false") : "null", all_ok ? "true" : "false");
            fclose(f);
        }
        fprintf(out, "RESULT: %s\n", all_ok ? "PASS" : "FAIL");
        return all_ok ? 0 : 1;
    } catch (const std::exception& e) {
        fprintf(err, "extpop_run: run failed: %s\n", e.what());
        return 1;
    }
}

}  // namespace extpop
