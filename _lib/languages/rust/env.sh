#!/bin/sh
# ## Overview
# Environment initialization for Rust.
#
# ## Usage
# Sets up `RUST_VERSION` and prepends Rust to PATH.

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
    [ -n "${_env_caller_this:-}" ] && THIS_FILE="${_env_caller_this}"; [ -n "${_env_caller_dir:-}" ] && SCRIPT_DIR="${_env_caller_dir}"; unset SCRIPT_NAME _env_caller_this _env_caller_dir || true; if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
_EB_CALLER_THIS="${THIS_FILE}"
_EB_CALLER_DIR="${SCRIPT_DIR}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/env_base.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true
_SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
RUST_VERSION="${RUST_VERSION:-latest}"
if [ "${RUST_VERSION}" = "latest" ]; then
  if [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/rust/default" ]; then
    RUST_VERSION='default'
  else
    RUST_VERSION='stable'
  fi
fi
_rust_dir="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/rust/${RUST_VERSION}"
if [ -d "${_rust_dir}" ]; then
  export CARGO_HOME="${CARGO_HOME:-${_rust_dir}/cargo}"
  export RUSTUP_HOME="${RUSTUP_HOME:-${_rust_dir}/rustup}"
  libscript_path_prepend "${CARGO_HOME}/bin" "${_rust_dir}/bin"
else
  libscript_path_prepend "${_rust_dir}/bin" "/opt/ooce/rust/bin" "/opt/ooce/bin"
fi
STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_env_caller_dir:-}" ] && SCRIPT_DIR="${_env_caller_dir}"
[ -n "${_env_caller_this:-}" ] && THIS_FILE="${_env_caller_this}"
unset SCRIPT_NAME _env_caller_this _env_caller_dir || true
