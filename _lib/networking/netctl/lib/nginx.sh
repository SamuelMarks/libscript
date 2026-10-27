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
: "${NETCTL_DIR:=$(cd "$SCRIPT_DIR/.." && pwd)}"
SCRIPT_NAME="${NETCTL_DIR}/lib/prelude.sh"
export SCRIPT_NAME
. "${SCRIPT_NAME}"

# ## netctl_emit_nginx
# Performs the netctl_emit_nginx operation and updates component state.
netctl_emit_nginx() {
  state_file="${1:-$NETCTL_STATE_FILE}"

  if [ ! -f "$state_file" ]; then
    printf '%s
' "Error: State file '$state_file' not found." >&2
    return 1
  fi

  domain=$(jq -r '.domain // "_"' "$state_file" 2>/dev/null || printf '_')
  if [ -z "$domain" ] || [ "$domain" = "null" ]; then
    domain='_'
  fi

  printf '%s
' "server {"

  # Extract listen ports
  jq -r '.listen[]' "$state_file" | while read -r port; do
    if [ "$port" = "443" ]; then
      if [ -f "/etc/letsencrypt/live/${domain}/fullchain.pem" ]; then
        printf '%s\n' '    listen 443 ssl;'
        printf '%s\n' "    ssl_certificate /etc/letsencrypt/live/${domain}/fullchain.pem;"
        printf '%s\n' "    ssl_certificate_key /etc/letsencrypt/live/${domain}/privkey.pem;"
        if [ -f "/etc/letsencrypt/options-ssl-nginx.conf" ]; then
          printf '%s\n' '    include /etc/letsencrypt/options-ssl-nginx.conf;'
        fi
        if [ -f "/etc/letsencrypt/ssl-dhparams.pem" ]; then
          printf '%s\n' '    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;'
        fi
      elif [ -f "/etc/nginx/ssl/${domain}.crt" ] && [ -f "/etc/nginx/ssl/${domain}.key" ]; then
        printf '%s\n' '    listen 443 ssl;'
        printf '%s\n' "    ssl_certificate /etc/nginx/ssl/${domain}.crt;"
        printf '%s\n' "    ssl_certificate_key /etc/nginx/ssl/${domain}.key;"
      fi
    else
      printf '%s\n' "    listen $port;"
    fi
  done

  printf '%s
' "    server_name ${domain};"
  printf '%s
' "    include mime.types;"
  printf '%s
' "    types {"
  printf '%s
' "        application/wasm wasm;"
  printf '%s
' "    }"

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
        printf '        proxy_set_header Upgrade $http_upgrade;\n'
        printf '        proxy_set_header Connection "upgrade";\n'
        printf '        proxy_set_header Host $host;\n'
        printf '        proxy_set_header X-Real-IP $remote_addr;\n'
        printf '        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n'
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
