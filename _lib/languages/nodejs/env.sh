#!/bin/sh
# ## Overview
# Internal script for nodejs.
#
# ## Usage
# Executes initialization, logic, or testing for nodejs.
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

NODEJS_VERSION="${NODEJS_VERSION:-latest}"
export NODEJS_VERSION
_nodejs_home="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/nodejs"
for _nodejs_cand in "${_nodejs_home}/${NODEJS_VERSION}/bin" "${_nodejs_home}/v${NODEJS_VERSION#v}/bin" "${_nodejs_home}/default/bin"; do
  if [ -d "$_nodejs_cand" ] || [ "$_nodejs_cand" = "${_nodejs_home}/${NODEJS_VERSION}/bin" ]; then
    case ":${PATH:-}:" in
      *":${_nodejs_cand}:"*) ;;
      *) PATH="${_nodejs_cand}${PATH:+:${PATH}}" ;;
    esac
  fi
done
export PATH
