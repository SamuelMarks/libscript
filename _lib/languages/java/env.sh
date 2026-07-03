#!/bin/sh
# ## Overview
# Environment initialization for Java.
#
# ## Usage
# Sets up `JAVA_HOME` and prepends it to PATH.

# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
JAVA_VERSION="${JAVA_VERSION:-17}"
if [ "${JAVA_VERSION}" = "latest" ]; then
  JAVA_VERSION="21"
fi
export JAVA_HOME="${LIBSCRIPT_HOME:-$HOME/.libscript}/java/${JAVA_VERSION}"
export PATH="${JAVA_HOME}/bin:${PATH}"