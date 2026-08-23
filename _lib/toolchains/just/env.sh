#!/bin/sh
# ## Overview
# Internal script for just.
#
# ## Usage
# Executes initialization, logic, or testing for just.
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

JUST_VERSION="${JUST_VERSION:-latest}"
if [ "${JUST_VERSION}" = "latest" ]; then
  EXACT_VERSION="latest"
else
  EXACT_VERSION="${JUST_VERSION}"
fi

export JUST_ROOT="${LIBSCRIPT_HOME:-$HOME/.libscript}/just/${JUST_VERSION:-latest}"
export PATH="$JUST_ROOT/bin:${PATH}"

