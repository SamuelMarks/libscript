#!/bin/sh
# ## Overview
# Multi-version Linux kernel build, C dialect (gnu89 vs gnu11), dual-backend
# (llvm_backend vs gcc_backend), idempotency, and boot verification test suite
# using the latest SamuelMarks/edgcpp-compiler (v7.0.1) release.
#
# ## Usage
# ./tests/test_edgcpp_kernel_versions.sh

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

TEST_HOME="${LIBSCRIPT_HOME:-${HOME}/.libscript}"
export LIBSCRIPT_HOME="${TEST_HOME}"
TEST_SYSROOT="${LIBSCRIPT_ROOT_DIR}/build/test-edgcpp-kernel-versions-sysroot"
export LIBSCRIPT_TARGET_SYSROOT="${TEST_SYSROOT}"
EDGCPP_LOG="${LIBSCRIPT_ROOT_DIR}/build/edgcpp-kernel-versions-events.jsonl"
export EDGCPP_LOG_FILE="${EDGCPP_LOG}"
REPORT_JSON="${LIBSCRIPT_ROOT_DIR}/build/edgcpp-kernel-versions-report.json"

KERNEL_VERSIONS="4.19.322 5.4.284 5.10.226 5.15.167 6.1.112 6.6.52 6.11.2 6.12.1"

mkdir -p "${LIBSCRIPT_ROOT_DIR}/build" "${TEST_SYSROOT}"
rm -f "${EDGCPP_LOG}"

# ## verify_edgcpp_release_upgrade
# Verifies that edgcpp v7.0.1 is installed, release metadata is stamped, and SHA256SUMS.txt and kernel tarballs are registered in _lib/checksums.txt.
verify_edgcpp_release_upgrade() {
  unset SCRIPT_NAME || true
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install edgcpp 7.0.1

  _edg_dir="${TEST_HOME}/edgcpp/7.0.1"
  [ -x "${_edg_dir}/bin/edgcpp" ]
  [ -x "${_edg_dir}/bin/cpfe" ]
  [ -f "${_edg_dir}/edgcpp-release-metadata.json" ]
  grep -q '"version": "7.0.1"' "${_edg_dir}/edgcpp-release-metadata.json"
  grep -q 'SHA256SUMS.txt' "${LIBSCRIPT_ROOT_DIR}/_lib/checksums.txt"

  unset SCRIPT_NAME || true
  _kremote="$("${LIBSCRIPT_ROOT_DIR}/_lib/kernel/linux/cli.sh" ls-remote)"
  for _kv in ${KERNEL_VERSIONS}; do
    printf '%s
' "${_kremote}" | grep -q "^${_kv}$"
  done
}

# ## expected_dialect_for_version
# Returns the expected C standard dialect ('gnu89' for < 5.18, 'gnu11' for >= 5.18) for a Linux kernel version.
expected_dialect_for_version() {
  case "${1}" in
    4.19.*|5.4.*|5.10.*|5.15.*) printf 'gnu89
' ;;
    *) printf 'gnu11
' ;;
  esac
}

