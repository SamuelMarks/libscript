#!/bin/sh
# ## Overview
# Internal script for httpd.
#
# ## Usage
# Executes initialization, logic, or testing for httpd.
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

HTTPD_VERSION="${HTTPD_VERSION:-latest}"
if [ "${HTTPD_VERSION}" = "latest" ]; then
  EXACT_VERSION="latest"
else
  EXACT_VERSION="${HTTPD_VERSION}"
fi

export PATH="${LIBSCRIPT_HOME:-$HOME/.libscript}/httpd/${EXACT_VERSION}/bin:${PATH}"
