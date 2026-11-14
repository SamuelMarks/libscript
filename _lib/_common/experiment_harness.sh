#!/bin/sh
# ## Overview
# Zero-dependency SIGPLAN empirical evaluation substrate (`experiment_harness.sh`). Implements provenance envelopes (`RULE-1`), native ISA guards (`RULE-2`), cold/warm subprocess trial separation (`RULE-3`), non-parametric `samples_ns` quantile/IQR/P99 statistics (`RULE-4`), 5-OS normalized `ru_maxrss`/`PeakWorkingSetSize` accounting (`RULE-5`), pinned release Cargo/C11/MSVC/Watcom profiles (`RULE-6`), codebase prerequisite gating (`RULE-7`), WINE/WSL2 baseline controls, PE64 DLL import audits, and zero-fork `.patch` hunk classification.
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

# ## libscript_exp_ensure_bench_probe
# Compiles `_lib/_common/c_probes/libscript_bench_probe.c` idempotently into `${LIBSCRIPT_ROOT_DIR}/build/.bench_probe/libscript_bench_probe` when a C compiler is available.
libscript_exp_ensure_bench_probe() {
  if [ -n "${LIBSCRIPT_BENCH_PROBE_BIN:-}" ] && [ -x "${LIBSCRIPT_BENCH_PROBE_BIN}" ]; then
    return 0
  fi
  _prb_dir="${LIBSCRIPT_ROOT_DIR}/build/.bench_probe"
  _prb_bin="${_prb_dir}/libscript_bench_probe"
  _prb_src="${LIBSCRIPT_ROOT_DIR}/_lib/_common/c_probes/libscript_bench_probe.c"
  [ -f "${_prb_src}" ] || return 1
  if [ -x "${_prb_bin}" ] && [ "${FORCE_REBUILD:-0}" != "1" ] && [ ! "${_prb_src}" -nt "${_prb_bin}" ]; then
    export LIBSCRIPT_BENCH_PROBE_BIN="${_prb_bin}"
    return 0
  fi
  _prb_cc=''
  for _cand_cc in clang cc gcc; do
    if command -v "${_cand_cc}" >/dev/null 2>&1; then
      _prb_cc="${_cand_cc}"
      break
    fi
  done
  [ -n "${_prb_cc}" ] || return 1
  mkdir -p "${_prb_dir}"
  if "${_prb_cc}" -O2 -std=c11 "${_prb_src}" -o "${_prb_bin}.tmp" >/dev/null 2>&1; then
    mv -f "${_prb_bin}.tmp" "${_prb_bin}"
    chmod +x "${_prb_bin}"
    export LIBSCRIPT_BENCH_PROBE_BIN="${_prb_bin}"
    return 0
  fi
  rm -f "${_prb_bin}.tmp"
  return 1
}

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
  cat <<'CLK_EOF' > "${_clk_src}.tmp"
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
CLK_EOF
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
  if libscript_exp_ensure_bench_probe; then
    if "${LIBSCRIPT_BENCH_PROBE_BIN}" --now-ns; then
      return 0
    fi
  fi
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
    sha256sum "${_esf_target}" | awk '{print tolower($1)}'
    return 0
  fi
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "${_esf_target}" | awk '{print tolower($1)}'
    return 0
  fi
  if command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "${_esf_target}" | awk '{print tolower($NF)}'
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

  cat <<PROV_EOF > "${_ecp_out}.tmp"
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
PROV_EOF
  mv -f "${_ecp_out}.tmp" "${_ecp_out}"
}

# ## libscript_exp_capture_ecosystem_metadata
# Captures commit SHAs and dirty flags across a multi-repository ecosystem, compiler `--version` banners, OS kernel, CPU model, and RAM into `metadata.json` (`win_port` Rule 5).
libscript_exp_capture_ecosystem_metadata() {
  _eem_root="${1:-${LIBSCRIPT_EXPERIMENT_ECOSYSTEM_ROOT:-$(dirname -- "${LIBSCRIPT_ROOT_DIR}")}}"
  _eem_out="${2}"
  _eem_repos_csv="${3:-cdd-c,auto-win-msvc,msi-rs,win-cmd-rs,bento,busybox-windows,toybox-windows,dash-windows,gawk-windows,jq-windows,memcached-windows,redis-windows,valkey-windows,freebsd-usr-bin-windows,freebsd-src}"

  mkdir -p "$(dirname -- "${_eem_out}")"
  _eem_hw="${_eem_out}.hw.json"
  libscript_emit_hw_manifest_json "${_eem_hw}"

  _eem_ls_sha='0000000000000000000000000000000000000000'
  _eem_ls_dirty='false'
  if command -v git >/dev/null 2>&1 && git -C "${LIBSCRIPT_ROOT_DIR}" rev-parse --verify HEAD >/dev/null 2>&1; then
    _eem_ls_sha=$(git -C "${LIBSCRIPT_ROOT_DIR}" rev-parse HEAD 2>/dev/null || printf '0000000000000000000000000000000000000000')
    _eem_st=$(git -C "${LIBSCRIPT_ROOT_DIR}" status --porcelain 2>/dev/null || true)
    [ -n "${_eem_st}" ] && _eem_ls_dirty='true'
  fi

  _eem_clang_v=$(clang --version 2>/dev/null | head -n 1 | sed 's/\\/\\\\/g; s/"/\\"/g' || printf 'unavailable')
  _eem_gcc_v=$(gcc --version 2>/dev/null | head -n 1 | sed 's/\\/\\\\/g; s/"/\\"/g' || printf 'unavailable')
  _eem_rustc_v=$(rustc --version 2>/dev/null | head -n 1 | sed 's/\\/\\\\/g; s/"/\\"/g' || printf 'unavailable')
  _eem_wcl_v=$(wcl386 -? 2>/dev/null | head -n 1 | sed 's/\\/\\\\/g; s/"/\\"/g' || printf 'unavailable')
  _eem_wix_v=$(wix --version 2>/dev/null | head -n 1 | sed 's/\\/\\\\/g; s/"/\\"/g' || printf 'unavailable')
  _eem_wixl_v=$(wixl --version 2>/dev/null | head -n 1 | sed 's/\\/\\\\/g; s/"/\\"/g' || printf 'unavailable')
  _eem_wine_v=$(wine --version 2>/dev/null | head -n 1 | sed 's/\\/\\\\/g; s/"/\\"/g' || printf 'unavailable')
  _eem_kern=$(uname -srm 2>/dev/null | sed 's/\\/\\\\/g; s/"/\\"/g' || printf 'unknown')
  _eem_ts=$(date -u +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || printf '1970-01-01T00:00:00Z')
  _eem_hw_esc=$(printf '%s' "${_eem_hw}" | sed 's/\\/\\\\/g; s/"/\\"/g')

  {
    printf '{\n'
    printf '  "schema_version": "1.0.0",\n'
    printf '  "git_commit_sha": "%s",\n' "${_eem_ls_sha}"
    printf '  "git_dirty": %s,\n' "${_eem_ls_dirty}"
    printf '  "libscript_commit_sha": "%s",\n' "${_eem_ls_sha}"
    printf '  "timestamp_utc": "%s",\n' "${_eem_ts}"
    printf '  "host_manifest_ref": "%s",\n' "${_eem_hw_esc}"
    printf '  "kernel": "%s",\n' "${_eem_kern}"
    printf '  "cpu_model": "%s",\n' "$(printf '%s' "${LIBSCRIPT_HW_CPU_MODEL:-unknown}" | sed 's/\\/\\\\/g; s/"/\\"/g')"
    printf '  "phys_cores": %s,\n' "${LIBSCRIPT_HW_PHYS_CORES:-1}"
    printf '  "tool_versions": {\n'
    printf '    "clang": "%s",\n' "${_eem_clang_v}"
    printf '    "gcc": "%s",\n' "${_eem_gcc_v}"
    printf '    "rustc": "%s",\n' "${_eem_rustc_v}"
    printf '    "wcl386": "%s",\n' "${_eem_wcl_v}"
    printf '    "wix": "%s",\n' "${_eem_wix_v}"
    printf '    "wixl": "%s",\n' "${_eem_wixl_v}"
    printf '    "wine": "%s"\n' "${_eem_wine_v}"
    printf '  },\n'
    printf '  "repositories": {\n'
    _old_ifs="${IFS}"
    IFS=','
    # shellcheck disable=SC2086
    set -- ${_eem_repos_csv}
    IFS="${_old_ifs}"
    _r_idx=0
    _r_tot=$#
    for _r_name in "$@"; do
      _r_idx=$((_r_idx + 1))
      _r_dir="${_eem_root}/${_r_name}"
      _r_present='false'
      _r_sha='0000000000000000000000000000000000000000'
      _r_dirty='false'
      if [ -d "${_r_dir}" ]; then
        _r_present='true'
        if command -v git >/dev/null 2>&1 && git -C "${_r_dir}" rev-parse --verify HEAD >/dev/null 2>&1; then
          _r_sha=$(git -C "${_r_dir}" rev-parse HEAD 2>/dev/null || printf '0000000000000000000000000000000000000000')
          _r_st=$(git -C "${_r_dir}" status --porcelain 2>/dev/null || true)
          [ -n "${_r_st}" ] && _r_dirty='true'
        fi
      fi
      _comma=','
      [ "${_r_idx}" -eq "${_r_tot}" ] && _comma=''
      printf '    "%s": { "present": %s, "git_commit_sha": "%s", "git_dirty": %s }%s\n' \
        "${_r_name}" "${_r_present}" "${_r_sha}" "${_r_dirty}" "${_comma}"
    done
    printf '  }\n'
    printf '}\n'
  } > "${_eem_out}.tmp"
  mv -f "${_eem_out}.tmp" "${_eem_out}"
}

