#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'
# Resolve component directory and LibScript root
DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"
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
os_uninstall_script="${DIR}"'/uninstall_'"${TARGET_OS}"'.sh'
if [ -f "${os_uninstall_script}" ]; then
  SCRIPT_NAME="${os_uninstall_script}"
  export SCRIPT_NAME
  . "${SCRIPT_NAME}"
else
  # Generic uninstall logic often just removes directories or package manager packages
  SCRIPT_NAME="${DIR}"'/uninstall_generic.sh'
  export SCRIPT_NAME
  [ -f "${SCRIPT_NAME}" ] && . "${SCRIPT_NAME}"
fi

# Automated netctl unregistration
if [ -n "${CADDY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --unlisten "unix:${CADDY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${CADDY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${CADDY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --unlisten "${CADDY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${CADDY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${CADDY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --unlisten "${CADDY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
fi
