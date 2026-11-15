/**
 * @file libscript_bench_probe.c
 * @brief Cross-platform zero-dependency C11/C89 subprocess timing, CPU, RSS, hardware counter, and timeout probe.
 *
 * Measures monotonic wall-clock nanoseconds (`QueryPerformanceCounter` on Win32,
 * `clock_gettime(CLOCK_MONOTONIC)` on POSIX), child user and system CPU nanoseconds
 * (`GetProcessTimes` / Job Object accounting on Win32, `wait4` / `getrusage` on POSIX),
 * OS-normalized peak resident memory in bytes and MiB (`PeakJobMemoryUsed` / `PeakWorkingSetSize`
 * on Windows, `ru_maxrss` bytes on Darwin, `ru_maxrss * 1024` on Linux/BSD, page scaling on
 * SunOS/illumos), hardware retired instructions and elapsed cycles (`proc_pid_rusage`
 * `RUSAGE_INFO_V4` on Darwin, `perf_event_open` on Linux, `QueryProcessCycleTime` on Win32),
 * optional `--stdout-file` / `--stderr-file` redirection, and `--timeout-ms` deadline enforcement.
 */

#if !defined(_WIN32)
#define _POSIX_C_SOURCE 200809L
#define _DARWIN_C_SOURCE 1
#define _BSD_SOURCE 1
#define _DEFAULT_SOURCE 1
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(_WIN32)
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <psapi.h>
#if defined(_MSC_VER)
#pragma comment(lib, "psapi.lib")
#endif
#else
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdint.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>
#if defined(__APPLE__)
#include <libproc.h>
#include <sys/proc_info.h>
#endif
#if defined(__linux__)
#include <linux/perf_event.h>
#include <sys/ioctl.h>
#include <sys/syscall.h>
#endif
#endif

#if defined(_WIN32)
typedef unsigned __int64 ls_u64;
#define LS_U64_FMT "%I64u"
#else
typedef unsigned long long ls_u64;
#define LS_U64_FMT "%llu"
#endif

/**
 * @brief Aggregated child subprocess telemetry record.
 */
typedef struct ls_child_metrics {
  ls_u64 elapsed_ns;
  ls_u64 user_cpu_ns;
  ls_u64 sys_cpu_ns;
  ls_u64 peak_bytes;
  ls_u64 hw_instructions;
  ls_u64 hw_cycles;
  const char *hw_counter_source;
  int timed_out;
  int exit_code;
} ls_child_metrics;

/**
 * @brief Returns a monotonic timestamp in integer nanoseconds.
 * @param out_ns Pointer receiving the monotonic timestamp in nanoseconds.
 * @return 0 on success, non-zero on OS clock failure.
 */
static int ls_monotonic_now_ns(ls_u64 *out_ns) {
#if defined(_WIN32)
  LARGE_INTEGER freq;
  LARGE_INTEGER counter;
  ls_u64 whole_sec;
  ls_u64 rem_ticks;
  if (!QueryPerformanceFrequency(&freq) || freq.QuadPart <= 0) {
    return 1;
  }
  if (!QueryPerformanceCounter(&counter)) {
    return 1;
  }
  whole_sec = (ls_u64)(counter.QuadPart / freq.QuadPart);
  rem_ticks = (ls_u64)(counter.QuadPart % freq.QuadPart);
  *out_ns = (whole_sec * 1000000000ULL) + ((rem_ticks * 1000000000ULL) / (ls_u64)freq.QuadPart);
  return 0;
#else
  struct timespec ts;
  if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) {
    return 1;
  }
  *out_ns = ((ls_u64)ts.tv_sec * 1000000000ULL) + (ls_u64)ts.tv_nsec;
  return 0;
#endif
}

#if defined(_WIN32)
/**
 * @brief Converts a Win32 FILETIME (100-ns intervals) into unsigned 64-bit nanoseconds.
 * @param ft Pointer to FILETIME structure.
 * @return Duration in nanoseconds.
 */
static ls_u64 ls_filetime_to_ns(const FILETIME *ft) {
  ULARGE_INTEGER uli;
  uli.LowPart = ft->dwLowDateTime;
  uli.HighPart = ft->dwHighDateTime;
  return ((ls_u64)uli.QuadPart) * 100ULL;
}

