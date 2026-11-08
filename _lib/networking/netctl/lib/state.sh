#!/bin/sh
# ## Overview
# Network control library module for state.
# 
# ## Usage
# This script provides internal functions and should not be executed directly.

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
: "${NETCTL_DIR:=$(cd "$SCRIPT_DIR/.." && pwd)}"
SCRIPT_NAME="${NETCTL_DIR}/lib/prelude.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"

NETCTL_STATE_FILE="${NETCTL_STATE_FILE:-.netctl.json}"

# ## netctl_init
# Initializes a fresh netctl state structure in the temporary workspace.
netctl_init() {
  if [ ! -s "$NETCTL_STATE_FILE" ]; then
    printf '%s\n' '{"domain":"_","listen":[],"tls":"","cert_store_dir":"","acme_webroot":"","routes":{}}' > "$NETCTL_STATE_FILE"
  fi
}

# ## netctl_state_write
# Persists a key-value record into the active netctl state file.
netctl_state_write() {
  # Write stdin to state file safely
  cat > "${NETCTL_STATE_FILE}.tmp"
  mv "${NETCTL_STATE_FILE}.tmp" "$NETCTL_STATE_FILE"
}

# ## netctl_set_domain
# Sets the server_name / domain in the netctl state file.
netctl_set_domain() {
  domain="$1"
  netctl_init
  jq --arg d "$domain" '.domain = $d' "$NETCTL_STATE_FILE" | netctl_state_write
}

# ## netctl_set_tls
# Sets the TLS provider mode (such as letsencrypt or self-signed) in the netctl state file.
netctl_set_tls() {
  tls_mode="$1"
  netctl_init
  jq --arg t "$tls_mode" '.tls = $t' "$NETCTL_STATE_FILE" | netctl_state_write
}

# ## netctl_set_cert_store_dir
# Sets the persistent read-only certificate store directory in the netctl state file.
netctl_set_cert_store_dir() {
  cert_dir="$1"
  netctl_init
  jq --arg c "$cert_dir" '.cert_store_dir = $c' "$NETCTL_STATE_FILE" | netctl_state_write
}

# ## netctl_set_acme_webroot
# Sets the ACME HTTP-01 challenge webroot directory in the netctl state file.
netctl_set_acme_webroot() {
  webroot="$1"
  netctl_init
  jq --arg w "$webroot" '.acme_webroot = $w' "$NETCTL_STATE_FILE" | netctl_state_write
}

# ## netctl_set_proxy_connect_timeout
# Sets the upstream proxy connect timeout in the netctl state file.
netctl_set_proxy_connect_timeout() {
  timeout="$1"
  netctl_init
  jq --arg t "$timeout" '.proxy_connect_timeout = $t' "$NETCTL_STATE_FILE" | netctl_state_write
}

# ## netctl_set_proxy_send_timeout
# Sets the upstream proxy send timeout in the netctl state file.
netctl_set_proxy_send_timeout() {
  timeout="$1"
  netctl_init
  jq --arg t "$timeout" '.proxy_send_timeout = $t' "$NETCTL_STATE_FILE" | netctl_state_write
}

# ## netctl_set_proxy_read_timeout
# Sets the upstream proxy read timeout in the netctl state file.
netctl_set_proxy_read_timeout() {
  timeout="$1"
  netctl_init
  jq --arg t "$timeout" '.proxy_read_timeout = $t' "$NETCTL_STATE_FILE" | netctl_state_write
}

# ## netctl_set_proxy_buffering
# Sets the upstream proxy buffering mode in the netctl state file.
netctl_set_proxy_buffering() {
  buffering="$1"
  netctl_init
  jq --arg b "$buffering" '.proxy_buffering = $b' "$NETCTL_STATE_FILE" | netctl_state_write
}

# ## netctl_add_listen
# Appends a listen port/protocol entry to the current netctl state.
netctl_add_listen() {
  port="$1"
  netctl_init
  jq --arg p "$port" '.listen += [$p] | .listen |= unique' "$NETCTL_STATE_FILE" | netctl_state_write
}

# ## netctl_add_static
# Appends a static file serving route to the current netctl state.
netctl_add_static() {
  path="$1"
  target="$2"
  netctl_init
  jq --arg p "$path" --arg t "$target" '.routes[$p] = {"type": "static", "target": $t}' "$NETCTL_STATE_FILE" | netctl_state_write
}

# ## netctl_add_spa
# Registers a Single-Page Application (SPA) static route with index.html fallback.
netctl_add_spa() {
  path="$1"
  target="$2"
  netctl_init
  jq --arg p "$path" --arg t "$target" '.routes[$p] = {"type": "spa", "target": $t}' "$NETCTL_STATE_FILE" | netctl_state_write
}

# ## netctl_add_proxy
# Appends a reverse-proxy upstream routing rule to the current netctl state.
netctl_add_proxy() {
  path="$1"
  target="$2"
  netctl_init
  jq --arg p "$path" --arg t "$target" '.routes[$p] = {"type": "proxy", "target": $t}' "$NETCTL_STATE_FILE" | netctl_state_write
}

# ## netctl_add_ws
# Registers a WebSocket reverse proxy route with Upgrade headers.
netctl_add_ws() {
  path="$1"
  target="$2"
  netctl_init
  _norm_target=$(printf '%s
' "$target" | sed -e 's#^ws://#http://#' -e 's#^wss://#https://#')
  jq --arg p "$path" --arg t "$_norm_target" '.routes[$p] = {"type": "ws", "target": $t}' "$NETCTL_STATE_FILE" | netctl_state_write
}

# ## netctl_add_rewrite
# Appends a URL rewrite rule to the current netctl state.
netctl_add_rewrite() {
  path="$1"
  pattern="$2"
  netctl_init
  jq --arg p "$path" --arg pt "$pattern" '.routes[$p] = {"type": "rewrite", "pattern": $pt}' "$NETCTL_STATE_FILE" | netctl_state_write
}
