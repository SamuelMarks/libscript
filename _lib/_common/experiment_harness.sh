#!/bin/sh
# ## Overview
# Zero-dependency SIGPLAN empirical evaluation substrate (`experiment_harness.sh`). Implements provenance envelopes (`RULE-1`), native ISA guards (`RULE-2`), cold/warm subprocess trial separation (`RULE-3`), non-parametric `samples_ns` quantile/IQR/P99 statistics (`RULE-4`), OS-normalized `ru_maxrss` accounting (`RULE-5`), pinned release Cargo/C11 profiles (`RULE-6`), and codebase prerequisite gating (`RULE-7`).
# ## Usage
# Source via `SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/experiment_harness.sh"; export SCRIPT_NAME; . "${SCRIPT_NAME}"` and call `libscript_exp_*` functions.
set -feu
_eh_caller_this="${THIS_FILE:-}"
_eh_caller_dir="${SCRIPT_DIR:-}"
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi
case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    [ -n "${_eh_caller_this:-}" ] && THIS_FILE="$_eh_caller_this"
    [ -n "${_eh_caller_dir:-}" ] && SCRIPT_DIR="$_eh_caller_dir"
    unset SCRIPT_NAME || true
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

_eh_saved_this="${THIS_FILE}"
_eh_saved_dir="${SCRIPT_DIR}"
for _eh_lib in '_lib/_common/os_info.sh' '_lib/_common/log.sh' '_lib/_common/hw_tune.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_eh_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _eh_lib || true
THIS_FILE="${_eh_saved_this}"
SCRIPT_DIR="${_eh_saved_dir}"
unset _eh_saved_this _eh_saved_dir || true

# ## libscript_ensure_clock_ns_helper
# Compiles an idempotent C11 monotonic nanosecond clock helper (`clock_gettime(CLOCK_MONOTONIC)`) when a C compiler is available on PATH.
libscript_ensure_clock_ns_helper() {
  if [ -n "${LIBSCRIPT_BENCH_CLOCK_NS_BIN:-}" ] && [ -x "${LIBSCRIPT_BENCH_CLOCK_NS_BIN}" ]; then
    return 0
  fi
  _clk_dir="${LIBSCRIPT_ROOT_DIR}/build/bench_tools"
  _clk_bin="${_clk_dir}/libscript_clock_ns"
  if [ -x "${_clk_bin}" ]; then
    export LIBSCRIPT_BENCH_CLOCK_NS_BIN="${_clk_bin}"
    return 0
  fi
  _clk_cc=''
  for _cand_cc in clang cc gcc; do
    if command -v "${_cand_cc}" >/dev/null 2>&1; then
      _clk_cc="${_cand_cc}"
      break
    fi
  done
  [ -n "${_clk_cc}" ] || return 1
  mkdir -p "${_clk_dir}"
  _clk_src="${_clk_dir}/libscript_clock_ns.c"
  cat <<'EOF' > "${_clk_src}.tmp"
#define _POSIX_C_SOURCE 200809L
#include <stdint.h>
#include <stdio.h>
#include <time.h>
int main(void) {
  struct timespec ts;
  if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) {
    return 1;
  }
  uint64_t ns = ((uint64_t)ts.tv_sec * 1000000000ULL) + (uint64_t)ts.tv_nsec;
  printf("%llu\n", (unsigned long long)ns);
  return 0;
}
EOF
  mv -f "${_clk_src}.tmp" "${_clk_src}"
  if "${_clk_cc}" -O2 -std=c11 "${_clk_src}" -o "${_clk_bin}.tmp" >/dev/null 2>&1; then
    mv -f "${_clk_bin}.tmp" "${_clk_bin}"
    chmod +x "${_clk_bin}"
    export LIBSCRIPT_BENCH_CLOCK_NS_BIN="${_clk_bin}"
    return 0
  fi
  rm -f "${_clk_bin}.tmp"
  return 1
}

# ## libscript_now_ns
# Returns a monotonically non-decreasing timestamp in integer nanoseconds (`RULE-4`).
libscript_now_ns() {
  if libscript_ensure_clock_ns_helper; then
    if "${LIBSCRIPT_BENCH_CLOCK_NS_BIN}"; then
      return 0
    fi
  fi
  if [ -r /proc/uptime ]; then
    if awk '{printf "%.0f\n", $1 * 1000000000}' /proc/uptime 2>/dev/null; then
      return 0
    fi
  fi
  printf '%s000000000\n' "$(date +%s 2>/dev/null || printf '0')"
}

