#!/bin/sh
# ## Overview
# Environment variable initialization script for the maven component.
# It sets up necessary paths and environment variables required for the component
# to function correctly within the libscript context.
#
# ## Usage
# Source this script to load the environment variables. Do not execute it directly.


set -feu
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

MAVEN_VERSION="${MAVEN_VERSION:-latest}"
if [ "${MAVEN_VERSION}" = "latest" ]; then
  EXACT_VERSION="3.9.6"
else
  EXACT_VERSION="${MAVEN_VERSION}"
fi

export PATH="${LIBSCRIPT_HOME:-$HOME/.libscript}/maven/${EXACT_VERSION}/bin:${PATH}"
