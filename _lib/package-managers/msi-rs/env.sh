#!/bin/sh
# ## Overview
# Environment variable initialization script for the msi-rs component.
# It sets up necessary paths and environment variables required for the component
# to function correctly within the libscript context.
#
# ## Usage
# Source this script to load the environment variables. Do not execute it directly:
#   . ./env.sh

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
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

MSI_RS_VERSION="${MSI_RS_VERSION:-latest}"
if [ -d "${LIBSCRIPT_ROOT_DIR}/tools/wix" ]; then
  PATH="${LIBSCRIPT_ROOT_DIR}/tools/wix:${PATH}"
fi
if [ -d "${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/default/bin" ]; then
  PATH="${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/default/bin:${PATH}"
fi
PATH="${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/${MSI_RS_VERSION}/bin:${PATH}"
export PATH
