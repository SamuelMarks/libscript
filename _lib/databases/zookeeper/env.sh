#!/bin/sh
# ## Overview
# Environment initialization for Apache ZooKeeper.
#
# ## Usage
# . ./_lib/databases/zookeeper/env.sh

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"

: "${LIBSCRIPT_HOME:=${HOME:-/tmp}/.libscript}"
: "${ZOOKEEPER_VERSION:=latest}"
: "${ZOOKEEPER_HOME:=${LIBSCRIPT_HOME}/zookeeper/${ZOOKEEPER_VERSION}}"
: "${ZOOKEEPER_CLIENT_PORT:=2181}"
: "${ZOOKEEPER_DATA_DIR:=${LIBSCRIPT_HOME}/zookeeper/data}"

export ZOOKEEPER_VERSION
export ZOOKEEPER_HOME
export ZOOKEEPER_CLIENT_PORT
export ZOOKEEPER_DATA_DIR

if [ -d "${ZOOKEEPER_HOME}/bin" ]; then
  case ":${PATH:-}:" in
    *":${ZOOKEEPER_HOME}/bin:"*) ;;
    *) PATH="${ZOOKEEPER_HOME}/bin:${PATH:-}" ;;
  esac
  export PATH
fi
