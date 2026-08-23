#!/bin/sh
# ## Overview
# Internal script for wait4x.
#
# ## Usage
# Executes initialization, logic, or testing for wait4x.
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

WAIT4X_VERSION="${WAIT4X_VERSION:-latest}"
if [ "${WAIT4X_VERSION}" = "latest" ]; then
  EXACT_VERSION="latest"
else
  EXACT_VERSION="${WAIT4X_VERSION}"
fi

export WAIT4X_ROOT="${LIBSCRIPT_HOME:-$HOME/.libscript}/wait4x/${WAIT4X_VERSION:-latest}"
export PATH="$WAIT4X_ROOT/bin:${PATH}"