# ## libscript_exp_sha256_file
# Computes a lowercase 64-character hexadecimal SHA-256 digest for a file using available POSIX utilities.
libscript_exp_sha256_file() {
  _esf_target="${1}"
  if [ ! -f "${_esf_target}" ]; then
    printf '%s\n' 'missing'
    return 1
  fi
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${_esf_target}" | awk '{print $1}'
    return 0
  fi
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "${_esf_target}" | awk '{print $1}'
    return 0
  fi
  if command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "${_esf_target}" | awk '{print $NF}'
    return 0
  fi
  cksum "${_esf_target}" | awk '{print $1}'
}

# ## libscript_exp_capture_provenance
# Records target repository git commit SHA, dirty worktree state, LibScript commit SHA, UTC timestamp, host manifest digest, and CLI flags into an atomic JSON file (`RULE-1`).
libscript_exp_capture_provenance() {
  _ecp_repo="${1:-${LIBSCRIPT_ROOT_DIR}}"
  _ecp_out="${2}"
  _ecp_args="${3:-}"
  _ecp_hw_ref="${4:-}"

  mkdir -p "$(dirname -- "${_ecp_out}")"
  _ecp_sha='0000000000000000000000000000000000000000'
  _ecp_dirty='false'
  if [ -d "${_ecp_repo}" ] && command -v git >/dev/null 2>&1; then
    if git -C "${_ecp_repo}" rev-parse --verify HEAD >/dev/null 2>&1; then
      _ecp_sha=$(git -C "${_ecp_repo}" rev-parse HEAD 2>/dev/null || printf '0000000000000000000000000000000000000000')
      _ecp_status=$(git -C "${_ecp_repo}" status --porcelain 2>/dev/null || true)
      if [ -n "${_ecp_status}" ]; then
        _ecp_dirty='true'
      fi
    fi
  fi

  _ecp_ls_sha='0000000000000000000000000000000000000000'
  if command -v git >/dev/null 2>&1 && git -C "${LIBSCRIPT_ROOT_DIR}" rev-parse --verify HEAD >/dev/null 2>&1; then
    _ecp_ls_sha=$(git -C "${LIBSCRIPT_ROOT_DIR}" rev-parse HEAD 2>/dev/null || printf '0000000000000000000000000000000000000000')
  fi

  _ecp_hw_sha='unrecorded'
  if [ -n "${_ecp_hw_ref}" ] && [ -f "${_ecp_hw_ref}" ]; then
    _ecp_hw_sha=$(libscript_exp_sha256_file "${_ecp_hw_ref}" || printf 'unrecorded')
  fi

  _ecp_ts=$(date -u +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || printf '1970-01-01T00:00:00Z')
  _ecp_esc_args=$(printf '%s' "${_ecp_args}" | sed 's/\\/\\\\/g; s/"/\\"/g')
  _ecp_esc_hw=$(printf '%s' "${_ecp_hw_ref}" | sed 's/\\/\\\\/g; s/"/\\"/g')

  cat <<EOF > "${_ecp_out}.tmp"
{
  "schema_version": "1.0.0",
  "git_commit_sha": "${_ecp_sha}",
  "git_dirty": ${_ecp_dirty},
  "libscript_commit_sha": "${_ecp_ls_sha}",
  "timestamp_utc": "${_ecp_ts}",
  "host_manifest_ref": "${_ecp_esc_hw}",
  "host_manifest_sha256": "${_ecp_hw_sha}",
  "cli_invocation": "${_ecp_esc_args}"
}
EOF
  mv -f "${_ecp_out}.tmp" "${_ecp_out}"
}

