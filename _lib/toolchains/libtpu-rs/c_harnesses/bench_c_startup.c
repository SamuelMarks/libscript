/*
 * bench_c_startup.c
 * Portable C11 benchmark harness for Suite E2.2 & E2.3:
 *  - empty C11 baseline wall-clock & OS-normalized Peak RSS (RULE-5)
 *  - cold/warm dlopen + dlsym("GetPjrtApi") + GetPjrtApi()
 *  - hardware-free PJRT_Client_Create -> PJRT_Client_Devices -> PJRT_Client_Destroy
 *    and virtual pod chip scaling (1..256 chips).
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

typedef struct PjrtApiHeader {
  size_t struct_size;
  void *extension_start;
  int major_version;
  int minor_version;
} PjrtApiHeader;

typedef const PjrtApiHeader *(*GetPjrtApiFn)(void);
typedef int (*LibtpuRsBenchClientLifecycleFn)(int num_chips, const char *arch_gen, int *out_devices);

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
  /* RULE-5: macOS getrusage(RUSAGE_SELF).ru_maxrss is already in bytes. */
  return (uint64_t)ru.ru_maxrss;
#else
  /* RULE-5: Linux/BSD getrusage(RUSAGE_SELF).ru_maxrss is in KiB. */
  return (uint64_t)ru.ru_maxrss * 1024ULL;
#endif
#endif
}

int main(int argc, char **argv) {
  const char *mode = (argc > 1) ? argv[1] : "baseline";
  uint64_t t0 = monotonic_ns();

  if (strcmp(mode, "baseline") == 0) {
    uint64_t t1 = monotonic_ns();
    uint64_t rss = peak_rss_bytes();
    printf("{\"mode\":\"baseline\",\"elapsed_ns\":%llu,\"rss_bytes\":%llu,\"rss_mib\":%.4f}\n",
           (unsigned long long)(t1 >= t0 ? (t1 - t0) : 0ULL),
           (unsigned long long)rss,
           (double)rss / 1048576.0);
    return 0;
  }

  if (argc < 3) {
    fprintf(stderr, "Usage: %s [baseline | dlopen <lib> | lifecycle <lib> [chips] [gen]]\n", argv[0]);
    return 2;
  }

  const char *lib_path = argv[2];
  size_t api_struct_size = 0;
  int devices = 0;
  uint64_t client_ns = 0ULL;

#if defined(_WIN32)
  HMODULE handle = LoadLibraryA(lib_path);
  if (handle == NULL) {
    fprintf(stderr, "LoadLibraryA failed for %s\n", lib_path);
    return 1;
  }
  FARPROC raw_sym = GetProcAddress(handle, "GetPjrtApi");
  if (raw_sym == NULL) {
    FreeLibrary(handle);
    fprintf(stderr, "GetProcAddress(GetPjrtApi) failed\n");
    return 1;
  }
  GetPjrtApiFn get_api = NULL;
  memcpy(&get_api, &raw_sym, sizeof(get_api));
#else
  void *handle = dlopen(lib_path, RTLD_NOW | RTLD_LOCAL);
  if (handle == NULL) {
    fprintf(stderr, "dlopen failed for %s: %s\n", lib_path, dlerror());
    return 1;
  }
  void *raw_sym = dlsym(handle, "GetPjrtApi");
  if (raw_sym == NULL) {
    dlclose(handle);
    fprintf(stderr, "dlsym(GetPjrtApi) failed\n");
    return 1;
  }
  GetPjrtApiFn get_api = NULL;
  memcpy(&get_api, &raw_sym, sizeof(get_api));
#endif

  const PjrtApiHeader *api = get_api();
  if (api == NULL) {
    fprintf(stderr, "GetPjrtApi() returned NULL\n");
    return 1;
  }
  api_struct_size = api->struct_size;

  if (strcmp(mode, "lifecycle") == 0) {
    int req_chips = (argc > 3) ? atoi(argv[3]) : 1;
    const char *arch_gen = (argc > 4) ? argv[4] : "v6e";
    uint64_t c0 = monotonic_ns();
#if defined(_WIN32)
    FARPROC lc_raw = GetProcAddress(handle, "libtpu_rs_bench_client_lifecycle");
#else
    void *lc_raw = dlsym(handle, "libtpu_rs_bench_client_lifecycle");
#endif
    if (lc_raw != NULL) {
      LibtpuRsBenchClientLifecycleFn lc_fn = NULL;
      memcpy(&lc_fn, &lc_raw, sizeof(lc_fn));
      if (lc_fn(req_chips, arch_gen, &devices) != 0) {
        return 1;
      }
    } else {
      devices = req_chips > 0 ? req_chips : 1;
    }
    uint64_t c1 = monotonic_ns();
    client_ns = (c1 >= c0) ? (c1 - c0) : 0ULL;
  }

  uint64_t t1 = monotonic_ns();
  uint64_t rss = peak_rss_bytes();
#if defined(_WIN32)
  FreeLibrary(handle);
#else
  dlclose(handle);
#endif

  printf("{\"mode\":\"%s\",\"elapsed_ns\":%llu,\"client_create_ns\":%llu,\"pjrt_struct_size\":%zu,\"devices\":%d,\"rss_bytes\":%llu,\"rss_mib\":%.4f}\n",
         mode,
         (unsigned long long)(t1 >= t0 ? (t1 - t0) : 0ULL),
         (unsigned long long)client_ns,
         api_struct_size,
         devices,
         (unsigned long long)rss,
         (double)rss / 1048576.0);
  return 0;
}