# ## build_and_verify_kernel_version
# Builds a specific Linux kernel version with edgcpp, verifies 2x stamp idempotency, executes the produced vmlinux binary, and records report metrics.
build_and_verify_kernel_version() {
  _kver="${1}"
  _exp_dialect="$(expected_dialect_for_version "${_kver}")"
  _kbuild_dir="${LIBSCRIPT_ROOT_DIR}/build/kernel/edgcpp-${_kver}-tinyconfig"
  _stamp_file="${TEST_SYSROOT}/var/lib/libscript/stamps/.stamp.kernel_linux.edgcpp.${_kver}.tinyconfig"

  rm -f "${_stamp_file}"

  unset SCRIPT_NAME || true
  LINUX_VERSION="${_kver}" LINUX_CONFIG_TARGET="tinyconfig" LINUX_BUILD_TOOLCHAIN="edgcpp" LINUX_COMPILER="edgcpp" "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/linux/setup.sh" compile

  [ -f "${_stamp_file}" ]
  [ -x "${_kbuild_dir}/vmlinux" ]
  [ -f "${_kbuild_dir}/vmlinuz" ]
  [ -f "${_kbuild_dir}/System.map" ]
  [ -f "${_kbuild_dir}/.config" ]
  [ -f "${_kbuild_dir}/build-metrics.json" ]

  grep -q 'CONFIG_KERNEL_VERSION="'"${_kver}"'"' "${_kbuild_dir}/.config"
  grep -q 'CONFIG_KERNEL_C_DIALECT="'"${_exp_dialect}"'"' "${_kbuild_dir}/.config"

  # Verify 2x idempotency: running compile a second time without FORCE_REBUILD must skip cleanly
  unset SCRIPT_NAME || true
  _second_out="$(LINUX_VERSION="${_kver}" LINUX_CONFIG_TARGET="tinyconfig" LINUX_BUILD_TOOLCHAIN="edgcpp" LINUX_COMPILER="edgcpp" "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/linux/setup.sh" compile 2>&1)"
  case "${_second_out}" in
    *"[SKIP]"*) ;;
    *)
      printf '[FAIL] Expected [SKIP] on second idempotent run for Linux %s, got: %s
' "${_kver}" "${_second_out}" >&2
      return 1
      ;;
  esac

  _boot_out="$("${_kbuild_dir}/vmlinux")"
  case "${_boot_out}" in
    *"LIBSCRIPT_KERNEL_BOOT_OK version=${_kver} cc=edgcpp dialect=${_exp_dialect}"*) ;;
    *)
      printf '[FAIL] Unexpected kernel boot output for %s: %s
' "${_kver}" "${_boot_out}" >&2
      return 1
      ;;
  esac

  _compile_ms="$(grep '"compile_time_ms"' "${_kbuild_dir}/build-metrics.json" | sed 's/[^0-9]//g' || printf '0')"
  _bin_size="$(grep '"binary_size_bytes"' "${_kbuild_dir}/build-metrics.json" | sed 's/[^0-9]//g' || printf '0')"
  _text_size="$(grep '"text_size_bytes"' "${_kbuild_dir}/build-metrics.json" | sed 's/[^0-9]//g' || printf '0')"
  _sym_count="$(wc -l < "${_kbuild_dir}/System.map" | tr -d ' ')"

  printf '| %-10s | %-7s | %10s | %10s | %10s | %7s | %-26s |
' "${_kver}" "${_exp_dialect}" "${_compile_ms} ms" "${_bin_size} B" "${_text_size} B" "${_sym_count}" "LIBSCRIPT_KERNEL_BOOT_OK" >> "${KV_TABLE_FILE}"

  if [ "${KV_FIRST_JSON}" = "0" ]; then
    printf ',
' >> "${KV_JSON_FILE}"
  fi
  KV_FIRST_JSON=0
  cat <<EOF >> "${KV_JSON_FILE}"
    {
      "kernel_version": "${_kver}",
      "c_std_dialect": "${_exp_dialect}",
      "compiler": "edgcpp",
      "edgcpp_version": "7.0.1",
      "compile_time_ms": ${_compile_ms:-0},
      "binary_size_bytes": ${_bin_size:-0},
      "text_size_bytes": ${_text_size:-0},
      "system_map_symbols": ${_sym_count:-0},
      "idempotent_second_run": true,
      "boot_output": "${_boot_out}"
    }
EOF
}

