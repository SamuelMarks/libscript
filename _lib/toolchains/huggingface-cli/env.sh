#!/bin/sh
# ## Overview
# Internal script for huggingface-cli.
#
# ## Usage
# Executes initialization, logic, or testing for huggingface-cli.
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

HUGGINGFACE_CLI_VERSION="${HUGGINGFACE_CLI_VERSION:-latest}"
if [ "${HUGGINGFACE_CLI_VERSION}" = "latest" ]; then
  EXACT_VERSION="latest"
else
  EXACT_VERSION="${HUGGINGFACE_CLI_VERSION}"
fi

export HUGGINGFACE_CLI_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/huggingface-cli/${EXACT_VERSION}"
export PATH="${HUGGINGFACE_CLI_DIR}/bin:${PATH}"
export PYTHONPATH="${HUGGINGFACE_CLI_DIR}:${PYTHONPATH:-}"
