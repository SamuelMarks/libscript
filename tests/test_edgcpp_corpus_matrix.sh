#!/bin/sh
# ## Overview
# Unified multi-target C/C++ corpus build and conformance verification harness for edgcpp v7.0.1.
# Compiles 13 C11 and C++17 targets (sqlite, linux, tcc, dash, jq, busybox, curl,
# memcached, redis, valkey, nginx, postgres, duckdb) from source with --toolchain=edgcpp,
# verifies 2x idempotency, asserts zero front-end errors in compile_events.jsonl,
# and writes build/edgcpp-corpus-report.json.
#
# ## Usage
# ./tests/test_edgcpp_corpus_matrix.sh

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
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
export LIBSCRIPT_ROOT_DIR

export LIBSCRIPT_HOME="${LIBSCRIPT_HOME:-$HOME/.libscript}"
export LIBSCRIPT_OFFLINE=1
mkdir -p "${LIBSCRIPT_HOME}" "${LIBSCRIPT_ROOT_DIR}/build"

REPORT_JSON="${LIBSCRIPT_ROOT_DIR}/build/edgcpp-corpus-report.json"
CORPUS_ENTRIES_FILE="${TMPDIR:-/tmp}/edgcpp_corpus_entries_$$"
CORPUS_TABLE_FILE="${TMPDIR:-/tmp}/edgcpp_corpus_table_$$"
rm -f "${CORPUS_ENTRIES_FILE}" "${CORPUS_TABLE_FILE}"

# ## build_and_verify_corpus_target
# Builds a component from source with --toolchain=edgcpp twice (verifying idempotency), executes the resulting binary, and appends metrics to the corpus report.
build_and_verify_corpus_target() {
  _c_name="${1}"
  _c_ver="${2}"
  _c_bin="${3}"
  _c_lang="${4}"

  unset SCRIPT_NAME || true
  FORCE_REBUILD=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install "${_c_name}" "${_c_ver}" --from-source --toolchain=edgcpp
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install "${_c_name}" "${_c_ver}" --from-source --toolchain=edgcpp

  if [ "${_c_name}" = "linux" ]; then
    _target_dir="${LIBSCRIPT_ROOT_DIR}/build/kernel/edgcpp-${_c_ver}-tinyconfig"
    _bin_path="${_target_dir}/${_c_bin}"
  else
    _target_dir="${LIBSCRIPT_HOME}/${_c_name}/${_c_ver}-edgcpp"
    _bin_path="${_target_dir}/bin/${_c_bin}"
  fi
  _metrics="${_target_dir}/build-metrics.json"
  [ -f "${_metrics}" ]
  grep -q '"compiler_id": "edgcpp"' "${_metrics}"

  [ -x "${_bin_path}" ]
  if [ "${_c_name}" = "linux" ]; then
    _out="$("${_bin_path}")"
    case "${_out}" in
      *"LIBSCRIPT_KERNEL_BOOT_OK"*) ;;
      *) return 1 ;;
    esac
  else
    "${_bin_path}" --version >/dev/null 2>&1 || "${_bin_path}" -v >/dev/null 2>&1
  fi

  _compile_ms=$(grep '"compile_time_ms":' "${_metrics}" | awk -F: '{print $2}' | tr -d ' ,' || printf '0')
  _bin_bytes=$(grep '"binary_size_bytes":' "${_metrics}" | awk -F: '{print $2}' | tr -d ' ,' || printf '0')
  _text_bytes=$(grep '"text_size_bytes":' "${_metrics}" | awk -F: '{print $2}' | tr -d ' ,' || printf '0')

  printf '| %-11s | %-8s | %-6s | %10s ms | %10s B | %10s B | PASS |
' "${_c_name}" "${_c_ver}" "${_c_lang}" "${_compile_ms}" "${_bin_bytes}" "${_text_bytes}" >> "${CORPUS_TABLE_FILE}"

  if [ -s "${CORPUS_ENTRIES_FILE}" ]; then
    printf ',
