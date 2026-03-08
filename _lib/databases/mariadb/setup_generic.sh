#!/bin/sh
# shellcheck disable=SC3054,SC3040,SC2296,SC2128,SC2039,SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145



set -feu
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE}"

elif [ "${ZSH_VERSION-}" ]; then
  this_file="${0}"

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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091,SC2034
. "${SCRIPT_NAME}"

MARIADB_INSTALL_METHOD="${MARIADB_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-system}}"

if [ "${MARIADB_INSTALL_METHOD}" = 'system' ]; then
  depends 'mariadb'
else
  echo "[WARN] From-source or alternative installation requested for mariadb, but currently only system package manager is fully supported."
  depends 'mariadb'
fi

mariadb_conf="/etc/mysql/mariadb.conf.d/50-server.cnf"
if [ ! -f "${mariadb_conf}" ] && [ -f "/etc/my.cnf" ]; then
  mariadb_conf="/etc/my.cnf"
elif [ ! -f "${mariadb_conf}" ] && [ -f "/etc/mysql/my.cnf" ]; then
  mariadb_conf="/etc/mysql/my.cnf"
fi

if [ -f "${mariadb_conf}" ]; then
  if [ -n "${MARIADB_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
    priv sed -i "s|^ *port *=.*|port = ${MARIADB_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}|" "${mariadb_conf}"
  fi
  if [ -n "${MARIADB_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ]; then
    priv sed -i "s|^ *bind-address *=.*|bind-address = ${MARIADB_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}|" "${mariadb_conf}"
  fi
fi

if [ -n "${MARIADB_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
  "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "unix:${MARIADB_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 || true
elif [ -n "${MARIADB_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${MARIADB_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${MARIADB_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${MARIADB_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 || true
elif [ -n "${MARIADB_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${MARIADB_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 || true
fi