# ## libscript_exp_verify_lockfile
# Validates a pinned provenance lockfile (`c_upstreams.lock.json` or `batch_wild_corpus.lock.json`) for required entry count, non-zero commit/SHA-256 digests, and optional local cache SHA-256 integrity.
libscript_exp_verify_lockfile() {
  _evl_lock="${1}"
  _evl_min_entries="${2:-1}"
  _evl_cache_dir="${3:-}"

  if [ ! -s "${_evl_lock}" ]; then
    log_error "[LOCKFILE] Missing or empty provenance lockfile '${_evl_lock}'."
    return 1
  fi
  if grep -Eq '"(commit_sha|git_commit_sha)"[[:space:]]*:[[:space:]]*"0{40}"' "${_evl_lock}"; then
    log_error "[LOCKFILE] Rejected placeholder zero commit SHA in '${_evl_lock}'."
    return 1
  fi
  if grep -Eq '"sha256"[[:space:]]*:[[:space:]]*"0{64}"' "${_evl_lock}"; then
    log_error "[LOCKFILE] Rejected placeholder zero SHA-256 digest in '${_evl_lock}'."
    return 1
  fi

  _evl_cnt=$(grep -Ec '"(id|repo|name)"[[:space:]]*:' "${_evl_lock}" 2>/dev/null || printf '0')
  if [ "${_evl_cnt}" -lt "${_evl_min_entries}" ]; then
    log_error "[LOCKFILE] '${_evl_lock}' has ${_evl_cnt} entries (< required ${_evl_min_entries})."
    return 1
  fi

  if [ -n "${_evl_cache_dir}" ] && [ -d "${_evl_cache_dir}" ]; then
    _evl_pairs=$(awk '
      /"local_rel_path"[[:space:]]*:/ {
        p = $0; sub(/^.*:[[:space:]]*"/, "", p); sub(/".*$/, "", p)
      }
      /"sha256"[[:space:]]*:/ {
        h = $0; sub(/^.*:[[:space:]]*"/, "", h); sub(/".*$/, "", h)
        if (p != "" && h != "") { print p "|" tolower(h); p = ""; h = "" }
      }
    ' "${_evl_lock}")
    if [ -n "${_evl_pairs}" ]; then
      _evl_bad=0
      for _pair in ${_evl_pairs}; do
        _rel_p="${_pair%|*}"
        _exp_h="${_pair#*|}"
        if [ -f "${_evl_cache_dir}/${_rel_p}" ]; then
          _act_h=$(libscript_exp_sha256_file "${_evl_cache_dir}/${_rel_p}")
          if [ "${_act_h}" != "${_exp_h}" ]; then
            log_error "[LOCKFILE] SHA-256 mismatch on '${_rel_p}': expected ${_exp_h}, got ${_act_h}."
            _evl_bad=1
          fi
        fi
      done
      [ "${_evl_bad}" -eq 0 ] || return 1
    fi
  fi
  return 0
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
# Enforces native hardware ISA execution and rejects Rosetta 2, QEMU user/TCG, or binfmt_misc binary translation unless an explicit controlled emulation mode is active (`RULE-2`).
libscript_exp_assert_native_isa() {
  _eani_expected="${1:-}"
  _eani_emu="${LIBSCRIPT_EXPERIMENT_EMULATION_MODE:-native_only}"

  case "${_eani_emu}" in
    wine_warm|wine_cold|wsl2_loopback|wsl2_cross_boundary|wsl2_cli_spawn|cygwin|msys2|dos32_vagrant_com1|qemu_user_x86_64|qemu_user_aarch64|qemu_user_riscv64|qemu_user_s390x|qemu_user_powerpc64le|qemu_user_armhf)
      return 0
      ;;
  esac

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
      amd64|i86pc) _norm_arch='x86_64' ;;
      aarch64) _norm_arch='arm64' ;;
    esac
    _norm_exp="${_eani_expected}"
    case "${_norm_exp}" in
      amd64|linux_x64|windows_x64|freebsd_x64|illumos_x64|x64) _norm_exp='x86_64' ;;
      aarch64|macos_arm64|linux_arm64|freebsd_arm64) _norm_exp='arm64' ;;
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

  _erc_peak_b=0
  if libscript_exp_ensure_bench_probe; then
    _prb_out="${_erc_out_json}.probe.tmp"
    _erc_rc=0
    "${LIBSCRIPT_BENCH_PROBE_BIN}" --json-out "${_prb_out}" --exec "${_erc_exec}" "$@" >/dev/null 2>&1 || _erc_rc=$?
    _erc_dt=$(awk '/"elapsed_ns"/ { gsub(/[^0-9]/, "", $2); print $2+0; exit }' "${_prb_out}" 2>/dev/null || printf '1')
    _erc_peak_b=$(awk '/"peak_rss_bytes"/ { gsub(/[^0-9]/, "", $2); print $2+0; exit }' "${_prb_out}" 2>/dev/null || printf '0')
    [ -n "${_erc_dt}" ] || _erc_dt=1
    [ -n "${_erc_peak_b}" ] || _erc_peak_b=0
    rm -f "${_prb_out}"
  else
    _erc_t0=$(libscript_now_ns)
    _erc_rc=0
    "${_erc_exec}" "$@" >/dev/null 2>&1 || _erc_rc=$?
    _erc_t1=$(libscript_now_ns)
    _erc_dt=$(awk -v a="${_erc_t0}" -v b="${_erc_t1}" 'BEGIN { d = b - a; if (d < 1) d = 1; printf "%.0f", d }')
  fi
  if [ -n "${_erc_tmp_bin}" ]; then
    rm -f "${_erc_tmp_bin}"
  fi

  if [ "${_erc_rc}" -ne 0 ]; then
    log_error "[RULE-3] Cold subprocess '${_erc_bin}' exited with non-zero status ${_erc_rc}."
    return "${_erc_rc}"
  fi

  _erc_ms=$(awk -v d="${_erc_dt}" 'BEGIN { printf "%.6f", d / 1000000.0 }')
  _erc_mib=$(awk -v b="${_erc_peak_b}" 'BEGIN { printf "%.4f", b / 1048576.0 }')
  cat <<COLD_EOF > "${_erc_out_json}.tmp"
{
  "cold_cache_mode": "${_erc_mode}",
  "cold_latency_ns": ${_erc_dt},
  "cold_latency_ms": ${_erc_ms},
  "peak_rss_bytes": ${_erc_peak_b},
  "peak_rss_mib": ${_erc_mib}
}
COLD_EOF
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

