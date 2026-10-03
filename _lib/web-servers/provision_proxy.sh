#!/bin/sh
# ## Overview
# Declarative Reverse Proxy Synthesizer. Generates Nginx, Caddy, or IIS configurations
# to map multi-vHost architectures to underlying WSGI ports and static webroots.
#
# ## Usage
#   ./provision_proxy.sh --proxy <nginx|caddy|iis> --app-dir <dir> --packaging <path>

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
export DIR="${SCRIPT_DIR}"

proxy_type=""
app_dir=""
packaging_path=""

while [ $# -gt 0 ]; do
  case "$1" in
    --proxy) proxy_type="$2"; shift 2 ;;
    --app-dir) app_dir="$2"; shift 2 ;;
    --packaging) packaging_path="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [ -z "$proxy_type" ] || [ -z "$app_dir" ] || [ -z "$packaging_path" ]; then
  printf 'Error: --proxy, --app-dir, and --packaging are required.\n' >&2
  exit 1
fi

webroot_base="$app_dir/webroot"
conf_dir="$app_dir/proxy"
mkdir -p "$conf_dir"

case "$proxy_type" in
  nginx)
    conf_file="$conf_dir/nginx.conf"
    printf '# Auto-generated Nginx Config\n' > "$conf_file"
    if command -v jq >/dev/null 2>&1; then
      jq -c '.services[]?' "$packaging_path" | while read -r svc; do
        svc_id=$(printf '%s' "$svc" | jq -r '.id')
        svc_type=$(printf '%s' "$svc" | jq -r '.type')
        if [ "$svc_type" = "wsgi" ] || [ "$svc_type" = "asgi" ]; then
          port=$(printf '%s' "$svc" | jq -r '.port_binding')
          cat <<EOF >> "$conf_file"
server {
    listen 80;
    server_name ${svc_id}.local;
    location / {
        proxy_pass http://127.0.0.1:${port};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
        elif [ "$svc_type" = "static" ]; then
          cat <<EOF >> "$conf_file"
server {
    listen 80;
    server_name ${svc_id}.local;
    root ${webroot_base}/${svc_id};
    index index.html;
    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF
        fi
      done
    fi
    # Generate optional self-signed cert if openssl is present
    if command -v openssl >/dev/null 2>&1 && [ ! -f "$conf_dir/cert.pem" ]; then
        openssl req -x509 -newkey rsa:4096 -keyout "$conf_dir/key.pem" -out "$conf_dir/cert.pem" -days 365 -nodes -subj "/CN=localhost" 2>/dev/null || true
    fi
    ;;
    
  caddy)
    conf_file="$conf_dir/Caddyfile"
    printf '# Auto-generated Caddyfile\n' > "$conf_file"
    if command -v jq >/dev/null 2>&1; then
      jq -c '.services[]?' "$packaging_path" | while read -r svc; do
        svc_id=$(printf '%s' "$svc" | jq -r '.id')
        svc_type=$(printf '%s' "$svc" | jq -r '.type')
        if [ "$svc_type" = "wsgi" ] || [ "$svc_type" = "asgi" ]; then
          port=$(printf '%s' "$svc" | jq -r '.port_binding')
          cat <<EOF >> "$conf_file"
${svc_id}.local {
    reverse_proxy 127.0.0.1:${port}
}
EOF
        elif [ "$svc_type" = "static" ]; then
          cat <<EOF >> "$conf_file"
${svc_id}.local {
    root * ${webroot_base}/${svc_id}
    file_server
    try_files {path} {path}/ /index.html
}
EOF
        fi
      done
    fi
    ;;
    
  iis)
    conf_file="$conf_dir/Web.config"
    cat <<EOF > "$conf_file"
<?xml version="1.0" encoding="UTF-8"?>
<!-- Auto-generated IIS Web.config -->
<configuration>
  <system.webServer>
    <rewrite>
      <rules>
EOF
    if command -v jq >/dev/null 2>&1; then
      jq -c '.services[]?' "$packaging_path" | while read -r svc; do
        svc_id=$(printf '%s' "$svc" | jq -r '.id')
        svc_type=$(printf '%s' "$svc" | jq -r '.type')
        if [ "$svc_type" = "wsgi" ] || [ "$svc_type" = "asgi" ]; then
          port=$(printf '%s' "$svc" | jq -r '.port_binding')
          cat <<EOF >> "$conf_file"
        <rule name="ReverseProxyInbound_${svc_id}" stopProcessing="true">
          <match url="(.*)" />
          <conditions>
            <add input="{HTTP_HOST}" pattern="^${svc_id}\.local$" />
          </conditions>
          <action type="Rewrite" url="http://127.0.0.1:${port}/{R:1}" />
        </rule>
EOF
        fi
      done
    fi
    cat <<EOF >> "$conf_file"
      </rules>
    </rewrite>
  </system.webServer>
</configuration>
EOF
    ;;
    
  *)
    printf 'Error: Unsupported proxy type "%s"\n' "$proxy_type" >&2
    exit 1
    ;;
esac

exit 0