#!/bin/sh
# ## Overview
# Environment configuration script for `libtpu-rs`. Exports `LIBTPU_RS_DIR`, `LIBTPU_RS_SO`, `LIBTPU_RS_SDK_SO`, `LIBTPU_RS_WHEEL`, and `LIBTPU_RS_SO_SHA256` without polluting `TPU_LIBRARY_PATH` unless requested.
#
# ## Usage
# Source via `SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/libtpu-rs/env.sh"; export SCRIPT_NAME; . "${SCRIPT_NAME}"`.
set -feu; _env_caller_this="${THIS_FILE:-}"; _env_caller_dir="${SCRIPT_DIR:-}"
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
    if [ -n "${_env_caller_this:-}" ]; then THIS_FILE="${_env_caller_this}"; fi; if [ -n "${_env_caller_dir:-}" ]; then SCRIPT_DIR="${_env_caller_dir}"; fi; unset SCRIPT_NAME _env_caller_this _env_caller_dir || true; if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
_EB_CALLER_THIS="${THIS_FILE}"
_EB_CALLER_DIR="${SCRIPT_DIR}"
for _ltr_env_lib in 'engine/common/os_info.sh' 'engine/common/env_base.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_ltr_env_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _ltr_env_lib || true

LIBTPU_RS_VERSION="${LIBTPU_RS_VERSION:-0.0.52}"
if [ "${LIBTPU_RS_VERSION}" = 'latest' ] || [ "${LIBTPU_RS_VERSION}" = 'lts' ]; then
  EXACT_VERSION='0.0.52'
else
  EXACT_VERSION="${LIBTPU_RS_VERSION}"
fi

_ltr_base="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/libtpu-rs/${EXACT_VERSION}"
_ltr_ext='so'
if [ "${UNAME:-}" = 'Darwin' ]; then
  _ltr_ext='dylib'
fi

_ltr_whl="${LIBTPU_RS_WHEEL_PATH:-}"
if [ -z "${_ltr_whl}" ] && [ -f "${_ltr_base}/wheels/wheel_path.txt" ]; then
  IFS= read -r _ltr_whl < "${_ltr_base}/wheels/wheel_path.txt" || true
fi
_ltr_sha="${LIBTPU_RS_SO_SHA256:-}"
if [ -z "${_ltr_sha}" ] && [ -f "${_ltr_base}/lib/libtpu_so_sha256.txt" ]; then
  IFS= read -r _ltr_sha < "${_ltr_base}/lib/libtpu_so_sha256.txt" || true
fi

export LIBTPU_RS_DIR="${_ltr_base}"
export LIBTPU_RS_SO="${LIBTPU_RS_SO_PATH:-${_ltr_base}/lib/libtpu.${_ltr_ext}}"
export LIBTPU_RS_SDK_SO="${LIBTPU_RS_SDK_SO_PATH:-${_ltr_base}/lib/sdk.${_ltr_ext}}"
export LIBTPU_RS_WHEEL="${_ltr_whl}"
export LIBTPU_RS_SO_SHA256="${_ltr_sha}"
if [ "${LIBTPU_RS_ACTIVATE_TPU_LIBRARY_PATH:-0}" = '1' ]; then
  export TPU_LIBRARY_PATH="${LIBTPU_RS_SO}"
fi

libscript_path_prepend "${_ltr_base}/bin"
STACK="${STACK%"${THIS_FILE}":}"
export STACK
if [ -n "${_env_caller_dir:-}" ]; then SCRIPT_DIR="${_env_caller_dir}"; fi
if [ -n "${_env_caller_this:-}" ]; then THIS_FILE="${_env_caller_this}"; fi
unset SCRIPT_NAME _env_caller_this _env_caller_dir _ltr_base _ltr_ext _ltr_whl _ltr_sha || true
