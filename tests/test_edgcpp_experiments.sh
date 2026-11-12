#!/bin/sh
# ## Overview
# Integration test suite for the modular EDG C/C++ Backends experimental protocol (`benchmark_experiments.sh` and `torture_suite.sh`).
# ## Usage
# ./tests/test_edgcpp_experiments.sh
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
unset SCRIPT_NAME || true

chmod +x "${LIBSCRIPT_ROOT_DIR}/_lib/languages/edgcpp/torture_suite.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/languages/edgcpp/benchmark_experiments.sh"

# ## verify_torture_and_stl_harness
# Verifies that torture_suite.sh passes all optimization levels (-O0 to -O3) and STL stress tests and is idempotent on rerun.
verify_torture_and_stl_harness() {
  _tmp_rep="${TMPDIR:-/tmp}/test_edg_torture_$$.json"
  rm -f "${_tmp_rep}"
  "${LIBSCRIPT_ROOT_DIR}/_lib/languages/edgcpp/cli.sh" torture --compiler=EDG-LLVM --output="${_tmp_rep}"
  [ -s "${_tmp_rep}" ]
  grep -q '"all_passed": true' "${_tmp_rep}"
  grep -q '"total_tests": 13' "${_tmp_rep}"
  grep -q '"stl_headers_stress_passed": true' "${_tmp_rep}"

  # Second run must hit idempotency check
  _out2="$(LIBSCRIPT_LOG_LEVEL=0 "${LIBSCRIPT_ROOT_DIR}/_lib/languages/edgcpp/cli.sh" torture --compiler=EDG-LLVM --output="${_tmp_rep}" 2>&1)"
  printf '%s
' "${_out2}" | grep -q "already verified"
  rm -f "${_tmp_rep}"
}

# ## verify_5way_experiments_and_latex
# Verifies that benchmark_experiments.sh runs across all 5 compiler baselines, emits JSON and LaTeX tables, and is idempotent on rerun.
verify_5way_experiments_and_latex() {
  _exp_dir="${TMPDIR:-/tmp}/test_edg_exp_$$"
  _rep_json="${_exp_dir}/report.json"
  _tex_out="${_exp_dir}/tables.tex"
  rm -rf "${_exp_dir}"
  mkdir -p "${_exp_dir}"

  "${LIBSCRIPT_ROOT_DIR}/_lib/languages/edgcpp/cli.sh" experiments --workloads="linux-kernel,gcc-core,g++,llvm-core,clang,clang++,sqlite3,gcc-torture,stl-stress" --compilers="BASE-GCC,BASE-CLANG,EDG-LEGACY,EDG-GCC,EDG-LLVM" --runs=1 --report="${_rep_json}" --latex="${_tex_out}"

  [ -s "${_rep_json}" ]
  [ -s "${_tex_out}" ]
  grep -q '"all_experiments_passed": true' "${_rep_json}"
  grep -q '"total_cells": 45' "${_rep_json}"
  grep -q 'BASE-GCC & BASE-CLANG & EDG-LEGACY & EDG-GCC & EDG-LLVM' "${_tex_out}"
  grep -q 'tab:pipeline_overhead' "${_tex_out}"

  # Second run must be idempotent
  _exp_out2="$(LIBSCRIPT_LOG_LEVEL=0 "${LIBSCRIPT_ROOT_DIR}/_lib/languages/edgcpp/cli.sh" experiments --report="${_rep_json}" --latex="${_tex_out}" 2>&1)"
  printf '%s
' "${_exp_out2}" | grep -q "already up-to-date"
  rm -rf "${_exp_dir}"
}

verify_torture_and_stl_harness
verify_5way_experiments_and_latex
printf '[PASS] All EDG C/C++ Backends experimental protocol tests succeeded!
'
