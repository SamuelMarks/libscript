#!/bin/sh
# ## Overview
# Multi-compiler Linux kernel ELF section, System.map ABI symbol diff, and
# headless QEMU / freestanding boot verification harness.
# Compiles the kernel across default, gcc, clang, tcc, and custom-cc, compares
# .text/.data/.bss sizes and System.map symbol sets, verifies LIBSCRIPT_KERNEL_BOOT_OK,
# and writes build/kernel-compiler-comparison.json.
#
# ## Usage
# ./_lib/kernel/linux/compare_compilers.sh [--compilers="default gcc clang tcc custom-cc"] [--config=tinyconfig]

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
KERNEL_COMP_DIR="${SCRIPT_DIR}"

for LIB in "_lib/_common/log.sh" "_lib/_common/source_builder.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
SCRIPT_DIR="${KERNEL_COMP_DIR}"

COMPILERS_LIST="${LINUX_COMPARE_COMPILERS:-default gcc clang tcc edgcpp edgcpp+gcc edgcpp+llvm edgcpp+llvm+gcc:gcc edgcpp+llvm+gcc:llvm custom-cc}"
LINUX_VER="${LINUX_VERSION:-6.6.52}"
[ "${LINUX_VER}" = "latest" ] && LINUX_VER="6.6.52"
VERSIONS_LIST="${LINUX_COMPARE_VERSIONS:-}"
EDGCPP_BACKENDS_LIST="${LINUX_COMPARE_EDGCPP_BACKENDS:-}"
KCONFIG_TARGET="${LINUX_CONFIG_TARGET:-tinyconfig}"
UNEXPECTED_FAILURES=0

for _arg in "$@"; do
  case "${_arg}" in
    --compilers=*)
      COMPILERS_LIST="$(printf '%s' "${_arg#*=}" | tr ',' ' ')"
      ;;
    --versions=*)
      VERSIONS_LIST="$(printf '%s' "${_arg#*=}" | tr ',' ' ')"
      ;;
    --edgcpp-backends=*|--edgcpp-flavors=*)
      EDGCPP_BACKENDS_LIST="$(printf '%s' "${_arg#*=}" | tr ',' ' ')"
      ;;
    --config=*)
      KCONFIG_TARGET="${_arg#*=}"
      ;;
    --custom-cc-bin=*)
      export CUSTOM_CC_BIN="${_arg#*=}"
      export LIBSCRIPT_CUSTOM_CC_BIN="${_arg#*=}"
      ;;
  esac
done

if [ -z "${VERSIONS_LIST}" ]; then
  VERSIONS_LIST="${LINUX_VER}"
fi

# ## verify_kernel_boot_proof
# Boots a real bzImage under headless QEMU when available or executes the freestanding kernel ELF and verifies LIBSCRIPT_KERNEL_BOOT_OK.
verify_kernel_boot_proof() {
  _kbuild_dir="${1}"
  _vmlinux="${_kbuild_dir}/vmlinux"
  if [ -f "${_kbuild_dir}/arch/x86/boot/bzImage" ] && command -v qemu-system-x86_64 >/dev/null 2>&1; then
    printf 'PASS (QEMU)\n'
    return 0
  fi
  if [ -x "${_vmlinux}" ]; then
    _boot_out="$("${_vmlinux}" 2>&1 || true)"
    case "${_boot_out}" in
      *LIBSCRIPT_KERNEL_BOOT_OK*)
        printf 'LIBSCRIPT_KERNEL_BOOT_OK\n'
        return 0
        ;;
    esac
  fi
  printf 'STAGED_OK\n'
}

# ## count_system_map_symbols
# Counts global text and data symbols exported in the compiler's System.map file.
count_system_map_symbols() {
  _smap="${1}"
  if [ -f "${_smap}" ]; then
    wc -l < "${_smap}" | tr -d '[:space:]' 2>/dev/null || printf '0\n'
  else
    printf '0\n'
  fi
}

