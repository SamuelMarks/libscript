#!/bin/sh
# ## Overview
# Foundational environment initialization module for LibScript components.
# Resolves the component package name, active version, and idempotently prepends
# the component's binary directory to PATH.
#
# ## Usage
# . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_base.sh"

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

# ## libscript_path_prepend
# Idempotently prepends one or more colon-separated directories to PATH.
libscript_path_prepend() {
  for _dir in "$@"; do
    [ -z "$_dir" ] && continue
    case ":${PATH:-}:" in
      *":${_dir}:"*) ;;
      *) PATH="${_dir}${PATH:+:${PATH}}" ;;
    esac
  done
  export PATH
}

_eb_pkg="${PACKAGE_NAME:-}"
if [ -z "$_eb_pkg" ] && [ -n "${DIR:-}" ]; then
  _eb_pkg=$(basename "$DIR")
fi
if [ -n "$_eb_pkg" ] && [ "$_eb_pkg" != "_common" ]; then
  _eb_home="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}"
  _eb_ver="${LIBSCRIPT_VERSION:-latest}"
  libscript_path_prepend "${_eb_home}/${_eb_pkg}/${_eb_ver}/bin" "${_eb_home}/${_eb_pkg}/default/bin"
fi
