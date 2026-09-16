#!/bin/sh
# ## Overview
# Defines environment variables for the Memcached Cache component on Unix systems.
# It aligns the standard `LIBSCRIPT_LISTEN_PORT` with `MEMCACHED_LISTEN`
# if provided, ensuring correct port configuration.
# 
# ## Usage
# Source this file to apply Memcached's environment variables.


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
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
export LIBSCRIPT_LISTEN_PORT="${MEMCACHED_LISTEN:-${LIBSCRIPT_LISTEN_PORT:-11211}}"

MEMCACHED_VERSION="${MEMCACHED_VERSION:-latest}"
export PATH="${LIBSCRIPT_HOME:-$HOME/.libscript}/memcached/${MEMCACHED_VERSION}/bin:${PATH}"
