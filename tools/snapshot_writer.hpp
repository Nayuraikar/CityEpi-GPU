#pragma once
// CESNAP v1 per-agent daily state snapshot writer (format spec: docs/snapshot_format.md). V0 only.
// Streams one packed frame per simulated day straight to disk: memory is O(N/4) for the frame buffer, never O(days).
// Purely an observer: it only READS Population::state; it does not touch the transition algorithm or any RNG.
//
// Layout (all integers little-endian):
//   [0,64)   header
//   [64,..)  home_loc  u32 x N                      (agent id = array index, same order as the CEPOP file)
//   pad to 8
//   frames   n_frames x frame_bytes                 (2 bits per agent: S=0 E=1 I=2 R=3, agent i in bits 2*(i%4) of byte i/4)
//   pad to 8
//   counts   n_frames x 4 x u32                     (S,E,I,R counted by the writer from the packed states)
//   footer   16 bytes: payload_crc32 u32 | 0 u32 | "CESNAPE\0"   (CRC-32 zlib/IEEE of bytes [64, footer_start))
// Frame d is the state at the END of day d: frame 0 = after seeding / before any step, frame D = after D steps.
#include <algorithm>   // std::fill (was only reachable transitively under Apple clang; Homebrew clang 23 / libc++ failed to build extpop_run)
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <filesystem>
#include <stdexcept>
#include <string>
#include <vector>
#include "agent.hpp"

namespace extpop {

class SnapshotWriter {
public:
    static constexpr uint32_t kVersion = 1, kEndian = 0x01020304u, kHeader = 64;
    static constexpr char kMagic[8] = {'C', 'E', 'S', 'N', 'A', 'P', '1', '\0'};
    static constexpr char kEndMagic[8] = {'C', 'E', 'S', 'N', 'A', 'P', 'E', '\0'};
    static constexpr const char* kFile = "states.cesnap";

    SnapshotWriter() = default;
    SnapshotWriter(const SnapshotWriter&) = delete;
    SnapshotWriter& operator=(const SnapshotWriter&) = delete;
    ~SnapshotWriter() { abort(); }

    static uint64_t align8(uint64_t x) { return (x + 7) & ~uint64_t(7); }
    static uint64_t frame_bytes(uint64_t n) { return (n + 3) / 4; }
    // Exact file size for (agents, frames).
    static uint64_t expected_size(uint64_t n, uint64_t frames) {
        const uint64_t frames_off = align8(kHeader + 4 * n);
        const uint64_t counts_off = align8(frames_off + frames * frame_bytes(n));
        return counts_off + frames * 16 + 16;
    }

    void open(const std::string& dir, const std::vector<uint32_t>& home_loc, uint64_t n_frames, uint32_t dataset_crc32,
              uint64_t seed) {
        namespace fs = std::filesystem;
        fs::create_directories(dir);
        dir_ = dir;
        final_ = (fs::path(dir) / kFile).string();
        tmp_ = final_ + ".partial";
        n_ = home_loc.size();
        frames_ = n_frames;
        if (n_ == 0 || n_frames == 0) throw std::runtime_error("snapshot: empty population or zero frames");
        f_ = fopen(tmp_.c_str(), "wb");
        if (!f_) throw std::runtime_error("snapshot: cannot create " + tmp_);
        uint8_t h[kHeader] = {0};
        std::memcpy(h, kMagic, 8);
        put32(h + 8, kVersion); put32(h + 12, kEndian);
        put64(h + 16, n_); put64(h + 24, n_frames);
        put32(h + 32, kHeader); put32(h + 36, 2 /*bits per agent*/);
        put32(h + 40, (uint32_t)frame_bytes(n_)); put32(h + 44, 0 /*flags*/);
        put32(h + 48, dataset_crc32); put32(h + 52, 0 /*backend: 0 = V0*/);
        put64(h + 56, seed);
        write(h, kHeader);  // header is not covered by the payload CRC
        crc_ = 0xFFFFFFFFu;
        std::vector<uint8_t> hl(4 * n_);
        for (size_t i = 0; i < n_; ++i) put32(&hl[4 * i], home_loc[i]);
        write_crc(hl.data(), hl.size());
        pad_to8(written_);
        buf_.assign(frame_bytes(n_), 0);
        counts_.reserve(n_frames);
    }

