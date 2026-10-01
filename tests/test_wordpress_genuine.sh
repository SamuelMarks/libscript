#!/bin/sh
# ## Overview
# Tests genuine WordPress PHP execution by sending a request to the installer.
#
# ## Usage
# ./tests/test_wordpress_genuine.sh

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

printf "[INFO] Testing genuine WordPress PHP execution...\n"
if ! curl -s -I "http://localhost:80/wp-admin/install.php" | grep -q "200 OK"; then
  printf "[ERROR] WordPress install.php did not return 200 OK.\n" >&2
  exit 1
fi
printf "[PASS] Genuine WordPress execution confirmed.\n"
