#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
# Resolve component directory and LibScript root
DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(D="${DIR}"; while [ ! -f "${D}/ROOT" ] && [ "${D}" != "/" ]; do D="$(dirname -- "${D}")"; done; [ "${D}" = "/" ] && D="${DIR}"; printf '%s' "${D}")}"
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
