#!/bin/sh
# ## Overview
# Environment configuration script for upstream reference `libtpu`. Exports `LIBTPU_REFERENCE_DIR`, `LIBTPU_REFERENCE_SO`, and `LIBTPU_REFERENCE_SDK_SO` without polluting `TPU_LIBRARY_PATH` unless explicitly requested.
#
# ## Usage
# Source via `SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/runtimes/libtpu/env.sh"; export SCRIPT_NAME; . "${SCRIPT_NAME}"`.
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
_EB_CALLER_THIS="${THIS_FILE}"
_EB_CALLER_DIR="${SCRIPT_DIR}"
for _lt_env_lib in '_lib/_common/os_info.sh' '_lib/_common/env_base.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_lt_env_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _lt_env_lib || true

LIBTPU_VERSION="${LIBTPU_VERSION:-0.0.52}"
if [ "${LIBTPU_VERSION}" = "latest" ]; then
  EXACT_VERSION='0.0.52'
else
  EXACT_VERSION="${LIBTPU_VERSION}"
fi

_lt_base="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/libtpu/${EXACT_VERSION}"
_lt_arch='x86_64'
case "${ARCH:-x86_64}" in
  aarch64|arm64) _lt_arch='aarch64' ;;
esac

export LIBTPU_REFERENCE_DIR="${_lt_base}"
export LIBTPU_REFERENCE_SO="${LIBTPU_SO_PATH:-${_lt_base}/${_lt_arch}/libtpu.so}"
export LIBTPU_REFERENCE_SDK_SO="${LIBTPU_SDK_SO_PATH:-${_lt_base}/${_lt_arch}/sdk.so}"
if [ "${LIBTPU_ACTIVATE_TPU_LIBRARY_PATH:-0}" = "1" ]; then
  export TPU_LIBRARY_PATH="${LIBTPU_REFERENCE_SO}"
fi

libscript_path_prepend "${_lt_base}/bin"
STACK="${STACK%"${THIS_FILE}":}"
export STACK
