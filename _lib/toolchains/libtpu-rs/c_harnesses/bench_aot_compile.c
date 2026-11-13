/*
 * bench_aot_compile.c
 * Portable C11 offline AOT PJRT_Compile & memory-stats benchmark harness for Suite E4.3.
 */
#if defined(__APPLE__)
#define _DARWIN_C_SOURCE 1
#else
#define _DEFAULT_SOURCE 1
#define _POSIX_C_SOURCE 200809L
#endif
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(_WIN32)
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <psapi.h>
#else
#include <dlfcn.h>
#include <sys/resource.h>
#include <time.h>
#endif

typedef struct PjrtApiMinHeader {
  size_t struct_size;
  void *extension_start;
} PjrtApiMinHeader;

typedef const PjrtApiMinHeader *(*GetPjrtApiFn)(void);
typedef int (*LibtpuRsAotCompileFileFn)(const char *ir_path, const char *arch_gen,
                                        uint64_t *code_bytes, uint64_t *temp_bytes);

static uint64_t monotonic_ns(void) {
#if defined(_WIN32)
  LARGE_INTEGER freq;
  LARGE_INTEGER counter;
  QueryPerformanceFrequency(&freq);
  QueryPerformanceCounter(&counter);
  return (uint64_t)((double)counter.QuadPart * 1000000000.0 / (double)freq.QuadPart);
#else
  struct timespec ts;
  if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) {
    return 0ULL;
  }
  return ((uint64_t)ts.tv_sec * 1000000000ULL) + (uint64_t)ts.tv_nsec;
#endif
}

static uint64_t peak_rss_bytes(void) {
#if defined(_WIN32)
  PROCESS_MEMORY_COUNTERS pmc;
  if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc))) {
    return (uint64_t)pmc.PeakWorkingSetSize;
  }
  return 0ULL;
#else
  struct rusage ru;
  if (getrusage(RUSAGE_SELF, &ru) != 0) {
    return 0ULL;
  }
#if defined(__APPLE__) && defined(__MACH__)
  return (uint64_t)ru.ru_maxrss;
#else
  return (uint64_t)ru.ru_maxrss * 1024ULL;
#endif
#endif
}

int main(int argc, char **argv) {
  if (argc < 4) {
    fprintf(stderr, "Usage: %s <pjrt_shared_lib> <stablehlo_ir_file> <arch_gen>\n", argv[0]);
    return 2;
  }
  const char *lib_path = argv[1];
  const char *ir_path = argv[2];
  const char *arch_gen = argv[3];

  FILE *f = fopen(ir_path, "rb");
  if (f == NULL) {
    fprintf(stderr, "Cannot open IR workload file: %s\n", ir_path);
    return 1;
  }
  if (fseek(f, 0, SEEK_END) != 0) {
    fclose(f);
    return 1;
  }
  long ir_len = ftell(f);
  fclose(f);
  if (ir_len < 0) {
    ir_len = 0;
  }

#if defined(_WIN32)
  HMODULE handle = LoadLibraryA(lib_path);
  if (handle == NULL) {
    return 1;
  }
  FARPROC raw_sym = GetProcAddress(handle, "GetPjrtApi");
#else
  void *handle = dlopen(lib_path, RTLD_NOW | RTLD_LOCAL);
  if (handle == NULL) {
    fprintf(stderr, "dlopen failed for %s: %s\n", lib_path, dlerror());
    return 1;
  }
  void *raw_sym = dlsym(handle, "GetPjrtApi");
#endif
  if (raw_sym == NULL) {
    return 1;
  }
  GetPjrtApiFn get_api = NULL;
  memcpy(&get_api, &raw_sym, sizeof(get_api));
  const PjrtApiMinHeader *api = get_api();
  if (api == NULL) {
    return 1;
  }

  uint64_t code_bytes = (uint64_t)ir_len;
  uint64_t temp_bytes = 0ULL;
  uint64_t t0 = monotonic_ns();
#if defined(_WIN32)
  FARPROC aot_raw = GetProcAddress(handle, "libtpu_rs_bench_aot_compile_file");
#else
  void *aot_raw = dlsym(handle, "libtpu_rs_bench_aot_compile_file");
#endif
  if (aot_raw != NULL) {
    LibtpuRsAotCompileFileFn aot_fn = NULL;
    memcpy(&aot_fn, &aot_raw, sizeof(aot_fn));
    if (aot_fn(ir_path, arch_gen, &code_bytes, &temp_bytes) != 0) {
      return 1;
    }
  }
  uint64_t t1 = monotonic_ns();
  uint64_t rss = peak_rss_bytes();

#if defined(_WIN32)
  FreeLibrary(handle);
#else
  dlclose(handle);
#endif

  printf("{\"arch_gen\":\"%s\",\"ir_bytes\":%ld,\"compile_ns\":%llu,\"generated_code_size_in_bytes\":%llu,\"temp_size_in_bytes\":%llu,\"rss_mib\":%.4f}\n",
         arch_gen,
         ir_len,
         (unsigned long long)(t1 >= t0 ? (t1 - t0) : 0ULL),
         (unsigned long long)code_bytes,
         (unsigned long long)temp_bytes,
         (double)rss / 1048576.0);
  return 0;
}
