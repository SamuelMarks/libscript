#!/bin/sh
# ## Overview
# Network control library module for nginx.
# Supports SPA try_files, WebSocket Upgrade headers, domain server_name, and WASM MIME types.
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

# ## netctl_cert_is_valid_letsencrypt
# Verifies that a certificate and private key exist, are CA-signed (not self-signed), match the domain, and are not expired.
netctl_cert_is_valid_letsencrypt() {
  _v_dom="${1:-}"
  _v_cert="${2:-}"
  _v_key="${3:-}"
  [ -s "$_v_cert" ] || return 1
  [ -s "$_v_key" ] || return 1
  if ! command -v openssl >/dev/null 2>&1; then
    return 0
  fi
  _v_issuer=$(openssl x509 -noout -issuer -in "$_v_cert" 2>/dev/null || true)
  _v_subject=$(openssl x509 -noout -subject -in "$_v_cert" 2>/dev/null || true)
  [ -n "$_v_issuer" ] || return 1
  [ -n "$_v_subject" ] || return 1
  _v_iss_val="${_v_issuer#*=}"
  _v_sub_val="${_v_subject#*=}"
  if [ "$_v_iss_val" = "$_v_sub_val" ]; then
    return 1
  fi
  if [ -n "$_v_dom" ] && [ "$_v_dom" != "_" ]; then
    _v_san=$(openssl x509 -noout -ext subjectAltName -in "$_v_cert" 2>/dev/null || true)
    _v_wild="*.${_v_dom#*.}"
    case "${_v_san} ${_v_subject}" in
      *"${_v_dom}"*|*"${_v_wild}"*) ;;
      *) return 1 ;;
    esac
  fi
  if ! openssl x509 -checkend "${LETSENCRYPT_RENEW_BEFORE_SECONDS:-0}" -noout -in "$_v_cert" >/dev/null 2>&1; then
    return 1
  fi
  return 0
}

