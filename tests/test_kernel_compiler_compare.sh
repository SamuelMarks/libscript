#!/bin/sh
# ## Overview
# Integration test suite for the Linux kernel multi-compiler Kbuild engine,
# declarative OS profile resolution (`resolve_stack.jq`), ELF/System.map diff,
# and boot verification (`_lib/kernel/linux/compare_compilers.sh`).
#
# ## Usage
# ./tests/test_kernel_compiler_compare.sh

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

# ## verify_kernel_profiles_resolution
# Verifies that all declarative Linux kernel compiler profiles resolve cleanly via resolve_stack.jq.
verify_kernel_profiles_resolution() {
  if ! command -v jq >/dev/null 2>&1; then
    return 0
  fi
  for _prof in linux-kernel-gcc-tiny.json linux-kernel-clang-tiny.json linux-kernel-tcc-tiny.json linux-kernel-edgcpp-tiny.json linux-kernel-custom-cc-tiny.json linux-kernel-gcc-defconfig.json linux-kernel-edgcpp-defconfig.json linux-kernel-custom-cc-defconfig.json; do
    _prof_path="${LIBSCRIPT_ROOT_DIR}/profiles/${_prof}"
    [ -f "${_prof_path}" ]
    _plan="$(jq -L "${LIBSCRIPT_ROOT_DIR}/_lib/utilities" -L "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration" --arg target_os linux -f "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/resolve_stack.jq" "${_prof_path}")"
    printf '%s\n' "${_plan}" | grep -q '"LINUX_BUILD_TOOLCHAIN"'
  done
}

# ## verify_kernel_compiler_matrix
# Runs _lib/kernel/linux/compare_compilers.sh twice consecutively and verifies the comparison JSON report.
verify_kernel_compiler_matrix() {
  unset SCRIPT_NAME || true
  "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/linux/compare_compilers.sh"
  "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/linux/compare_compilers.sh"

  _kreport="${LIBSCRIPT_ROOT_DIR}/build/kernel-compiler-comparison.json"
  [ -f "${_kreport}" ]
  grep -q '"LIBSCRIPT_KERNEL_BOOT_OK"' "${_kreport}"
  grep -q '"compiler_id": "edgcpp"' "${_kreport}"
  grep -q '"compiler_id": "custom-cc"' "${_kreport}"
}

verify_kernel_profiles_resolution
verify_kernel_compiler_matrix

printf '[PASS] Linux kernel multi-compiler comparison and profile resolution tests succeeded!
'
