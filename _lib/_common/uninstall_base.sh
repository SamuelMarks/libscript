#!/bin/sh
# ## Overview
# Provides the foundational uninstall logic for components.
# It aggregates essential common libraries (logging, paths, package managers)
# and delegates the actual teardown process to OS-specific uninstall scripts
# (or a generic fallback), followed by unregistering associated `netctl` ports.
# 
# ## Usage
# Source or execute this file internally as the core implementation of `uninstall.sh`.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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
# Resolve component directory and LibScript root
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export DIR="${SCRIPT_DIR}"
export LIBSCRIPT_ROOT_DIR

# Source common OS info
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/os_info.sh'
export SCRIPT_NAME
. "${SCRIPT_NAME}"

# Source package manager utilities
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
. "${SCRIPT_NAME}"

# Source path resolution
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/paths.sh'
export SCRIPT_NAME
. "${SCRIPT_NAME}"
resolve_component_paths

# OS-specific delegation logic for uninstall
OS_UNINSTALL_SCRIPT="${DIR}"'/uninstall_'"${TARGET_OS}"'.sh'
if [ -f "${OS_UNINSTALL_SCRIPT}" ]; then
  SCRIPT_NAME="${OS_UNINSTALL_SCRIPT}"
  export SCRIPT_NAME
  . "${SCRIPT_NAME}"
else
  # Generic uninstall logic often just removes directories or package manager packages
  SCRIPT_NAME="${DIR}"'/uninstall_generic.sh'
  export SCRIPT_NAME
  [ -f "${SCRIPT_NAME}" ] && . "${SCRIPT_NAME}"
fi


# Automated netctl unregistration
_PKG_UPPER=$(basename "${DIR}" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
eval "_LISTEN_SOCKET=\${${_PKG_UPPER}_LISTEN_SOCKET:-\${LIBSCRIPT_LISTEN_SOCKET:-}}"
eval "_LISTEN_ADDRESS=\${${_PKG_UPPER}_LISTEN_ADDRESS:-\${LIBSCRIPT_LISTEN_ADDRESS:-}}"
eval "_LISTEN_PORT=\${${_PKG_UPPER}_LISTEN_PORT:-\${LIBSCRIPT_LISTEN_PORT:-}}"

if [ -n "${_LISTEN_SOCKET}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --unlisten "unix:${_LISTEN_SOCKET}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${_LISTEN_ADDRESS}" ] && [ -n "${_LISTEN_PORT}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --unlisten "${_LISTEN_ADDRESS}:${_LISTEN_PORT}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${_LISTEN_PORT}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --unlisten "${_LISTEN_PORT}" >/dev/null 2>&1 ; then
    true
  fi
fi