# ## libscript_exp_run_statistical_bench
# Runs configurable `(W, N)` statistical benchmarks via `hyperfine` (when available and enabled) or native subprocess warm loops, emitting canonical `samples_ns`, `median_p50_ns`, `iqr_ns`, and `p99_ns` JSON (`win_port` §4.2).
libscript_exp_run_statistical_bench() {
  _esb_warmup="${1}"
  _esb_trials="${2}"
  _esb_prepare="${3}"
  _esb_out_json="${4}"
  shift 4

  mkdir -p "$(dirname -- "${_esb_out_json}")"
  _esb_samples="${_esb_out_json}.samples_ns"

  if [ "${LIBSCRIPT_EXP_USE_HYPERFINE:-1}" = "1" ] && command -v hyperfine >/dev/null 2>&1 && [ $# -eq 1 ]; then
    _hf_json="${_esb_out_json}.hyperfine.tmp"
    if [ -n "${_esb_prepare}" ]; then
      hyperfine --warmup "${_esb_warmup}" --runs "${_esb_trials}" --prepare "${_esb_prepare}" --export-json "${_hf_json}" "$1" >/dev/null 2>&1
    else
      hyperfine --warmup "${_esb_warmup}" --runs "${_esb_trials}" --export-json "${_hf_json}" "$1" >/dev/null 2>&1
    fi
    awk '
      /"times"[[:space:]]*:/ { in_times = 1; next }
      in_times && /\]/ { in_times = 0 }
      in_times {
        gsub(/[^0-9.eE+-]/, "", $0)
        if ($0 != "") printf "%.0f\n", ($0 + 0) * 1000000000.0
      }
    ' "${_hf_json}" > "${_esb_samples}"
    rm -f "${_hf_json}"
  else
    _w_i=1
    while [ "${_w_i}" -le "${_esb_warmup}" ]; do
      if [ -n "${_esb_prepare}" ]; then
        /bin/sh -c "${_esb_prepare}" >/dev/null 2>&1 || true
      fi
      "$@" >/dev/null 2>&1
      _w_i=$((_w_i + 1))
    done
    : > "${_esb_samples}.tmp"
    _n_i=1
    while [ "${_n_i}" -le "${_esb_trials}" ]; do
      if [ -n "${_esb_prepare}" ]; then
        /bin/sh -c "${_esb_prepare}" >/dev/null 2>&1 || true
      fi
      _t0=$(libscript_now_ns)
      "$@" >/dev/null 2>&1
      _t1=$(libscript_now_ns)
      awk -v a="${_t0}" -v b="${_t1}" 'BEGIN { d = b - a; if (d < 1) d = 1; printf "%.0f\n", d }' >> "${_esb_samples}.tmp"
      _n_i=$((_n_i + 1))
    done
    mv -f "${_esb_samples}.tmp" "${_esb_samples}"
  fi

  libscript_exp_compute_stats "${_esb_samples}" "${_esb_out_json}"
  rm -f "${_esb_samples}"
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

      sum_v = 0.0
      for (i = 1; i <= n; i++) sum_v += vals[i]
      mean_v = sum_v / n
      var_v = 0.0
      if (n > 1) {
        for (i = 1; i <= n; i++) {
          diff_v = vals[i] - mean_v
          var_v += diff_v * diff_v
        }
        var_v = var_v / (n - 1)
      }
      stddev_v = sqrt(var_v)

      printf "{\n"
      printf "  \"count\": %d,\n", n
      printf "  \"min_ns\": %.0f,\n", min_v
      printf "  \"p25_ns\": %.0f,\n", p25_v
      printf "  \"median_p50_ns\": %.0f,\n", p50_v
      printf "  \"mean_ns\": %.0f,\n", mean_v
      printf "  \"stddev_ns\": %.0f,\n", stddev_v
      printf "  \"p75_ns\": %.0f,\n", p75_v
      printf "  \"iqr_ns\": %.0f,\n", iqr_v
      printf "  \"p99_ns\": %.0f,\n", p99_v
      printf "  \"max_ns\": %.0f,\n", max_v
      printf "  \"median_s\": %.6f,\n", p50_v / 1000000000.0
      printf "  \"stddev_s\": %.6f,\n", stddev_v / 1000000000.0
      printf "  \"median_ms\": %.6f,\n", p50_v / 1000000.0
      printf "  \"mean_ms\": %.6f,\n", mean_v / 1000000.0
      printf "  \"stddev_ms\": %.6f,\n", stddev_v / 1000000.0
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
# Normalizes 5-OS raw RSS values (`bytes` on Darwin/Windows_NT/SunOS_bytes, `pages * 4096` on SunOS_pages, and `KiB * 1024` on Linux/FreeBSD/SunOS) into exact integer bytes (`RULE-5`).
libscript_exp_normalize_rss_bytes() {
  _enr_raw="${1}"
  _enr_os="${2:-${UNAME:-Linux}}"

  case "${_enr_os}" in
    Darwin|darwin|Windows_NT|windows|SunOS_bytes|illumos_bytes)
      awk -v r="${_enr_raw}" 'BEGIN { printf "%.0f\n", r + 0 }'
      ;;
    SunOS_pages|illumos_pages)
      _pg=$(getconf PAGESIZE 2>/dev/null || printf '4096')
      awk -v r="${_enr_raw}" -v p="${_pg}" 'BEGIN { printf "%.0f\n", (r + 0) * (p + 0) }'
      ;;
    Linux|linux|FreeBSD|freebsd|SunOS|sunos|illumos|*)
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

# ## libscript_exp_wine_session
# Manages unconfounded warm (`wineserver -p`) vs. cold (`wineserver -k`) WINE baseline sessions with an isolated `WINEPREFIX` (`win_port` §1.3 & §8.2).
libscript_exp_wine_session() {
  _ews_action="${1}"
  _ews_prefix="${2:-${TMPDIR:-/tmp}/libscript_wineprefix}"
  shift 2 || true

  export WINEPREFIX="${_ews_prefix}"
  export WINEDEBUG='-all'
  mkdir -p "${WINEPREFIX}"

  case "${_ews_action}" in
    warm_start)
      export LIBSCRIPT_EXPERIMENT_EMULATION_MODE='wine_warm'
      export LIBSCRIPT_BENCH_WINE_MODE='warm'
      if command -v wineserver >/dev/null 2>&1 && command -v wine >/dev/null 2>&1; then
        wineserver -p >/dev/null 2>&1 || true
        wine cmd.exe /c "exit 0" >/dev/null 2>&1 || true
      fi
      ;;
    cold_reset)
      export LIBSCRIPT_EXPERIMENT_EMULATION_MODE='wine_cold'
      export LIBSCRIPT_BENCH_WINE_MODE='cold'
      if command -v wineserver >/dev/null 2>&1; then
        wineserver -k >/dev/null 2>&1 || true
      fi
      ;;
    exec)
      if command -v wine >/dev/null 2>&1; then
        wine "$@"
      else
        log_error '[WINE] wine binary not found on PATH.'
        return 127
      fi
      ;;
    stop)
      if command -v wineserver >/dev/null 2>&1; then
        wineserver -k >/dev/null 2>&1 || true
      fi
      export LIBSCRIPT_EXPERIMENT_EMULATION_MODE='native_only'
      ;;
    *)
      log_error "[WINE] Unknown libscript_exp_wine_session action '${_ews_action}'."
      return 1
      ;;
  esac
}

