/**
 * @file eh_bench.cpp
 * @brief DCE-proof C++ exception unwinding microbenchmarks (Experiment 3 -> Table 5 Rows 1-3).
 *
 * Modes:
 *   --mode=raii     Row 1: Non-throwing RAII fast path (default 10^8 iterations, 0% throws)
 *   --mode=single   Row 2: 10-frame single-inheritance BaseEx& catch (default 10^5 throws)
 *   --mode=diamond  Row 3: 10-frame virtual-diamond & MI VBase& catch (default 10^5 throws)
 */

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <exception>
#include <stdexcept>

#if defined(_MSC_VER)
#include <intrin.h>
#define EH_NOINLINE __declspec(noinline)
static inline void eh_barrier_u64(std::uint64_t &v) {
  volatile std::uint64_t sink = v;
  _ReadWriteBarrier();
  v = sink;
}
static inline void eh_barrier_mem(std::uint64_t *p) {
  volatile std::uint64_t cur = *p;
  _ReadWriteBarrier();
  *p = cur;
}
#else
#define EH_NOINLINE __attribute__((noinline))
static inline void eh_barrier_u64(std::uint64_t &v) {
  asm volatile("" : "+r"(v) : : "memory");
}
static inline void eh_barrier_mem(std::uint64_t *p) {
  asm volatile("" : "+m"(*p) : : "memory");
}
#endif

struct Guard {
  std::uint64_t *sink;
  ~Guard() { eh_barrier_mem(sink); }
};

struct BaseEx {
  int code;
  explicit BaseEx(int c) : code(c) {}
  virtual ~BaseEx() = default;
};

struct DerivedEx : BaseEx {
  int payload;
  DerivedEx(int c, int p) : BaseEx(c), payload(p) {}
};

struct VBase {
  long v = 100;
  virtual ~VBase() = default;
};
struct Left : virtual VBase {
  long l = 1;
};
struct Right : virtual VBase {
  long r = 2;
};
struct Pad {
  long p = 99;
};
struct MostDerived : Pad, Left, Right {
  long d = 3;
};

static EH_NOINLINE std::uint64_t raii_leaf(std::uint64_t x, int never_throw, std::uint64_t *sink) {
  Guard g{sink};
  try {
    if (never_throw < 0) {
      throw std::runtime_error("unreachable");
    }
    return x + 1ULL;
  } catch (const std::exception &) {
    return 0ULL;
  }
}

static EH_NOINLINE std::uint64_t raii_d3(std::uint64_t x, int nt, std::uint64_t *s) {
  Guard g{s};
  try { return raii_leaf(x + 1ULL, nt, s); } catch (const std::exception &) { return 0ULL; }
}

static EH_NOINLINE std::uint64_t raii_d2(std::uint64_t x, int nt, std::uint64_t *s) {
  Guard g{s};
  try { return raii_d3(x + 1ULL, nt, s); } catch (const std::exception &) { return 0ULL; }
}

static EH_NOINLINE std::uint64_t raii_d1(std::uint64_t x, int nt, std::uint64_t *s) {
  Guard g{s};
  try { return raii_d2(x + 1ULL, nt, s); } catch (const std::exception &) { return 0ULL; }
}

#define DEFINE_SINGLE_FRAME(CUR, NEXT) \
  static EH_NOINLINE int single_f##CUR(int iter, std::uint64_t *sink) { \
    Guard g{sink}; \
    *sink += 1ULL; \
    return single_f##NEXT(iter, sink) + 1; \
  }

static EH_NOINLINE int single_f10(int iter, std::uint64_t *sink) {
  Guard g{sink};
  if (iter >= 0) {
    throw DerivedEx(42, iter);
  }
  return 0;
}

DEFINE_SINGLE_FRAME(9, 10)
DEFINE_SINGLE_FRAME(8, 9)
DEFINE_SINGLE_FRAME(7, 8)
DEFINE_SINGLE_FRAME(6, 7)
DEFINE_SINGLE_FRAME(5, 6)
DEFINE_SINGLE_FRAME(4, 5)
DEFINE_SINGLE_FRAME(3, 4)
DEFINE_SINGLE_FRAME(2, 3)
DEFINE_SINGLE_FRAME(1, 2)

#define DEFINE_DIAMOND_FRAME(CUR, NEXT) \
  static EH_NOINLINE long diamond_f##CUR(int iter, std::uint64_t *sink) { \
    Guard g{sink}; \
    *sink += 1ULL; \
    return diamond_f##NEXT(iter, sink) + 1L; \
  }

static EH_NOINLINE long diamond_f10(int iter, std::uint64_t *sink) {
  Guard g{sink};
  if (iter >= 0) {
    MostDerived md;
    md.v = 100L;
    throw md;
  }
  return 0L;
}

DEFINE_DIAMOND_FRAME(9, 10)
DEFINE_DIAMOND_FRAME(8, 9)
DEFINE_DIAMOND_FRAME(7, 8)
DEFINE_DIAMOND_FRAME(6, 7)
DEFINE_DIAMOND_FRAME(5, 6)
DEFINE_DIAMOND_FRAME(4, 5)
DEFINE_DIAMOND_FRAME(3, 4)
DEFINE_DIAMOND_FRAME(2, 3)
DEFINE_DIAMOND_FRAME(1, 2)

int main(int argc, char **argv) {
  const char *mode = "raii";
  std::uint64_t iters = 0;
  int i;

  for (i = 1; i < argc; ++i) {
    if (std::strncmp(argv[i], "--mode=", 7) == 0) {
      mode = argv[i] + 7;
    } else if (std::strncmp(argv[i], "--iters=", 8) == 0) {
      iters = static_cast<std::uint64_t>(std::strtoull(argv[i] + 8, nullptr, 10));
    }
  }

  std::uint64_t sink = static_cast<std::uint64_t>(argc > 0 ? 1 : 0);
  std::uint64_t acc = 0;
  int rt_guard = (argc > 0) ? 1 : -1;

  if (std::strcmp(mode, "raii") == 0) {
    if (iters == 0) iters = 100000000ULL;
    for (std::uint64_t k = 0; k < iters; ++k) {
      std::uint64_t v = k ^ sink;
      eh_barrier_u64(v);
      acc += raii_d1(v, rt_guard, &sink);
    }
    eh_barrier_u64(acc);
    return (acc > 0 && sink > 0) ? 0 : 2;
  }

  if (std::strcmp(mode, "single") == 0) {
    if (iters == 0) iters = 100000ULL;
    for (std::uint64_t k = 0; k < iters; ++k) {
      int arg = static_cast<int>(k & 0x7FFFU);
      try {
        acc += static_cast<std::uint64_t>(single_f1(arg, &sink));
      } catch (BaseEx &e) {
        acc += static_cast<std::uint64_t>(e.code);
      }
    }
    eh_barrier_u64(acc);
    return (acc == iters * 42ULL) ? 0 : 3;
  }

  if (std::strcmp(mode, "diamond") == 0) {
    if (iters == 0) iters = 100000ULL;
    for (std::uint64_t k = 0; k < iters; ++k) {
      int arg = static_cast<int>(k & 0x7FFFU);
      try {
        acc += static_cast<std::uint64_t>(diamond_f1(arg, &sink));
      } catch (VBase &vb) {
        if (vb.v != 100L) {
          return 4;
        }
        acc += static_cast<std::uint64_t>(vb.v);
      }
    }
    eh_barrier_u64(acc);
    return (acc == iters * 100ULL) ? 0 : 5;
  }

  return 1;
}
