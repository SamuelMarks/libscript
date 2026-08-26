#!/bin/sh
# ## Overview
# Environment initialization for Deno.
#
# ## Usage
# Sets up `DENO_VERSION` and prepends Deno to PATH.

# shellcheck disable=SC2296,SC3028,SC3040,SC3054
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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
_SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
export DENO_INSTALL_METHOD="${DENO_INSTALL_METHOD:-libscript_native}"
DENO_VERSION="${DENO_VERSION:-latest}"
export PATH="${LIBSCRIPT_HOME:-$HOME/.libscript}/deno/${DENO_VERSION}/bin:${PATH}"