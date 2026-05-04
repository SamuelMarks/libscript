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
DIR=$(CDPATH='' cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(D="${DIR}"; while [ ! -f "${D}"'/ROOT' ]; do D="$(dirname -- "${D}")"; done; printf '%s' "${D}")}"

for LIB in _lib/_common/pkg_mgr.sh ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

SQLITE_INSTALL_METHOD="${SQLITE_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-system}}"

if [ "${SQLITE_INSTALL_METHOD}" = 'system' ]; then
  libscript_depends 'sqlite'
else
  log_info "[WARN] From-source or alternative installation requested for sqlite, but currently only system package manager is fully supported."
  libscript_depends 'sqlite'
fi

case "1" in
  "$( [ -n "${SQLITE_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ] && echo 1 )")
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "unix:${SQLITE_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 ; then
    true
  fi
    ;;
  "$( [ -n "${SQLITE_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${SQLITE_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ] && echo 1 )")
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${SQLITE_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${SQLITE_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
    ;;
  "$( [ -n "${SQLITE_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ] && echo 1 )")
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${SQLITE_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
    ;;
esac
