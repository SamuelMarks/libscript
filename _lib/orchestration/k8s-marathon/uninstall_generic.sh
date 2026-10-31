#!/bin/sh
# ## Overview
# Generic uninstall implementation for k8s-marathon supporting `--purge-data`.
#
# ## Usage
# Dispatches to `_lib/_common/uninstall_generic.sh`.

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
export DIR="${SCRIPT_DIR}"
export PACKAGE_NAME='k8s-marathon'

for _arg in "$@"; do
  if [ "$_arg" = "--purge-data" ]; then
    rm -rf "${K8S_MARATHON_STATE_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/k8s-marathon/state}"
  fi
done

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/uninstall_generic.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