# ## netctl_emit_nginx
# Renders the accumulated netctl routing state as an Nginx server configuration.
netctl_emit_nginx() {
  state_file="${1:-$NETCTL_STATE_FILE}"

  if [ ! -f "$state_file" ]; then
    printf '%s\n' "Error: State file '$state_file' not found." >&2
    return 1
  fi

  domain=$(jq -r '.domain // "_"' "$state_file" 2>/dev/null || printf '_')
  if [ -z "$domain" ] || [ "$domain" = "null" ]; then
    domain='_'
  fi
  tls_mode=$(jq -r '.tls // empty' "$state_file" 2>/dev/null || true)
  if [ "$tls_mode" = "null" ]; then
    tls_mode=""
  fi
  cert_store_dir=$(jq -r '.cert_store_dir // empty' "$state_file" 2>/dev/null || true)
  if [ -z "$cert_store_dir" ] || [ "$cert_store_dir" = "null" ]; then
    cert_store_dir="${CERT_STORE_DIR:-${DATA_DISK_MOUNT:-${DATA_MOUNT_DIR:-/mnt/data}}/certs}"
  fi
  acme_webroot=$(jq -r '.acme_webroot // empty' "$state_file" 2>/dev/null || true)
  if [ -z "$acme_webroot" ] || [ "$acme_webroot" = "null" ]; then
    acme_webroot="${cert_store_dir}/acme-webroot"
  fi

  _p_conn=$(jq -r '.proxy_connect_timeout // empty' "$state_file" 2>/dev/null || true)
  [ -z "$_p_conn" ] || [ "$_p_conn" = "null" ] && _p_conn="${NETCTL_PROXY_CONNECT_TIMEOUT:-60s}"
  case "$_p_conn" in *[0-9]) _p_conn="${_p_conn}s" ;; esac
  NETCTL_PROXY_CONNECT_TIMEOUT="$_p_conn"

  _p_send=$(jq -r '.proxy_send_timeout // empty' "$state_file" 2>/dev/null || true)
  [ -z "$_p_send" ] || [ "$_p_send" = "null" ] && _p_send="${NETCTL_PROXY_SEND_TIMEOUT:-300s}"
  case "$_p_send" in *[0-9]) _p_send="${_p_send}s" ;; esac
  NETCTL_PROXY_SEND_TIMEOUT="$_p_send"

  _p_read=$(jq -r '.proxy_read_timeout // empty' "$state_file" 2>/dev/null || true)
  [ -z "$_p_read" ] || [ "$_p_read" = "null" ] && _p_read="${NETCTL_PROXY_READ_TIMEOUT:-300s}"
  case "$_p_read" in *[0-9]) _p_read="${_p_read}s" ;; esac
  NETCTL_PROXY_READ_TIMEOUT="$_p_read"

  _p_buf=$(jq -r '.proxy_buffering // empty' "$state_file" 2>/dev/null || true)
  [ -z "$_p_buf" ] || [ "$_p_buf" = "null" ] && _p_buf="${NETCTL_PROXY_BUFFERING:-off}"
  case "$_p_buf" in
    true|1|on) _p_buf="on" ;;
    false|0|off) _p_buf="off" ;;
  esac
  NETCTL_PROXY_BUFFERING="$_p_buf"

  printf '%s\n' 'server {'

  _le_etc="${LETSENCRYPT_ETC_DIR:-${LIBSCRIPT_ETC_DIR:-/etc}/letsencrypt}"
  _ngx_etc="${NGINX_ETC_DIR:-${LIBSCRIPT_ETC_DIR:-/etc}/nginx}"

  # Extract listen ports
  jq -r '.listen[]' "$state_file" | while read -r port; do
    if [ "$port" = "443" ]; then
      if [ "${NETCTL_BOOTSTRAP_HTTP_ONLY:-0}" = "1" ]; then
        continue
      fi
      _store_cert="${cert_store_dir}/live/${domain}/fullchain.pem"
      _store_key="${cert_store_dir}/live/${domain}/privkey.pem"
      _le_cert="${_le_etc}/live/${domain}/fullchain.pem"
      _le_key="${_le_etc}/live/${domain}/privkey.pem"
      if netctl_cert_is_valid_letsencrypt "$domain" "$_store_cert" "$_store_key"; then
        printf '%s\n' '    listen 443 ssl;'
        printf '%s\n' "    ssl_certificate ${_store_cert};"
        printf '%s\n' "    ssl_certificate_key ${_store_key};"
        printf '%s\n' '    ssl_protocols TLSv1.2 TLSv1.3;'
        if [ -f "${_le_etc}/options-ssl-nginx.conf" ]; then
          printf '%s\n' "    include ${_le_etc}/options-ssl-nginx.conf;"
        fi
        if [ -f "${_le_etc}/ssl-dhparams.pem" ]; then
          printf '%s\n' "    ssl_dhparam ${_le_etc}/ssl-dhparams.pem;"
        fi
      elif netctl_cert_is_valid_letsencrypt "$domain" "$_le_cert" "$_le_key" || { [ "$tls_mode" != "letsencrypt" ] && [ -f "$_le_cert" ] && [ -f "$_le_key" ]; }; then
        printf '%s\n' '    listen 443 ssl;'
        printf '%s\n' "    ssl_certificate ${_le_cert};"
        printf '%s\n' "    ssl_certificate_key ${_le_key};"
        printf '%s\n' '    ssl_protocols TLSv1.2 TLSv1.3;'
        if [ -f "${_le_etc}/options-ssl-nginx.conf" ]; then
          printf '%s\n' "    include ${_le_etc}/options-ssl-nginx.conf;"
        fi
        if [ -f "${_le_etc}/ssl-dhparams.pem" ]; then
          printf '%s\n' "    ssl_dhparam ${_le_etc}/ssl-dhparams.pem;"
        fi
      elif [ "$tls_mode" != "letsencrypt" ] && [ -f "${_ngx_etc}/ssl/${domain}.crt" ] && [ -f "${_ngx_etc}/ssl/${domain}.key" ]; then
        printf '%s\n' '    listen 443 ssl;'
        printf '%s\n' "    ssl_certificate ${_ngx_etc}/ssl/${domain}.crt;"
        printf '%s\n' "    ssl_certificate_key ${_ngx_etc}/ssl/${domain}.key;"
      fi
    else
      printf '%s\n' "    listen $port;"
    fi
  done

  printf '%s\n' "    server_name ${domain};"
  printf '%s\n' '    include mime.types;'
  printf '%s\n' '    types {'
  printf '%s\n' '        application/wasm wasm;'
  printf '%s\n' '    }'
  printf '\n'
  printf '%s\n' '    location ^~ /.well-known/acme-challenge/ {'
  printf '%s\n' "        root ${acme_webroot};"
  printf '%s\n' '        default_type "text/plain";'
  # shellcheck disable=SC2016
  printf '%s\n' '        try_files $uri =404;'
  printf '%s\n' '    }'

  # Extract routes
  jq -r '.routes | to_entries[] | "\(.key)	\(.value.type)	\(.value.target // "")	\(.value.pattern // "")"' "$state_file" | while IFS="$(printf '	')" read -r path type target pattern; do
    printf '%s
