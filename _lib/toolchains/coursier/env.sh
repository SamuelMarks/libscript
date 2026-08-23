#!/bin/sh
# ## Overview
# Internal script for coursier.
#
# ## Usage
# Executes initialization, logic, or testing for coursier.
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

COURSIER_VERSION="${COURSIER_VERSION:-latest}"
if [ "${COURSIER_VERSION}" = "latest" ]; then
  EXACT_VERSION="latest"
else
  EXACT_VERSION="${COURSIER_VERSION}"
fi

export COURSIER_ROOT="${LIBSCRIPT_HOME:-$HOME/.libscript}/coursier/${COURSIER_VERSION:-latest}"
export PATH="$COURSIER_ROOT/bin:${PATH}"