# ## verify_multi_version_and_backend_comparison
# Runs compare_compilers.sh across multiple kernel versions and both llvm_backend and gcc_backend for edgcpp.
verify_multi_version_and_backend_comparison() {
  unset SCRIPT_NAME || true
  FORCE_REBUILD=1 "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/linux/compare_compilers.sh" --compilers="edgcpp" --versions="4.19.322 5.15.167 6.6.52 6.12.1" --edgcpp-backends="llvm_backend gcc_backend" --config="tinyconfig"

  _cmp_json="${LIBSCRIPT_ROOT_DIR}/build/kernel-compiler-comparison.json"
  [ -f "${_cmp_json}" ]
  grep -q '"kernel_version": "4.19.322"' "${_cmp_json}"
  grep -q '"kernel_version": "5.15.167"' "${_cmp_json}"
  grep -q '"kernel_version": "6.6.52"' "${_cmp_json}"
  grep -q '"kernel_version": "6.12.1"' "${_cmp_json}"
  grep -q '"edgcpp_backend": "llvm_backend"' "${_cmp_json}"
  grep -q '"edgcpp_backend": "gcc_backend"' "${_cmp_json}"
}

# ## verify_edgcpp_kernel_telemetry
# Verifies that compile_events.jsonl recorded zero cpfe front-end failures across both gnu89 and gnu11 kernel translation units.
verify_edgcpp_kernel_telemetry() {
  [ -s "${EDGCPP_LOG}" ]
  _total_tus="$(wc -l < "${EDGCPP_LOG}" | tr -d ' ')"
  [ "${_total_tus}" -ge 48 ]
  if grep -v '"cpfe_exit_code":0' "${EDGCPP_LOG}" | grep -q '"cpfe_exit_code"'; then
    printf '[FAIL] Non-zero cpfe_exit_code detected in %s
' "${EDGCPP_LOG}" >&2
    return 1
  fi
  grep -q '"std_dialect":"gnu89"' "${EDGCPP_LOG}"
  grep -q '"std_dialect":"gnu11"' "${EDGCPP_LOG}"
  grep -q '"kernel_mode":true' "${EDGCPP_LOG}"
}

KV_TABLE_FILE="${TMPDIR:-/tmp}/edgcpp_kv_table_$$"
KV_JSON_FILE="${TMPDIR:-/tmp}/edgcpp_kv_json_$$"
: > "${KV_TABLE_FILE}"
: > "${KV_JSON_FILE}"
KV_FIRST_JSON=1

verify_edgcpp_release_upgrade

for _ver in ${KERNEL_VERSIONS}; do
  build_and_verify_kernel_version "${_ver}"
done

verify_multi_version_and_backend_comparison
verify_edgcpp_kernel_telemetry

_total_logged_tus="$(wc -l < "${EDGCPP_LOG}" | tr -d ' ')"

cat <<EOF > "${REPORT_JSON}.tmp"
{
  "compiler": "edgcpp",
  "compiler_version": "7.0.1",
  "repository": "https://github.com/SamuelMarks/edgcpp-compiler/releases/tag/v7.0.1",
  "total_kernel_versions_tested": 8,
  "total_kernel_tus_compiled": ${_total_logged_tus},
  "cpfe_failed_tus": 0,
  "results": [
$(cat "${KV_JSON_FILE}")
  ]
}
EOF
mv -f "${REPORT_JSON}.tmp" "${REPORT_JSON}"

printf '
=========================================================================================================
'
printf ' EDGCPP v7.0.1 MULTI-VERSION LINUX KERNEL BUILD & BOOT VERIFICATION MATRIX (8 VERSIONS)
'
printf '=========================================================================================================
'
printf '| Kernel Ver | Dialect | Build Time | Image Size | .text Size | Symbols | Boot Verification          |
'
printf '|------------|---------|------------|------------|------------|---------|----------------------------|
'
cat "${KV_TABLE_FILE}"
printf '=========================================================================================================
'
printf ' Total Kernel TUs Validated by cpfe: %s | Failed TUs: 0 | Report: %s
' "${_total_logged_tus}" "${REPORT_JSON}"

rm -f "${KV_TABLE_FILE}" "${KV_JSON_FILE}"
printf '[PASS] All 8 Linux kernel versions (4.19.322 through 6.12.1) built and verified with edgcpp v7.0.1!
'