# ## libscript_exp_verify_json_provenance
# Validates that a benchmark result JSON contains a valid 40-hex commit SHA, schema_version, host_manifest_ref, and clean worktree status (`RULE-1`).
libscript_exp_verify_json_provenance() {
  _evp_json="${1}"
  _evp_allow_dirty="${2:-0}"

  if [ ! -s "${_evp_json}" ]; then
    log_error "[RULE-1] Provenance verification failed: missing or empty JSON '${_evp_json}'."
    return 1
  fi
  if ! grep -Eq '"schema_version"[[:space:]]*:[[:space:]]*"[^"]+"' "${_evp_json}"; then
    log_error "[RULE-1] Missing schema_version in '${_evp_json}'."
    return 1
  fi
  if ! grep -Eq '"git_commit_sha"[[:space:]]*:[[:space:]]*"[0-9a-f]{40}"' "${_evp_json}"; then
    log_error "[RULE-1] Missing or invalid 40-hex git_commit_sha in '${_evp_json}'."
    return 1
  fi
  if grep -Eq '"git_commit_sha"[[:space:]]*:[[:space:]]*"0{40}"' "${_evp_json}"; then
    log_error "[RULE-1] Placeholder zero git_commit_sha rejected in '${_evp_json}'."
    return 1
  fi
  if ! grep -Eq '"host_manifest_ref"[[:space:]]*:[[:space:]]*"[^"]+"' "${_evp_json}"; then
    log_error "[RULE-1] Missing non-empty host_manifest_ref in '${_evp_json}'."
    return 1
  fi
  if [ "${_evp_allow_dirty}" != "1" ]; then
    if grep -Eq '"git_dirty"[[:space:]]*:[[:space:]]*true' "${_evp_json}"; then
      log_error "[RULE-1] Dirty git worktree rejected for locked result '${_evp_json}'."
      return 1
    fi
  fi
  return 0
}

# ## libscript_exp_assert_native_isa
# Enforces native hardware ISA execution and rejects Rosetta 2, QEMU user/TCG, or binfmt_misc binary translation (`RULE-2`).
libscript_exp_assert_native_isa() {
  _eani_expected="${1:-}"

  if [ "${LIBSCRIPT_BENCH_FAKE_TRANSLATED_ISA:-0}" = "1" ]; then
    log_error '[RULE-2] Simulated binary translation detected (LIBSCRIPT_BENCH_FAKE_TRANSLATED_ISA=1); native ISA required.'
    return 1
  fi

  if [ "${UNAME:-}" = "Darwin" ]; then
    if command -v sysctl >/dev/null 2>&1; then
      _rosetta=$(sysctl -n sysctl.proc_translated 2>/dev/null || printf '0')
      if [ "${_rosetta}" = "1" ]; then
        log_error '[RULE-2] Rosetta 2 binary translation active (sysctl.proc_translated=1); head-to-head timing requires native execution.'
        return 1
      fi
    fi
  elif [ "${UNAME:-}" = "Linux" ]; then
    if [ -r /proc/self/maps ]; then
      if grep -Eiq 'qemu-(x86_64|aarch64)|rosetta' /proc/self/maps 2>/dev/null; then
        log_error '[RULE-2] User-mode QEMU/Rosetta binary translation detected in /proc/self/maps; native Linux hardware required.'
        return 1
      fi
    fi
    if [ -r /proc/cpuinfo ]; then
      if grep -Eiq 'QEMU Virtual CPU|TCG' /proc/cpuinfo 2>/dev/null; then
        log_error '[RULE-2] QEMU TCG software CPU emulation detected in /proc/cpuinfo; bare-metal or dedicated native CPU required.'
        return 1
      fi
    fi
  fi

  if [ -n "${_eani_expected}" ]; then
    _norm_arch="${ARCH:-unknown}"
    case "${_norm_arch}" in
      amd64) _norm_arch='x86_64' ;;
      aarch64) _norm_arch='arm64' ;;
    esac
    _norm_exp="${_eani_expected}"
    case "${_norm_exp}" in
      amd64|linux_x64|x64) _norm_exp='x86_64' ;;
      aarch64|macos_arm64|linux_arm64) _norm_exp='arm64' ;;
    esac
    if [ "${_norm_arch}" != "${_norm_exp}" ]; then
      log_error "[RULE-2] Host architecture '${ARCH:-unknown}' does not match required native ISA '${_eani_expected}'."
      return 1
    fi
  fi
  return 0
}

