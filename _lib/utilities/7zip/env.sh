#!/bin/sh
set -feu
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
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'

SEVENZIP_VERSION="${SEVENZIP_VERSION:-latest}"
if [ "${SEVENZIP_VERSION}" = "latest" ]; then
  EXACT_VERSION="latest"
else
  EXACT_VERSION="${SEVENZIP_VERSION}"
fi

export PATH="${LIBSCRIPT_HOME:-$HOME/.libscript}/7zip/${EXACT_VERSION}/bin:${PATH}"
