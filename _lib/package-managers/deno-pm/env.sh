#!/bin/sh
# ## Overview
# Environment variable initialization script for the deno-pm component.
# It sets up necessary paths and environment variables required for the component
# to function correctly within the libscript context.
#
# ## Usage
# Source this script to load the environment variables. Do not execute it directly.


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


DENO_PM_VERSION="${DENO_PM_VERSION:-latest}"
export PATH="${LIBSCRIPT_HOME:-$HOME/.libscript}/deno-pm/${DENO_PM_VERSION}/bin:${PATH}"

if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/languages/deno/env.sh" ]; then
  # shellcheck disable=SC1090,SC1091
  . "${LIBSCRIPT_ROOT_DIR}/_lib/languages/deno/env.sh"
else
  export PATH="${LIBSCRIPT_HOME:-$HOME/.libscript}/deno/latest/bin:${PATH}"
fi
