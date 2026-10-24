#!/bin/sh
# ## Overview
# Implements automated tests to verify the correctness of the component 'netctl' stack,
# including SPA fallback, WebSocket Upgrade headers, WASM MIME types, and declarative .ingress apply.
# 
# ## Usage
# Execute this script to run the test suite for netctl.

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
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

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  printf '%s
' "Usage: $(basename "$0")"
  printf '%s
' "Implements automated tests to verify the correctness of the component 'netctl' stack."
  printf '
'
  printf '%s
' "Options:"
  printf '%s
' "  --help, -h, /?, -?  Show this help message."
  exit 0
fi

export LIBSCRIPT_ROOT_DIR

NGINX_OUT=$("${SCRIPT_DIR}/cli.sh" --domain example.local --listen 8080 --spa / "/var/www/app" --ws /ws "ws://127.0.0.1:8000/ws" --proxy /api "http://127.0.0.1:8000" --emit nginx)
printf '%s
' "$NGINX_OUT" | grep -q "server_name example.local;"
printf '%s
' "$NGINX_OUT" | grep -q "application/wasm wasm;"
printf '%s
' "$NGINX_OUT" | grep -q "try_files \$uri \$uri/ /index.html;"
printf '%s
' "$NGINX_OUT" | grep -q "proxy_set_header Upgrade \$http_upgrade;"

CADDY_OUT=$("${SCRIPT_DIR}/cli.sh" --listen 8080 --spa / "/var/www/app" --emit caddy)
printf '%s
' "$CADDY_OUT" | grep -q "try_files {path} {path}/ /index.html"

APACHE_OUT=$("${SCRIPT_DIR}/cli.sh" --listen 8080 --spa / "/var/www/app" --ws /ws "ws://127.0.0.1:8000/ws" --emit apache)
printf '%s
' "$APACHE_OUT" | grep -q "FallbackResource /index.html"
printf '%s
' "$APACHE_OUT" | grep -q "RewriteCond %{HTTP:Upgrade} websocket"

printf '%s
' "netctl test pass"
