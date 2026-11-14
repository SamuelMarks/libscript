#!/bin/sh
# ## Overview
# Sub-suite E1 runner (`e1_compile_perf.sh`): Executes matched-optimization single-TU compilation latency, phase split (`fe_cpu_s` / `be_cpu_s`), Peak RSS, and hardware counter benchmarks across all 7 compiler pipelines (`raw/exp1_compile_perf.json` -> Table 4).
# ## Usage
# ./_lib/toolchains/edgcpp-backends-suite/suites/e1_compile_perf.sh <edg_repo> <results_dir> <host_arch>
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

# ## stage_e1_workloads
# Stages `sqlite3.c`, `shell.c`, C11-generated `cpp_crtp_bench.cpp`, `fmt_inst.cpp`, and C++20 `stl_suite.cpp` with exact raw and preprocessed LoC accounting.
stage_e1_workloads() {
  _wdir="${1}"
  mkdir -p "${_wdir}"

  _gen_bin="${_wdir}/gen_crtp_bench"
  _cc_host="${CLANG_MATCHED:-cc}"
  _cxx_host="${CLANGXX_MATCHED:-c++}"
  "${_cc_host}" -std=c11 -O2 "${SUITE_ROOT}/c_harnesses/gen_crtp_bench.c" -o "${_gen_bin}"
  _crtp_n=350
  if [ "${EDGCPP_BACKENDS_SUITE_SYNTHETIC:-0}" = "1" ]; then
    _crtp_n=24
  fi
  "${_gen_bin}" --classes "${_crtp_n}" -o "${_wdir}/cpp_crtp_bench.cpp"
  cp "${SUITE_ROOT}/c_harnesses/stl_suite.cpp" "${_wdir}/stl_suite.cpp"

  if [ "${EDGCPP_BACKENDS_SUITE_SYNTHETIC:-0}" = "1" ]; then
    cat <<'SQ_SYN' > "${_wdir}/sqlite3.c"
#include <stdint.h>
int sqlite3_libversion_number(void) { return 3046001; }
uint64_t sqlite3_hash_step(uint64_t h, int x) { return (h * 1315423911ULL) ^ (uint64_t)x; }
SQ_SYN
    cat <<'SH_SYN' > "${_wdir}/shell.c"
extern int sqlite3_libversion_number(void);
int main(void) { return sqlite3_libversion_number() == 3046001 ? 0 : 1; }
SH_SYN
    cat <<'FMT_SYN' > "${_wdir}/fmt_inst.cpp"
#include <cstdio>
#include <string>
std::string fmt_uint(unsigned long v) { char b[32]; std::snprintf(b, sizeof(b), "%lu", v); return b; }
FMT_SYN
  else
    SQLITE_VERSION='3.46.1' SQLITE_STAGE_DIR="${_wdir}" ACTION='stage-benchmark-inputs' "${LIBSCRIPT_ROOT_DIR}/_lib/databases/sqlite/setup_generic.sh" >/dev/null
    if [ -n "${FMT_SOURCE_DIR:-}" ] && [ -f "${FMT_SOURCE_DIR}/src/format.cc" ]; then
      cp "${FMT_SOURCE_DIR}/src/format.cc" "${_wdir}/fmt_inst.cpp"
    else
      cp "${_wdir}/cpp_crtp_bench.cpp" "${_wdir}/fmt_inst.cpp"
    fi
  fi

  LOC_SQLITE3=$(wc -l < "${_wdir}/sqlite3.c" | awk '{print $1+0}')
  LOC_SHELL=$(wc -l < "${_wdir}/shell.c" | awk '{print $1+0}')
  LOC_CRTP=$(wc -l < "${_wdir}/cpp_crtp_bench.cpp" | awk '{print $1+0}')
  LOC_FMT=$(wc -l < "${_wdir}/fmt_inst.cpp" | awk '{print $1+0}')
  LOC_STL_PRE=$("${_cxx_host}" -std=c++20 -E -P "${_wdir}/stl_suite.cpp" 2>/dev/null | wc -l | awk '{print $1+0}')
  if [ "${LOC_STL_PRE}" -eq 0 ]; then
    LOC_STL_PRE=$(wc -l < "${_wdir}/stl_suite.cpp" | awk '{print $1+0}')
  fi
}

