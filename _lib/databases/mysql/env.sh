#!/bin/sh
# ## Overview
# Environment variable configuration for MySQL.
#
# ## Usage
# Source this script to populate MySQL connection variables and update PATH.

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

export MYSQL_PORT="${MYSQL_PORT:-3306}"
export MYSQL_DATABASE="${MYSQL_DATABASE:-openedx}"
export MYSQL_USER="${MYSQL_USER:-openedx}"
export MYSQL_CHARACTER_SET="${MYSQL_CHARACTER_SET:-utf8mb4}"
export MYSQL_COLLATION="${MYSQL_COLLATION:-utf8mb4_unicode_ci}"

MYSQL_VERSION="${MYSQL_VERSION:-8.4.11}"
if [ -d "${LIBSCRIPT_HOME:-$HOME/.libscript}/mysql/${MYSQL_VERSION}/bin" ]; then
  export PATH="${LIBSCRIPT_HOME:-$HOME/.libscript}/mysql/${MYSQL_VERSION}/bin:${PATH}"
fi