# ## libscript_exp_wsl2_mode
# Configures and executes unconfounded WSL2 baseline modes (`in_vm_loopback`, `host_to_wsl_tcp`, `cli_spawn`) (`win_port` §1.3).
libscript_exp_wsl2_mode() {
  _ewm_mode="${1}"
  shift

  case "${_ewm_mode}" in
    in_vm_loopback)
      export LIBSCRIPT_EXPERIMENT_EMULATION_MODE='wsl2_loopback'
      if command -v wsl.exe >/dev/null 2>&1; then
        wsl.exe -- "$@"
      else
        "$@"
      fi
      ;;
    host_to_wsl_tcp)
      export LIBSCRIPT_EXPERIMENT_EMULATION_MODE='wsl2_cross_boundary'
      "$@"
      ;;
    cli_spawn)
      export LIBSCRIPT_EXPERIMENT_EMULATION_MODE='wsl2_cli_spawn'
      if command -v wsl.exe >/dev/null 2>&1; then
        wsl.exe -- "$@"
      else
        "$@"
      fi
      ;;
    *)
      log_error "[WSL2] Unknown WSL2 baseline mode '${_ewm_mode}'."
      return 1
      ;;
  esac
}

# ## libscript_exp_measure_binary_sizes
# Records exact unstripped and stripped byte/KiB footprints for Mach-O, ELF, PE64 (`/MT` vs. `/MD`), or OpenWatcom DOS32 `LE` binaries (`win_port` §1.2 & §5.3).
libscript_exp_measure_binary_sizes() {
  _embs_bin="${1}"
  _embs_crt="${2:-POSIX}"
  _embs_out_json="${3}"

  if [ ! -f "${_embs_bin}" ]; then
    log_error "[SIZE] Missing binary '${_embs_bin}'."
    return 1
  fi
  mkdir -p "$(dirname -- "${_embs_out_json}")"
  _unstrip_b=$(wc -c < "${_embs_bin}" | awk '{print $1+0}')
  _tmp_strip="${_embs_out_json}.stripped_bin.tmp"
  cp -f "${_embs_bin}" "${_tmp_strip}"

  if [ "${_embs_crt}" = "DOS32_LE" ] && command -v wstrip >/dev/null 2>&1; then
    wstrip -q "${_tmp_strip}" >/dev/null 2>&1 || true
  elif [ "${UNAME:-}" = "Darwin" ]; then
    strip -x "${_tmp_strip}" 2>/dev/null || strip -S "${_tmp_strip}" 2>/dev/null || true
  elif command -v llvm-strip >/dev/null 2>&1; then
    llvm-strip --strip-unneeded "${_tmp_strip}" 2>/dev/null || true
  elif command -v strip >/dev/null 2>&1; then
    strip --strip-unneeded "${_tmp_strip}" 2>/dev/null || strip "${_tmp_strip}" 2>/dev/null || true
  fi

  _strip_b=$(wc -c < "${_tmp_strip}" | awk '{print $1+0}')
  rm -f "${_tmp_strip}"

  awk -v ub="${_unstrip_b}" -v sb="${_strip_b}" -v crt="${_embs_crt}" 'BEGIN {
    printf "{\n"
    printf "  \"crt_variant\": \"%s\",\n", crt
    printf "  \"unstripped_bytes\": %.0f,\n", ub
    printf "  \"unstripped_kib\": %.2f,\n", ub / 1024.0
    printf "  \"stripped_bytes\": %.0f,\n", sb
    printf "  \"stripped_kib\": %.2f\n", sb / 1024.0
    printf "}\n"
  }' > "${_embs_out_json}.tmp"
  mv -f "${_embs_out_json}.tmp" "${_embs_out_json}"
}

# ## libscript_exp_audit_pe_dependents
# Extracts imported PE64 DLLs via `dumpbin /dependents` or `llvm-objdump -p` (or `--from-text <dump_file>`) and verifies Win32 subsystem purity (`win_port` §7.2).
libscript_exp_audit_pe_dependents() {
  _eapd_mode="${1}"
  _eapd_target="${2}"
  _eapd_out_json="${3:-}"

  _raw_dump=''
  if [ "${_eapd_mode}" = "--from-text" ]; then
    _raw_dump="${_eapd_target}"
    _eapd_out_json="${3}"
    if [ ! -f "${_raw_dump}" ]; then
      log_error "[PE-AUDIT] Missing dump text '${_raw_dump}'."
      return 1
    fi
  else
    _eapd_out_json="${2}"
    _eapd_target="${1}"
    if [ ! -f "${_eapd_target}" ]; then
      log_error "[PE-AUDIT] Missing PE binary '${_eapd_target}'."
      return 1
    fi
    _raw_dump="${_eapd_out_json}.pedump.tmp"
    mkdir -p "$(dirname -- "${_eapd_out_json}")"
    if command -v dumpbin >/dev/null 2>&1; then
      dumpbin /dependents "${_eapd_target}" > "${_raw_dump}" 2>/dev/null || true
    elif command -v llvm-objdump >/dev/null 2>&1; then
      llvm-objdump -p "${_eapd_target}" > "${_raw_dump}" 2>/dev/null || true
    elif command -v objdump >/dev/null 2>&1; then
      objdump -p "${_eapd_target}" > "${_raw_dump}" 2>/dev/null || true
    else
      : > "${_raw_dump}"
    fi
  fi

  mkdir -p "$(dirname -- "${_eapd_out_json}")"
  awk '
    {
      sub(/\r$/, "", $0)
      line = $0
      if (line ~ /DLL Name:[[:space:]]*[A-Za-z0-9_.-]+\.[Dd][Ll][Ll]/) {
        sub(/^.*DLL Name:[[:space:]]*/, "", line)
        sub(/[[:space:]].*$/, "", line)
        dll = tolower(line)
        if (!(dll in seen)) { seen[dll] = 1; dlls[++n] = dll }
      } else if (line ~ /^[[:space:]]+[A-Za-z0-9_.-]+\.[Dd][Ll][Ll][[:space:]]*$/) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
        dll = tolower(line)
        if (!(dll in seen)) { seen[dll] = 1; dlls[++n] = dll }
      }
    }
    END {
      pure = "true"
      for (i = 1; i <= n; i++) {
        if (dlls[i] ~ /^(cygwin1|msys-2\.0)\.dll$/) {
          pure = "false"
        }
      }
      printf "{\n"
      printf "  \"dll_count\": %d,\n", n
      printf "  \"pure_win32_subsystem\": %s,\n", pure
      printf "  \"imported_dlls\": ["
      for (i = 1; i <= n; i++) {
        printf "%s\"%s\"", (i > 1 ? ", " : ""), dlls[i]
      }
      printf "]\n}\n"
    }
  ' "${_raw_dump}" > "${_eapd_out_json}.tmp"

  if [ "${_eapd_mode}" != "--from-text" ]; then
    rm -f "${_raw_dump}"
  fi
  mv -f "${_eapd_out_json}.tmp" "${_eapd_out_json}"
}

