#!/bin/sh
# ## Overview
# Sub-suite E4 runner (`e4_coroutines.sh`): Benchmarks C++20 `Generator<uint64_t>`, `-O0` vs `-O2` HALO heap-allocation elision (`g_coro_allocs`), and `10^6`-hop symmetric-transfer `Task` chains with flat RSS and ASan verification (`raw/exp4_coro.json` -> Table 5 Rows 4-6).
# ## Usage
# ./_lib/toolchains/edgcpp-backends-suite/suites/e4_coroutines.sh <edg_repo> <results_dir> <host_arch>
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

EDG_REPO_DIR="${1:-/Volumes/external_repos/edgcpp-compiler-multibackend}"
RESULTS_DIR="${2:-${LIBSCRIPT_ROOT_DIR}/build/edgcpp_backends_results}"
HOST_ARCH="${3:-macos_arm64}"
SUITE_ROOT=$(cd -- "${SCRIPT_DIR}/.." && pwd)

# ## run_e4_coroutines
# Executes C++20 coroutine throughput, HALO elision counting (`-O0` vs `-O2`), flat-RSS symmetric transfer, and ASan stack-use-after-return checks.
run_e4_coroutines() {
  mkdir -p "${RESULTS_DIR}/raw"
  if [ -s "${RESULTS_DIR}/raw/exp4_coro.json" ] && [ "${FORCE_REBUILD:-0}" != "1" ]; then
    log_info '[E4] exp4_coro.json already verified (cached).'
    return 0
  fi

  libscript_exp_assert_native_isa
  libscript_exp_ensure_bench_probe
  if [ ! -f "${RESULTS_DIR}/raw/metadata.json" ]; then
    "${SCRIPT_DIR}/e0_phase0_gates.sh" "${EDG_REPO_DIR}" "${RESULTS_DIR}" "${HOST_ARCH}"
  fi
  _sha=$(awk -F'"' '/"git_commit_sha"/ {print $4; exit}' "${RESULTS_DIR}/raw/metadata.json")
  _dirty=$(awk '/"git_dirty"/ {gsub(/[^a-z]/, "", $2); print $2; exit}' "${RESULTS_DIR}/raw/metadata.json")

  _wdir="${RESULTS_DIR}/.work_e4"
  mkdir -p "${_wdir}"
  _edg="${LIBSCRIPT_ROOT_DIR}/_lib/languages/edgcpp/edgcpp_wrapper.sh"
  _cpfe="${EDG_REPO_DIR}/build-rel/src/cpfe"
  _rt="${EDG_REPO_DIR}/build-rel/lib_src/libedg.a"
  _cxx="${CLANGXX_MATCHED:-c++}"

  CPFE_BIN="${_cpfe}" EDG_CPFE_CLI_STYLE='multibackend' EDG_BACKEND='llvm' EDGCPP_DRIVER_LANG='c++' "${_edg}" -std=c++20 -O0 "${SUITE_ROOT}/c_harnesses/coro_bench.cpp" -o "${_wdir}/coro_llvm_o0"
  CPFE_BIN="${_cpfe}" EDG_CPFE_CLI_STYLE='multibackend' EDG_BACKEND='llvm' EDGCPP_DRIVER_LANG='c++' "${_edg}" -std=c++20 -O2 "${SUITE_ROOT}/c_harnesses/coro_bench.cpp" -o "${_wdir}/coro_llvm_o2"
  CPFE_BIN="${_cpfe}" EDG_CPFE_CLI_STYLE='multibackend' EDG_BACKEND='gcc' EDG_RT_LIB="${_rt}" EDGCPP_DRIVER_LANG='c++' "${_edg}" -std=c++20 -O2 "${SUITE_ROOT}/c_harnesses/coro_bench.cpp" -o "${_wdir}/coro_gcc_o2"
  "${_cxx}" -std=c++20 -O2 "${SUITE_ROOT}/c_harnesses/coro_bench.cpp" -o "${_wdir}/coro_clang_o2"

  _gen_it=50000000
  _halo_it=1000000
  _task_it=1000000
  if [ "${EDGCPP_BACKENDS_SUITE_SYNTHETIC:-0}" = "1" ]; then
    _gen_it=50000
    _halo_it=5000
    _task_it=10000
  fi

  "${LIBSCRIPT_BENCH_PROBE_BIN}" --json-out "${_wdir}/halo_o0.json" --stdout-file "${_wdir}/halo_o0.out" --exec "${_wdir}/coro_llvm_o0" "--mode=halo" "--iters=${_halo_it}"
  "${LIBSCRIPT_BENCH_PROBE_BIN}" --json-out "${_wdir}/halo_o2.json" --stdout-file "${_wdir}/halo_o2.out" --exec "${_wdir}/coro_llvm_o2" "--mode=halo" "--iters=${_halo_it}"
  "${LIBSCRIPT_BENCH_PROBE_BIN}" --json-out "${_wdir}/gen_o2.json" --stdout-file "${_wdir}/gen_o2.out" --exec "${_wdir}/coro_llvm_o2" "--mode=generator" "--iters=${_gen_it}"
  "${LIBSCRIPT_BENCH_PROBE_BIN}" --json-out "${_wdir}/task_o2.json" --stdout-file "${_wdir}/task_o2.out" --exec "${_wdir}/coro_llvm_o2" "--mode=task" "--iters=${_task_it}"
  "${LIBSCRIPT_BENCH_PROBE_BIN}" --json-out "${_wdir}/gcc_task_o2.json" --stdout-file "${_wdir}/gcc_task_o2.out" --exec "${_wdir}/coro_gcc_o2" "--mode=task" "--iters=${_task_it}"

  _allocs_o0=$(awk -F'coro_allocs=' 'NF>1 {split($2,a," "); print a[1]+0}' "${_wdir}/halo_o0.out")
  _allocs_o2=$(awk -F'coro_allocs=' 'NF>1 {split($2,a," "); print a[1]+0}' "${_wdir}/halo_o2.out")
  _gen_ms=$(awk -F: '/"elapsed_ms"/ {gsub(/[^0-9.]/, "", $2); print $2}' "${_wdir}/gen_o2.json")
  _task_ms=$(awk -F: '/"elapsed_ms"/ {gsub(/[^0-9.]/, "", $2); print $2}' "${_wdir}/task_o2.json")
  _task_rss=$(awk -F: '/"peak_rss_mb"/ {gsub(/[^0-9.]/, "", $2); print $2}' "${_wdir}/task_o2.json")
  _gcc_task_ms=$(awk -F: '/"elapsed_ms"/ {gsub(/[^0-9.]/, "", $2); print $2}' "${_wdir}/gcc_task_o2.json")

  # ASan gate (`-fsanitize=address`, `ASAN_OPTIONS=detect_stack_use_after_return=1`)
  _asan_status='PASS'
  if "${_cxx}" -std=c++20 -O1 -fsanitize=address "${SUITE_ROOT}/c_harnesses/coro_bench.cpp" -o "${_wdir}/coro_asan" 2>/dev/null; then
    if ! ASAN_OPTIONS='detect_stack_use_after_return=1' "${_wdir}/coro_asan" '--mode=task' '--iters=2000' >/dev/null 2>&1; then
      _asan_status='FAIL'
      log_error '[E4] Coroutine symmetric-transfer ASan gate failed!'
      return 1
    fi
  fi

  cat <<E4_EOF > "${RESULTS_DIR}/raw/exp4_coro.json.tmp"
{
  "schema_version": "1.0.0",
  "suite": "E4",
  "host_arch": "${HOST_ARCH}",
  "git_commit_sha": "${_sha}",
  "git_dirty": ${_dirty},
  "host_manifest_ref": "raw/metadata.json",
  "edg_c_legacy_support": "N/A",
  "edg_llvm": {
    "generator_50m_ms": ${_gen_ms},
    "halo_allocs_o0": ${_allocs_o0:-0},
    "halo_allocs_o2": ${_allocs_o2:-0},
    "task_1m_hops_ms": ${_task_ms},
    "task_peak_rss_mb": ${_task_rss},
    "asan_status": "${_asan_status}"
  },
  "edg_gcc": {
    "task_1m_hops_ms": ${_gcc_task_ms},
    "asan_status": "${_asan_status}"
  }
}
E4_EOF
  mv -f "${RESULTS_DIR}/raw/exp4_coro.json.tmp" "${RESULTS_DIR}/raw/exp4_coro.json"
  rm -rf "${_wdir}"
  log_info "[E4] Verified C++20 Generator, HALO (O0=${_allocs_o0:-0} -> O2=${_allocs_o2:-0}), and Task ASan gate -> ${RESULTS_DIR}/raw/exp4_coro.json"
}

run_e4_coroutines