# ## time_single_pipeline_cell
# Executes 1 untimed warmup + N timed runs (`-j1`) for a `(pipeline, src, std, opt)` cell and writes per-cell JSON stats.
time_single_pipeline_cell() {
  _pipe="${1}"
  _src="${2}"
  _lang="${3}"
  _std="${4}"
  _opt="${5}"
  _out_cell="${6}"

  _trials="${EDGCPP_BACKENDS_SUITE_TRIALS:-11}"
  if [ "${EDGCPP_BACKENDS_SUITE_SYNTHETIC:-0}" = "1" ]; then
    _trials=3
  fi
  _warm="${EDGCPP_BACKENDS_SUITE_WARMUPS:-1}"
  _edg_drv="${LIBSCRIPT_ROOT_DIR}/_lib/languages/edgcpp/edgcpp_wrapper.sh"
  _cpfe="${EDG_REPO_DIR}/build-rel/src/cpfe"
  _clang="${CLANG_MATCHED:-clang}"
  _clangxx="${CLANGXX_MATCHED:-clang++}"
  _gcc="${GCC_MATCHED:-gcc}"
  _gxx="${GXX_MATCHED:-g++}"
  if ! command -v "${_gcc}" >/dev/null 2>&1; then _gcc="${_clang}"; fi
  if ! command -v "${_gxx}" >/dev/null 2>&1; then _gxx="${_clangxx}"; fi

  _samples="${_out_cell}.samples_ns"
  : > "${_samples}"
  _obj="${_out_cell}.o"
  _log="${_out_cell}.timing.log"
  _prb="${_out_cell}.probe.json"
  _tot=$((_warm + _trials))
  _idx=1
  _last_rss='0.0000'
  _last_inst='0'
  _last_fe='0.000000'
  _last_be='0.000000'

  while [ "${_idx}" -le "${_tot}" ]; do
    case "${_pipe}" in
      EDG-FE-ONLY)
        # shellcheck disable=SC2086
        CPFE_BIN="${_cpfe}" EDG_CPFE_CLI_STYLE='multibackend' EDG_BACKEND='fe-only' "${LIBSCRIPT_BENCH_PROBE_BIN}" --json-out "${_prb}" --stderr-file "${_log}" --exec "${_edg_drv}" "-std=${_std}" ${_opt} -c "${_src}" -o "${_obj}"
        ;;
      EDG-LLVM)
        # shellcheck disable=SC2086
        CPFE_BIN="${_cpfe}" EDG_CPFE_CLI_STYLE='multibackend' EDG_BACKEND='llvm' "${LIBSCRIPT_BENCH_PROBE_BIN}" --json-out "${_prb}" --stderr-file "${_log}" --exec "${_edg_drv}" "-std=${_std}" ${_opt} -c "${_src}" -o "${_obj}"
        ;;
      EDG-GCC)
        # shellcheck disable=SC2086
        CPFE_BIN="${_cpfe}" EDG_CPFE_CLI_STYLE='multibackend' EDG_BACKEND='gcc' "${LIBSCRIPT_BENCH_PROBE_BIN}" --json-out "${_prb}" --stderr-file "${_log}" --exec "${_edg_drv}" "-std=${_std}" ${_opt} -c "${_src}" -o "${_obj}"
        ;;
      EDG-C-LEGACY)
        _int_c="${_out_cell}.int.c"
        libscript_exp_run_two_stage_pipeline "${_prb}" "${_int_c}" "\"${_cpfe}\" --c11 --gnu_version=130200 --c-be --timing --gen_c_file_name=\"${_int_c}\" \"${_src}\"" "\"${_clang}\" -x c ${_opt} -w -c \"${_int_c}\" -o \"${_obj}\""
        ;;
      EDG-CPP-LEGACY)
        _int_cpp="${_out_cell}.int.cpp"
        libscript_exp_run_two_stage_pipeline "${_prb}" "${_int_cpp}" "\"${_cpfe}\" --c++17 --gnu_version=130200 --timing --gen_c_file_name=\"${_int_cpp}\" \"${_src}\"" "\"${_clangxx}\" -std=${_std} ${_opt} -w -c \"${_int_cpp}\" -o \"${_obj}\""
        ;;
      NATIVE-CLANG)
        _nc="${_clang}"
        [ "${_lang}" = "cxx" ] && _nc="${_clangxx}"
        # shellcheck disable=SC2086
        "${LIBSCRIPT_BENCH_PROBE_BIN}" --json-out "${_prb}" --stderr-file "${_log}" --exec "${_nc}" "-std=${_std}" ${_opt} -c "${_src}" -o "${_obj}"
        ;;
      NATIVE-GCC)
        _ng="${_gcc}"
        [ "${_lang}" = "cxx" ] && _ng="${_gxx}"
        # shellcheck disable=SC2086
        "${LIBSCRIPT_BENCH_PROBE_BIN}" --json-out "${_prb}" --stderr-file "${_log}" --exec "${_ng}" "-std=${_std}" ${_opt} -c "${_src}" -o "${_obj}"
        ;;
    esac

    if [ "${_idx}" -gt "${_warm}" ]; then
      if grep -q '"total_wall_s"' "${_prb}" 2>/dev/null; then
        awk -F: '/"total_wall_s"/ {gsub(/[^0-9.]/, "", $2); printf "%.0f\n", ($2+0)*1000000000.0}' "${_prb}" >> "${_samples}"
      else
        awk -F: '/"elapsed_ns"/ {gsub(/[^0-9]/, "", $2); print $2}' "${_prb}" >> "${_samples}"
      fi
      _last_rss=$(awk -F: '/"peak_rss_mb"/ {gsub(/[^0-9.]/, "", $2); print $2; exit}' "${_prb}")
      _last_inst=$(awk -F: '/"hw_instructions"/ {gsub(/[^0-9]/, "", $2); print $2+0; exit}' "${_prb}")
      if [ -f "${_log}" ]; then
        libscript_exp_parse_cpfe_timing "${_log}" "${_prb}" "${_out_cell}.phase.json"
        _last_fe=$(awk -F: '/"fe_cpu_s"/ {gsub(/[^0-9.]/, "", $2); print $2; exit}' "${_out_cell}.phase.json")
        _last_be=$(awk -F: '/"be_cpu_s"/ {gsub(/[^0-9.]/, "", $2); print $2; exit}' "${_out_cell}.phase.json")
      fi
    fi
    _idx=$((_idx + 1))
  done

  libscript_exp_compute_median_stddev "${_samples}" "${_out_cell}.stats.json" 0 "${_opt}" "${_opt}"
  _med_s=$(awk -F: '/"median_s"/ {gsub(/[^0-9.]/, "", $2); print $2; exit}' "${_out_cell}.stats.json")
  _std_s=$(awk -F: '/"stddev_s"/ {gsub(/[^0-9.]/, "", $2); print $2; exit}' "${_out_cell}.stats.json")
  printf '{"pipeline":"%s","opt":"%s","fe_cpu_s":%s,"be_cpu_s":%s,"wall_s":%s,"wall_stddev_s":%s,"peak_rss_mb":%s,"hw_instructions":%s}\n' \
    "${_pipe}" "${_opt}" "${_last_fe:-0.0}" "${_last_be:-0.0}" "${_med_s:-0.001}" "${_std_s:-0.0}" "${_last_rss:-1.0}" "${_last_inst:-0}" > "${_out_cell}"
  rm -f "${_samples}" "${_obj}" "${_log}" "${_prb}" "${_out_cell}.phase.json" "${_out_cell}.stats.json" "${_out_cell}.int.c" "${_out_cell}.int.cpp"
}