/**
 * @brief Appends a properly escaped Win32 command-line argument to a mutable buffer.
 * @param dst Destination character buffer.
 * @param cap Total buffer capacity in bytes.
 * @param arg Null-terminated argument string to quote/append.
 * @return 0 on success, non-zero on buffer overflow.
 */
static int ls_append_win_arg(char *dst, size_t cap, const char *arg) {
  size_t len = strlen(dst);
  const char *p;
  int need_quotes = 0;

  if (len > 0) {
    if (len + 1 >= cap) return 1;
    dst[len++] = ' ';
    dst[len] = '\0';
  }
  if (arg[0] == '\0') {
    need_quotes = 1;
  } else {
    for (p = arg; *p != '\0'; ++p) {
      if (*p == ' ' || *p == '\t' || *p == '"') {
        need_quotes = 1;
        break;
      }
    }
  }
  if (!need_quotes) {
    size_t alen = strlen(arg);
    if (len + alen >= cap) return 1;
    memcpy(dst + len, arg, alen + 1);
    return 0;
  }
  if (len + 1 >= cap) return 1;
  dst[len++] = '"';
  for (p = arg; *p != '\0'; ++p) {
    size_t backslashes = 0;
    while (*p == '\\') {
      ++backslashes;
      ++p;
    }
    if (*p == '\0') {
      size_t k;
      for (k = 0; k < backslashes * 2; ++k) {
        if (len + 1 >= cap) return 1;
        dst[len++] = '\\';
      }
      break;
    } else if (*p == '"') {
      size_t k;
      for (k = 0; k < backslashes * 2 + 1; ++k) {
        if (len + 1 >= cap) return 1;
        dst[len++] = '\\';
      }
      if (len + 1 >= cap) return 1;
      dst[len++] = '"';
    } else {
      size_t k;
      for (k = 0; k < backslashes; ++k) {
        if (len + 1 >= cap) return 1;
        dst[len++] = '\\';
      }
      if (len + 1 >= cap) return 1;
      dst[len++] = *p;
    }
  }
  if (len + 2 >= cap) return 1;
  dst[len++] = '"';
  dst[len] = '\0';
  return 0;
}
#endif

#if defined(__linux__)
/**
 * @brief Opens a Linux inherited user-space hardware perf counter fd for child measurement.
 * @param hw_config `PERF_COUNT_HW_*` counter selector.
 * @return File descriptor >= 0 on success, -1 if unsupported or restricted.
 */
static int ls_open_linux_hw_counter(ls_u64 hw_config) {
#if defined(__NR_perf_event_open)
  struct perf_event_attr pe;
  long fd;
  memset(&pe, 0, sizeof(pe));
  pe.type = PERF_TYPE_HARDWARE;
  pe.size = sizeof(struct perf_event_attr);
  pe.config = hw_config;
  pe.disabled = 1;
  pe.exclude_kernel = 1;
  pe.exclude_hv = 1;
  pe.inherit = 1;
  pe.enable_on_exec = 1;
  fd = syscall(__NR_perf_event_open, &pe, 0, -1, -1, 0);
  if (fd < 0) {
    return -1;
  }
  return (int)fd;
#else
  (void)hw_config;
  return -1;
#endif
}
#endif

/**
 * @brief Executes a child process while recording wall time, CPU time, peak RSS, HW counters, and timeout state.
 * @param argc Number of child command arguments.
 * @param argv Null-terminated child command argument array.
 * @param timeout_ms Maximum allowed wall-clock runtime in milliseconds (0 = unlimited).
 * @param stdout_path Optional path to redirect child stdout (NULL = inherit).
 * @param stderr_path Optional path to redirect child stderr (NULL = inherit).
 * @param out Pointer receiving aggregated telemetry.
 * @return 0 on successful measurement, non-zero if spawn failed.
 */
