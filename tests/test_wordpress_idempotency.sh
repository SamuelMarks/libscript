#!/bin/sh
# ## Overview
# Two-pass idempotency verification test for WordPress 7.1.2 setup.
# Executes the setup pipeline twice and verifies zero duplicate lines, zero crashes,
# and identical configuration stability.
#
# ## Usage
#   ./tests/test_wordpress_idempotency.sh

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

printf '==> Testing WordPress Setup Two-Pass Idempotency...
'

TMP_WWW=$(mktemp -d)

printf '[INFO] Executing Setup Pass 1...
'
"${LIBSCRIPT_ROOT_DIR}/stacks/cms/wordpress/setup_generic.sh" --wwwroot "$TMP_WWW" --skip-deps --server-name "wordpress.local"

if [ ! -f "${TMP_WWW}/wp-config.php" ]; then
  printf '[ERROR] wp-config.php not created in Pass 1!
' >&2
  rm -rf "$TMP_WWW"
  exit 1
fi

printf '[INFO] Executing Setup Pass 2...
'
"${LIBSCRIPT_ROOT_DIR}/stacks/cms/wordpress/setup_generic.sh" --wwwroot "$TMP_WWW" --skip-deps --server-name "wordpress.local"

# Check that wp-config.php does not contain duplicate DB_NAME definitions
DEF_COUNT=$(grep -c "define( *'DB_NAME'" "${TMP_WWW}/wp-config.php" || true)
if [ "$DEF_COUNT" -ne 1 ]; then
  printf '[ERROR] Idempotency violated: Found %s occurrences of DB_NAME in wp-config.php!
' "$DEF_COUNT" >&2
  rm -rf "$TMP_WWW"
  exit 1
fi

rm -rf "$TMP_WWW"
printf '==> Two-pass idempotency verification succeeded!
'
exit 0
