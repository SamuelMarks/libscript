#!/bin/sh
# ## Overview
# Environment initialization for k8s-marathon.
#
# ## Usage
# . ./_lib/orchestration/k8s-marathon/env.sh

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
: "${K8S_MARATHON_VERSION:=latest}"
: "${K8S_MARATHON_HOME:=${LIBSCRIPT_HOME}/k8s-marathon/${K8S_MARATHON_VERSION}}"
: "${K8S_MARATHON_PORT:=8081}"
: "${K8S_MARATHON_NAMESPACE:=default}"
: "${K8S_MARATHON_BACKEND:=k8s}"
: "${K8S_MARATHON_URL:=http://127.0.0.1:${K8S_MARATHON_PORT}}"

export K8S_MARATHON_VERSION
export K8S_MARATHON_HOME
export K8S_MARATHON_PORT
export K8S_MARATHON_NAMESPACE
export K8S_MARATHON_BACKEND
export K8S_MARATHON_URL

if [ -d "${K8S_MARATHON_HOME}/bin" ]; then
  case ":${PATH:-}:" in
    *":${K8S_MARATHON_HOME}/bin:"*) ;;
    *) PATH="${K8S_MARATHON_HOME}/bin:${PATH:-}" ;;
  esac
  export PATH
fi