static int ls_measure_child(
    int argc,
    char **argv,
    ls_u64 timeout_ms,
    const char *stdout_path,
    const char *stderr_path,
    ls_child_metrics *out) {
  memset(out, 0, sizeof(*out));
  out->hw_counter_source = "unavailable";

#if defined(_WIN32)
  {
    char cmdline[32768];
    STARTUPINFOA si;
    PROCESS_INFORMATION pi;
    SECURITY_ATTRIBUTES sa;
    HANDLE job = NULL;
    HANDLE h_out = INVALID_HANDLE_VALUE;
    HANDLE h_err = INVALID_HANDLE_VALUE;
    JOBOBJECT_EXTENDED_LIMIT_INFORMATION jeli;
    JOBOBJECT_BASIC_ACCOUNTING_INFORMATION jbai;
    PROCESS_MEMORY_COUNTERS pmc;
    FILETIME ft_create, ft_exit, ft_kernel, ft_user;
    ULONG64 proc_cycles = 0;
    DWORD wait_limit = (timeout_ms > 0 && timeout_ms < 0xFFFFFFFFULL) ? (DWORD)timeout_ms : INFINITE;
    DWORD wait_rc;
    DWORD exit_code = 1;
    BOOL inherit_handles = FALSE;
    ls_u64 t0 = 0;
    ls_u64 t1 = 0;
    ls_u64 peak_b = 0;
    int i;

    cmdline[0] = '\0';
    for (i = 0; i < argc; ++i) {
      if (ls_append_win_arg(cmdline, sizeof(cmdline), argv[i]) != 0) {
        return 1;
      }
    }

    ZeroMemory(&sa, sizeof(sa));
    sa.nLength = sizeof(sa);
    sa.bInheritHandle = TRUE;

    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));

    if (stdout_path != NULL || stderr_path != NULL) {
      si.dwFlags |= STARTF_USESTDHANDLES;
      si.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
      si.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE);
      si.hStdError = GetStdHandle(STD_ERROR_HANDLE);
      inherit_handles = TRUE;
      if (stdout_path != NULL) {
        h_out = CreateFileA(
            stdout_path, GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, &sa, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
        if (h_out == INVALID_HANDLE_VALUE) {
          return 1;
        }
        si.hStdOutput = h_out;
      }
      if (stderr_path != NULL) {
        if (stdout_path != NULL && strcmp(stdout_path, stderr_path) == 0) {
          si.hStdError = h_out;
        } else {
          h_err = CreateFileA(
              stderr_path, GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, &sa, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
          if (h_err == INVALID_HANDLE_VALUE) {
            if (h_out != INVALID_HANDLE_VALUE) CloseHandle(h_out);
            return 1;
          }
          si.hStdError = h_err;
        }
      }
    }

    job = CreateJobObjectA(NULL, NULL);
    if (job != NULL) {
      ZeroMemory(&jeli, sizeof(jeli));
      jeli.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_SILENT_BREAKAWAY_OK;
      SetInformationJobObject(job, JobObjectExtendedLimitInformation, &jeli, sizeof(jeli));
    }

    if (ls_monotonic_now_ns(&t0) != 0) {
      if (h_out != INVALID_HANDLE_VALUE) CloseHandle(h_out);
      if (h_err != INVALID_HANDLE_VALUE) CloseHandle(h_err);
      if (job != NULL) CloseHandle(job);
      return 1;
    }

    if (!CreateProcessA(
            NULL,
            cmdline,
            NULL,
            NULL,
            inherit_handles,
            CREATE_SUSPENDED | CREATE_NO_WINDOW,
            NULL,
            NULL,
            &si,
            &pi)) {
      if (h_out != INVALID_HANDLE_VALUE) CloseHandle(h_out);
      if (h_err != INVALID_HANDLE_VALUE) CloseHandle(h_err);
      if (job != NULL) CloseHandle(job);
      return 1;
    }

    if (h_out != INVALID_HANDLE_VALUE) CloseHandle(h_out);
    if (h_err != INVALID_HANDLE_VALUE) CloseHandle(h_err);

    if (job != NULL) {
      AssignProcessToJobObject(job, pi.hProcess);
    }
    ResumeThread(pi.hThread);
    wait_rc = WaitForSingleObject(pi.hProcess, wait_limit);
    if (wait_rc == WAIT_TIMEOUT) {
      out->timed_out = 1;
      if (job != NULL) {
        TerminateJobObject(job, 124);
      } else {
        TerminateProcess(pi.hProcess, 124);
      }
      WaitForSingleObject(pi.hProcess, 2000);
    }
    ls_monotonic_now_ns(&t1);

    if (out->timed_out) {
      out->exit_code = 124;
    } else if (GetExitCodeProcess(pi.hProcess, &exit_code)) {
      out->exit_code = (int)exit_code;
    } else {
      out->exit_code = 1;
    }

    if (GetProcessTimes(pi.hProcess, &ft_create, &ft_exit, &ft_kernel, &ft_user)) {
      out->user_cpu_ns = ls_filetime_to_ns(&ft_user);
      out->sys_cpu_ns = ls_filetime_to_ns(&ft_kernel);
    }

    if (QueryProcessCycleTime(pi.hProcess, &proc_cycles) && proc_cycles > 0) {
      out->hw_cycles = (ls_u64)proc_cycles;
      out->hw_counter_source = "win32_cycle_time";
    }

    ZeroMemory(&pmc, sizeof(pmc));
    pmc.cb = sizeof(pmc);
    if (GetProcessMemoryInfo(pi.hProcess, &pmc, sizeof(pmc))) {
      peak_b = (ls_u64)pmc.PeakWorkingSetSize;
    }
    if (job != NULL) {
      ZeroMemory(&jeli, sizeof(jeli));
      if (QueryInformationJobObject(job, JobObjectExtendedLimitInformation, &jeli, sizeof(jeli), NULL)) {
        if ((ls_u64)jeli.PeakJobMemoryUsed > peak_b) {
          peak_b = (ls_u64)jeli.PeakJobMemoryUsed;
        }
        if ((ls_u64)jeli.PeakProcessMemoryUsed > peak_b) {
          peak_b = (ls_u64)jeli.PeakProcessMemoryUsed;
        }
      }
      ZeroMemory(&jbai, sizeof(jbai));
      if (QueryInformationJobObject(job, JobObjectBasicAccountingInformation, &jbai, sizeof(jbai), NULL)) {
        ls_u64 job_user_ns = ((ls_u64)jbai.TotalUserTime.QuadPart) * 100ULL;
        ls_u64 job_kern_ns = ((ls_u64)jbai.TotalKernelTime.QuadPart) * 100ULL;
        if (job_user_ns > out->user_cpu_ns) out->user_cpu_ns = job_user_ns;
        if (job_kern_ns > out->sys_cpu_ns) out->sys_cpu_ns = job_kern_ns;
      }
      CloseHandle(job);
    }

    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);

    out->elapsed_ns = (t1 > t0) ? (t1 - t0) : 1ULL;
    out->peak_bytes = peak_b;
    return 0;
  }