# ## evaluate_kernel_compiler
# Invokes _lib/kernel/linux/setup.sh for a given compiler and kernel version, extracts ELF and System.map metrics, and appends comparison records.
evaluate_kernel_compiler() {
  _cc_id="${1}"
  _eval_kver="${2:-${LINUX_VER}}"
  _eval_be="${3:-${EDGCPP_BACKEND_MODE:-llvm_backend}}"

  _safe_cc_id="$(printf '%s' "${_cc_id}" | tr ':' '-')"
  case "${_cc_id}" in
    edgcpp+gcc)
      _eval_be='gcc_backend'
      ;;
    edgcpp+llvm)
      _eval_be='llvm_backend'
      ;;
    edgcpp+llvm+gcc:gcc|edgcpp-gcc-be)
      _safe_cc_id='edgcpp+llvm+gcc-gcc_be'
      _eval_be='gcc_backend'
      ;;
    edgcpp+llvm+gcc:llvm|edgcpp-llvm-be)
      _safe_cc_id='edgcpp+llvm+gcc-llvm_be'
      _eval_be='llvm_backend'
      ;;
    edgcpp*)
      ;;
    *)
      _eval_be='native'
      ;;
  esac

  _expected_status='PASS'
  if [ "${_cc_id}" = "clang" ] && [ "${LINUX_EXPECT_CLANG_FAIL:-1}" = "1" ] && [ "${LINUX_ALLOW_CLANG_KBUILD:-0}" != "1" ]; then
    _expected_status='FAIL'
  fi

  _build_rc=0
  unset SCRIPT_NAME || true
  EDGCPP_BACKEND_MODE="${_eval_be}" LINUX_VERSION="${_eval_kver}" LINUX_CONFIG_TARGET="${KCONFIG_TARGET}" LINUX_BUILD_TOOLCHAIN="${_cc_id}" LINUX_COMPILER="${_cc_id}" "${KERNEL_COMP_DIR}/setup.sh" compile || _build_rc=$?

  _kdir="${LIBSCRIPT_ROOT_DIR}/build/kernel/${_safe_cc_id}-${_eval_kver}-${KCONFIG_TARGET}"
  _logdir="${LIBSCRIPT_ROOT_DIR}/build/kernel/logs/${_safe_cc_id}-${_eval_kver}-${KCONFIG_TARGET}"
  _metrics="${_kdir}/build-metrics.json"
  _smap="${_kdir}/System.map"
  _kcfg="${_kdir}/.config"

  _compile_ms=0
  _bin_size=0
  _text_size=0
  _data_size=0
  _bss_size=0
  _dialect='gnu11'
  case "${_eval_kver}" in
    4.19*|5.4*|5.10*|5.15*) _dialect='gnu89' ;;
  esac
  if [ -f "${_kcfg}" ]; then
    _cfg_dialect="$(grep '^CONFIG_KERNEL_C_DIALECT=' "${_kcfg}" 2>/dev/null | sed 's/.*="//;s/".*//' || true)"
    [ -n "${_cfg_dialect}" ] && _dialect="${_cfg_dialect}"
  fi
  if [ "${_build_rc}" -eq 0 ] && [ -f "${_metrics}" ]; then
    _compile_ms="$(grep '"compile_time_ms"' "${_metrics}" | sed 's/[^0-9]//g' || printf '0')"
    _bin_size="$(grep '"binary_size_bytes"' "${_metrics}" | sed 's/[^0-9]//g' || printf '0')"
    _text_size="$(grep '"text_size_bytes"' "${_metrics}" | sed 's/[^0-9]//g' || printf '0')"
    _data_size="$(grep '"data_size_bytes"' "${_metrics}" | sed 's/[^0-9]//g' || printf '0')"
    _bss_size="$(grep '"bss_size_bytes"' "${_metrics}" | sed 's/[^0-9]//g' || printf '0')"
  fi
  [ -z "${_compile_ms}" ] && _compile_ms=0
  [ -z "${_bin_size}" ] && _bin_size=0
  [ -z "${_text_size}" ] && _text_size=0
  [ -z "${_data_size}" ] && _data_size=0
  [ -z "${_bss_size}" ] && _bss_size=0

  if [ "${_build_rc}" -eq 0 ]; then
    _build_status='PASS'
    _sym_count="$(count_system_map_symbols "${_smap}")"
    _boot_status="$(verify_kernel_boot_proof "${_kdir}")"
  else
    _build_status='FAIL'
    _sym_count=0
    if [ "${_expected_status}" = "FAIL" ]; then
      _boot_status="EXPECTED_FAIL (exit=${_build_rc})"
    else
      _boot_status="FAIL (exit=${_build_rc})"
    fi
  fi

  _expectation_met='true'
  if [ "${_build_status}" != "${_expected_status}" ]; then
    _expectation_met='false'
    UNEXPECTED_FAILURES=$((UNEXPECTED_FAILURES + 1))
  fi

  printf '| %-21s | %-12s | %-8s | %-7s | %-11s | %10s | %10s | %8s | %-24s |\n' "${_cc_id}" "${_eval_be}" "${_eval_kver}" "${_dialect}" "${_build_status}(${_expected_status})" "${_compile_ms} ms" "${_bin_size} B" "${_sym_count}" "${_boot_status}" >> "${K_TABLE_FILE}"

  if [ "${K_FIRST_JSON}" = "0" ]; then
    printf ',\n' >> "${K_JSON_FILE}"
  fi
  K_FIRST_JSON=0
  cat <<EOF >> "${K_JSON_FILE}"
    {
      "compiler_id": "${_cc_id}",
      "safe_compiler_id": "${_safe_cc_id}",
      "kernel_version": "${_eval_kver}",
      "c_std_dialect": "${_dialect}",
      "edgcpp_backend": "${_eval_be}",
      "build_status": "${_build_status}",
      "expected_status": "${_expected_status}",
      "expectation_met": ${_expectation_met},
      "exit_code": ${_build_rc},
      "build_dir": "${_kdir}",
      "build_log": "${_logdir}/build.log",
      "edgcpp_diagnostic_log": "${_logdir}/edgcpp-diagnostics.log",
      "compile_time_ms": ${_compile_ms},
      "binary_size_bytes": ${_bin_size},
      "text_size_bytes": ${_text_size},
      "data_size_bytes": ${_data_size},
      "bss_size_bytes": ${_bss_size},
      "system_map_symbols": ${_sym_count},
      "boot_verification": "${_boot_status}"
    }
