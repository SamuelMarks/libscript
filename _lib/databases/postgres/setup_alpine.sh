#!/bin/sh
# ## Overview
# Alpine Linux setup script for PostgreSQL.
#
# ## Usage
# Installs PostgreSQL via apk and sets up openrc services.


set -feu
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
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)

SCRIPT_NAME="${DIR}"'/env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"

for LIB in '_lib/_common/pkg_mgr.sh' '_lib/_common/priv.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

# Detect available postgresql version if default 15 is not available
detect_pkg_mgr
if ! is_installed 'postgresql'"${POSTGRES_VERSION}"; then
  for v in 18 17 16 15; do
    if pkg_mgr 'openrc' "postgresql$v" "postgresql$v-client" "postgresql$v-contrib" "postgresql$v-openrc" 2>/dev/null; then
      POSTGRES_VERSION="$v"
      export POSTGRES_VERSION
      break
    fi
  done
fi

if ! is_installed 'postgresql'"${POSTGRES_VERSION}"; then
  pkg_mgr 'openrc' 'postgresql'"${POSTGRES_VERSION}" 'postgresql'"${POSTGRES_VERSION}"'-client' 'postgresql'"${POSTGRES_VERSION}"'-contrib' 'postgresql'"${POSTGRES_VERSION}"'-openrc'
fi
EXISTED=0
if [ -f "/etc/init.d/${LIBSCRIPT_SERVICE_NAME:-postgresql}" ]; then
  EXISTED=1
fi
if [ "${EXISTED}" -ne 1 ]; then
  priv rc-update add "${LIBSCRIPT_SERVICE_NAME:-postgresql}" || true
fi

STDOUT="$(mktemp)"
STDERR="$(mktemp)"
trap 'rm -f -- "${STDOUT}" "${STDERR}"' EXIT HUP INT QUIT TERM

priv /etc/init.d/postgresql setup 2>/dev/null || true

if ! priv rc-service "${LIBSCRIPT_SERVICE_NAME:-postgresql}" start >"${STDOUT}" 2>"${STDERR}"; then
  if [ ! "${STDERR}" = ' * WARNING: postgresql is already starting' ]; then
    >&2 printf '%s\n' "${STDERR}"
    printf '%s\n' "${STDOUT}"
  fi
fi

if [ -n "${POSTGRES_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" --listen "unix:${POSTGRES_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${POSTGRES_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" --listen "${POSTGRES_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" --listen "${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
fi
