#!/bin/sh
# ## Overview
# Shared generic setup fallbacks for LibScript components.
#
# ## Usage
# Sourced during component installation workflows.

set -feu
_sg_caller_this="${THIS_FILE:-}"; _sg_caller_dir="${SCRIPT_DIR:-}"
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
    [ -n "$_sg_caller_this" ] && THIS_FILE="$_sg_caller_this"
    [ -n "$_sg_caller_dir" ] && SCRIPT_DIR="$_sg_caller_dir"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
# # LibScript Common Generic Setup
#

# Component name should be set by the caller (component_core.sh sets PACKAGE_NAME)
_PKG_MGR_NAME="${PACKAGE_NAME:-}"

if [ -z "${_PKG_MGR_NAME}" ]; then
  # Fallback: try to get it from the caller directory name or pwd if not set
  if [ -n "${_sg_caller_dir:-}" ]; then
    _PKG_MGR_NAME=$(basename "${_sg_caller_dir}")
  else
    _PKG_MGR_NAME=$(basename "$(pwd)")
  fi
fi

for LIB in "_lib/_common/pkg_mgr.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

# Attempt to install via the detected package manager
libscript_depends "${_PKG_MGR_NAME}"

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_sg_caller_dir:-}" ] && SCRIPT_DIR="$_sg_caller_dir"
[ -n "${_sg_caller_this:-}" ] && THIS_FILE="$_sg_caller_this"
unset _sg_caller_this _sg_caller_dir || true
