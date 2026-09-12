#!/bin/sh
# ## Overview
# Internal script for xpk.
#
# ## Usage
# Executes initialization, logic, or testing for xpk.
set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

XPK_VERSION="${XPK_VERSION:-latest}"
if [ "${XPK_VERSION}" = "latest" ]; then
  EXACT_VERSION="latest"
else
  EXACT_VERSION="${XPK_VERSION}"
fi

export XPK_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/xpk/${EXACT_VERSION}"
export PATH="${XPK_DIR}/bin:${PATH}"
export PYTHONPATH="${XPK_DIR}:${PYTHONPATH:-}"
