#!/bin/sh
# ## Overview
# Functional test suite for WordPress 7.1.2 stack and management CLI tools.
# Validates CLI routing, help synopses, and component availability.
#
# ## Usage
#   ./tests/test_wordpress_stack.sh

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

WP_DIR="${LIBSCRIPT_ROOT_DIR}/stacks/cms/wordpress"

printf '==> Testing WordPress CLI Router...
'
"${WP_DIR}/cli.sh" help

printf '==> Testing WordPress Database Console...
'
"${WP_DIR}/dbshell.sh" help

printf '==> Testing WordPress Config Engine...
'
"${WP_DIR}/config.sh" help

printf '==> Testing WordPress User Management...
'
"${WP_DIR}/user.sh" help

printf '==> Testing WordPress Backup Utility...
'
"${WP_DIR}/backup.sh" help

printf '==> Testing WordPress Cron Scheduler...
'
"${WP_DIR}/cron.sh" help

printf '==> Testing WordPress Healthcheck...
'
"${WP_DIR}/healthcheck.sh" help

printf '==> All WordPress 7.1.2 stack tools verified successfully!
'
exit 0