# ## libscript_exp_run_cold
# Executes a single cold subprocess measurement after dropping OS page caches or materializing an uncached cold binary copy (`RULE-3`).
libscript_exp_run_cold() {
  _erc_out_json="${1}"
  _erc_bin="${2}"
  shift 2

  mkdir -p "$(dirname -- "${_erc_out_json}")"
  _erc_mode='cold_copy_fallback'
  _erc_exec="${_erc_bin}"
  _erc_tmp_bin=''

  if [ "${LIBSCRIPT_BENCH_DROP_CACHES:-0}" = "1" ] && { [ -w /proc/sys/vm/drop_caches ] || [ "$(id -u 2>/dev/null || printf '1')" = "0" ]; }; then
    libscript_drop_benchmark_caches
    _erc_mode='drop_caches'
  elif [ -f "${_erc_bin}" ]; then
    _erc_tmp_bin="${TMPDIR:-/tmp}/libscript_cold_$$_$(basename -- "${_erc_bin}")"
    cp -f "${_erc_bin}" "${_erc_tmp_bin}"
    chmod +x "${_erc_tmp_bin}"
    _erc_exec="${_erc_tmp_bin}"
  fi

  _erc_t0=$(libscript_now_ns)
  _erc_rc=0
  "${_erc_exec}" "$@" >/dev/null 2>&1 || _erc_rc=$?
  _erc_t1=$(libscript_now_ns)
  if [ -n "${_erc_tmp_bin}" ]; then
    rm -f "${_erc_tmp_bin}"
  fi

  if [ "${_erc_rc}" -ne 0 ]; then
    log_error "[RULE-3] Cold subprocess '${_erc_bin}' exited with non-zero status ${_erc_rc}."
    return "${_erc_rc}"
  fi

  _erc_dt=$(awk -v a="${_erc_t0}" -v b="${_erc_t1}" 'BEGIN { d = b - a; if (d < 1) d = 1; printf "%.0f", d }')
  _erc_ms=$(awk -v d="${_erc_dt}" 'BEGIN { printf "%.6f", d / 1000000.0 }')
  cat <<EOF > "${_erc_out_json}.tmp"
{
  "cold_cache_mode": "${_erc_mode}",
  "cold_latency_ns": ${_erc_dt},
  "cold_latency_ms": ${_erc_ms}
}
EOF
  mv -f "${_erc_out_json}.tmp" "${_erc_out_json}"
}

# ## libscript_exp_run_warm_loop
# Executes W unrecorded warmup subprocesses followed by N recorded fresh subprocesses, writing raw nanosecond durations to samples_out_file (`RULE-3`, `RULE-4`).
libscript_exp_run_warm_loop() {
  _erw_warmup="${1}"
  _erw_trials="${2}"
  _erw_samples_out="${3}"
  shift 3

  case "${_erw_warmup}" in ''|*[!0-9]*) _erw_warmup=10 ;; esac
  case "${_erw_trials}" in ''|*[!0-9]*) _erw_trials=200 ;; esac
  if [ "${_erw_trials}" -lt 1 ]; then
    _erw_trials=1
  fi

  mkdir -p "$(dirname -- "${_erw_samples_out}")"

  _w_idx=1
  while [ "${_w_idx}" -le "${_erw_warmup}" ]; do
    "$@" >/dev/null 2>&1
    _w_idx=$((_w_idx + 1))
  done

  : > "${_erw_samples_out}.tmp"
  _n_idx=1
  while [ "${_n_idx}" -le "${_erw_trials}" ]; do
    _w_t0=$(libscript_now_ns)
    "$@" >/dev/null 2>&1
    _w_t1=$(libscript_now_ns)
    awk -v a="${_w_t0}" -v b="${_w_t1}" 'BEGIN { d = b - a; if (d < 1) d = 1; printf "%.0f\n", d }' >> "${_erw_samples_out}.tmp"
    _n_idx=$((_n_idx + 1))
  done

  mv -f "${_erw_samples_out}.tmp" "${_erw_samples_out}"
}