#else
  {
    pid_t pid;
    int status = 0;
    struct rusage ru;
    ls_u64 t0 = 0;
    ls_u64 t1 = 0;
    ls_u64 raw_rss = 0;
#if defined(__linux__)
    int fd_inst = ls_open_linux_hw_counter(PERF_COUNT_HW_INSTRUCTIONS);
    int fd_cyc = ls_open_linux_hw_counter(PERF_COUNT_HW_CPU_CYCLES);
#endif
    (void)argc;

    memset(&ru, 0, sizeof(ru));
    if (ls_monotonic_now_ns(&t0) != 0) {
#if defined(__linux__)
      if (fd_inst >= 0) close(fd_inst);
      if (fd_cyc >= 0) close(fd_cyc);
#endif
      return 1;
    }

    pid = fork();
    if (pid < 0) {
#if defined(__linux__)
      if (fd_inst >= 0) close(fd_inst);
      if (fd_cyc >= 0) close(fd_cyc);
#endif
      return 1;
    }
    if (pid == 0) {
      if (timeout_ms > 0) {
        setpgid(0, 0);
      }
      if (stdout_path != NULL) {
        int fd_o = open(stdout_path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (fd_o < 0) _exit(126);
        if (dup2(fd_o, STDOUT_FILENO) < 0) _exit(126);
        if (stderr_path != NULL && strcmp(stdout_path, stderr_path) == 0) {
          if (dup2(fd_o, STDERR_FILENO) < 0) _exit(126);
        }
        close(fd_o);
      }
      if (stderr_path != NULL && (stdout_path == NULL || strcmp(stdout_path, stderr_path) != 0)) {
        int fd_e = open(stderr_path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (fd_e < 0) _exit(126);
        if (dup2(fd_e, STDERR_FILENO) < 0) _exit(126);
        close(fd_e);
      }
      execvp(argv[0], argv);
      _exit(127);
    }

    if (timeout_ms > 0) {
      setpgid(pid, pid);
    }

    if (timeout_ms > 0) {
      ls_u64 limit_ns = timeout_ms * 1000000ULL;
      for (;;) {
        siginfo_t si;
        ls_u64 now_ns = 0;
        struct timespec sleep_ts;
        memset(&si, 0, sizeof(si));
        if (waitid(P_PID, (id_t)pid, &si, WEXITED | WNOHANG | WNOWAIT) == 0 && si.si_pid == pid) {
          break;
        }
        if (ls_monotonic_now_ns(&now_ns) == 0 && now_ns > t0 && (now_ns - t0) >= limit_ns) {
          out->timed_out = 1;
          kill(-pid, SIGTERM);
          kill(pid, SIGTERM);
          sleep_ts.tv_sec = 0;
          sleep_ts.tv_nsec = 25000000L;
          nanosleep(&sleep_ts, NULL);
          kill(-pid, SIGKILL);
          kill(pid, SIGKILL);
          break;
        }
        sleep_ts.tv_sec = 0;
        sleep_ts.tv_nsec = 2000000L;
        nanosleep(&sleep_ts, NULL);
      }
    } else {
      siginfo_t si;
      for (;;) {
        memset(&si, 0, sizeof(si));
        if (waitid(P_PID, (id_t)pid, &si, WEXITED | WNOWAIT) == 0) {
          break;
        }
        if (errno != EINTR) {
          break;
        }
      }
    }

#if defined(__APPLE__) && defined(RUSAGE_INFO_V4)
    {
      struct rusage_info_v4 ri;
      memset(&ri, 0, sizeof(ri));
      if (proc_pid_rusage(pid, RUSAGE_INFO_V4, (rusage_info_t *)&ri) == 0) {
        out->hw_instructions = (ls_u64)ri.ri_instructions;
        out->hw_cycles = (ls_u64)ri.ri_cycles;
        if (out->hw_instructions > 0 || out->hw_cycles > 0) {
          out->hw_counter_source = "darwin_rusage_v4";
        }
      }
    }
#endif

#if defined(__APPLE__) || defined(__linux__) || defined(__FreeBSD__) || defined(__OpenBSD__) || defined(__NetBSD__)
    while (wait4(pid, &status, 0, &ru) < 0) {
      if (errno != EINTR) {
        return 1;
      }
    }
#else
    while (waitpid(pid, &status, 0) < 0) {
      if (errno != EINTR) {
        return 1;
      }
    }
    getrusage(RUSAGE_CHILDREN, &ru);
#endif
    ls_monotonic_now_ns(&t1);

#if defined(__linux__)
    if (fd_inst >= 0) {
      uint64_t val = 0;
      if (read(fd_inst, &val, sizeof(val)) == (ssize_t)sizeof(val)) {
        out->hw_instructions = (ls_u64)val;
        out->hw_counter_source = "linux_perf_event";
      }
      close(fd_inst);
    }
    if (fd_cyc >= 0) {
      uint64_t val = 0;
      if (read(fd_cyc, &val, sizeof(val)) == (ssize_t)sizeof(val)) {
        out->hw_cycles = (ls_u64)val;
        out->hw_counter_source = "linux_perf_event";
      }
      close(fd_cyc);
    }
#endif

    if (ru.ru_maxrss > 0) {
      raw_rss = (ls_u64)ru.ru_maxrss;
    }
    out->user_cpu_ns =
        ((ls_u64)ru.ru_utime.tv_sec * 1000000000ULL) + ((ls_u64)ru.ru_utime.tv_usec * 1000ULL);
    out->sys_cpu_ns =
        ((ls_u64)ru.ru_stime.tv_sec * 1000000000ULL) + ((ls_u64)ru.ru_stime.tv_usec * 1000ULL);

#if defined(__APPLE__)
    out->peak_bytes = raw_rss;
#elif defined(__sun)
    {
      long pg = sysconf(_SC_PAGESIZE);
      if (pg <= 0) pg = 4096;
      out->peak_bytes = raw_rss * (ls_u64)pg;
    }
#else
    out->peak_bytes = raw_rss * 1024ULL;
#endif

    out->elapsed_ns = (t1 > t0) ? (t1 - t0) : 1ULL;
    if (out->timed_out) {
      out->exit_code = 124;
    } else if (WIFEXITED(status)) {
      out->exit_code = WEXITSTATUS(status);
    } else if (WIFSIGNALED(status)) {
      out->exit_code = 128 + WTERMSIG(status);
    } else {
      out->exit_code = 1;
    }
    return 0;
  }
#endif
}

/**
 * @brief CLI entry point for `libscript_bench_probe`.
 * @param argc Argument count.
 * @param argv Argument vector (`--now-ns`, `--div-mib <bytes>`, or
 *             `[--json-out <path>] [--timeout-ms <ms>] [--stdout-file <path>] [--stderr-file <path>] --exec <cmd...>`).
 * @return Process exit status.
 */
int main(int argc, char **argv) {
  const char *json_out = NULL;
  const char *stdout_path = NULL;
  const char *stderr_path = NULL;
  ls_u64 timeout_ms = 0;
  int i = 1;

  if (argc < 2) {
    fprintf(
        stderr,
        "Usage: %s [--now-ns | --div-mib <bytes> | [--json-out <file>] [--timeout-ms <ms>] "
        "[--stdout-file <file>] [--stderr-file <file>] --exec <cmd...>]\n",
        argv[0]);
    return 2;
  }

  if (strcmp(argv[1], "--now-ns") == 0) {
    ls_u64 ns = 0;
    if (ls_monotonic_now_ns(&ns) != 0) {
      return 1;
    }
    printf(LS_U64_FMT "\n", ns);
    return 0;
  }

  if (strcmp(argv[1], "--div-mib") == 0 && argc >= 3) {
    double val = strtod(argv[2], NULL);
    printf("%.4f\n", val / 1048576.0);
    return 0;
  }

  while (i < argc) {
    if (strcmp(argv[i], "--json-out") == 0 && i + 1 < argc) {
      json_out = argv[i + 1];
      i += 2;
    } else if (strcmp(argv[i], "--timeout-ms") == 0 && i + 1 < argc) {
      timeout_ms = (ls_u64)strtoull(argv[i + 1], NULL, 10);
      i += 2;
    } else if (strcmp(argv[i], "--stdout-file") == 0 && i + 1 < argc) {
      stdout_path = argv[i + 1];
      i += 2;
    } else if (strcmp(argv[i], "--stderr-file") == 0 && i + 1 < argc) {
      stderr_path = argv[i + 1];
      i += 2;
    } else if (strcmp(argv[i], "--exec") == 0 && i + 1 < argc) {
      ls_child_metrics m;
      double mib;

      if (ls_measure_child(argc - (i + 1), &argv[i + 1], timeout_ms, stdout_path, stderr_path, &m) != 0) {
        return 127;
      }
      mib = (double)m.peak_bytes / 1048576.0;
      if (json_out != NULL) {
        FILE *fp = fopen(json_out, "wb");
        if (fp == NULL) {
          return 1;
        }
        fprintf(
            fp,
            "{\n"
            "  \"elapsed_ns\": " LS_U64_FMT ",\n"
            "  \"elapsed_ms\": %.6f,\n"
            "  \"elapsed_s\": %.6f,\n"
            "  \"user_cpu_ns\": " LS_U64_FMT ",\n"
            "  \"sys_cpu_ns\": " LS_U64_FMT ",\n"
            "  \"user_cpu_s\": %.6f,\n"
            "  \"sys_cpu_s\": %.6f,\n"
            "  \"peak_rss_bytes\": " LS_U64_FMT ",\n"
            "  \"peak_rss_mib\": %.4f,\n"
            "  \"peak_rss_mb\": %.4f,\n"
            "  \"hw_instructions\": " LS_U64_FMT ",\n"
            "  \"hw_cycles\": " LS_U64_FMT ",\n"
            "  \"hw_counter_source\": \"%s\",\n"
            "  \"timed_out\": %s,\n"
            "  \"exit_code\": %d\n"
            "}\n",
            m.elapsed_ns,
            (double)m.elapsed_ns / 1000000.0,
            (double)m.elapsed_ns / 1000000000.0,
            m.user_cpu_ns,
            m.sys_cpu_ns,
            (double)m.user_cpu_ns / 1000000000.0,
            (double)m.sys_cpu_ns / 1000000000.0,
            m.peak_bytes,
            mib,
            mib,
            m.hw_instructions,
            m.hw_cycles,
            m.hw_counter_source,
            m.timed_out ? "true" : "false",
            m.exit_code);
        fclose(fp);
      } else {
        printf(LS_U64_FMT " " LS_U64_FMT " %d\n", m.elapsed_ns, m.peak_bytes, m.exit_code);
      }
      return m.exit_code;
    } else {
      ++i;
    }
  }

  return 2;
}
