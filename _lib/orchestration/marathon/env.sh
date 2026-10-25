#!/bin/sh
# ## Overview
# Environment initialization for Marathon.
#
# ## Usage
# . ./_lib/orchestration/marathon/env.sh

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
_EB_CALLER_THIS="${THIS_FILE}"
_EB_CALLER_DIR="${SCRIPT_DIR}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_base.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

: "${LIBSCRIPT_HOME:=${HOME:-/tmp}/.libscript}"
: "${MARATHON_VERSION:=latest}"
: "${MARATHON_HOME:=${LIBSCRIPT_HOME}/marathon/${MARATHON_VERSION}}"
: "${MARATHON_HTTP_PORT:=8080}"
: "${MARATHON_URL:=http://127.0.0.1:${MARATHON_HTTP_PORT}}"

export MARATHON_VERSION
export MARATHON_HOME
export MARATHON_HTTP_PORT
export MARATHON_URL

if [ -d "${MARATHON_HOME}/bin" ]; then
  case ":${PATH:-}:" in
    *":${MARATHON_HOME}/bin:"*) ;;
    *) PATH="${MARATHON_HOME}/bin:${PATH:-}" ;;
  esac
  export PATH
fi
