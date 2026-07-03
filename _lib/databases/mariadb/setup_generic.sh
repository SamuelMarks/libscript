#!/bin/sh
# ## Overview
# Generic setup module for MariaDB.
#
# ## Usage
# Installs MariaDB using the system package manager and configures ports and bind addresses.


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
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
DIR="${SCRIPT_DIR}"

for LIB in "_lib/_common/pkg_mgr.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

MARIADB_INSTALL_METHOD="${MARIADB_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript-native}}"

if [ "${MARIADB_INSTALL_METHOD}" = 'system' ]; then
  libscript_depends 'mariadb'
else
  log_info "[WARN] From-source or alternative installation requested for mariadb, but currently only system package manager is fully supported."
  libscript_depends 'mariadb'
fi

MARIADB_CONF="/etc/mysql/mariadb.conf.d/50-server.cnf"
if [ ! -f "${MARIADB_CONF}" ] && [ -f "/etc/my.cnf" ]; then
  MARIADB_CONF="/etc/my.cnf"
elif [ ! -f "${MARIADB_CONF}" ] && [ -f "/etc/mysql/my.cnf" ]; then
  MARIADB_CONF="/etc/mysql/my.cnf"
fi

if [ -f "${MARIADB_CONF}" ]; then
  if [ -n "${MARIADB_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
    priv sed -i "s|^ *port *=.*|port = ${MARIADB_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}|" "${MARIADB_CONF}"
  fi
  if [ -n "${MARIADB_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ]; then
    priv sed -i "s|^ *bind-address *=.*|bind-address = ${MARIADB_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}|" "${MARIADB_CONF}"
  fi
fi

case "${_LIBSCRIPT_TRUE:-1}" in
  "$( [ -n "${MARIADB_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ] && printf '%s\n' 1 )")
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "unix:${MARIADB_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 ; then
    true
  fi
    ;;
  "$( [ -n "${MARIADB_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${MARIADB_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ] && printf '%s\n' 1 )")
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${MARIADB_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${MARIADB_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
    ;;
  "$( [ -n "${MARIADB_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ] && printf '%s\n' 1 )")
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${MARIADB_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
    ;;
esac
