#!/bin/sh
# ## Overview
# 4-way differential C compiler benchmark and verification harness for SQLite.
# Compiles the SQLite C amalgamation from source using default/gcc/clang/tcc/custom-cc,
# verifies byte-for-byte identical 6-stage SQL torture suite output digests across
# all compilers, benchmarks OLTP/OLAP query throughput, and writes
# build/sqlite-compiler-comparison.json.
#
# ## Usage
# ./_lib/databases/sqlite/compare_compilers.sh [--compilers="gcc clang tcc custom-cc"] [--custom-cc-bin=/path/to/cc]

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
COMPARE_DIR="${SCRIPT_DIR}"

for LIB in "_lib/_common/log.sh" "_lib/_common/source_builder.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
SCRIPT_DIR="${COMPARE_DIR}"

COMPILERS_LIST="${SQLITE_COMPARE_COMPILERS:-default gcc clang tcc edgcpp custom-cc}"
SQLITE_VER="${SQLITE_VERSION:-3.46.1}"
[ "${SQLITE_VER}" = "latest" ] && SQLITE_VER="3.46.1"

for _arg in "$@"; do
  case "${_arg}" in
    --compilers=*)
      COMPILERS_LIST="$(printf '%s' "${_arg#*=}" | tr ',' ' ')"
      ;;
    --custom-cc-bin=*)
      export CUSTOM_CC_BIN="${_arg#*=}"
      export LIBSCRIPT_CUSTOM_CC_BIN="${_arg#*=}"
      ;;
  esac
done

# ## run_sqlite_microbenchmark
# Executes a deterministic in-memory OLTP insert + analytic query workload and returns elapsed milliseconds.
run_sqlite_microbenchmark() {
  _bench_bin="${1}"
  _t0="$(libscript_now_ms)"
  "${_bench_bin}" -batch -noheader :memory: "
CREATE TABLE bench(id INTEGER PRIMARY KEY, grp INTEGER, val REAL, label TEXT);
WITH RECURSIVE gen(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM gen WHERE x < 2500)
INSERT INTO bench SELECT x, x % 17, (x * 1.6180339887), 'row-' || x FROM gen;
CREATE INDEX idx_bench_grp ON bench(grp, val);
SELECT grp, COUNT(*), ROUND(AVG(val), 2), ROUND(SUM(val), 2) FROM bench GROUP BY grp ORDER BY grp;
" >/dev/null
  _t1="$(libscript_now_ms)"
  _el=$((_t1 - _t0))
  [ "${_el}" -lt 1 ] && _el=1
  printf '%s\n' "${_el}"
}

