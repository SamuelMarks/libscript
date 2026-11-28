#!/bin/sh
# ## Overview
# Smoke and idempotency test suite for the upstream reference `libtpu` component.
#
# ## Usage
# ./_lib/runtimes/libtpu/test.sh

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

# ## run_libtpu_component_smoke
# Verifies idempotent repeated installation, SHA-256 & wheel metadata persistence, and isolated environment exports.
run_libtpu_component_smoke() {
  _t_dir=$(mktemp -d)
  printf 'mock-og-libtpu-elf\n' > "${_t_dir}/mock_libtpu.so"
  printf 'mock-og-sdk-elf\n' > "${_t_dir}/mock_sdk.so"
  printf 'mock-og-wheel\n' > "${_t_dir}/libtpu-0.0.52-py3-none-manylinux_2_31_x86_64.whl"

  STACK='' LIBSCRIPT_HOME="${_t_dir}/home" \
    LIBTPU_SO_PATH="${_t_dir}/mock_libtpu.so" \
    LIBTPU_SDK_SO_PATH="${_t_dir}/mock_sdk.so" \
    LIBTPU_REFERENCE_WHEEL="${_t_dir}/libtpu-0.0.52-py3-none-manylinux_2_31_x86_64.whl" \
    ACTION='install' "${SCRIPT_DIR}/setup_generic.sh" >/dev/null

  STACK='' LIBSCRIPT_HOME="${_t_dir}/home" \
    LIBTPU_SO_PATH="${_t_dir}/mock_libtpu.so" \
    LIBTPU_SDK_SO_PATH="${_t_dir}/mock_sdk.so" \
    LIBTPU_REFERENCE_WHEEL="${_t_dir}/libtpu-0.0.52-py3-none-manylinux_2_31_x86_64.whl" \
    ACTION='install' "${SCRIPT_DIR}/setup_generic.sh" >/dev/null

  (
    export LIBSCRIPT_HOME="${_t_dir}/home"
    unset LIBTPU_SO_PATH LIBTPU_SDK_SO_PATH LIBTPU_REFERENCE_WHEEL LIBTPU_REFERENCE_SO_SHA256 TPU_LIBRARY_PATH || true
    SCRIPT_NAME="${SCRIPT_DIR}/env.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
    [ -n "${LIBTPU_REFERENCE_DIR}" ]
    [ -f "${LIBTPU_REFERENCE_SO}" ]
    [ -f "${LIBTPU_REFERENCE_SDK_SO}" ]
    [ -f "${LIBTPU_REFERENCE_WHEEL}" ]
    [ -n "${LIBTPU_REFERENCE_SO_SHA256}" ]
    [ -z "${TPU_LIBRARY_PATH:-}" ]
    libtpu-info --version >/dev/null
  )

  rm -rf "${_t_dir}"
}

run_libtpu_component_smoke
