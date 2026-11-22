/**
 * @file coro_bench.cpp
 * @brief C++20 coroutine microbenchmarks: Generator throughput, HALO elision counter, and symmetric-transfer Task chain (Experiment 4 -> Table 5 Rows 4-6).
 */

#include <atomic>
#include <coroutine>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <new>

static std::atomic<std::uint64_t> g_coro_allocs{0};

template <typename T>
struct Generator {
  struct promise_type {
    T current_value{};

    static void *operator new(std::size_t n) {
      g_coro_allocs.fetch_add(1, std::memory_order_relaxed);
      return ::operator new(n);
    }
    static void *operator new(std::size_t n, std::align_val_t al) {
      g_coro_allocs.fetch_add(1, std::memory_order_relaxed);
      return ::operator new(n, al);
    }
    static void operator delete(void *p) noexcept { ::operator delete(p); }
    static void operator delete(void *p, std::align_val_t al) noexcept { ::operator delete(p, al); }

    Generator get_return_object() noexcept {
      return Generator{std::coroutine_handle<promise_type>::from_promise(*this)};
    }
    std::suspend_always initial_suspend() noexcept { return {}; }
    std::suspend_always final_suspend() noexcept { return {}; }
    std::suspend_always yield_value(T v) noexcept {
      current_value = v;
      return {};
    }
    void return_void() noexcept {}
    void unhandled_exception() { std::abort(); }
  };

  std::coroutine_handle<promise_type> h;
  explicit Generator(std::coroutine_handle<promise_type> handle) noexcept : h(handle) {}
  Generator(Generator &&other) noexcept : h(other.h) { other.h = nullptr; }
  Generator(const Generator &) = delete;
  ~Generator() {
    if (h) h.destroy();
  }
  bool next() {
    h.resume();
    return !h.done();
  }
  T value() const noexcept { return h.promise().current_value; }
};

static Generator<std::uint64_t> prng_stream(std::uint64_t seed, std::uint64_t count) {
  std::uint64_t x = seed ? seed : 0xCAFEBABE12345678ULL;
  for (std::uint64_t i = 0; i < count; ++i) {
    x ^= x >> 12;
    x ^= x << 25;
    x ^= x >> 27;
    co_yield x * 0x2545F4914F6CDD1DULL;
  }
}

static Generator<std::uint64_t> range_gen(std::uint64_t base) {
  for (std::uint64_t k = 0; k < 5ULL; ++k) {
    co_yield base + k;
  }
}

struct PingPongTask {
  struct promise_type {
    std::coroutine_handle<> partner = std::noop_coroutine();
    PingPongTask get_return_object() noexcept {
      return PingPongTask{std::coroutine_handle<promise_type>::from_promise(*this)};
    }
    std::suspend_always initial_suspend() noexcept { return {}; }
    std::suspend_always final_suspend() noexcept { return {}; }
    void return_void() noexcept {}
    void unhandled_exception() { std::abort(); }
  };

  struct SymmetricHop {
    std::coroutine_handle<> next;
    bool await_ready() const noexcept { return false; }
    std::coroutine_handle<> await_suspend(std::coroutine_handle<>) const noexcept { return next; }
    void await_resume() const noexcept {}
  };

  std::coroutine_handle<promise_type> h;
  explicit PingPongTask(std::coroutine_handle<promise_type> handle) noexcept : h(handle) {}
  PingPongTask(PingPongTask &&o) noexcept : h(o.h) { o.h = nullptr; }
  ~PingPongTask() {
    if (h) h.destroy();
  }
};

static PingPongTask make_worker(std::uint64_t hops, std::uint64_t *counter) {
  std::coroutine_handle<PingPongTask::promise_type> self;
  struct GetSelf {
    std::coroutine_handle<PingPongTask::promise_type> *out;
    bool await_ready() const noexcept { return false; }
    bool await_suspend(std::coroutine_handle<PingPongTask::promise_type> h) const noexcept {
      *out = h;
      return false;
    }
    void await_resume() const noexcept {}
  };
  co_await GetSelf{&self};
  for (std::uint64_t i = 0; i < hops; ++i) {
    *counter += 1ULL;
    co_await PingPongTask::SymmetricHop{self.promise().partner};
  }
}

int main(int argc, char **argv) {
  const char *mode = "generator";
  std::uint64_t iters = 0;

  for (int i = 1; i < argc; ++i) {
    if (std::strncmp(argv[i], "--mode=", 7) == 0) {
      mode = argv[i] + 7;
    } else if (std::strncmp(argv[i], "--iters=", 8) == 0) {
      iters = static_cast<std::uint64_t>(std::strtoull(argv[i] + 8, nullptr, 10));
    }
  }

  std::uint64_t seed = static_cast<std::uint64_t>(argc > 0 ? argc : 1);
  g_coro_allocs.store(0, std::memory_order_relaxed);

  if (std::strcmp(mode, "generator") == 0) {
    if (iters == 0) iters = 50000000ULL;
    std::uint64_t acc = 0;
    auto g = prng_stream(seed, iters);
    while (g.next()) {
      acc ^= g.value();
    }
#if defined(__GNUC__) || defined(__clang__)
    asm volatile("" : "+r"(acc) : : "memory");
#endif
    std::printf("generator_checksum=%llu coro_allocs=%llu\n",
                static_cast<unsigned long long>(acc),
                static_cast<unsigned long long>(g_coro_allocs.load()));
    return (acc == 0ULL) ? 1 : 0;
  }

  if (std::strcmp(mode, "halo") == 0) {
    if (iters == 0) iters = 1000000ULL;
    std::uint64_t acc = 0;
    for (std::uint64_t i = 0; i < iters; ++i) {
      auto g = range_gen(i ^ seed);
      while (g.next()) {
        acc += g.value();
      }
    }
#if defined(__GNUC__) || defined(__clang__)
    asm volatile("" : "+r"(acc) : : "memory");
#endif
    std::printf("coro_allocs=%llu halo_checksum=%llu\n",
                static_cast<unsigned long long>(g_coro_allocs.load()),
                static_cast<unsigned long long>(acc));
    return (acc == 0ULL) ? 1 : 0;
  }

  if (std::strcmp(mode, "task") == 0) {
    if (iters == 0) iters = 1000000ULL;
    std::uint64_t half = iters / 2ULL;
    if (half == 0) half = 1ULL;
    std::uint64_t hops = 0;
    PingPongTask a = make_worker(half, &hops);
    PingPongTask b = make_worker(half, &hops);
    a.h.promise().partner = b.h;
    b.h.promise().partner = a.h;
    a.h.resume();
    if (!b.h.done()) {
      b.h.resume();
    }
    std::printf("task_hops=%llu\n", static_cast<unsigned long long>(hops));
    return (hops >= half) ? 0 : 2;
  }

  return 1;
}