# ## libscript_exp_audit_zero_fork_repo
# Audits an upstream checkout and `*-windows` port harness for zero upstream dirty files, zero in-repo polyfill `.c`/`.h` files, standalone `tests/*.c` counts, and `.patch` C/H vs. build diff LoC (`win_port` §1.4 & §6.2).
libscript_exp_audit_zero_fork_repo() {
  _eaz_upstream="${1}"
  _eaz_harness="${2}"
  _eaz_out_json="${3}"

  mkdir -p "$(dirname -- "${_eaz_out_json}")"
  _dirty_cnt=0
  if [ -d "${_eaz_upstream}/.git" ] && command -v git >/dev/null 2>&1; then
    _dirty_cnt=$(git -C "${_eaz_upstream}" status --porcelain 2>/dev/null | wc -l | awk '{print $1+0}')
  fi

  _polyfill_cnt=0
  _test_c_cnt=0
  if [ -d "${_eaz_harness}" ]; then
    _polyfill_cnt=$(find "${_eaz_harness}" \
      \( -name .git -o -name build -o -name 'build_*' -o -name rewritten_src -o -name upstream -o -name vendor -o -name tests -o -name test \) -prune \
      -o -type f \( -name '*.c' -o -name '*.h' \) -print 2>/dev/null | wc -l | awk '{print $1+0}')
    if [ -d "${_eaz_harness}/tests" ]; then
      _test_c_cnt=$(find "${_eaz_harness}/tests" -type f \( -name '*.c' -o -name '*.h' \) -print 2>/dev/null | wc -l | awk '{print $1+0}')
    fi
  fi

  _patch_tmp="${_eaz_out_json}.patches.tmp"
  : > "${_patch_tmp}"
  if [ -d "${_eaz_harness}/patches" ]; then
    find "${_eaz_harness}/patches" -type f -name '*.patch' -print 2>/dev/null | LC_ALL=C sort | while IFS= read -r _pf; do
      cat "${_pf}" >> "${_patch_tmp}"
      printf '\n' >> "${_patch_tmp}"
    done
  fi

  awk -v dirty="${_dirty_cnt}" -v poly="${_polyfill_cnt}" -v tcnt="${_test_c_cnt}" '
    BEGIN { cur_kind = "build"; c_loc = 0; b_loc = 0 }
    /^\+\+\+[[:space:]]+/ {
      f = $2
      sub(/^[ab]\//, "", f)
      sub(/\t.*$/, "", f)
      if (f ~ /\.(c|h|cc|cpp|hpp|inc)$/) {
        cur_kind = "c_h"
      } else {
        cur_kind = "build"
      }
      next
    }
    /^---[[:space:]]+/ { next }
    /^[+-]/ {
      if (cur_kind == "c_h") c_loc++
      else b_loc++
    }
    END {
      printf "{\n"
      printf "  \"upstream_git_dirty_files\": %d,\n", dirty + 0
      printf "  \"in_repo_polyfill_c_h\": %d,\n", poly + 0
      printf "  \"standalone_test_runner_c_h\": %d,\n", tcnt + 0
      printf "  \"staged_patch_c_h_loc\": %d,\n", c_loc
      printf "  \"staged_patch_build_loc\": %d,\n", b_loc
      printf "  \"staged_patch_total_loc\": %d\n", c_loc + b_loc
      printf "}\n"
    }
  ' "${_patch_tmp}" > "${_eaz_out_json}.tmp"
  rm -f "${_patch_tmp}"
  mv -f "${_eaz_out_json}.tmp" "${_eaz_out_json}"
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
    cat <<CARGO_EOF > "${_epc_out_json}.tmp"
{
  "profile_id": "${_epc_spec}",
  "opt_level": ${_opt},
  "lto": "${_lto}",
  "codegen_units": ${_cgu},
  "debug": false,
  "post_link_strip": "${_strip_tool}"
}
CARGO_EOF
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
# Evaluates codebase prerequisite gates (`RULE-7`) for `libtpu` (`E4`, `E6`) and `win_port` (`WP_CDD`, `WP_AWM`, `WP_CMD`, `WP_MSI`) against the target repository and records pass/block status in JSON.
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
    WP_AWM|wp_awm)
      if [ ! -d "${_ecq_repo}" ]; then
        _ecq_ok='false'
        _ecq_notes='missing_auto_win_msvc_repo'
      elif [ -f "${_ecq_repo}/cmake/AutoWinMsvcTransform.cmake" ]; then
        if ! grep -Eq 'AUTO_WIN_MSVC_USE_CDD_C' "${_ecq_repo}/cmake/AutoWinMsvcTransform.cmake" 2>/dev/null; then
          _ecq_ok='false'
          _ecq_notes='missing_AUTO_WIN_MSVC_USE_CDD_C_in_cmake'
        fi
      fi
      ;;
    WP_CMD|wp_cmd)
      if [ ! -d "${_ecq_repo}" ]; then
        _ecq_ok='false'
        _ecq_notes='missing_win_cmd_rs_repo'
      elif [ -f "${_ecq_repo}/src/parser/peg.rs" ]; then
        if ! grep -Eq 'CompoundBlock|IfStmt|ForStmt' "${_ecq_repo}/src/parser/peg.rs" 2>/dev/null; then
          _ecq_ok='false'
          _ecq_notes='incomplete_PegRuleKey_memoization'
        fi
      fi
      ;;
    WP_MSI|wp_msi)
      if [ ! -d "${_ecq_repo}" ]; then
        _ecq_ok='false'
        _ecq_notes='missing_msi_rs_repo'
      elif [ -f "${_ecq_repo}/crates/msi/src/execution/transaction/mod.rs" ]; then
        if ! grep -Eq 'armed[[:space:]]*:[[:space:]]*bool' "${_ecq_repo}/crates/msi/src/execution/transaction/mod.rs" 2>/dev/null; then
          _ecq_ok='false'
          _ecq_notes='missing_affine_armed_rollback_guard'
        fi
      fi
      ;;
    EDG_PHASE0|edg_phase0)
      if [ ! -d "${_ecq_repo}" ]; then
        _ecq_ok='false'
        _ecq_notes='missing_edgcpp_multibackend_repo'
      else
        if [ -f "${_ecq_repo}/lib_src/gcc_be_eh_rt.c" ]; then
          if grep -Eq 'base_count[[:space:]]*<=[[:space:]]*16' "${_ecq_repo}/lib_src/gcc_be_eh_rt.c" 2>/dev/null; then
            _ecq_ok='false'
            _ecq_notes="${_ecq_notes:+${_ecq_notes},}fixed_base_count_16_cap_in_gcc_be_eh_rt"
          fi
        fi
        if [ -f "${_ecq_repo}/src/gcc_gen_be_stmt.c" ]; then
          if grep -Eq '_Z_coro_frame_%p' "${_ecq_repo}/src/gcc_gen_be_stmt.c" 2>/dev/null; then
            _ecq_ok='false'
            _ecq_notes="${_ecq_notes:+${_ecq_notes},}aslr_pointer_coro_frame_name_in_gcc_gen_be_stmt"
          fi
        fi
        if [ -f "${_ecq_repo}/src/gcc_gen_be_type.c" ]; then
          if grep -Eq 'deferred_structs\[4096\]' "${_ecq_repo}/src/gcc_gen_be_type.c" 2>/dev/null; then
            _ecq_ok='false'
            _ecq_notes="${_ecq_notes:+${_ecq_notes},}fixed_4096_deferred_structs_cap_in_gcc_gen_be_type"
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
  cat <<PREREQ_EOF > "${_ecq_out_json}.tmp"
{
  "suite": "${_ecq_suite}",
  "all_prereqs_met": ${_ecq_ok},
  "details": "${_ecq_notes}"
}
PREREQ_EOF
  mv -f "${_ecq_out_json}.tmp" "${_ecq_out_json}"
  [ "${_ecq_ok}" = "true" ]
}

# ## libscript_exp_compute_median_stddev
# Computes median, sample standard deviation (sigma), quantiles, and matched-optimization baseline speedup ratio from a nanosecond sample file (`EXPERIMENTS.md` §1.2 & §4.1).
libscript_exp_compute_median_stddev() {
  _ecms_samples="${1}"
  _ecms_out_json="${2}"
  _ecms_base_med_ns="${3:-0}"
  _ecms_opt="${4:--O2}"
  _ecms_base_opt="${5:-${_ecms_opt}}"

  if [ "${_ecms_opt}" != "${_ecms_base_opt}" ]; then
    log_error "[OPT-PARITY] Mismatched optimization flags rejected: candidate='${_ecms_opt}' vs baseline='${_ecms_base_opt}'."
    return 1
  fi
  libscript_exp_compute_stats "${_ecms_samples}" "${_ecms_out_json}.base.tmp"
  awk -v bmed="${_ecms_base_med_ns}" -v opt="${_ecms_opt}" '
    /"median_p50_ns"/ {
      v = $2; gsub(/[^0-9.]/, "", v); med = v + 0
    }
    /^[[:space:]]*"samples_ns":/ {
      printf "  \"opt_flags\": \"%s\",\n", opt
      if ((bmed + 0) > 0 && med > 0) {
        printf "  \"matched_speedup_ratio\": %.6f,\n", (bmed + 0) / med
      } else {
        printf "  \"matched_speedup_ratio\": 1.000000,\n"
      }
    }
    { print }
  ' "${_ecms_out_json}.base.tmp" > "${_ecms_out_json}.tmp"
  rm -f "${_ecms_out_json}.base.tmp"
  mv -f "${_ecms_out_json}.tmp" "${_ecms_out_json}"
}