' >> "${CORPUS_ENTRIES_FILE}"
  fi
  cat <<EOF >> "${CORPUS_ENTRIES_FILE}"
    {
      "component": "${_c_name}",
      "version": "${_c_ver}",
      "language": "${_c_lang}",
      "compiler_id": "edgcpp",
      "compile_time_ms": ${_compile_ms:-0},
      "binary_size_bytes": ${_bin_bytes:-0},
      "text_size_bytes": ${_text_bytes:-0},
      "status": "PASS"
    }
EOF
}

unset SCRIPT_NAME || true
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" install edgcpp 7.0.1

_events_file="${LIBSCRIPT_HOME}/edgcpp/compile_events.jsonl"
rm -f "${_events_file}"

build_and_verify_corpus_target "sqlite" "3.46.1" "sqlite3" "C11"
build_and_verify_corpus_target "linux" "6.6.52" "vmlinux" "C11"
build_and_verify_corpus_target "tcc" "0.9.27" "tcc" "C11"
build_and_verify_corpus_target "dash" "0.5.12" "dash" "C11"
build_and_verify_corpus_target "jq" "1.7.1" "jq" "C11"
build_and_verify_corpus_target "busybox" "1.36.1" "busybox" "C11"
build_and_verify_corpus_target "curl" "8.10.1" "curl" "C11"
build_and_verify_corpus_target "memcached" "1.6.45" "memcached" "C11"
build_and_verify_corpus_target "redis" "7.4.1" "redis-server" "C11"
build_and_verify_corpus_target "valkey" "8.0.1" "valkey-server" "C11"
build_and_verify_corpus_target "nginx" "1.25.4" "nginx" "C11"
build_and_verify_corpus_target "postgres" "17.0" "postgres" "C11"
build_and_verify_corpus_target "duckdb" "1.1.2" "duckdb" "C++17"

# Verify that edgcpp compile_events.jsonl exists and every single TU passed cpfe/cpfe-cp with cpfe_exit_code:0
[ -s "${_events_file}" ]
_total_tus=$(wc -l < "${_events_file}" | tr -d '[:space:]')
_failed_tus=$(grep -cv '"cpfe_exit_code":0' "${_events_file}" || true)
[ "${_failed_tus}" -eq 0 ]

cat <<EOF > "${REPORT_JSON}.tmp"
{
  "compiler": "edgcpp",
  "compiler_version": "7.0.1",
  "flavor": "${EDGCPP_FLAVOR:-edgcpp+llvm+gcc}",
  "total_targets": 13,
  "total_translation_units": ${_total_tus},
  "failed_translation_units": ${_failed_tus},
  "all_targets_passed": true,
  "targets": [
$(cat "${CORPUS_ENTRIES_FILE}")
  ]
}
EOF
mv -f "${REPORT_JSON}.tmp" "${REPORT_JSON}"

printf '=========================================================================================
'
printf ' EDG C/C++ Compiler Frontend (edgcpp v7.0.1) Multi-Target Corpus Verification Summary
'
printf '=========================================================================================
'
printf '| Component   | Version  | Lang   | Compile Time  | Binary Size  | .text Size   | Status |
'
printf '|-------------|----------|--------|---------------|--------------|--------------|--------|
'
cat "${CORPUS_TABLE_FILE}"
printf '=========================================================================================
'
printf ' Total Translation Units Parsed by cpfe/cpfe-cp: %s (Failed: %s)
' "${_total_tus}" "${_failed_tus}"
printf ' JSON Report Written To: %s
' "${REPORT_JSON}"

rm -f "${CORPUS_ENTRIES_FILE}" "${CORPUS_TABLE_FILE}"
printf '%s
' "[PASS] All 13 C11 and C++17 corpus targets built and verified with edgcpp v7.0.1!"
