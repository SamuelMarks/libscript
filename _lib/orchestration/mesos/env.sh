#!/bin/sh
# ## Overview
# Environment initialization for Apache Mesos.
#
# ## Usage
# . ./_lib/orchestration/mesos/env.sh

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
: "${MESOS_VERSION:=latest}"
: "${MESOS_HOME:=${LIBSCRIPT_HOME}/mesos/${MESOS_VERSION}}"
: "${MESOS_WORK_DIR:=${LIBSCRIPT_HOME}/mesos/work}"
: "${MESOS_MASTER:=127.0.0.1:5050}"

export MESOS_VERSION
export MESOS_HOME
export MESOS_WORK_DIR
export MESOS_MASTER

if [ -d "${MESOS_HOME}/bin" ]; then
  case ":${PATH:-}:" in
    *":${MESOS_HOME}/bin:"*) ;;
    *) PATH="${MESOS_HOME}/bin:${PATH:-}" ;;
  esac
  export PATH
fi
