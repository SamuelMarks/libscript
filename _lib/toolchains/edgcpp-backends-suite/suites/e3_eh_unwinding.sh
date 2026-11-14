#!/bin/sh
# ## Overview
# Sub-suite E3 runner (`e3_eh_unwinding.sh`): Compiles and benchmarks `c_harnesses/eh_bench.cpp` at `-O2` across Zero-Cost DWARF, Mode B SJLJ+RTTI, and Legacy SJLJ pipelines (`raw/exp3_eh.json` -> Table 5 Rows 1-3).
# ## Usage
# ./_lib/toolchains/edgcpp-backends-suite/suites/e3_eh_unwinding.sh <edg_repo> <results_dir> <host_arch>
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

# ## run_e3_eh_unwinding
# Compiles and times Row 1 (0%-throw RAII), Row 2 (10-frame single-inheritance), and Row 3 (10-frame virtual-diamond `VBase&` catch) at `-O2`.
run_e3_eh_unwinding() {
  mkdir -p "${RESULTS_DIR}/raw"
  if [ -s "${RESULTS_DIR}/raw/exp3_eh.json" ] && [ "${FORCE_REBUILD:-0}" != "1" ]; then
    log_info '[E3] exp3_eh.json already verified (cached).'
    return 0
  fi

  libscript_exp_assert_native_isa
  libscript_exp_ensure_bench_probe
  if [ ! -f "${RESULTS_DIR}/raw/metadata.json" ]; then
    "${SCRIPT_DIR}/e0_phase0_gates.sh" "${EDG_REPO_DIR}" "${RESULTS_DIR}" "${HOST_ARCH}"
  fi
  _sha=$(awk -F'"' '/"git_commit_sha"/ {print $4; exit}' "${RESULTS_DIR}/raw/metadata.json")
  _dirty=$(awk '/"git_dirty"/ {gsub(/[^a-z]/, "", $2); print $2; exit}' "${RESULTS_DIR}/raw/metadata.json")

  _wdir="${RESULTS_DIR}/.work_e3"
  mkdir -p "${_wdir}"
  _edg="${LIBSCRIPT_ROOT_DIR}/_lib/languages/edgcpp/edgcpp_wrapper.sh"
  _cpfe="${EDG_REPO_DIR}/build-rel/src/cpfe"
  _rt="${EDG_REPO_DIR}/build-rel/lib_src/libedg.a"
  _cxx="${CLANGXX_MATCHED:-c++}"

  CPFE_BIN="${_cpfe}" EDG_CPFE_CLI_STYLE='multibackend' EDG_BACKEND='llvm' EDGCPP_DRIVER_LANG='c++' "${_edg}" -std=c++17 -O2 "${SUITE_ROOT}/c_harnesses/eh_bench.cpp" -o "${_wdir}/eh_edg_llvm"
  CPFE_BIN="${_cpfe}" EDG_CPFE_CLI_STYLE='multibackend' EDG_BACKEND='gcc' EDG_RT_LIB="${_rt}" EDGCPP_DRIVER_LANG='c++' "${_edg}" -std=c++17 -O2 "${SUITE_ROOT}/c_harnesses/eh_bench.cpp" -o "${_wdir}/eh_edg_gcc"
  "${_cxx}" -std=c++17 -O2 "${SUITE_ROOT}/c_harnesses/eh_bench.cpp" -o "${_wdir}/eh_clang"

  _r1_it=100000000
  _r23_it=100000
  if [ "${EDGCPP_BACKENDS_SUITE_SYNTHETIC:-0}" = "1" ]; then
    _r1_it=50000
    _r23_it=500
  fi

  for _b in eh_edg_llvm eh_edg_gcc eh_clang; do
    "${LIBSCRIPT_BENCH_PROBE_BIN}" --json-out "${_wdir}/${_b}_raii.json" --exec "${_wdir}/${_b}" "--mode=raii" "--iters=${_r1_it}"
    "${LIBSCRIPT_BENCH_PROBE_BIN}" --json-out "${_wdir}/${_b}_single.json" --exec "${_wdir}/${_b}" "--mode=single" "--iters=${_r23_it}"
    "${LIBSCRIPT_BENCH_PROBE_BIN}" --json-out "${_wdir}/${_b}_diamond.json" --exec "${_wdir}/${_b}" "--mode=diamond" "--iters=${_r23_it}"
  done

  _llvm_raii=$(awk -F: '/"elapsed_ms"/ {gsub(/[^0-9.]/, "", $2); print $2}' "${_wdir}/eh_edg_llvm_raii.json")
  _llvm_sng=$(awk -F: '/"elapsed_ms"/ {gsub(/[^0-9.]/, "", $2); print $2}' "${_wdir}/eh_edg_llvm_single.json")
  _llvm_dia=$(awk -F: '/"elapsed_ms"/ {gsub(/[^0-9.]/, "", $2); print $2}' "${_wdir}/eh_edg_llvm_diamond.json")
  _gcc_raii=$(awk -F: '/"elapsed_ms"/ {gsub(/[^0-9.]/, "", $2); print $2}' "${_wdir}/eh_edg_gcc_raii.json")
  _gcc_sng=$(awk -F: '/"elapsed_ms"/ {gsub(/[^0-9.]/, "", $2); print $2}' "${_wdir}/eh_edg_gcc_single.json")
  _gcc_dia=$(awk -F: '/"elapsed_ms"/ {gsub(/[^0-9.]/, "", $2); print $2}' "${_wdir}/eh_edg_gcc_diamond.json")
  _clg_raii=$(awk -F: '/"elapsed_ms"/ {gsub(/[^0-9.]/, "", $2); print $2}' "${_wdir}/eh_clang_raii.json")
  _clg_dia=$(awk -F: '/"elapsed_ms"/ {gsub(/[^0-9.]/, "", $2); print $2}' "${_wdir}/eh_clang_diamond.json")

  cat <<E3_EOF > "${RESULTS_DIR}/raw/exp3_eh.json.tmp"
{
  "schema_version": "1.0.0",
  "suite": "E3",
  "host_arch": "${HOST_ARCH}",
  "git_commit_sha": "${_sha}",
  "git_dirty": ${_dirty},
  "host_manifest_ref": "raw/metadata.json",
  "edg_llvm_dwarf": {
    "raii_fast_path_ms": ${_llvm_raii},
    "single_inherit_throw_ms": ${_llvm_sng},
    "virtual_diamond_throw_ms": ${_llvm_dia}
  },
  "edg_gcc_sjlj_rtti": {
    "raii_fast_path_ms": ${_gcc_raii},
    "single_inherit_throw_ms": ${_gcc_sng},
    "virtual_diamond_throw_ms": ${_gcc_dia}
  },
  "native_clang_dwarf": {
    "raii_fast_path_ms": ${_clg_raii},
    "virtual_diamond_throw_ms": ${_clg_dia}
  }
}
E3_EOF
  mv -f "${RESULTS_DIR}/raw/exp3_eh.json.tmp" "${RESULTS_DIR}/raw/exp3_eh.json"
  rm -rf "${_wdir}"
  log_info "[E3] Verified C++ exception unwinding rows (RAII, single-inheritance, virtual-diamond VBase&) -> ${RESULTS_DIR}/raw/exp3_eh.json"
}

run_e3_eh_unwinding