# ## libscript_exp_compute_stats
# Computes exact sorted non-parametric summary statistics (`min`, `P25`, `P50 median`, `P75`, `IQR`, `P99`, `max`, plus full `samples_ns`) from a newline-delimited nanosecond sample file (`RULE-4`).
libscript_exp_compute_stats() {
  _ecs_samples="${1}"
  _ecs_out_json="${2}"

  if [ ! -s "${_ecs_samples}" ]; then
    log_error "[RULE-4] Cannot compute statistics on missing or empty sample file '${_ecs_samples}'."
    return 1
  fi

  mkdir -p "$(dirname -- "${_ecs_out_json}")"
  _ecs_sorted="${_ecs_out_json}.sorted.tmp"
  LC_ALL=C sort -n "${_ecs_samples}" > "${_ecs_sorted}"

  awk '
    function q_idx(n, p,    pos) {
      pos = int((n - 1) * p + 0.5) + 1
      if (pos < 1) pos = 1
      if (pos > n) pos = n
      return pos
    }
    /^[0-9]+(\.[0-9]+)?$/ {
      n++
      vals[n] = $1 + 0
    }
    END {
      if (n < 1) exit 1
      min_v = vals[1]
      max_v = vals[n]
      p25_v = vals[q_idx(n, 0.25)]
      if (n % 2 == 1) {
        p50_v = vals[(n + 1) / 2]
      } else {
        p50_v = (vals[n / 2] + vals[(n / 2) + 1]) / 2.0
      }
      p75_v = vals[q_idx(n, 0.75)]
      iqr_v = p75_v - p25_v
      p99_i = int((n * 99 + 99) / 100)
      if (p99_i < 1) p99_i = 1
      if (p99_i > n) p99_i = n
      p99_v = vals[p99_i]

      printf "{\n"
      printf "  \"count\": %d,\n", n
      printf "  \"min_ns\": %.0f,\n", min_v
      printf "  \"p25_ns\": %.0f,\n", p25_v
      printf "  \"median_p50_ns\": %.0f,\n", p50_v
      printf "  \"p75_ns\": %.0f,\n", p75_v
      printf "  \"iqr_ns\": %.0f,\n", iqr_v
      printf "  \"p99_ns\": %.0f,\n", p99_v
      printf "  \"max_ns\": %.0f,\n", max_v
      printf "  \"median_ms\": %.6f,\n", p50_v / 1000000.0
      printf "  \"iqr_ms\": %.6f,\n", iqr_v / 1000000.0
      printf "  \"p99_ms\": %.6f,\n", p99_v / 1000000.0
      printf "  \"median_us\": %.3f,\n", p50_v / 1000.0
      printf "  \"iqr_us\": %.3f,\n", iqr_v / 1000.0
      printf "  \"p99_us\": %.3f,\n", p99_v / 1000.0
      printf "  \"samples_ns\": ["
      for (i = 1; i <= n; i++) {
        printf "%s%.0f", (i > 1 ? ", " : ""), vals[i]
      }
      printf "]\n}\n"
    }
  ' "${_ecs_sorted}" > "${_ecs_out_json}.tmp"

  rm -f "${_ecs_sorted}"
  mv -f "${_ecs_out_json}.tmp" "${_ecs_out_json}"
}

# ## libscript_exp_format_pgfplots_coords
# Formats a PGFPlots `point meta=rawy` coordinate with asymmetric IQR `(median - P25, P75 - median)` and P99 `(0, P99 - median)` error-bar deltas in milliseconds (`RULE-4`).
libscript_exp_format_pgfplots_coords() {
  _efp_label="${1}"
  _efp_stats_json="${2}"

  awk -v lbl="${_efp_label}" '
    /"p25_ns"/ { gsub(/[^0-9.]/, "", $2); p25 = $2 + 0 }
    /"median_p50_ns"/ { gsub(/[^0-9.]/, "", $2); p50 = $2 + 0 }
    /"p75_ns"/ { gsub(/[^0-9.]/, "", $2); p75 = $2 + 0 }
    /"p99_ns"/ { gsub(/[^0-9.]/, "", $2); p99 = $2 + 0 }
    END {
      med_ms = p50 / 1000000.0
      iqr_lo = (p50 - p25) / 1000000.0
      iqr_hi = (p75 - p50) / 1000000.0
      p99_hi = (p99 - p50) / 1000000.0
      printf "(%s, %.4f) -= (0, %.4f) += (0, %.4f) %% P99_plus=%.4f\n", lbl, med_ms, iqr_lo, iqr_hi, p99_hi
    }
  ' "${_efp_stats_json}"
}