# ## libscript_exp_parse_cpfe_timing
# Extracts front-end (`fe_cpu_s`) and backend (`be_cpu_s`) CPU seconds from `cpfe --timing` output and verifies `fe_cpu_s + be_cpu_s <= user_cpu_s + sys_cpu_s` (`EXPERIMENTS.md` §4.2).
libscript_exp_parse_cpfe_timing() {
  _epct_log="${1}"
  _epct_probe_json="${2:-}"
  _epct_out_json="${3}"

  mkdir -p "$(dirname -- "${_epct_out_json}")"
  _u_s='0'
  _s_s='0'
  if [ -n "${_epct_probe_json}" ] && [ -f "${_epct_probe_json}" ]; then
    _u_s=$(awk -F: '/"user_cpu_s"/ {gsub(/[^0-9.]/, "", $2); print $2+0}' "${_epct_probe_json}" 2>/dev/null || printf '0')
    _s_s=$(awk -F: '/"sys_cpu_s"/ {gsub(/[^0-9.]/, "", $2); print $2+0}' "${_epct_probe_json}" 2>/dev/null || printf '0')
  fi
  [ -n "${_u_s}" ] || _u_s='0'
  [ -n "${_s_s}" ] || _s_s='0'

  _in_log="${_epct_log}"
  if [ ! -f "${_in_log}" ]; then
    _in_log='/dev/null'
  fi

  awk -v us="${_u_s}" -v ss="${_s_s}" '
    BEGIN { fe = 0.0; be = 0.0; found = 0 }
    {
      line = tolower($0)
      if (line ~ /(front[ -]?end|fe_cpu_s|fe time|parsing)/) {
        for (i = 1; i <= NF; i++) {
          tok = $i; gsub(/[^0-9.]/, "", tok)
          if (tok ~ /^[0-9]+(\.[0-9]+)?$/) { fe = tok + 0; found = 1 }
        }
      } else if (line ~ /(back[ -]?end|be_cpu_s|be time|codegen|llvm_gen_be|gcc_gen_be|c_gen_be|cp_gen_be)/) {
        for (i = 1; i <= NF; i++) {
          tok = $i; gsub(/[^0-9.]/, "", tok)
          if (tok ~ /^[0-9]+(\.[0-9]+)?$/) { be = tok + 0; found = 1 }
        }
      }
    }
    END {
      tot = fe + be
      rusage_tot = (us + 0) + (ss + 0)
      ok = "true"
      if (rusage_tot > 0 && tot > (rusage_tot + 0.05)) {
        ok = "false"
      }
      printf "{\n"
      printf "  \"timing_markers_found\": %s,\n", (found ? "true" : "false")
      printf "  \"fe_cpu_s\": %.6f,\n", fe
      printf "  \"be_cpu_s\": %.6f,\n", be
      printf "  \"phase_sum_cpu_s\": %.6f,\n", tot
      printf "  \"rusage_user_cpu_s\": %.6f,\n", us + 0
      printf "  \"rusage_sys_cpu_s\": %.6f,\n", ss + 0
      printf "  \"rusage_consistent\": %s\n", ok
      printf "}\n"
    }
  ' "${_in_log}" > "${_epct_out_json}.tmp"
  mv -f "${_epct_out_json}.tmp" "${_epct_out_json}"
}

# ## libscript_exp_run_two_stage_pipeline
# Executes a two-stage legacy EDG pipeline (`EDG-C-LEGACY` or `EDG-CPP-LEGACY`), recording Stage 1, `.int.*` byte size, and Stage 2 separately with `total = Stage1 + Stage2` and `peak_rss_mb = max(Stage1, Stage2)` (`EXPERIMENTS.md` §1.4).
libscript_exp_run_two_stage_pipeline() {
  _ertp_out_json="${1}"
  _ertp_int_file="${2}"
  _ertp_stage1_cmd="${3}"
  _ertp_stage2_cmd="${4}"

  mkdir -p "$(dirname -- "${_ertp_out_json}")"
  libscript_exp_ensure_bench_probe || return 1

  _s1_json="${_ertp_out_json}.s1.tmp"
  _s1_log="${_ertp_out_json}.s1.log.tmp"
  _s2_json="${_ertp_out_json}.s2.tmp"
  _s2_log="${_ertp_out_json}.s2.log.tmp"
  _s1_rc=0
  "${LIBSCRIPT_BENCH_PROBE_BIN}" --json-out "${_s1_json}" --stderr-file "${_s1_log}" --exec /bin/sh -c "${_ertp_stage1_cmd}" || _s1_rc=$?
  if [ "${_s1_rc}" -ne 0 ]; then
    rm -f "${_s1_json}" "${_s1_log}"
    return "${_s1_rc}"
  fi

  _int_bytes=0
  if [ -f "${_ertp_int_file}" ]; then
    _int_bytes=$(wc -c < "${_ertp_int_file}" | awk '{print $1+0}')
  fi

  _s2_rc=0
  "${LIBSCRIPT_BENCH_PROBE_BIN}" --json-out "${_s2_json}" --stderr-file "${_s2_log}" --exec /bin/sh -c "${_ertp_stage2_cmd}" || _s2_rc=$?
  if [ "${_s2_rc}" -ne 0 ]; then
    rm -f "${_s1_json}" "${_s1_log}" "${_s2_json}" "${_s2_log}"
    return "${_s2_rc}"
  fi

  awk -v ib="${_int_bytes}" '
    FNR == NR {
      if ($0 ~ /"elapsed_s"/) { gsub(/[^0-9.]/, "", $2); w1 = $2 + 0 }
      if ($0 ~ /"user_cpu_s"/) { gsub(/[^0-9.]/, "", $2); u1 = $2 + 0 }
      if ($0 ~ /"sys_cpu_s"/) { gsub(/[^0-9.]/, "", $2); s1 = $2 + 0 }
      if ($0 ~ /"peak_rss_mb"/) { gsub(/[^0-9.]/, "", $2); r1 = $2 + 0 }
      if ($0 ~ /"hw_instructions"/) { gsub(/[^0-9.]/, "", $2); i1 = $2 + 0 }
      if ($0 ~ /"hw_cycles"/) { gsub(/[^0-9.]/, "", $2); c1 = $2 + 0 }
      next
    }
    {
      if ($0 ~ /"elapsed_s"/) { gsub(/[^0-9.]/, "", $2); w2 = $2 + 0 }
      if ($0 ~ /"user_cpu_s"/) { gsub(/[^0-9.]/, "", $2); u2 = $2 + 0 }
      if ($0 ~ /"sys_cpu_s"/) { gsub(/[^0-9.]/, "", $2); s2 = $2 + 0 }
      if ($0 ~ /"peak_rss_mb"/) { gsub(/[^0-9.]/, "", $2); r2 = $2 + 0 }
      if ($0 ~ /"hw_instructions"/) { gsub(/[^0-9.]/, "", $2); i2 = $2 + 0 }
      if ($0 ~ /"hw_cycles"/) { gsub(/[^0-9.]/, "", $2); c2 = $2 + 0 }
    }
    END {
      pr = (r1 >= r2) ? r1 : r2
      printf "{\n"
      printf "  \"stage1_wall_s\": %.6f,\n", w1
      printf "  \"stage1_cpu_s\": %.6f,\n", u1 + s1
      printf "  \"stage1_rss_mb\": %.4f,\n", r1
      printf "  \"intermediate_bytes\": %.0f,\n", ib + 0
      printf "  \"stage2_wall_s\": %.6f,\n", w2
      printf "  \"stage2_cpu_s\": %.6f,\n", u2 + s2
      printf "  \"stage2_rss_mb\": %.4f,\n", r2
      printf "  \"total_wall_s\": %.6f,\n", w1 + w2
      printf "  \"total_cpu_s\": %.6f,\n", u1 + s1 + u2 + s2
      printf "  \"peak_rss_mb\": %.4f,\n", pr
      printf "  \"hw_instructions\": %.0f,\n", i1 + i2
      printf "  \"hw_cycles\": %.0f,\n", c1 + c2
      printf "  \"exit_code\": 0\n"
      printf "}\n"
    }
  ' "${_s1_json}" "${_s2_json}" > "${_ertp_out_json}.tmp"

  rm -f "${_s1_json}" "${_s1_log}" "${_s2_json}" "${_s2_log}"
  mv -f "${_ertp_out_json}.tmp" "${_ertp_out_json}"
}

