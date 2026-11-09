#!/bin/sh
# ## Overview
# Serves as the primary Unix default uninstall script for components, removing INSTALLED_DIR if present.
# ## Usage
# Execute this script to perform a basic file-level uninstallation on Unix systems.
set -feu
_common_uninst_caller_this="${THIS_FILE:-}"; _common_uninst_caller_dir="${SCRIPT_DIR:-}"
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
    [ -n "$_common_uninst_caller_this" ] && THIS_FILE="$_common_uninst_caller_this"
    [ -n "$_common_uninst_caller_dir" ] && SCRIPT_DIR="$_common_uninst_caller_dir"
    unset SCRIPT_NAME || true; if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR
_common_uninst_this="${THIS_FILE}"

if ! command -v log_info >/dev/null 2>&1; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
fi
THIS_FILE="${_common_uninst_this}"

# Default uninstall logic
if [ -n "${INSTALLED_DIR:-}" ] && [ -d "${INSTALLED_DIR}" ]; then
  log_info "Removing ${INSTALLED_DIR}..."
  rm -rf "${INSTALLED_DIR}"
else
  log_info "No local installation directory found for ${PACKAGE_NAME:-component} at ${INSTALLED_DIR:-unknown}."
fi
# Add background service removal logic here if applicable
STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_common_uninst_caller_dir:-}" ] && SCRIPT_DIR="$_common_uninst_caller_dir"
[ -n "${_common_uninst_caller_this:-}" ] && THIS_FILE="$_common_uninst_caller_this"
unset SCRIPT_NAME _common_uninst_caller_this _common_uninst_caller_dir _common_uninst_this || true