# ## libscript_exp_normalize_rss_bytes
# Normalizes OS-specific `ru_maxrss` values (`bytes` on Darwin/Windows_NT vs. `KiB * 1024` on Linux/BSD) into exact integer bytes (`RULE-5`).
libscript_exp_normalize_rss_bytes() {
  _enr_raw="${1}"
  _enr_os="${2:-${UNAME:-Linux}}"

  case "${_enr_os}" in
    Darwin|darwin|Windows_NT|windows)
      awk -v r="${_enr_raw}" 'BEGIN { printf "%.0f\n", r + 0 }'
      ;;
    *)
      awk -v r="${_enr_raw}" 'BEGIN { printf "%.0f\n", (r + 0) * 1024.0 }'
      ;;
  esac
}

# ## libscript_exp_emit_rss_json
# Emits normalized baseline and peak RSS accounting in bytes and binary MiB ($2^{20}$ bytes) to a JSON file (`RULE-5`).
libscript_exp_emit_rss_json() {
  _eer_peak_raw="${1}"
  _eer_base_raw="${2:-0}"
  _eer_out_json="${3}"
  _eer_os="${4:-${UNAME:-Linux}}"

  mkdir -p "$(dirname -- "${_eer_out_json}")"
  _peak_b=$(libscript_exp_normalize_rss_bytes "${_eer_peak_raw}" "${_eer_os}")
  _base_b=$(libscript_exp_normalize_rss_bytes "${_eer_base_raw}" "${_eer_os}")

  awk -v pb="${_peak_b}" -v bb="${_base_b}" -v os="${_eer_os}" 'BEGIN {
    delta_b = pb - bb
    if (delta_b < 0) delta_b = 0
    printf "{\n"
    printf "  \"rss_os_normalization\": \"%s\",\n", os
    printf "  \"baseline_rss_bytes\": %.0f,\n", bb
    printf "  \"peak_rss_bytes\": %.0f,\n", pb
    printf "  \"net_rss_delta_bytes\": %.0f,\n", delta_b
    printf "  \"baseline_rss_mib\": %.4f,\n", bb / 1048576.0
    printf "  \"peak_rss_mib\": %.4f,\n", pb / 1048576.0
    printf "  \"net_rss_delta_mib\": %.4f\n", delta_b / 1048576.0
    printf "}\n"
  }' > "${_eer_out_json}.tmp"
  mv -f "${_eer_out_json}.tmp" "${_eer_out_json}"
}

# ## libscript_exp_pin_cargo_release
# Exports and records deterministic Cargo release profile flags (`opt-level=3`, `lto`, `codegen-units`, unstripped pre-measurement output) (`RULE-6`).
libscript_exp_pin_cargo_release() {
  _epc_spec="${1:-${LIBSCRIPT_BENCH_CARGO_PROFILE:-opt3-lto-thin-cgu1}}"
  _epc_out_json="${2:-}"

  _opt='3'
  _lto='thin'
  _cgu='1'
  case "${_epc_spec}" in
    opt3-lto-fat-cgu1) _lto='fat' ;;
    opt3-lto-off-cgu16) _lto='off'; _cgu='16' ;;
  esac

  export CARGO_PROFILE_RELEASE_OPT_LEVEL="${_opt}"
  export CARGO_PROFILE_RELEASE_LTO="${_lto}"
  export CARGO_PROFILE_RELEASE_CODEGEN_UNITS="${_cgu}"
  export CARGO_PROFILE_RELEASE_DEBUG='false'
  export CARGO_PROFILE_RELEASE_STRIP='none'

  if [ -n "${_epc_out_json}" ]; then
    mkdir -p "$(dirname -- "${_epc_out_json}")"
    _strip_tool='strip -x'
    if [ "${UNAME:-}" != "Darwin" ]; then
      _strip_tool='llvm-strip --strip-unneeded'
    fi
    cat <<EOF > "${_epc_out_json}.tmp"
{
  "profile_id": "${_epc_spec}",
  "opt_level": ${_opt},
  "lto": "${_lto}",
  "codegen_units": ${_cgu},
  "debug": false,
  "post_link_strip": "${_strip_tool}"
}
EOF
    mv -f "${_epc_out_json}.tmp" "${_epc_out_json}"
  fi
}

