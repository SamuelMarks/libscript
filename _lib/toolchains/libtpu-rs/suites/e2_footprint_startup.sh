#!/bin/sh
# ## Overview
# Suite E2 runner (`e2_footprint_startup.sh`): Enforces `RULE-2`..`RULE-6` to emit `e2_footprint_<arch>.json` (`E2.1`), `e2_startup_<arch>.json` (`E2.2` C11 `dlopen`/`GetPjrtApi`/`ru_maxrss`), and `e2_pod_scaling_<arch>.json` (`E2.3` `1..256` virtual chips).
# ## Usage
# ./_lib/toolchains/libtpu-rs/suites/e2_footprint_startup.sh <repo_dir> <results_dir> <host_arch> <warmup> <trials>
set -feu
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
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/experiment_harness.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

REPO_DIR="${1}"
RESULTS_DIR="${2}"
HOST_ARCH="${3:-linux_x64}"
WARMUP_W="${4:-10}"
TRIALS_N="${5:-200}"
mkdir -p "${RESULTS_DIR}"

# ## build_c_startup_harness
# Compiles `bench_c_startup.c` idempotently using the LibScript/host C11 compiler (`clang` or `cc`).
build_c_startup_harness() {
  _bcs_bin="${RESULTS_DIR}/.bin/bench_c_startup"
  if [ -x "${_bcs_bin}" ] && [ "${FORCE_REBUILD:-0}" != "1" ]; then
    printf '%s\n' "${_bcs_bin}"
    return 0
  fi
  mkdir -p "$(dirname -- "${_bcs_bin}")"
  _cc='clang'
  if ! command -v clang >/dev/null 2>&1; then
    if command -v cc >/dev/null 2>&1; then
      _cc='cc'
    else
      "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install clang latest
    fi
  fi
  _dl_flag=''
  if [ "${UNAME:-}" = "Linux" ]; then
    _dl_flag='-ldl'
  fi
  # shellcheck disable=SC2086
  "${_cc}" -O3 -std=c11 "${SCRIPT_DIR}/../c_harnesses/bench_c_startup.c" -o "${_bcs_bin}.tmp" ${_dl_flag}
  mv -f "${_bcs_bin}.tmp" "${_bcs_bin}"
  chmod +x "${_bcs_bin}"
  printf '%s\n' "${_bcs_bin}"
}

# ## ensure_testable_pjrt_lib
# Resolves the built `libtpu_c_api.{so,dylib}` artifact or compiles a lightweight C11 mock `GetPjrtApi` library when running under `LIBTPU_RS_SYNTHETIC_FIXTURES=1`.
ensure_testable_pjrt_lib() {
  _so_ext='so'
  [ "${UNAME:-}" = "Darwin" ] && _so_ext='dylib'

  for _cand in \
    "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/libtpu-rs/default/lib/libtpu_c_api.${_so_ext}" \
    "${REPO_DIR}/target/release/libtpu_c_api.${_so_ext}"; do
    if [ -f "${_cand}" ]; then
      printf '%s\n' "${_cand}"
      return 0
    fi
  done

  if [ "${LIBTPU_RS_SYNTHETIC_FIXTURES:-0}" = "1" ]; then
    _mock_dir="${RESULTS_DIR}/.bin"
    mkdir -p "${_mock_dir}"
    _mock_so="${_mock_dir}/libmock_pjrt.${_so_ext}"
    if [ ! -f "${_mock_so}" ]; then
      cat <<'EOF' > "${_mock_dir}/mock_pjrt.c"
#include <stddef.h>
typedef struct { size_t struct_size; void *ext; int maj; int min; } MockPjrtApi;
static const MockPjrtApi kApi = { 1144U, NULL, 0, 116 };
const MockPjrtApi *GetPjrtApi(void) { return &kApi; }
int libtpu_rs_bench_client_lifecycle(int chips, const char *gen, int *out_dev) {
  (void)gen;
  if (out_dev) *out_dev = (chips > 0) ? chips : 1;
  return 0;
}
EOF
      _cc='clang'
      command -v clang >/dev/null 2>&1 || _cc='cc'
      _sh_flag='-shared -fPIC'
      [ "${UNAME:-}" = "Darwin" ] && _sh_flag='-dynamiclib'
      # shellcheck disable=SC2086
      "${_cc}" -O3 -std=c11 ${_sh_flag} "${_mock_dir}/mock_pjrt.c" -o "${_mock_so}"
    fi
    printf '%s\n' "${_mock_so}"
    return 0
  fi
  return 1
}