# ## run_e1_compile_perf
# Executes the Experiment 1 compilation performance matrix and emits `raw/exp1_compile_perf.json`.
run_e1_compile_perf() {
  mkdir -p "${RESULTS_DIR}/raw"
  if [ -s "${RESULTS_DIR}/raw/exp1_compile_perf.json" ] && [ "${FORCE_REBUILD:-0}" != "1" ]; then
    log_info '[E1] exp1_compile_perf.json already verified (cached).'
    return 0
  fi

  libscript_exp_assert_native_isa
  libscript_exp_ensure_bench_probe
  export MAKEFLAGS='-j1'
  export CMAKE_BUILD_PARALLEL_LEVEL='1'

  if [ ! -f "${RESULTS_DIR}/raw/metadata.json" ]; then
    "${SCRIPT_DIR}/e0_phase0_gates.sh" "${EDG_REPO_DIR}" "${RESULTS_DIR}" "${HOST_ARCH}"
  fi
  _sha=$(awk -F'"' '/"git_commit_sha"/ {print $4; exit}' "${RESULTS_DIR}/raw/metadata.json")
  _dirty=$(awk '/"git_dirty"/ {gsub(/[^a-z]/, "", $2); print $2; exit}' "${RESULTS_DIR}/raw/metadata.json")

  _wdir="${RESULTS_DIR}/.work_e1"
  stage_e1_workloads "${_wdir}"

  time_single_pipeline_cell 'EDG-LLVM' "${_wdir}/sqlite3.c" 'c' 'c11' '-O2' "${_wdir}/sq_edg_llvm_o2.json"
  time_single_pipeline_cell 'EDG-GCC' "${_wdir}/sqlite3.c" 'c' 'c11' '-O2' "${_wdir}/sq_edg_gcc_o2.json"
  time_single_pipeline_cell 'EDG-C-LEGACY' "${_wdir}/sqlite3.c" 'c' 'c11' '-O2' "${_wdir}/sq_edg_c_o2.json"
  time_single_pipeline_cell 'EDG-FE-ONLY' "${_wdir}/sqlite3.c" 'c' 'c11' '-O0' "${_wdir}/sq_fe_o0.json"
  time_single_pipeline_cell 'NATIVE-CLANG' "${_wdir}/sqlite3.c" 'c' 'c11' '-O2' "${_wdir}/sq_clang_o2.json"
  time_single_pipeline_cell 'NATIVE-GCC' "${_wdir}/sqlite3.c" 'c' 'c11' '-O2' "${_wdir}/sq_gcc_o2.json"

  time_single_pipeline_cell 'EDG-LLVM' "${_wdir}/cpp_crtp_bench.cpp" 'cxx' 'c++17' '-O2' "${_wdir}/crtp_edg_llvm_o2.json"
  time_single_pipeline_cell 'EDG-CPP-LEGACY' "${_wdir}/cpp_crtp_bench.cpp" 'cxx' 'c++17' '-O2' "${_wdir}/crtp_edg_cpp_o2.json"
  time_single_pipeline_cell 'NATIVE-CLANG' "${_wdir}/cpp_crtp_bench.cpp" 'cxx' 'c++17' '-O2' "${_wdir}/crtp_clang_o2.json"

  time_single_pipeline_cell 'EDG-LLVM' "${_wdir}/stl_suite.cpp" 'cxx' 'c++20' '-O2' "${_wdir}/stl_edg_llvm_o2.json"
  time_single_pipeline_cell 'NATIVE-CLANG' "${_wdir}/stl_suite.cpp" 'cxx' 'c++20' '-O2' "${_wdir}/stl_clang_o2.json"

  _edg_cpp_w=$(awk -F'"wall_s":' '{split($2,a,","); print a[1]+0}' "${_wdir}/crtp_edg_llvm_o2.json")
  _leg_cpp_w=$(awk -F'"wall_s":' '{split($2,a,","); print a[1]+0}' "${_wdir}/crtp_edg_cpp_o2.json")
  _cxx_sp=$(awk -v l="${_leg_cpp_w}" -v e="${_edg_cpp_w}" 'BEGIN { if (e > 0) printf "%.2f", l / e; else print "1.00" }')

  cat <<E1_EOF > "${RESULTS_DIR}/raw/exp1_compile_perf.json.tmp"
{
  "schema_version": "1.0.0",
  "suite": "E1",
  "host_arch": "${HOST_ARCH}",
  "git_commit_sha": "${_sha}",
  "git_dirty": ${_dirty},
  "host_manifest_ref": "raw/metadata.json",
  "workloads": {
    "sqlite3_loc": ${LOC_SQLITE3},
    "shell_loc": ${LOC_SHELL},
    "cpp_crtp_loc": ${LOC_CRTP},
    "fmt_inst_loc": ${LOC_FMT},
    "stl_suite_preprocessed_loc": ${LOC_STL_PRE}
  },
  "matched_o2_cxx_speedup_vs_legacy": ${_cxx_sp},
  "cells": {
    "sqlite3_edg_fe_o0": $(cat "${_wdir}/sq_fe_o0.json"),
    "sqlite3_edg_llvm_o2": $(cat "${_wdir}/sq_edg_llvm_o2.json"),
    "sqlite3_edg_gcc_o2": $(cat "${_wdir}/sq_edg_gcc_o2.json"),
    "sqlite3_edg_c_legacy_o2": $(cat "${_wdir}/sq_edg_c_o2.json"),
    "sqlite3_native_clang_o2": $(cat "${_wdir}/sq_clang_o2.json"),
    "sqlite3_native_gcc_o2": $(cat "${_wdir}/sq_gcc_o2.json"),
    "crtp_edg_llvm_o2": $(cat "${_wdir}/crtp_edg_llvm_o2.json"),
    "crtp_edg_cpp_legacy_o2": $(cat "${_wdir}/crtp_edg_cpp_o2.json"),
    "crtp_native_clang_o2": $(cat "${_wdir}/crtp_clang_o2.json"),
    "stl_edg_llvm_o2": $(cat "${_wdir}/stl_edg_llvm_o2.json"),
    "stl_native_clang_o2": $(cat "${_wdir}/stl_clang_o2.json")
  }
}
E1_EOF
  mv -f "${RESULTS_DIR}/raw/exp1_compile_perf.json.tmp" "${RESULTS_DIR}/raw/exp1_compile_perf.json"
  rm -rf "${_wdir}"
  log_info "[E1] Matched-optimization compile latency & RSS recorded -> ${RESULTS_DIR}/raw/exp1_compile_perf.json"
}

run_e1_compile_perf
