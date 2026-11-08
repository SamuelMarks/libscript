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
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
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
printf '%s
' "$NGINX_OUT" | grep -q "proxy_connect_timeout 60s;"
printf '%s
' "$NGINX_OUT" | grep -q "proxy_send_timeout 300s;"
printf '%s
' "$NGINX_OUT" | grep -q "proxy_read_timeout 300s;"
printf '%s
' "$NGINX_OUT" | grep -q "proxy_buffering off;"
printf '%s
' "$NGINX_OUT" | grep -q "proxy_cache off;"

CUSTOM_TIMEOUT_OUT=$("${SCRIPT_DIR}/netctl.sh" --domain example.local --listen 80 --listen 443 --proxy-read-timeout 600s --proxy /api "http://127.0.0.1:8000" --emit nginx)
printf '%s
' "$CUSTOM_TIMEOUT_OUT" | grep -q "proxy_read_timeout 600s;"

CADDY_OUT=$("${SCRIPT_DIR}/cli.sh" --listen 8080 --spa / "/var/www/app" --emit caddy)
printf '%s
' "$CADDY_OUT" | grep -q "try_files {path} {path}/ /index.html"

APACHE_OUT=$("${SCRIPT_DIR}/cli.sh" --listen 8080 --spa / "/var/www/app" --ws /ws "ws://127.0.0.1:8000/ws" --emit apache)
printf '%s
' "$APACHE_OUT" | grep -q "FallbackResource /index.html"
printf '%s
' "$APACHE_OUT" | grep -q "RewriteCond %{HTTP:Upgrade} websocket"

# Verify /.well-known/acme-challenge/ emission, tls: "letsencrypt" cert resolution from CERT_STORE_DIR, and read-only permission enforcement
printf '%s\n' "$NGINX_OUT" | grep -q "location ^~ /.well-known/acme-challenge/"

if command -v openssl >/dev/null 2>&1; then
  _netctl_tmp=$(mktemp -d "${TMPDIR:-/tmp}/netctl_tls_test.XXXXXX")
  _cstore="${_netctl_tmp}/certs"
  _dom='secure.example.org'
  mkdir -p "${_cstore}/live/${_dom}"
  openssl req -x509 -nodes -days 30 -newkey rsa:2048 -keyout "${_netctl_tmp}/ca.key" -out "${_netctl_tmp}/ca.crt" -subj "/CN=Test Fake LE Root CA" >/dev/null 2>&1
  openssl req -nodes -newkey rsa:2048 -keyout "${_cstore}/live/${_dom}/privkey.pem" -out "${_netctl_tmp}/leaf.csr" -subj "/CN=${_dom}" >/dev/null 2>&1
  openssl x509 -req -days 30 -in "${_netctl_tmp}/leaf.csr" -CA "${_netctl_tmp}/ca.crt" -CAkey "${_netctl_tmp}/ca.key" -CAcreateserial -out "${_cstore}/live/${_dom}/fullchain.pem" >/dev/null 2>&1

  cat << EOF_TLS_MF > "${_netctl_tmp}/libscript.json"
{
  "ingress": {
    "provider": "nginx",
    "domain": "${_dom}",
    "tls": "letsencrypt",
    "cert_store_dir": "${_cstore}",
    "routes": {
      "/": {"static": "./dist", "spa": true}
    }
  }
}
EOF_TLS_MF

  TLS_NGINX_OUT=$(CERT_STORE_DIR="$_cstore" "${SCRIPT_DIR}/cli.sh" apply "${_netctl_tmp}/libscript.json" --format nginx)
  printf '%s\n' "$TLS_NGINX_OUT" | grep -q "listen 443 ssl;"
  printf '%s\n' "$TLS_NGINX_OUT" | grep -q "ssl_certificate ${_cstore}/live/${_dom}/fullchain.pem;"
  printf '%s\n' "$TLS_NGINX_OUT" | grep -q "ssl_certificate_key ${_cstore}/live/${_dom}/privkey.pem;"
  printf '%s\n' "$TLS_NGINX_OUT" | grep -q "root ${_cstore}/acme-webroot;"
  if [ -w "${_cstore}/live/${_dom}/fullchain.pem" ] && [ "$(id -u 2>/dev/null || printf '1')" != "0" ]; then
    chmod -R u+w "$_netctl_tmp" 2>/dev/null || true
    rm -rf "$_netctl_tmp"
    printf '%s\n' '[FAIL] Persisted fullchain.pem should be read-only (0444)' >&2
    exit 1
  fi
  chmod -R u+w "$_netctl_tmp" 2>/dev/null || true
  rm -rf "$_netctl_tmp"
fi

printf '%s
' "netctl test pass"
