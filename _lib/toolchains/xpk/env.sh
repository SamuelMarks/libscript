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
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'

XPK_VERSION="${XPK_VERSION:-latest}"
if [ "${XPK_VERSION}" = "latest" ]; then
  EXACT_VERSION="latest"
else
  EXACT_VERSION="${XPK_VERSION}"
fi

export XPK_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/xpk/${EXACT_VERSION}"
export PATH="${XPK_DIR}/bin:${PATH}"
export PYTHONPATH="${XPK_DIR}:${PYTHONPATH:-}"