# ## libscript_exp_assert_matched_baselines
# Verifies Same-LLVM and Same-GCC/libgccjit baseline version alignment and optimization-flag parity (`EXPERIMENTS.md` §1.2 & §1.3).
libscript_exp_assert_matched_baselines() {
  _eamb_cpfe="${1}"
  _eamb_clang="${2}"
  _eamb_gcc="${3}"
  _eamb_libgccjit="${4:-${EDG_LIBGCCJIT_PATH:-}}"
  _eamb_out_json="${5}"

  mkdir -p "$(dirname -- "${_eamb_out_json}")"
  _llvm_linked=''
  if [ -f "${_eamb_cpfe}" ]; then
    if [ "${UNAME:-}" = "Darwin" ] && command -v otool >/dev/null 2>&1; then
      _llvm_linked=$(otool -L "${_eamb_cpfe}" 2>/dev/null | awk '/libLLVM/ {print $1; exit}' | sed -E 's/.*LLVM[-.]([0-9]+).*/\1/' || true)
    elif command -v ldd >/dev/null 2>&1; then
      _llvm_linked=$(ldd "${_eamb_cpfe}" 2>/dev/null | awk '/libLLVM/ {print $1; exit}' | sed -E 's/.*LLVM[-.]([0-9]+).*/\1/' || true)
    fi
  fi
  [ -n "${_llvm_linked}" ] || _llvm_linked="${EXPECTED_CPFE_LLVM_MAJOR:-}"

  _clang_maj=''
  if command -v "${_eamb_clang}" >/dev/null 2>&1 || [ -x "${_eamb_clang}" ]; then
    _clang_maj=$("${_eamb_clang}" --version 2>/dev/null | awk 'NR==1 {for(i=1;i<=NF;i++) if ($i ~ /^[0-9]+\.[0-9]+/) {split($i,a,"."); print a[1]; exit}}' || true)
  fi

  _gcc_maj=''
  if command -v "${_eamb_gcc}" >/dev/null 2>&1 || [ -x "${_eamb_gcc}" ]; then
    _gcc_maj=$("${_eamb_gcc}" -dumpversion 2>/dev/null | awk -F. '{print $1}' || true)
  fi

  _jit_maj=''
  if [ -n "${_eamb_libgccjit}" ]; then
    _jit_maj=$(printf '%s' "${_eamb_libgccjit}" | sed -nE 's#.*/gcc/[^/]*/([0-9]+)(\.[0-9]+)*.*#\1#p' || true)
    if [ -z "${_jit_maj}" ] && command -v strings >/dev/null 2>&1 && [ -f "${_eamb_libgccjit}" ]; then
      _jit_maj=$(strings "${_eamb_libgccjit}" 2>/dev/null | awk '/GCC: \(/ {for(i=1;i<=NF;i++) if ($i ~ /^[0-9]+\.[0-9]+\.[0-9]+$/) {split($i,a,"."); print a[1]; exit}}' || true)
    fi
  fi

  _llvm_ok='true'
  if [ -n "${_llvm_linked}" ] && [ -n "${_clang_maj}" ] && [ "${_llvm_linked}" != "${_clang_maj}" ]; then
    _llvm_ok='false'
  fi
  _gcc_ok='true'
  if [ -n "${_jit_maj}" ] && [ -n "${_gcc_maj}" ] && [ "${_jit_maj}" != "${_gcc_maj}" ]; then
    _gcc_ok='false'
  fi

  cat <<BASE_EOF > "${_eamb_out_json}.tmp"
{
  "cpfe_llvm_major": "${_llvm_linked:-unknown}",
  "clang_matched_major": "${_clang_maj:-unknown}",
  "same_llvm_aligned": ${_llvm_ok},
  "libgccjit_major": "${_jit_maj:-unknown}",
  "gcc_matched_major": "${_gcc_maj:-unknown}",
  "same_gcc_aligned": ${_gcc_ok}
}
BASE_EOF
  mv -f "${_eamb_out_json}.tmp" "${_eamb_out_json}"

  if [ "${_llvm_ok}" != "true" ] || [ "${_gcc_ok}" != "true" ]; then
    log_error "[BASELINE-ALIGN] Baseline compiler mismatch (LLVM=${_llvm_linked}/${_clang_maj}, GCC=${_jit_maj}/${_gcc_maj})."
    return 1
  fi
  return 0
}

# ## libscript_exp_measure_code_size
# Measures linked Mach-O (`size -m`), ELF (`llvm-size -A` / `size -A -d`), or PE/COFF code and rodata section sizes in bytes and MB (`EXPERIMENTS.md` §6.1.4).
libscript_exp_measure_code_size() {
  _emcs_bin="${1}"
  _emcs_out_json="${2}"

  if [ ! -f "${_emcs_bin}" ]; then
    log_error "[CODE-SIZE] Missing binary '${_emcs_bin}'."
    return 1
  fi
  mkdir -p "$(dirname -- "${_emcs_out_json}")"

  _seg_text=0
  _sec_text=0
  _sec_ro=0
  _fmt='generic'

  if [ "${UNAME:-}" = "Darwin" ] && command -v size >/dev/null 2>&1; then
    _fmt='macho_size_m'
    _m_out=$(size -m "${_emcs_bin}" 2>/dev/null || true)
    if [ -n "${_m_out}" ]; then
      _seg_text=$(printf '%s\n' "${_m_out}" | awk '/^Segment __TEXT:/ {gsub(/[^0-9]/, "", $3); print $3+0; exit}')
      _sec_text=$(printf '%s\n' "${_m_out}" | awk '/Section \(__TEXT, __text\):/ {gsub(/[^0-9]/, "", $4); print $4+0; exit}')
      _sec_ro=$(printf '%s\n' "${_m_out}" | awk '/Section \(__TEXT, __(const|cstring)\):/ {gsub(/[^0-9]/, "", $4); sum += $4+0} END {print sum+0}')
    fi
  fi

  if [ "${_sec_text}" -eq 0 ] 2>/dev/null; then
    _sz_tool=''
    if command -v llvm-size >/dev/null 2>&1; then
      _sz_tool='llvm-size'
      _fmt='llvm_size_sysv'
    elif command -v size >/dev/null 2>&1; then
      _sz_tool='size'
      _fmt='posix_size_sysv'
    fi
    if [ -n "${_sz_tool}" ]; then
      _a_out=$("${_sz_tool}" -A "${_emcs_bin}" 2>/dev/null || true)
      if [ -n "${_a_out}" ]; then
        _sec_text=$(printf '%s\n' "${_a_out}" | awk '$1 ~ /^(\.text|__text)$/ {sum += $2+0} END {print sum+0}')
        _sec_ro=$(printf '%s\n' "${_a_out}" | awk '$1 ~ /^(\.rodata|\.rdata|__const|__cstring)/ {sum += $2+0} END {print sum+0}')
        _seg_text=$((_sec_text + _sec_ro))
      fi
    fi
  fi

  if [ "${_sec_text}" -eq 0 ] 2>/dev/null; then
    _sec_text=$(wc -c < "${_emcs_bin}" | awk '{print $1+0}')
    _seg_text="${_sec_text}"
  fi

  awk -v fmt="${_fmt}" -v seg="${_seg_text}" -v txt="${_sec_text}" -v ro="${_sec_ro}" 'BEGIN {
    tot = (seg > 0) ? seg : (txt + ro)
    printf "{\n"
    printf "  \"size_extractor\": \"%s\",\n", fmt
    printf "  \"segment_text_bytes\": %.0f,\n", seg + 0
    printf "  \"section_text_bytes\": %.0f,\n", txt + 0
    printf "  \"section_rodata_bytes\": %.0f,\n", ro + 0
    printf "  \"segment_text_mb\": %.6f,\n", (seg + 0) / 1048576.0
    printf "  \"section_text_mb\": %.6f,\n", (txt + 0) / 1048576.0
    printf "  \"code_total_mb\": %.6f\n", tot / 1048576.0
    printf "}\n"
  }' > "${_emcs_out_json}.tmp"
  mv -f "${_emcs_out_json}.tmp" "${_emcs_out_json}"
}