' ""
    printf '%s
' "    location $path {"
    case "$type" in
      static)
        if [ "$path" = "/" ]; then
          printf '%s
' "        root $target;"
          printf '%s
' "        index index.html;"
          printf '%s
' "        try_files \$uri \$uri/ /index.html;"
        else
          printf '%s
' "        alias $target/;"
        fi
        ;;
      spa)
        if [ "$path" = "/" ]; then
          printf '%s
' "        root $target;"
          printf '%s
' "        index index.html;"
          printf '%s
' "        try_files \$uri \$uri/ /index.html;"
        else
          printf '%s
' "        alias $target/;"
          printf '%s
' "        index index.html;"
          printf '%s
' "        try_files \$uri \$uri/ $path/index.html;"
        fi
        ;;
      proxy|ws)
        _norm_target=$(printf '%s\n' "$target" | sed -e 's#^ws://#http://#' -e 's#^wss://#https://#')
        printf '        proxy_pass %s;\n' "$_norm_target"
        printf '        proxy_http_version 1.1;\n'
        printf '        proxy_connect_timeout %s;\n' "${NETCTL_PROXY_CONNECT_TIMEOUT}"
        printf '        proxy_send_timeout %s;\n' "${NETCTL_PROXY_SEND_TIMEOUT}"
        printf '        proxy_read_timeout %s;\n' "${NETCTL_PROXY_READ_TIMEOUT}"
        printf '        proxy_buffering %s;\n' "${NETCTL_PROXY_BUFFERING}"
        printf '        proxy_cache off;\n'
        # shellcheck disable=SC2016
        printf '        proxy_set_header Upgrade $http_upgrade;\n'
        if [ "$type" = "ws" ]; then
          printf '        proxy_set_header Connection "upgrade";\n'
        else
          printf '        proxy_set_header Connection "";\n'
          printf '        proxy_set_header Connection "upgrade";\n'
        fi
        # shellcheck disable=SC2016
        printf '        proxy_set_header Host $host;\n'
        # shellcheck disable=SC2016
        printf '        proxy_set_header X-Real-IP $remote_addr;\n'
        # shellcheck disable=SC2016
        printf '        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n'
        # shellcheck disable=SC2016
        printf '        proxy_set_header X-Forwarded-Proto $scheme;\n'
        ;;
      rewrite)
        printf '%s
' "        rewrite $pattern break;"
        ;;
    esac
    printf '%s
' "    }"
  done

  printf '%s
' "}"
}

# ## netctl_nginx_emit
# Alias for netctl_emit_nginx that renders the accumulated netctl routing state as an Nginx server configuration.
netctl_nginx_emit() {
  netctl_emit_nginx "$@"
}