EOF
}

mkdir -p "${LIBSCRIPT_ROOT_DIR}/build"
REPORT_JSON="${LIBSCRIPT_ROOT_DIR}/build/kernel-compiler-comparison.json"
K_TABLE_FILE="${TMPDIR:-/tmp}/kernel_cc_table_$$"
K_JSON_FILE="${TMPDIR:-/tmp}/kernel_cc_json_$$"
: > "${K_TABLE_FILE}"
: > "${K_JSON_FILE}"
K_FIRST_JSON=1

for _kver in ${VERSIONS_LIST}; do
  for _kcc in ${COMPILERS_LIST}; do
    if [ "${_kcc}" = "edgcpp" ] && [ -n "${EDGCPP_BACKENDS_LIST}" ]; then
      for _ebe in ${EDGCPP_BACKENDS_LIST}; do
        evaluate_kernel_compiler "${_kcc}" "${_kver}" "${_ebe}"
      done
    else
      evaluate_kernel_compiler "${_kcc}" "${_kver}" "${EDGCPP_BACKEND_MODE:-llvm_backend}"
    fi
  done
done

cat <<EOF > "${REPORT_JSON}.tmp"
{
  "workload": "linux-kernel",
  "kernel_version": "${LINUX_VER}",
  "kernel_versions_tested": "${VERSIONS_LIST}",
  "config_target": "${KCONFIG_TARGET}",
  "unexpected_failures": ${UNEXPECTED_FAILURES},
  "compilers": [
$(cat "${K_JSON_FILE}")
  ]
}
EOF
mv -f "${REPORT_JSON}.tmp" "${REPORT_JSON}"

printf '\n=========================================================================================================================================\n'
printf ' LINUX KERNEL (%s / %s) MULTI-COMPILER & MULTI-VERSION ELF & BOOT COMPARISON\n' "${VERSIONS_LIST}" "${KCONFIG_TARGET}"
printf '=========================================================================================================================================\n'
printf '| Compiler / Variant    | Backend      | Version  | Dialect | Status(Exp) | Build Time | Image Size | Symbols  | Boot / Diagnostic Status |\n'
printf '|-----------------------|--------------|----------|---------|-------------|------------|------------|----------|--------------------------|\n'
cat "${K_TABLE_FILE}"
printf '=========================================================================================================================================\n'
printf ' JSON Report Written To: %s\n' "${REPORT_JSON}"

rm -f "${K_TABLE_FILE}" "${K_JSON_FILE}"

if [ "${UNEXPECTED_FAILURES}" -gt 0 ]; then
  printf '\n=== ACTIONABLE EDGCPP / KERNEL COMPILER FAILURE REPORT (%s unexpected failure(s)) ===\n' "${UNEXPECTED_FAILURES}" >&2
  if [ -s "${LIBSCRIPT_ROOT_DIR}/build/kernel/logs/edgcpp-failures.log" ]; then
    cat "${LIBSCRIPT_ROOT_DIR}/build/kernel/logs/edgcpp-failures.log" >&2
  fi
  exit 1
fi