    // Packs and appends one frame; returns the counts the writer itself derived from the packed states.
    Counts add_frame(const Population& pop) {
        if (!f_) throw std::runtime_error("snapshot: writer not open");
        if (pop.size() != n_) throw std::runtime_error("snapshot: population size changed");
        if (counts_.size() >= frames_) throw std::runtime_error("snapshot: more frames than declared");
        Counts c;
        const uint8_t* s = pop.state.data();
        std::fill(buf_.begin(), buf_.end(), 0);
        for (size_t i = 0; i < n_; ++i) {
            const uint8_t v = s[i];
            if (v > R) throw std::runtime_error("snapshot: invalid agent state");
            buf_[i >> 2] |= (uint8_t)(v << (2 * (i & 3)));
            switch (v) { case S: ++c.s; break; case E: ++c.e; break; case I: ++c.i; break; default: ++c.r; }
        }
        write_crc(buf_.data(), buf_.size());
        counts_.push_back(c);
        return c;
    }

    // Writes counts table + footer, then atomically renames the partial file into place. Returns the payload CRC.
    uint32_t finish(uint64_t* bytes_out = nullptr) {
        if (!f_) throw std::runtime_error("snapshot: writer not open");
        if (counts_.size() != frames_) throw std::runtime_error("snapshot: fewer frames than declared");
        pad_to8(written_);
        std::vector<uint8_t> ct(16 * frames_);
        for (size_t d = 0; d < frames_; ++d) {
            put32(&ct[16 * d], counts_[d].s); put32(&ct[16 * d + 4], counts_[d].e);
            put32(&ct[16 * d + 8], counts_[d].i); put32(&ct[16 * d + 12], counts_[d].r);
        }
        write_crc(ct.data(), ct.size());
        const uint32_t crc = ~crc_;
        uint8_t ft[16] = {0};
        put32(ft, crc);
        std::memcpy(ft + 8, kEndMagic, 8);
        write(ft, 16);
        if (fflush(f_) != 0 || fclose(f_) != 0) { f_ = nullptr; throw std::runtime_error("snapshot: write failed (disk full?)"); }
        f_ = nullptr;
        if (written_ != expected_size(n_, frames_)) throw std::runtime_error("snapshot: internal size mismatch");
        std::filesystem::rename(tmp_, final_);
        if (bytes_out) *bytes_out = written_;
        return crc;
    }

    void abort() {
        if (f_) { fclose(f_); f_ = nullptr; std::error_code ec; std::filesystem::remove(tmp_, ec); }
    }
    const std::string& path() const { return final_; }

private:
    FILE* f_ = nullptr;
    std::string dir_, final_, tmp_;
    size_t n_ = 0;
    uint64_t frames_ = 0, written_ = 0;
    uint32_t crc_ = 0xFFFFFFFFu;
    std::vector<uint8_t> buf_;
    std::vector<Counts> counts_;

    static void put32(uint8_t* p, uint32_t v) { for (int b = 0; b < 4; ++b) p[b] = (uint8_t)(v >> (8 * b)); }
    static void put64(uint8_t* p, uint64_t v) { for (int b = 0; b < 8; ++b) p[b] = (uint8_t)(v >> (8 * b)); }
    void write(const uint8_t* d, size_t n) {
        if (fwrite(d, 1, n, f_) != n) throw std::runtime_error("snapshot: write failed (disk full?)");
        written_ += n;
    }
    void write_crc(const uint8_t* d, size_t n) {
        static const std::vector<uint32_t> T = [] {
            std::vector<uint32_t> t(256);
            for (uint32_t i = 0; i < 256; ++i) { uint32_t c = i; for (int k = 0; k < 8; ++k) c = (c & 1) ? 0xEDB88320u ^ (c >> 1) : c >> 1; t[i] = c; }
            return t;
        }();
        for (size_t i = 0; i < n; ++i) crc_ = T[(crc_ ^ d[i]) & 0xFF] ^ (crc_ >> 8);
        write(d, n);
    }
    // zero padding (part of the CRC'd payload) up to the next 8-byte file offset
    void pad_to8(uint64_t abs_end) {
        static const uint8_t z[8] = {0};
        const uint64_t pad = align8(abs_end) - abs_end;
        if (pad) write_crc(z, (size_t)pad);
    }
};

}  // namespace extpop
