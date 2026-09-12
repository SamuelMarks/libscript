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
  THIS_FILE="${BASH_SOURCE}"
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

HUGGINGFACE_CLI_VERSION="${HUGGINGFACE_CLI_VERSION:-latest}"
if [ "${HUGGINGFACE_CLI_VERSION}" = "latest" ]; then
  EXACT_VERSION="latest"
else
  EXACT_VERSION="${HUGGINGFACE_CLI_VERSION}"
fi

export HUGGINGFACE_CLI_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/huggingface-cli/${EXACT_VERSION}"
export PATH="${HUGGINGFACE_CLI_DIR}/bin:${PATH}"
export PYTHONPATH="${HUGGINGFACE_CLI_DIR}:${PYTHONPATH:-}"
