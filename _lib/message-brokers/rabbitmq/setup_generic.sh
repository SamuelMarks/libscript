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
else
  this_file="${0}"
fi
DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

for lib in '_lib/_common/pkg_mgr.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

if depends 'rabbitmq'; then
    conf_file="/etc/rabbitmq/rabbitmq.conf"
    priv mkdir -p /etc/rabbitmq
    if [ -n "${RABBITMQ_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
      echo "listeners.tcp.default = ${RABBITMQ_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" | priv tee -a "${conf_file}" >/dev/null
    fi
    >&2 printf "RabbitMQ installed via package manager.
"
else
    >&2 printf "RabbitMQ package not found for this OS.
"
    exit 1
fi

case "1" in
  "$( [ -n "${RABBITMQ_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ] && echo 1 )")
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "unix:${RABBITMQ_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 ; then
    true
  fi
    ;;
  "$( [ -n "${RABBITMQ_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${RABBITMQ_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ] && echo 1 )")
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${RABBITMQ_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${RABBITMQ_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
    ;;
  "$( [ -n "${RABBITMQ_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ] && echo 1 )")
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${RABBITMQ_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
    ;;
esac
