#!/bin/sh
# ## Overview
# Integration test suite for the 4-way SQLite amalgamation compiler matrix
# (_lib/databases/sqlite/compare_compilers.sh). Verifies that SQLite compiles
# across default, gcc, clang, tcc, and custom-cc and produces identical 6-stage
# SQL torture digests.
#
# ## Usage
# ./tests/test_sqlite_compiler_matrix.sh

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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

# ## verify_sqlite_matrix_report
# Runs compare_compilers.sh twice consecutively and validates the JSON report.
verify_sqlite_matrix_report() {
  unset SCRIPT_NAME || true
  "${LIBSCRIPT_ROOT_DIR}/_lib/databases/sqlite/compare_compilers.sh" --compilers="default gcc clang tcc edgcpp custom-cc"
  "${LIBSCRIPT_ROOT_DIR}/_lib/databases/sqlite/compare_compilers.sh" --compilers="default gcc clang tcc edgcpp custom-cc"

  _report="${LIBSCRIPT_ROOT_DIR}/build/sqlite-compiler-comparison.json"
  [ -f "${_report}" ]
  grep -q '"all_digests_identical": true' "${_report}"
  grep -q '"compiler_id": "edgcpp"' "${_report}"
  grep -q '"compiler_id": "custom-cc"' "${_report}"
}

verify_sqlite_matrix_report
printf '[PASS] SQLite 4-way compiler matrix test succeeded!
'
