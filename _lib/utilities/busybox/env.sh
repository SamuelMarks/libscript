#!/bin/sh
# ## Overview
# Internal script for busybox.
#
# ## Usage
# Executes initialization, logic, or testing for busybox.
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

BUSYBOX_VERSION="${BUSYBOX_VERSION:-latest}"
if [ "${BUSYBOX_VERSION}" = "latest" ]; then
  EXACT_VERSION="latest"
else
  EXACT_VERSION="${BUSYBOX_VERSION}"
fi

export PATH="${LIBSCRIPT_HOME:-$HOME/.libscript}/busybox/${EXACT_VERSION}/bin:${PATH}"
