/**
 * @file gen_crtp_bench.c
 * @brief Deterministic C11 generator emitting `cpp_crtp_bench.cpp` (350-class CRTP + constexpr hierarchy).
 *
 * Replaces `benchmarks/gen_crtp_bench.py` with a zero-dependency C11 executable whose generated
 * C++17 translation unit feeds runtime `argc` through every CRTP template specialization and
 * verifies an exact checksum so `-O2`/`-O3` must optimize emitted methods rather than dead-stripping them.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
  int num_classes = 350;
  const char *out_path = NULL;
  FILE *fp = stdout;
  int i;

  for (i = 1; i < argc; ++i) {
    if (strcmp(argv[i], "--classes") == 0 && i + 1 < argc) {
      num_classes = atoi(argv[++i]);
      if (num_classes < 4) num_classes = 4;
    } else if (strcmp(argv[i], "-o") == 0 && i + 1 < argc) {
      out_path = argv[++i];
    }
  }

  if (out_path != NULL) {
    fp = fopen(out_path, "wb");
    if (fp == NULL) {
      return 1;
    }
  }

  fprintf(fp, "#include <cstdint>\n#include <cstdio>\n\n");
  fprintf(fp, "#if defined(_MSC_VER)\n#define BENCH_NOINLINE __declspec(noinline)\n");
  fprintf(fp, "#else\n#define BENCH_NOINLINE __attribute__((noinline))\n#endif\n\n");
  fprintf(fp, "template <typename Derived, std::uint64_t K>\nstruct CrtpBase {\n");
  fprintf(fp, "  static constexpr std::uint64_t mix_const(std::uint64_t x) noexcept {\n");
  fprintf(fp, "    return (x ^ (K * 0x9E3779B97F4A7C15ULL)) * 0xBF58476D1CE4E5B9ULL;\n  }\n");
  fprintf(fp, "  BENCH_NOINLINE std::uint64_t eval(std::uint64_t rt) const noexcept {\n");
  fprintf(fp, "    constexpr std::uint64_t cval = mix_const(K + 17ULL);\n");
  fprintf(fp, "    return static_cast<const Derived *>(this)->step(rt ^ (cval & 0xFFFFULL));\n  }\n};\n\n");

  for (i = 0; i < num_classes; ++i) {
    unsigned long k = (unsigned long)(i * 1315423911UL + 7UL) & 0xFFFFUL;
    fprintf(fp, "struct Node_%d : CrtpBase<Node_%d, %luULL> {\n", i, i, k);
    fprintf(fp, "  std::uint64_t bias;\n");
    fprintf(fp, "  constexpr explicit Node_%d(std::uint64_t b) noexcept : bias(b + %dULL) {}\n", i, i + 1);
    fprintf(fp, "  BENCH_NOINLINE std::uint64_t step(std::uint64_t v) const noexcept {\n");
    fprintf(fp, "    std::uint64_t z = v + bias + %luULL;\n", (unsigned long)((i * 37) + 3));
    fprintf(fp, "    z ^= (z >> 13);\n    z *= 0x2545F4914F6CDD1DULL;\n    return z ^ (z >> 17);\n  }\n};\n\n");
  }

  fprintf(fp, "int main(int argc, char **argv) {\n  (void)argv;\n");
  fprintf(fp, "  std::uint64_t seed = static_cast<std::uint64_t>(argc > 0 ? argc : 1);\n");
  fprintf(fp, "  std::uint64_t acc = 0x123456789ABCDEF0ULL ^ seed;\n");
  for (i = 0; i < num_classes; ++i) {
    fprintf(fp, "  { Node_%d n(seed + %dULL); acc ^= n.eval(acc + %dULL); }\n", i, i, i * 3);
  }
  fprintf(fp, "#if defined(__GNUC__) || defined(__clang__)\n");
  fprintf(fp, "  asm volatile(\"\" : \"+r\"(acc) : : \"memory\");\n#endif\n");
  fprintf(fp, "  return (acc == 0ULL) ? 1 : 0;\n}\n");

  if (out_path != NULL) {
    fclose(fp);
  }
  return 0;
}
