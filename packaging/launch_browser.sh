#!/bin/sh
# ## Overview
# Cross-platform browser launcher utility.
# Launches the default or available browser (xdg-open, open, chrome, firefox)
# targeting the specified URL. If no browser is present, prints the URL and exits cleanly.
#
# ## Usage
# ./packaging/launch_browser.sh <url> [name]
#
# ## Arguments
# url   The web address to open (e.g. http://localhost:8000)
# name  Optional display label for the URL

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

URL="${1:-}"
LABEL="${2:-Open edX Portal}"

if [ -z "$URL" ] || [ "$URL" = "-h" ] || [ "$URL" = "--help" ]; then
  printf 'Usage: %s <url> [label]

' "$(basename "$THIS_FILE")"
  printf 'Launches default web browser or displays URL.
'
  exit 0
fi

if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$URL" >/dev/null 2>&1 &
elif command -v open >/dev/null 2>&1; then
  open "$URL" >/dev/null 2>&1 &
elif command -v sensible-browser >/dev/null 2>&1; then
  sensible-browser "$URL" >/dev/null 2>&1 &
else
  printf '[INFO] %s available at: %s
' "$LABEL" "$URL"
fi

exit 0
