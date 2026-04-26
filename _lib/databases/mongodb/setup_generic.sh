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
DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

for lib in '_lib/_common/pkg_mgr.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

MONGODB_INSTALL_METHOD="${MONGODB_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-system}}"

if [ "${MONGODB_INSTALL_METHOD}" = 'system' ]; then
  depends 'mongodb'
else
  echo "[WARN] From-source or alternative installation requested for mongodb, but currently only system package manager is fully supported."
  depends 'mongodb'
fi

mongo_conf="/etc/mongod.conf"
if [ -f "${mongo_conf}" ]; then
  if [ -n "${MONGODB_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
    priv sed -i "s|^ *port: .*|  port: ${MONGODB_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}|" "${mongo_conf}"
  fi
  if [ -n "${MONGODB_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ]; then
    priv sed -i "s|^ *bindIp: .*|  bindIp: ${MONGODB_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}|" "${mongo_conf}"
  fi
fi

case "1" in
  "$( [ -n "${MONGODB_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ] && echo 1 )")
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "unix:${MONGODB_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 ; then
    true
  fi
    ;;
  "$( [ -n "${MONGODB_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${MONGODB_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ] && echo 1 )")
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${MONGODB_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${MONGODB_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
    ;;
  "$( [ -n "${MONGODB_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ] && echo 1 )")
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${MONGODB_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
    ;;
esac