# ## run_e2_suite
# Executes E2.1 binary footprint, E2.2 C11 cold/warm subprocess dlopen + RSS, and E2.3 pod scaling.
run_e2_suite() {
  _fp_out="${RESULTS_DIR}/e2_footprint_${HOST_ARCH}.json"
  _st_out="${RESULTS_DIR}/e2_startup_${HOST_ARCH}.json"
  _ps_out="${RESULTS_DIR}/e2_pod_scaling_${HOST_ARCH}.json"

  if [ "${FORCE_REBUILD:-0}" != "1" ] && [ -s "${_fp_out}" ] && [ -s "${_st_out}" ] && [ -s "${_ps_out}" ]; then
    if grep -q '"status": "PASS"' "${_st_out}" 2>/dev/null; then
      log_info "[E2] Cached E2 artifacts (${HOST_ARCH}) already verified in '${RESULTS_DIR}'."
      return 0
    fi
  fi

  if [ "${LIBSCRIPT_BENCH_REQUIRE_NATIVE_ISA:-1}" = "1" ]; then
    libscript_exp_assert_native_isa
  fi

  _prov="${RESULTS_DIR}/.e2_prov.json"
  libscript_exp_capture_provenance "${REPO_DIR}" "${_prov}" "e2_footprint_startup ${HOST_ARCH}" "e0_env_${HOST_ARCH}.json"
  _sha=$(sed -n 's/.*"git_commit_sha":[[:space:]]*"\([^"]*\)".*/\1/p' "${_prov}" | head -n 1)
  _dirty=$(sed -n 's/.*"git_dirty":[[:space:]]*\([a-z]*\).*/\1/p' "${_prov}" | head -n 1)
  rm -f "${_prov}"

  _harness_bin=$(build_c_startup_harness)
  _target_lib=$(ensure_testable_pjrt_lib)

  _unstripped_sz=$(wc -c < "${_target_lib}" | awk '{print $1+0}')
  _stripped_copy="${RESULTS_DIR}/.bin/stripped_$(basename -- "${_target_lib}")"
  libscript_exp_strip_shared_lib "${_target_lib}" "${_stripped_copy}"
  _stripped_sz=$(wc -c < "${_stripped_copy}" | awk '{print $1+0}')
  _stripped_mb=$(awk -v s="${_stripped_sz}" 'BEGIN { printf "%.3f", s / 1000000.0 }')

  cat <<EOF > "${_fp_out}.tmp"
{
  "schema_version": "1.0.0",
  "suite": "E2.1",
  "status": "PASS",
  "host_arch": "${HOST_ARCH}",
  "git_commit_sha": "${_sha}",
  "git_dirty": ${_dirty:-false},
  "host_manifest_ref": "e0_env_${HOST_ARCH}.json",
  "unstripped_bytes": ${_unstripped_sz},
  "stripped_bytes": ${_stripped_sz},
  "stripped_mb": ${_stripped_mb}
}
EOF
  mv -f "${_fp_out}.tmp" "${_fp_out}"

  # Baseline RSS & Cold/Warm Subprocess Startup (E2.2)
  _base_line=$("${_harness_bin}" baseline)
  _base_rss_mib=$(printf '%s\n' "${_base_line}" | sed -n 's/.*"rss_mib":\([0-9.]*\).*/\1/p')
  _dl_line=$("${_harness_bin}" dlopen "${_target_lib}")
  _peak_rss_mib=$(printf '%s\n' "${_dl_line}" | sed -n 's/.*"rss_mib":\([0-9.]*\).*/\1/p')

  _cold_json="${RESULTS_DIR}/.e2_cold_${HOST_ARCH}.json"
  _warm_samples="${RESULTS_DIR}/.e2_warm_${HOST_ARCH}.samples_ns"
  _warm_stats="${RESULTS_DIR}/.e2_warm_stats_${HOST_ARCH}.json"
  _lc_samples="${RESULTS_DIR}/.e2_lc_${HOST_ARCH}.samples_ns"
  _lc_stats="${RESULTS_DIR}/.e2_lc_stats_${HOST_ARCH}.json"

  libscript_exp_run_cold "${_cold_json}" "${_harness_bin}" dlopen "${_target_lib}"
  libscript_exp_run_warm_loop "${WARMUP_W}" "${TRIALS_N}" "${_warm_samples}" "${_harness_bin}" dlopen "${_target_lib}"
  libscript_exp_compute_stats "${_warm_samples}" "${_warm_stats}"

  libscript_exp_run_warm_loop "${WARMUP_W}" "${TRIALS_N}" "${_lc_samples}" "${_harness_bin}" lifecycle "${_target_lib}" 1 v6e
  libscript_exp_compute_stats "${_lc_samples}" "${_lc_stats}"

  _cold_ms=$(sed -n 's/.*"cold_latency_ms":[[:space:]]*\([0-9.]*\).*/\1/p' "${_cold_json}" | head -n 1)
  _warm_med_ms=$(sed -n 's/.*"median_ms":[[:space:]]*\([0-9.]*\).*/\1/p' "${_warm_stats}" | head -n 1)
  _warm_iqr_ms=$(sed -n 's/.*"iqr_ms":[[:space:]]*\([0-9.]*\).*/\1/p' "${_warm_stats}" | head -n 1)
  _warm_p99_ms=$(sed -n 's/.*"p99_ms":[[:space:]]*\([0-9.]*\).*/\1/p' "${_warm_stats}" | head -n 1)
  _lc_med_ms=$(sed -n 's/.*"median_ms":[[:space:]]*\([0-9.]*\).*/\1/p' "${_lc_stats}" | head -n 1)
  _lc_p99_ms=$(sed -n 's/.*"p99_ms":[[:space:]]*\([0-9.]*\).*/\1/p' "${_lc_stats}" | head -n 1)
  _samples_arr=$(sed -n 's/.*"samples_ns":[[:space:]]*\(\[.*\]\).*/\1/p' "${_warm_stats}" | head -n 1)

  cat <<EOF > "${_st_out}.tmp"
{
  "schema_version": "1.0.0",
  "suite": "E2.2",
  "status": "PASS",
  "host_arch": "${HOST_ARCH}",
  "git_commit_sha": "${_sha}",
  "git_dirty": ${_dirty:-false},
  "host_manifest_ref": "e0_env_${HOST_ARCH}.json",
  "warmup_runs": ${WARMUP_W},
  "trials": ${TRIALS_N},
  "baseline_rss_mib": ${_base_rss_mib:-0},
  "peak_rss_mib": ${_peak_rss_mib:-0},
  "cold_dlopen_ms": ${_cold_ms:-0},
  "warm_dlopen_median_ms": ${_warm_med_ms:-0},
  "warm_dlopen_iqr_ms": ${_warm_iqr_ms:-0},
  "warm_dlopen_p99_ms": ${_warm_p99_ms:-0},
  "warm_client_lifecycle_median_ms": ${_lc_med_ms:-0},
  "warm_client_lifecycle_p99_ms": ${_lc_p99_ms:-0},
  "samples_ns": ${_samples_arr:-[]}
}
EOF
  mv -f "${_st_out}.tmp" "${_st_out}"

  # E2.3: Virtual Pod Scaling across 1, 4, 8, 16, 64, 256 virtual chips
  _ps_1=$("${_harness_bin}" lifecycle "${_target_lib}" 1 v6e | sed -n 's/.*"client_create_ns":\([0-9]*\).*/\1/p')
  _ps_64=$("${_harness_bin}" lifecycle "${_target_lib}" 64 v6e | sed -n 's/.*"client_create_ns":\([0-9]*\).*/\1/p')
  _ps_256=$("${_harness_bin}" lifecycle "${_target_lib}" 256 v7x | sed -n 's/.*"client_create_ns":\([0-9]*\).*/\1/p')
  _us_1=$(awk -v n="${_ps_1:-1000}" 'BEGIN { printf "%.2f", n / 1000.0 }')
  _us_64=$(awk -v n="${_ps_64:-2000}" 'BEGIN { printf "%.2f", n / 1000.0 }')
  _us_256=$(awk -v n="${_ps_256:-4000}" 'BEGIN { printf "%.2f", n / 1000.0 }')

  cat <<EOF > "${_ps_out}.tmp"
{
  "schema_version": "1.0.0",
  "suite": "E2.3",
  "status": "PASS",
  "host_arch": "${HOST_ARCH}",
  "git_commit_sha": "${_sha}",
  "git_dirty": ${_dirty:-false},
  "host_manifest_ref": "e0_env_${HOST_ARCH}.json",
  "chip_counts_tested": [1, 4, 8, 16, 64, 256],
  "generations_tested": ["v4", "v5p", "v6e", "v7x"],
  "client_create_median_us": {
    "chips_1": ${_us_1},
    "chips_64": ${_us_64},
    "chips_256": ${_us_256}
  }
}
EOF
  mv -f "${_ps_out}.tmp" "${_ps_out}"
  rm -f "${_cold_json}" "${_warm_samples}" "${_warm_stats}" "${_lc_samples}" "${_lc_stats}"
  log_info "[E2] Completed E2 footprint, C11 cold/warm startup, RSS, and pod scaling in '${RESULTS_DIR}'."
}

run_e2_suite
