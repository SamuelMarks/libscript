#!/bin/sh
# ## Overview
# End-to-end integration test suite for the Open edX stack.
#
# ## Usage
# Verifies that Open edX LMS and Studio/CMS serve registration and login screens,
# authenticate sessions, and navigate past the login gate without error.

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

if [ -f "$SCRIPT_DIR/env.sh" ]; then
  unset SCRIPT_NAME || true
  . "$SCRIPT_DIR/env.sh"
fi

printf '==> Executing Open edX End-to-End Registration and Login Verification...
'
if command -v python3 >/dev/null 2>&1; then
  python3 "$SCRIPT_DIR/test_harness.py"
elif command -v python >/dev/null 2>&1; then
  python "$SCRIPT_DIR/test_harness.py"
else
  printf 'Python runtime required for Open edX end-to-end verification.
' >&2
  exit 1
fi
