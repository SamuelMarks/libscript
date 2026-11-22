/**
 * @file abi_interop_fuzz_gen.c
 * @brief Deterministic C11 Split-TU cross-compiler psABI signature generator (`seed = 2027`).
 *
 * Replaces `benchmarks/abi_interop_fuzz.py`, emitting `caller_XX.cpp`, `callee_XX.cpp`, and
 * `batch_XX.hpp` across 1,000 C and C++ function signatures spanning:
 *   0: Small/medium/large structs (1..64 bytes)
 *   1: `#pragma pack(1)` packed structs
 *   2: Bitfield runs including full-width `int:32`
 *   3: Mixed eightbyte structs (`{int32_t, float, double}`)
 *   4: 1-4 lane float/double HFAs
 *   5: Non-trivially copyable C++ structs (user copy ctor + dtor)
 *   6: C variadic functions (`...` via `va_start`/`va_arg`) & C++ virtual/non-virtual PMFs
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static uint64_t prng_next(uint64_t *state) {
  uint64_t x = *state;
  x ^= x >> 12;
  x ^= x << 25;
  x ^= x >> 27;
  *state = x;
  return x * 0x2545F4914F6CDD1DULL;
}

int main(int argc, char **argv) {
  uint64_t seed = 2027ULL;
  int total_sigs = 1000;
  int batch_size = 50;
  const char *out_dir = ".";
  int i, b;

  for (i = 1; i < argc; ++i) {
    if (strcmp(argv[i], "--seed") == 0 && i + 1 < argc) {
      seed = (uint64_t)strtoull(argv[++i], NULL, 10);
    } else if (strcmp(argv[i], "--count") == 0 && i + 1 < argc) {
      total_sigs = atoi(argv[++i]);
    } else if (strcmp(argv[i], "--batch-size") == 0 && i + 1 < argc) {
      batch_size = atoi(argv[++i]);
    } else if (strcmp(argv[i], "--out-dir") == 0 && i + 1 < argc) {
      out_dir = argv[++i];
    }
  }

  if (total_sigs < 1) total_sigs = 50;
  if (batch_size < 1) batch_size = 50;

  {
    int num_batches = (total_sigs + batch_size - 1) / batch_size;
    int sig_idx = 0;

    for (b = 0; b < num_batches; ++b) {
      char hdr_path[1024];
      char caller_path[1024];
      char callee_path[1024];
      FILE *fh, *fcaller, *fcallee;
      int start_id = sig_idx;
      int end_id = sig_idx + batch_size;
      if (end_id > total_sigs) end_id = total_sigs;

      snprintf(hdr_path, sizeof(hdr_path), "%s/batch_%02d.hpp", out_dir, b);
      snprintf(caller_path, sizeof(caller_path), "%s/caller_%02d.cpp", out_dir, b);
      snprintf(callee_path, sizeof(callee_path), "%s/callee_%02d.cpp", out_dir, b);

      fh = fopen(hdr_path, "wb");
      fcaller = fopen(caller_path, "wb");
      fcallee = fopen(callee_path, "wb");
      if (!fh || !fcaller || !fcallee) {
        return 1;
      }

      fprintf(fh, "#pragma once\n#include <cstdarg>\n#include <cstdint>\n#include <cmath>\n\n");
      fprintf(fcallee, "#include \"batch_%02d.hpp\"\n\n", b);
      fprintf(fcaller, "#include \"batch_%02d.hpp\"\n#include <cstdio>\n\nint main() {\n  int failures = 0;\n", b);

      for (sig_idx = start_id; sig_idx < end_id; ++sig_idx) {
        uint64_t r = prng_next(&seed);
        int kind = sig_idx % 7;
        int c1 = (int)((r & 0x7FU) + 3U);
        int c2 = (int)(((r >> 8) & 0x7FU) + 5U);

        if (kind == 0) {
          int bytes = (int)((sig_idx % 8) + 1) * 8;
          int words = bytes / 8;
          int w;
          unsigned long exp0 = (words == 1)
              ? ((unsigned long)(17 + c1) ^ (unsigned long)c2)
              : (unsigned long)(17 + c1);
          unsigned long exp_last = (words == 1)
              ? exp0
              : ((unsigned long)((words - 1) + 10) ^ (unsigned long)c2);
          fprintf(fh, "struct Pod_%d { std::uint64_t w[%d]; };\n", sig_idx, words);
          fprintf(fh, "Pod_%d abi_fn_%d(Pod_%d a, std::uint64_t tag);\n", sig_idx, sig_idx, sig_idx);
          fprintf(fcallee, "Pod_%d abi_fn_%d(Pod_%d a, std::uint64_t tag) { a.w[0] += tag + 0x%xULL; a.w[%d] ^= 0x%xULL; return a; }\n",
                  sig_idx, sig_idx, sig_idx, (unsigned)c1, words - 1, (unsigned)c2);
          fprintf(fcaller, "  { Pod_%d in{}; ", sig_idx);
          for (w = 0; w < words; ++w) fprintf(fcaller, "in.w[%d] = %dULL; ", w, w + 10);
          fprintf(fcaller, "Pod_%d out = abi_fn_%d(in, 7ULL); if (out.w[0] != 0x%lxULL || out.w[%d] != 0x%lxULL) ++failures; }\n",
                  sig_idx, sig_idx, exp0, words - 1, exp_last);
        } else if (kind == 1) {
          fprintf(fh, "#pragma pack(push, 1)\nstruct Packed_%d { std::uint8_t tag; std::uint32_t mid; std::uint16_t tail; };\n#pragma pack(pop)\n", sig_idx);
          fprintf(fh, "Packed_%d abi_fn_%d(Packed_%d p);\n", sig_idx, sig_idx, sig_idx);
          fprintf(fcallee, "Packed_%d abi_fn_%d(Packed_%d p) { p.tag = static_cast<std::uint8_t>(p.tag + 1U); p.mid += %uU; p.tail ^= %uU; return p; }\n",
                  sig_idx, sig_idx, sig_idx, (unsigned)c1, (unsigned)c2);
          fprintf(fcaller, "  { Packed_%d p{3U, 1000U, 25U}; Packed_%d q = abi_fn_%d(p); if (q.tag != 4U || q.mid != %uU || q.tail != (25U ^ %uU)) ++failures; }\n",
                  sig_idx, sig_idx, sig_idx, 1000U + (unsigned)c1, (unsigned)c2);
        } else if (kind == 2) {
          fprintf(fh, "struct Bitf_%d { unsigned a : 5; unsigned b : 11; int full32 : 32; unsigned c : 16; };\n", sig_idx);
          fprintf(fh, "int abi_fn_%d(Bitf_%d bf);\n", sig_idx, sig_idx);
          fprintf(fcallee, "int abi_fn_%d(Bitf_%d bf) { return static_cast<int>(bf.a + bf.b + bf.c) + bf.full32 + %d; }\n",
                  sig_idx, sig_idx, c1);
          fprintf(fcaller, "  { Bitf_%d bf{7U, 300U, 50000, 900U}; if (abi_fn_%d(bf) != (7 + 300 + 900 + 50000 + %d)) ++failures; }\n",
                  sig_idx, sig_idx, c1);
        } else if (kind == 3) {
          fprintf(fh, "struct Mixed_%d { std::int32_t i; float f; double d; };\n", sig_idx);
          fprintf(fh, "Mixed_%d abi_fn_%d(Mixed_%d m);\n", sig_idx, sig_idx, sig_idx);
          fprintf(fcallee, "Mixed_%d abi_fn_%d(Mixed_%d m) { m.i += %d; m.f += 2.0f; m.d += 4.0; return m; }\n",
                  sig_idx, sig_idx, sig_idx, c1);
          fprintf(fcaller, "  { Mixed_%d m{10, 1.5f, 3.25}; Mixed_%d r = abi_fn_%d(m); if (r.i != %d || std::fabs(r.f - 3.5f) > 1e-5f || std::fabs(r.d - 7.25) > 1e-9) ++failures; }\n",
                  sig_idx, sig_idx, sig_idx, 10 + c1);
        } else if (kind == 4) {
          int lanes = (sig_idx % 4) + 1;
          int l;
          fprintf(fh, "struct Hfa_%d { float v[%d]; };\n", sig_idx, lanes);
          fprintf(fh, "Hfa_%d abi_fn_%d(Hfa_%d h);\n", sig_idx, sig_idx, sig_idx);
          fprintf(fcallee, "Hfa_%d abi_fn_%d(Hfa_%d h) { for (int i = 0; i < %d; ++i) h.v[i] = h.v[i] * 2.0f + 1.0f; return h; }\n",
                  sig_idx, sig_idx, sig_idx, lanes);
          fprintf(fcaller, "  { Hfa_%d h{}; ", sig_idx);
          for (l = 0; l < lanes; ++l) fprintf(fcaller, "h.v[%d] = %d.0f; ", l, l + 1);
          fprintf(fcaller, "Hfa_%d o = abi_fn_%d(h); if (std::fabs(o.v[%d] - %d.0f) > 1e-4f) ++failures; }\n",
                  sig_idx, sig_idx, lanes - 1, lanes * 2 + 1);
        } else if (kind == 5) {
          fprintf(fh, "struct NonTriv_%d {\n  std::int64_t x;\n  std::int64_t copies;\n", sig_idx);
          fprintf(fh, "  explicit NonTriv_%d(std::int64_t v) : x(v), copies(0) {}\n", sig_idx);
          fprintf(fh, "  NonTriv_%d(const NonTriv_%d &o) : x(o.x + %d), copies(o.copies + 1) {}\n", sig_idx, sig_idx, c1);
          fprintf(fh, "  ~NonTriv_%d() { x = -1; }\n};\n", sig_idx);
          fprintf(fh, "NonTriv_%d abi_fn_%d(NonTriv_%d nt);\n", sig_idx, sig_idx, sig_idx);
          fprintf(fcallee, "NonTriv_%d abi_fn_%d(NonTriv_%d nt) { NonTriv_%d res(nt.x + %d); return res; }\n",
                  sig_idx, sig_idx, sig_idx, sig_idx, c2);
          fprintf(fcaller, "  { NonTriv_%d a(100); NonTriv_%d b = abi_fn_%d(a); if (b.x < (100 + %d + %d)) ++failures; }\n",
                  sig_idx, sig_idx, sig_idx, c1, c2);
        } else {
          fprintf(fh, "extern \"C\" long abi_var_%d(int n, ...);\n", sig_idx);
          fprintf(fh, "struct PmfHost_%d { long base; virtual long vadd(long v) const; long nvadd(long v) const; virtual ~PmfHost_%d() = default; };\n", sig_idx, sig_idx);
          fprintf(fh, "long abi_pmf_%d(const PmfHost_%d &obj, long (PmfHost_%d::*pmf)(long) const, long arg);\n", sig_idx, sig_idx, sig_idx);
          fprintf(fcallee, "extern \"C\" long abi_var_%d(int n, ...) { va_list ap; va_start(ap, n); long s = 0; for (int i = 0; i < n; ++i) s += va_arg(ap, long); va_end(ap); return s; }\n", sig_idx);
          fprintf(fcallee, "long PmfHost_%d::vadd(long v) const { return base + v + %dL; }\n", sig_idx, c1);
          fprintf(fcallee, "long PmfHost_%d::nvadd(long v) const { return base + v + %dL; }\n", sig_idx, c2);
          fprintf(fcallee, "long abi_pmf_%d(const PmfHost_%d &obj, long (PmfHost_%d::*pmf)(long) const, long arg) { return (obj.*pmf)(arg); }\n", sig_idx, sig_idx, sig_idx);
          fprintf(fcaller, "  { PmfHost_%d h; h.base = 20L; if (abi_var_%d(3, 10L, 20L, 30L) != 60L) ++failures; if (abi_pmf_%d(h, &PmfHost_%d::vadd, 5L) != %dL) ++failures; if (abi_pmf_%d(h, &PmfHost_%d::nvadd, 5L) != %dL) ++failures; }\n",
                  sig_idx, sig_idx, sig_idx, sig_idx, 25 + c1, sig_idx, sig_idx, 25 + c2);
        }
      }

      fprintf(fcaller, "  return failures;\n}\n");
      fclose(fh);
      fclose(fcaller);
      fclose(fcallee);
    }
  }
  return 0;
}