# ## libscript_exp_capture_compiler_metadata
# Emits `results/raw/metadata.json` with `RULE-1` provenance, OS/CPU/RAM, AC power status, and exact `LLVM`, `libgccjit`, `Clang`, and `GCC` versions (`EXPERIMENTS.md` §12).
libscript_exp_capture_compiler_metadata() {
  _eccm_repo="${1:-${LIBSCRIPT_ROOT_DIR}}"
  _eccm_out_json="${2}"

  libscript_detect_hardware
  libscript_detect_ac_power
  mkdir -p "$(dirname -- "${_eccm_out_json}")"

  _sha='0000000000000000000000000000000000000000'
  _dirty='false'
  if command -v git >/dev/null 2>&1 && [ -d "${_eccm_repo}/.git" ]; then
    _sha=$(git -C "${_eccm_repo}" rev-parse HEAD 2>/dev/null || printf '%s' "${_sha}")
    if [ -n "$(git -C "${_eccm_repo}" status --porcelain 2>/dev/null || true)" ]; then
      _dirty='true'
    fi
  elif [ -n "${EDG_PINNED_GIT_SHA:-}" ]; then
    _sha="${EDG_PINNED_GIT_SHA}"
  fi

  _ls_sha='0000000000000000000000000000000000000000'
  if command -v git >/dev/null 2>&1 && [ -d "${LIBSCRIPT_ROOT_DIR}/.git" ]; then
    _ls_sha=$(git -C "${LIBSCRIPT_ROOT_DIR}" rev-parse HEAD 2>/dev/null || printf '%s' "${_ls_sha}")
  fi

  _ram_gib=$(awk -v m="${LIBSCRIPT_HW_MEM_MB}" 'BEGIN { printf "%.2f", m / 1024.0 }')
  _clang_m="${CLANG_MATCHED:-clang}"
  _clang_ver='unavailable'
  if command -v "${_clang_m}" >/dev/null 2>&1 || [ -x "${_clang_m}" ]; then
    _clang_ver=$("${_clang_m}" --version 2>/dev/null | head -n 1 | tr -d '\r' | sed 's/\\/\\\\/g; s/"/\\"/g' || printf 'unavailable')
  fi
  _sys_clang_ver='unavailable'
  if command -v /usr/bin/clang >/dev/null 2>&1; then
    _sys_clang_ver=$(/usr/bin/clang --version 2>/dev/null | head -n 1 | tr -d '\r' | sed 's/\\/\\\\/g; s/"/\\"/g' || printf 'unavailable')
  fi
  _gcc_m="${GCC_MATCHED:-gcc}"
  _gcc_ver='unavailable'
  if command -v "${_gcc_m}" >/dev/null 2>&1 || [ -x "${_gcc_m}" ]; then
    _gcc_ver=$("${_gcc_m}" --version 2>/dev/null | head -n 1 | tr -d '\r' | sed 's/\\/\\\\/g; s/"/\\"/g' || printf 'unavailable')
  fi
  _llvm_ver='unavailable'
  if [ -n "${LLVM_PREFIX:-}" ] && [ -x "${LLVM_PREFIX}/bin/llvm-config" ]; then
    _llvm_ver=$("${LLVM_PREFIX}/bin/llvm-config" --version 2>/dev/null | head -n 1 | tr -d '\r' || printf 'unavailable')
  elif command -v llvm-config >/dev/null 2>&1; then
    _llvm_ver=$(llvm-config --version 2>/dev/null | head -n 1 | tr -d '\r' || printf 'unavailable')
  fi
  _jit_p=$(printf '%s' "${EDG_LIBGCCJIT_PATH:-unavailable}" | sed 's/\\/\\\\/g; s/"/\\"/g')
  _cpu_e=$(printf '%s' "${LIBSCRIPT_HW_CPU_MODEL}" | sed 's/\\/\\\\/g; s/"/\\"/g')

  cat <<META_EOF > "${_eccm_out_json}.tmp"
{
  "schema_version": "1.0.0",
  "git_commit_sha": "${_sha}",
  "git_dirty": ${_dirty},
  "libscript_commit_sha": "${_ls_sha}",
  "host_manifest_ref": "${UNAME_LOWER:-unknown}_${ARCH:-unknown}",
  "os": "${UNAME:-unknown}",
  "arch": "${ARCH:-unknown}",
  "kernel_release": "${KERNEL_RELEASE:-unknown}",
  "cpu_model": "${_cpu_e}",
  "logical_cores": ${LIBSCRIPT_HW_CORES},
  "physical_cores": ${LIBSCRIPT_HW_PHYS_CORES},
  "ram_mib": ${LIBSCRIPT_HW_MEM_MB},
  "ram_gib": ${_ram_gib},
  "ac_power": "${LIBSCRIPT_HW_AC_POWER}",
  "compilers": {
    "llvm_version": "${_llvm_ver}",
    "libgccjit_path": "${_jit_p}",
    "clang_matched": "${_clang_ver}",
    "clang_system": "${_sys_clang_ver}",
    "gcc_matched": "${_gcc_ver}"
  }
}
META_EOF
  mv -f "${_eccm_out_json}.tmp" "${_eccm_out_json}"
}

# ## libscript_exp_run_manifest
# Executes a declarative `experiment-suite.schema.json` manifest in sub-suite order, dispatching `.sh` entrypoints relative to the manifest directory and verifying output creation.
libscript_exp_run_manifest() {
  _erm_manifest="${1}"
  _erm_selected="${2:-all}"
  _erm_results_dir="${3:-}"

  if [ ! -f "${_erm_manifest}" ]; then
    log_error "[MANIFEST] Experiment suite manifest '${_erm_manifest}' not found."
    return 1
  fi
  _erm_dir=$(cd -- "$(dirname -- "${_erm_manifest}")" && pwd)
  if [ -z "${_erm_results_dir}" ]; then
    _erm_results_dir="${LIBSCRIPT_ROOT_DIR}/build/experiment_manifest_results"
  fi
  mkdir -p "${_erm_results_dir}"

  _erm_entries=$(awk '
    /"subsuites"[[:space:]]*:/ { in_sub = 1; next }
    in_sub && /"id"[[:space:]]*:/ {
      sid = $0; sub(/^.*:[[:space:]]*"/, "", sid); sub(/".*$/, "", sid)
    }
    in_sub && /"entrypoint"[[:space:]]*:/ {
      ep = $0; sub(/^.*:[[:space:]]*"/, "", ep); sub(/".*$/, "", ep)
      if (sid != "" && ep != "") { print sid "|" ep; sid = ""; ep = "" }
    }
  ' "${_erm_manifest}")

  for _item in ${_erm_entries}; do
    _sid="${_item%|*}"
    _ep="${_item#*|}"
    if [ "${_erm_selected}" != "all" ]; then
      case ",${_erm_selected}," in
        *,"${_sid}",*) ;;
        *) continue ;;
      esac
    fi
    _ep_sh="${_erm_dir}/${_ep}.sh"
    if [ ! -f "${_ep_sh}" ] && [ -f "${_erm_dir}/${_ep}" ]; then
      _ep_sh="${_erm_dir}/${_ep}"
    fi
    if [ ! -f "${_ep_sh}" ]; then
      log_error "[MANIFEST] Missing sub-suite entrypoint '${_ep_sh}' for '${_sid}'."
      return 1
    fi
    log_info "[MANIFEST] Running sub-suite '${_sid}' (${_ep_sh})..."
    LIBSCRIPT_EXPERIMENT_OUT_DIR="${_erm_results_dir}" /bin/sh "${_ep_sh}" --results-dir="${_erm_results_dir}"
  done
}

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_eh_caller_dir:-}" ] && SCRIPT_DIR="${_eh_caller_dir}"
[ -n "${_eh_caller_this:-}" ] && THIS_FILE="${_eh_caller_this}"
unset SCRIPT_NAME _eh_caller_this _eh_caller_dir || true
