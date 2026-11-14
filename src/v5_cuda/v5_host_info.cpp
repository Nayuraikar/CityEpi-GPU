#include <cstdio>
#include <cstring>
#include <string>
#include <unistd.h>
#include <sys/utsname.h>
#ifdef __APPLE__
#include <sys/sysctl.h>
#endif
#include "v5_simulation.hpp"

V5HostInfo v5_host_info() {
    V5HostInfo h;
    h.cpu_model = "unknown";
    h.os = "unknown";
    const long nc = sysconf(_SC_NPROCESSORS_ONLN);
    h.logical_cores = nc > 0 ? (int)nc : 0;
    struct utsname u;
    if (uname(&u) == 0) h.os = std::string(u.sysname) + " " + u.release + " " + u.machine;
#ifdef __APPLE__
    char buf[256]; size_t len = sizeof buf;
    if (sysctlbyname("machdep.cpu.brand_string", buf, &len, nullptr, 0) == 0) h.cpu_model = buf;
    uint64_t mem = 0; len = sizeof mem;
    if (sysctlbyname("hw.memsize", &mem, &len, nullptr, 0) == 0) h.mem_bytes = (size_t)mem;
#else
    if (FILE* f = fopen("/proc/cpuinfo", "r")) {
        char line[512];
        while (fgets(line, sizeof line, f)) {
            if (!strncmp(line, "model name", 10) || !strncmp(line, "Model name", 10)) {
                const char* c = strchr(line, ':');
                if (c) { h.cpu_model = c + 1; while (!h.cpu_model.empty() && (h.cpu_model.back() == '\n' || h.cpu_model.back() == ' ')) h.cpu_model.pop_back();
                         size_t s = h.cpu_model.find_first_not_of(' '); if (s != std::string::npos) h.cpu_model.erase(0, s); }
                break;
            }
        }
        fclose(f);
    }
    if (FILE* f = fopen("/proc/meminfo", "r")) {
        char line[256]; unsigned long long kb = 0;
        while (fgets(line, sizeof line, f)) if (sscanf(line, "MemTotal: %llu kB", &kb) == 1) { h.mem_bytes = (size_t)kb * 1024; break; }
        fclose(f);
    }
#endif
    return h;
}
