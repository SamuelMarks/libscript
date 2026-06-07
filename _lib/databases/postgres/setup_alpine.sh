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
DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)

SCRIPT_NAME="${DIR}"'/env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"

apk add 'openrc' 'postgresql'"${POSTGRES_VERSION}" 'postgresql'"${POSTGRES_VERSION}"'-contrib' 'postgresql'"${POSTGRES_VERSION}"'-openrc'
EXISTED=0
if [ -f "/etc/init.d/${LIBSCRIPT_SERVICE_NAME:-postgresql}" ]; then
  EXISTED=1
fi
if [ "${EXISTED}" -ne 1 ]; then
  rc-update add "${LIBSCRIPT_SERVICE_NAME:-postgresql}"
fi

STDOUT="$(mktemp)"
STDERR="$(mktemp)"
trap 'rm -f -- "${STDOUT}" "${STDERR}"' EXIT HUP INT QUIT TERM

if ! rc-service "${LIBSCRIPT_SERVICE_NAME:-postgresql}" start >"${STDOUT}" 2>"${STDERR}"; then
  rc="${?}"
  if [ ! "${STDERR}" = ' * WARNING: postgresql is already starting' ]; then
    >&2 printf '%s\n' "${STDERR}"
    printf '%s\n' "${STDOUT}"
    exit "${rc}"
  fi
fi

if [ -n "${POSTGRES_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "unix:${POSTGRES_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${POSTGRES_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${POSTGRES_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
fi