# ## compare_single_compiler
# Builds or locates the SQLite amalgamation for a single compiler, verifies the 6-stage digest, and records metrics.
compare_single_compiler() {
  _cc_id="${1}"
  log_info "=== Evaluating SQLite ${SQLITE_VER} with compiler: ${_cc_id} ==="

  unset SCRIPT_NAME || true
  SQLITE_INSTALL_METHOD="from-source" SQLITE_BUILD_TOOLCHAIN="${_cc_id}" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install sqlite "${SQLITE_VER}" --from-source --toolchain="${_cc_id}"

  if [ "${_cc_id}" = "default" ]; then
    _target_dir="${LIBSCRIPT_HOME:-$HOME/.libscript}/sqlite/${SQLITE_VER}"
  else
    _target_dir="${LIBSCRIPT_HOME:-$HOME/.libscript}/sqlite/${SQLITE_VER}-${_cc_id}"
  fi
  _bin="${_target_dir}/bin/sqlite3"
  _metrics="${_target_dir}/build-metrics.json"

  unset SCRIPT_NAME || true
  _digest="$(SQLITE_BIN="${_bin}" "${SCRIPT_DIR}/test.sh" --digest-only)"
  if [ -z "${REFERENCE_DIGEST}" ]; then
    REFERENCE_DIGEST="${_digest}"
  fi

  _match="true"
  if [ "${_digest}" != "${REFERENCE_DIGEST}" ]; then
    _match="false"
    log_error "Digest mismatch for ${_cc_id}: got ${_digest}, expected ${REFERENCE_DIGEST}"
    exit 1
  fi

  _bench_ms="$(run_sqlite_microbenchmark "${_bin}")"
  _compile_ms=0
  _bin_size=0
  _text_size=0
  if [ -f "${_metrics}" ]; then
    _compile_ms="$(grep '"compile_time_ms"' "${_metrics}" | sed 's/[^0-9]//g' || printf '0')"
    _bin_size="$(grep '"binary_size_bytes"' "${_metrics}" | sed 's/[^0-9]//g' || printf '0')"
    _text_size="$(grep '"text_size_bytes"' "${_metrics}" | sed 's/[^0-9]//g' || printf '0')"
  fi
  [ -z "${_compile_ms}" ] && _compile_ms=0
  [ -z "${_bin_size}" ] && _bin_size=0
  [ -z "${_text_size}" ] && _text_size=0

  printf '| %-11s | %12s | %12s | %10s | %12s | %-10s |\n' "${_cc_id}" "${_compile_ms} ms" "${_bin_size} B" "${_text_size} B" "${_bench_ms} ms" "PASS" >> "${TABLE_FILE}"

  if [ "${FIRST_JSON_ENTRY}" = "0" ]; then
    printf ',
' >> "${JSON_ENTRIES_FILE}"
  fi
  FIRST_JSON_ENTRY=0
  cat <<EOF >> "${JSON_ENTRIES_FILE}"
    {
      "compiler_id": "${_cc_id}",
      "binary_path": "${_bin}",
      "compile_time_ms": ${_compile_ms},
      "binary_size_bytes": ${_bin_size},
      "text_size_bytes": ${_text_size},
      "benchmark_query_ms": ${_bench_ms},
      "torture_digest": "${_digest}",
      "digest_matches_reference": ${_match}
    }
EOF
}

mkdir -p "${LIBSCRIPT_ROOT_DIR}/build"
REPORT_JSON="${LIBSCRIPT_ROOT_DIR}/build/sqlite-compiler-comparison.json"
TABLE_FILE="${TMPDIR:-/tmp}/sqlite_cc_table_$$"
JSON_ENTRIES_FILE="${TMPDIR:-/tmp}/sqlite_cc_json_$$"
: > "${TABLE_FILE}"
: > "${JSON_ENTRIES_FILE}"
REFERENCE_DIGEST=""
FIRST_JSON_ENTRY=1

for _comp_id in ${COMPILERS_LIST}; do
  compare_single_compiler "${_comp_id}"
done

cat <<EOF > "${REPORT_JSON}.tmp"
{
  "workload": "sqlite-amalgamation",
  "sqlite_version": "${SQLITE_VER}",
  "reference_digest": "${REFERENCE_DIGEST}",
  "all_digests_identical": true,
  "compilers": [
$(cat "${JSON_ENTRIES_FILE}")
  ]
}
EOF
mv -f "${REPORT_JSON}.tmp" "${REPORT_JSON}"

printf '
=====================================================================================
'
printf ' SQLITE C AMALGAMATION MULTI-COMPILER DIFFERENTIAL VERIFICATION (%s)
' "${SQLITE_VER}"
printf '=====================================================================================
'
printf '| Compiler    | Compile Time | Binary Size  | .text Size | Query Bench  | Correctness|
'
printf '|-------------|--------------|--------------|------------|--------------|------------|
'
cat "${TABLE_FILE}"
printf '=====================================================================================
'
printf ' Reference Torture Digest: %s
' "${REFERENCE_DIGEST}"
printf ' JSON Report Written To:   %s
' "${REPORT_JSON}"

rm -f "${TABLE_FILE}" "${JSON_ENTRIES_FILE}"
