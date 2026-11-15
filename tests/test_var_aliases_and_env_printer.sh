#!/bin/sh
# ## Overview
# Hermetic tests for global variable alias normalization (DOWNLOAD_DIR, LOGS_DIR, LIBSCRIPT_LOGS_DIR,
# LIBSCRIPT_GLOBAL_INSTALL_METHOD, LIBSCRIPT_TARGET_ROOTFS) and dynamic schema-driven env_printer.sh.
# ## Usage
# ./tests/test_var_aliases_and_env_printer.sh
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
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2; fi
    if (return 0 2>/dev/null); then return 0; else exit 0; fi ;;
  *)
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
TEST_TMP="${LIBSCRIPT_ROOT_DIR}/tests_tmp/var_aliases_$$"
mkdir -p "$TEST_TMP"
# ## cleanup_tmp
# Removes temporary test directory on exit.
cleanup_tmp() {
  rm -rf "$TEST_TMP"
}
trap 'cleanup_tmp' EXIT INT TERM

# ## fail_test
# Prints an error diagnostic and exits 1.
fail_test() {
  printf '[FAIL] %s\n' "$1" >&2
  exit 1
}

# 1. paths.sh idempotent 2x normalization of DOWNLOAD_DIR & LIBSCRIPT_LOGS_DIR -> canonical globals
OUT_PATHS=$(
  STACK=''
  LIBSCRIPT_DOWNLOAD_DIR=''
  LIBSCRIPT_LOG_DIR=''
  LOGS_DIR=''
  DOWNLOAD_DIR="${TEST_TMP}/custom_dl"
  LIBSCRIPT_LOGS_DIR="${TEST_TMP}/custom_logs"
  PACKAGE_NAME='lynx'
  export STACK LIBSCRIPT_DOWNLOAD_DIR LIBSCRIPT_LOG_DIR LOGS_DIR DOWNLOAD_DIR LIBSCRIPT_LOGS_DIR PACKAGE_NAME
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/paths.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  resolve_component_paths
  resolve_component_paths
  printf '%s|%s|%s\n' "$LIBSCRIPT_DOWNLOAD_DIR" "$LIBSCRIPT_LOG_DIR" "$LOGS_DIR"
)
[ "$OUT_PATHS" = "${TEST_TMP}/custom_dl|${TEST_TMP}/custom_logs|${TEST_TMP}/custom_logs/lynx" ] || fail_test "paths.sh alias normalization mismatch: ${OUT_PATHS}"
printf '[PASS] paths.sh normalizes DOWNLOAD_DIR and LIBSCRIPT_LOGS_DIR idempotently (2x).\n'

# 2. context.sh normalization of LIBSCRIPT_TARGET_ROOTFS -> LIBSCRIPT_TARGET_SYSROOT
OUT_CTX=$(
  STACK=''
  LIBSCRIPT_TARGET_ROOTFS="${TEST_TMP}/legacy_rootfs"
  export STACK LIBSCRIPT_TARGET_ROOTFS
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/context.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  printf '%s\n' "$LIBSCRIPT_TARGET_SYSROOT"
)
[ "$OUT_CTX" = "${TEST_TMP}/legacy_rootfs" ] || fail_test "context.sh failed to normalize LIBSCRIPT_TARGET_ROOTFS: ${OUT_CTX}"
printf '[PASS] context.sh normalizes LIBSCRIPT_TARGET_ROOTFS -> LIBSCRIPT_TARGET_SYSROOT.\n'

# 3. pkg_mgr.sh libscript_resolve_install_method honors both canonical and legacy global method vars
M1=$(
  STACK=''
  LIBSCRIPT_DEFAULT_INSTALL_METHOD='from-source'
  export STACK LIBSCRIPT_DEFAULT_INSTALL_METHOD
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mgr.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  libscript_resolve_install_method 'LYNX'
)
M2=$(
  STACK=''
  LIBSCRIPT_GLOBAL_INSTALL_METHOD='from-source'
  export STACK LIBSCRIPT_GLOBAL_INSTALL_METHOD
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mgr.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  libscript_resolve_install_method 'LYNX'
)
[ "$M1" = 'from-source' ] && [ "$M2" = 'from-source' ] || fail_test "Install method resolution mismatch: M1=${M1} M2=${M2}"
printf '[PASS] libscript_resolve_install_method honors canonical and legacy install method globals.\n'

# 4. Dynamic env_printer.sh forwards OLLAMA_HOST for ollama but isolates lynx from OLLAMA_HOST
OLLAMA_ENV=$(
  STACK=''
  OLLAMA_HOST='http://127.0.0.1:19999'
  PACKAGE_NAME='ollama'
  COMP_DIR="${LIBSCRIPT_ROOT_DIR}/_lib/app-servers/ollama"
  export STACK OLLAMA_HOST PACKAGE_NAME COMP_DIR
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_printer.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  libscript_print_env 'sh' "${TEST_TMP}/ollama_inst"
)
printf '%s\n' "$OLLAMA_ENV" | grep -q '19999' || fail_test "env_printer.sh did not forward schema-declared OLLAMA_HOST for ollama: ${OLLAMA_ENV}"

LYNX_ENV=$(
  STACK=''
  OLLAMA_HOST='http://127.0.0.1:19999'
  PACKAGE_NAME='lynx'
  COMP_DIR="${LIBSCRIPT_ROOT_DIR}/_lib/utilities/lynx"
  export STACK OLLAMA_HOST PACKAGE_NAME COMP_DIR
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_printer.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  libscript_print_env 'sh' "${TEST_TMP}/lynx_inst"
)
if printf '%s\n' "$LYNX_ENV" | grep -q 'OLLAMA_HOST'; then
  fail_test "env_printer.sh leaked OLLAMA_HOST into unrelated lynx environment: ${LYNX_ENV}"
fi
printf '[PASS] env_printer.sh dynamically forwards component schema vars without cross-component leakage.\n'
cleanup_tmp
exit 0
