#!/bin/sh
# ## Overview
# Foundational environment initialization module for LibScript components.
# Resolves the component package name, active version, and idempotently prepends
# the component's binary directory to PATH.
#
# ## Usage
# . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_base.sh"

set -feu

_eb_caller_this="${_EB_CALLER_THIS:-}"
_eb_caller_dir="${_EB_CALLER_DIR:-}"
if [ -z "$_eb_caller_dir" ] && [ -n "${SCRIPT_DIR:-}" ]; then
  _eb_caller_dir="$SCRIPT_DIR"
fi

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

# ## libscript_path_prepend
# Idempotently prepends one or more colon-separated directories to PATH.
libscript_path_prepend() {
  for _dir in "$@"; do
    [ -z "$_dir" ] && continue
    case ":${PATH:-}:" in
      ":${_dir}:"*) ;;
      *":${_dir}:"*)
        _eb_clean_p=$(printf '%s' ":${PATH}:" | sed "s|:${_dir}:|:|g")
        _eb_clean_p="${_eb_clean_p#:}"
        _eb_clean_p="${_eb_clean_p%:}"
        PATH="${_dir}${_eb_clean_p:+:${_eb_clean_p}}"
        ;;
      *) PATH="${_dir}${PATH:+:${PATH}}" ;;
    esac
  done
  export PATH
}

_eb_pkg="${PACKAGE_NAME:-}"
if [ -z "$_eb_pkg" ] && [ -n "${_eb_caller_dir:-}" ]; then
  _eb_pkg=$(basename "$_eb_caller_dir")
elif [ -z "$_eb_pkg" ] && [ -n "${DIR:-}" ]; then
  _eb_pkg=$(basename "$DIR")
fi
if [ -n "$_eb_pkg" ] && [ "$_eb_pkg" != "_common" ] && [ "$_eb_pkg" != "_noop" ]; then
  if [ -z "${LIBSCRIPT_HOME:-}" ]; then
    if [ -n "${REMOTE_HOME:-}" ] && [ -d "${REMOTE_HOME}" ]; then
      LIBSCRIPT_HOME="${REMOTE_HOME}/.libscript"
    elif [ -n "${SERVICE_USER:-}" ] && [ "${SERVICE_USER}" != "root" ] && [ -d "/home/${SERVICE_USER}" ]; then
      LIBSCRIPT_HOME="/home/${SERVICE_USER}/.libscript"
    elif [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ] && [ -d "/home/${SUDO_USER}" ]; then
      LIBSCRIPT_HOME="/home/${SUDO_USER}/.libscript"
    else
      LIBSCRIPT_HOME="${HOME:-/root}/.libscript"
    fi
    export LIBSCRIPT_HOME
  fi
  _eb_home="${LIBSCRIPT_HOME}"
  _eb_pkg_up=$(printf '%s' "$_eb_pkg" | tr '[:lower:]-' '[:upper:]_')
  _eb_comp_ver=$(printenv "${_eb_pkg_up}_VERSION" 2>/dev/null || true)
  if [ -n "$_eb_comp_ver" ]; then
    _eb_ver="$_eb_comp_ver"
  elif [ -n "${LIBSCRIPT_VERSION:-}" ] && { [ -z "${PACKAGE_NAME:-}" ] || [ "${PACKAGE_NAME:-}" = "$_eb_pkg" ]; }; then
    _eb_ver="${LIBSCRIPT_VERSION}"
  else
    _eb_ver='latest'
  fi
  export "${_eb_pkg_up}_VERSION=${_eb_ver}"
  if [ -d "${_eb_home}/${_eb_pkg}/${_eb_ver}/bin" ]; then
    libscript_path_prepend "${_eb_home}/${_eb_pkg}/${_eb_ver}/bin"
  elif [ -d "${_eb_home}/${_eb_pkg}/v${_eb_ver}/bin" ]; then
    libscript_path_prepend "${_eb_home}/${_eb_pkg}/v${_eb_ver}/bin"
  elif [ -d "${_eb_home}/${_eb_pkg}/default/bin" ]; then
    libscript_path_prepend "${_eb_home}/${_eb_pkg}/default/bin"
  elif [ -d "${_eb_home}/${_eb_pkg}/latest/bin" ]; then
    libscript_path_prepend "${_eb_home}/${_eb_pkg}/latest/bin"
  elif [ -d "${_eb_home}/${_eb_pkg}" ]; then
    _eb_fallback_bin=""
    set +f
    for _eb_sub in "${_eb_home}/${_eb_pkg}/"*/bin; do
      if [ -d "$_eb_sub" ]; then
        _eb_fallback_bin="$_eb_sub"
      fi
    done
    set -f
    if [ -n "$_eb_fallback_bin" ]; then
      libscript_path_prepend "$_eb_fallback_bin"
    fi
  fi
fi

STACK="${STACK%"${THIS_FILE}":}"
export STACK
if [ -n "$_eb_caller_dir" ]; then
  SCRIPT_DIR="$_eb_caller_dir"
fi
if [ -n "$_eb_caller_this" ]; then
  THIS_FILE="$_eb_caller_this"
fi
unset _eb_caller_this _eb_caller_dir || true
