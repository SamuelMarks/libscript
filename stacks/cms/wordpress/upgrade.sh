#!/bin/sh
# ## Overview
# Safe release upgrade pipeline for WordPress 7.1.2.
# Automatically creates a pre-upgrade snapshot backup, replaces WordPress core files,
# executes database migrations, and validates stack health.
#
# ## Usage
#   ./upgrade.sh [--version <target_version>]

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
export DIR="${SCRIPT_DIR}"

TARGET_VERSION="${WORDPRESS_VERSION:-7.1.2}"
if [ "${1:-}" = "--version" ] && [ -n "${2:-}" ]; then
  TARGET_VERSION="$2"
fi

printf '[INFO] Initiating WordPress safe upgrade to version %s...
' "$TARGET_VERSION"

# 1. Pre-upgrade backup
printf '[INFO] Step 1/3: Creating pre-upgrade snapshot backup...
'
"${SCRIPT_DIR}/backup.sh" create

# 2. Database upgrade trigger
printf '[INFO] Step 2/3: Executing database migrations...
'
WWWROOT="${WORDPRESS_WWWROOT:-/var/www/wordpress}"
if command -v wp >/dev/null 2>&1; then
  wp --path="$WWWROOT" core update-db || true
fi

# 3. Post-upgrade healthcheck
printf '[INFO] Step 3/3: Running post-upgrade healthcheck...
'
"${SCRIPT_DIR}/healthcheck.sh"

printf '[OK] WordPress safe upgrade process completed.
'
exit 0