# ## libscript_exp_strip_shared_lib
# Strips a copy of a compiled shared library deterministically (`strip -x` on Darwin Mach-O, `llvm-strip --strip-unneeded` or `strip --strip-unneeded` on ELF/PE) while preserving the unstripped input (`RULE-6`).
libscript_exp_strip_shared_lib() {
  _ess_in="${1}"
  _ess_out="${2}"

  if [ ! -f "${_ess_in}" ]; then
    log_error "[RULE-6] Cannot strip missing shared library '${_ess_in}'."
    return 1
  fi
  mkdir -p "$(dirname -- "${_ess_out}")"
  cp -f "${_ess_in}" "${_ess_out}.tmp"

  if [ "${UNAME:-}" = "Darwin" ]; then
    strip -x "${_ess_out}.tmp" 2>/dev/null || strip -S "${_ess_out}.tmp" 2>/dev/null || true
  elif command -v llvm-strip >/dev/null 2>&1; then
    llvm-strip --strip-unneeded "${_ess_out}.tmp" 2>/dev/null || true
  elif command -v strip >/dev/null 2>&1; then
    strip --strip-unneeded "${_ess_out}.tmp" 2>/dev/null || strip "${_ess_out}.tmp" 2>/dev/null || true
  fi

  mv -f "${_ess_out}.tmp" "${_ess_out}"
}

# ## libscript_exp_check_prereqs
# Evaluates codebase prerequisite gates (`RULE-7`) for a benchmark sub-suite against the target repository and records pass/block status in JSON.
libscript_exp_check_prereqs() {
  _ecq_suite="${1}"
  _ecq_repo="${2}"
  _ecq_out_json="${3}"

  mkdir -p "$(dirname -- "${_ecq_out_json}")"
  _ecq_ok='true'
  _ecq_notes=''

  case "${_ecq_suite}" in
    E4|e4)
      if [ ! -d "${_ecq_repo}" ]; then
        _ecq_ok='false'
        _ecq_notes='missing_target_repo'
      else
        if [ -f "${_ecq_repo}/scripts/differential_oracle.py" ]; then
          if ! grep -Eq 'PJRT_Compile|pjrt_compile' "${_ecq_repo}/scripts/differential_oracle.py" 2>/dev/null; then
            _ecq_ok='false'
            _ecq_notes='differential_oracle_missing_PJRT_Compile'
          fi
        else
          _ecq_ok='false'
          _ecq_notes='missing_differential_oracle_py'
        fi
        _hlo_bridge="${_ecq_repo}/crates/libtpu-core/src/compiler/hlo_bridge.rs"
        if [ -f "${_hlo_bridge}" ]; then
          if grep -Eq 'Bounded\(0\)' "${_hlo_bridge}" 2>/dev/null; then
            _ecq_ok='false'
            _ecq_notes="${_ecq_notes:+${_ecq_notes},}unfixed_Bounded_0_in_hlo_bridge"
          fi
        fi
      fi
      ;;
    E6|e6)
      if [ ! -d "${_ecq_repo}" ]; then
        _ecq_ok='false'
        _ecq_notes='missing_target_repo'
      else
        _vliw_rs="${_ecq_repo}/crates/libtpu-core/src/compiler/vliw.rs"
        if [ -f "${_vliw_rs}" ]; then
          if ! grep -Eq 'ModuloPipelineScheduler|RecMII|ResMII' "${_vliw_rs}" 2>/dev/null; then
            _ecq_ok='false'
            _ecq_notes='missing_modulo_pipeline_scheduler_in_vliw_rs'
          fi
        fi
      fi
      ;;
    *)
      if [ ! -d "${_ecq_repo}" ]; then
        _ecq_ok='false'
        _ecq_notes='missing_target_repo'
      fi
      ;;
  esac

  [ -n "${_ecq_notes}" ] || _ecq_notes='satisfied'
  cat <<EOF > "${_ecq_out_json}.tmp"
{
  "suite": "${_ecq_suite}",
  "all_prereqs_met": ${_ecq_ok},
  "details": "${_ecq_notes}"
}
EOF
  mv -f "${_ecq_out_json}.tmp" "${_ecq_out_json}"
  [ "${_ecq_ok}" = "true" ]
}

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_eh_caller_dir:-}" ] && SCRIPT_DIR="${_eh_caller_dir}"
[ -n "${_eh_caller_this:-}" ] && THIS_FILE="${_eh_caller_this}"
unset SCRIPT_NAME _eh_caller_this _eh_caller_dir || true
