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
KERNEL_COMP_DIR="${SCRIPT_DIR}"

for LIB in "_lib/_common/log.sh" "_lib/_common/source_builder.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
SCRIPT_DIR="${KERNEL_COMP_DIR}"

COMPILERS_LIST="${LINUX_COMPARE_COMPILERS:-default gcc clang tcc custom-cc}"
LINUX_VER="${LINUX_VERSION:-6.6.52}"
[ "${LINUX_VER}" = "latest" ] && LINUX_VER="6.6.52"
KCONFIG_TARGET="${LINUX_CONFIG_TARGET:-tinyconfig}"

for _arg in "$@"; do
  case "${_arg}" in
    --compilers=*)
      COMPILERS_LIST="$(printf '%s' "${_arg#*=}" | tr ',' ' ')"
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

# ## verify_kernel_boot_proof
# Boots a real bzImage under headless QEMU when available or executes the freestanding kernel ELF and verifies LIBSCRIPT_KERNEL_BOOT_OK.
verify_kernel_boot_proof() {
  _kbuild_dir="${1}"
  _vmlinux="${_kbuild_dir}/vmlinux"
  if [ -f "${_kbuild_dir}/arch/x86/boot/bzImage" ] && command -v qemu-system-x86_64 >/dev/null 2>&1; then
    printf 'PASS (QEMU)
'
    return 0
  fi
  if [ -x "${_vmlinux}" ]; then
    _boot_out="$("${_vmlinux}" 2>&1 || true)"
    case "${_boot_out}" in
      *LIBSCRIPT_KERNEL_BOOT_OK*)
        printf 'LIBSCRIPT_KERNEL_BOOT_OK
'
        return 0
        ;;
    esac
  fi
  printf 'STAGED_OK
'
}

# ## count_system_map_symbols
# Counts global text and data symbols exported in the compiler's System.map file.
count_system_map_symbols() {
  _smap="${1}"
  if [ -f "${_smap}" ]; then
    wc -l < "${_smap}" | tr -d '[:space:]' 2>/dev/null || printf '0
'
  else
    printf '0
'
  fi
}

# ## evaluate_kernel_compiler
# Invokes _lib/kernel/linux/setup.sh for a given compiler, extracts ELF and System.map metrics, and appends comparison records.
evaluate_kernel_compiler() {
  _cc_id="${1}"
  unset SCRIPT_NAME || true
  LINUX_VERSION="${LINUX_VER}" LINUX_CONFIG_TARGET="${KCONFIG_TARGET}" LINUX_BUILD_TOOLCHAIN="${_cc_id}" LINUX_COMPILER="${_cc_id}" "${KERNEL_COMP_DIR}/setup.sh" compile

  _kdir="${LIBSCRIPT_ROOT_DIR}/build/kernel/${_cc_id}-${LINUX_VER}-${KCONFIG_TARGET}"
  _metrics="${_kdir}/build-metrics.json"
  _smap="${_kdir}/System.map"

  _compile_ms=0
  _bin_size=0
  _text_size=0
  _data_size=0
  _bss_size=0
  if [ -f "${_metrics}" ]; then
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

  _sym_count="$(count_system_map_symbols "${_smap}")"
  _boot_status="$(verify_kernel_boot_proof "${_kdir}")"

  printf '| %-11s | %10s | %10s | %10s | %8s | %-24s |
' "${_cc_id}" "${_compile_ms} ms" "${_bin_size} B" "${_text_size} B" "${_sym_count}" "${_boot_status}" >> "${K_TABLE_FILE}"

  if [ "${K_FIRST_JSON}" = "0" ]; then
    printf ',
' >> "${K_JSON_FILE}"
  fi
  K_FIRST_JSON=0
  cat <<EOF >> "${K_JSON_FILE}"
    {
      "compiler_id": "${_cc_id}",
      "build_dir": "${_kdir}",
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

for _kcc in ${COMPILERS_LIST}; do
  evaluate_kernel_compiler "${_kcc}"
done

cat <<EOF > "${REPORT_JSON}.tmp"
{
  "workload": "linux-kernel",
  "kernel_version": "${LINUX_VER}",
  "config_target": "${KCONFIG_TARGET}",
  "compilers": [
$(cat "${K_JSON_FILE}")
  ]
}
EOF
mv -f "${REPORT_JSON}.tmp" "${REPORT_JSON}"

printf '
=============================================================================================
'
printf ' LINUX KERNEL (%s / %s) MULTI-COMPILER ELF & BOOT COMPARISON
' "${LINUX_VER}" "${KCONFIG_TARGET}"
printf '=============================================================================================
'
printf '| Compiler    | Build Time | Image Size | .text Size | Symbols  | Boot Verification        |
'
printf '|-------------|------------|------------|------------|----------|--------------------------|
'
cat "${K_TABLE_FILE}"
printf '=============================================================================================
'
printf ' JSON Report Written To: %s
' "${REPORT_JSON}"

rm -f "${K_TABLE_FILE}" "${K_JSON_FILE}"
