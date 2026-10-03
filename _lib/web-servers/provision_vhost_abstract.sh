#!/bin/sh
# ## Overview
# Provisions a reverse proxy virtual host (Nginx or Apache httpd) abstractly.
# Includes idempotent interpolation using block markers and strict syntax testing.
#
# ## Usage
#   ./provision_vhost_abstract.sh --app-id <id> --server-name <domain> [--proxy-engine <nginx|apache2>] [--listen-port <port>] [--target <url>] [--doc-root <path>] --conf-file <path>

set -eu

THIS_FILE="$(readlink -f "$0" 2>/dev/null || printf "%s/%s" "$(cd "$(dirname "$0")" && pwd -P)" "$(basename "$0")")"
THIS_DIR="$(dirname "$THIS_FILE")"

APP_ID=""
SERVER_NAME=""
PROXY_ENGINE="nginx"
LISTEN_PORT="80"
TARGET=""
DOC_ROOT=""
CONF_FILE=""

## Parses command-line arguments for virtual host provisioning
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --app-id) APP_ID="$2"; shift 2 ;;
      --server-name) SERVER_NAME="$2"; shift 2 ;;
      --proxy-engine) PROXY_ENGINE="$2"; shift 2 ;;
      --listen-port) LISTEN_PORT="$2"; shift 2 ;;
      --target) TARGET="$2"; shift 2 ;;
      --doc-root) DOC_ROOT="$2"; shift 2 ;;
      --conf-file) CONF_FILE="$2"; shift 2 ;;
      *) printf '[ERROR] Unknown argument: %s\n' "$1" >&2; exit 1 ;;
    esac
  done
}

## Validates the parsed arguments
validate_args() {
  if [ -z "$APP_ID" ]; then
    printf '[ERROR] --app-id is required\n' >&2
    exit 1
  fi
  if [ -z "$SERVER_NAME" ]; then
    printf '[ERROR] --server-name is required\n' >&2
    exit 1
  fi
  if [ -z "$CONF_FILE" ]; then
    printf '[ERROR] --conf-file is required\n' >&2
    exit 1
  fi
}

## Generates the Nginx block configuration
generate_nginx_block() {
  cat <<EOF
# BEGIN libscript-managed: ${APP_ID}
server {
    listen ${LISTEN_PORT};
    server_name ${SERVER_NAME};
EOF
  if [ -n "$DOC_ROOT" ]; then
    cat <<EOF
    root ${DOC_ROOT};
    index index.html index.php;
EOF
  fi
  if [ -n "$TARGET" ]; then
    cat <<EOF
    location / {
        proxy_pass http://${TARGET};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
EOF
  fi
  cat <<EOF
}
# END libscript-managed: ${APP_ID}
EOF
}

## Generates the Apache httpd block configuration
generate_apache2_block() {
  cat <<EOF
# BEGIN libscript-managed: ${APP_ID}
<VirtualHost *:${LISTEN_PORT}>
    ServerName ${SERVER_NAME}
EOF
  if [ -n "$DOC_ROOT" ]; then
    cat <<EOF
    DocumentRoot "${DOC_ROOT}"
EOF
  fi
  if [ -n "$TARGET" ]; then
    cat <<EOF
    ProxyPreserveHost On
    ProxyPass / http://${TARGET}/
    ProxyPassReverse / http://${TARGET}/
EOF
  fi
  cat <<EOF
</VirtualHost>
# END libscript-managed: ${APP_ID}
EOF
}

## Safely interpolates the generated block into the target configuration file
interpolate_block() {
  new_block_file="${THIS_DIR}/.tmp_block_${APP_ID}"
  backup_file="${CONF_FILE}.bak"
  
  if [ "$PROXY_ENGINE" = "nginx" ]; then
    generate_nginx_block > "$new_block_file"
  elif [ "$PROXY_ENGINE" = "apache2" ]; then
    generate_apache2_block > "$new_block_file"
  else
    printf '[ERROR] Unsupported proxy engine: %s\n' "$PROXY_ENGINE" >&2
    exit 1
  fi

  if [ ! -f "$CONF_FILE" ]; then
    mkdir -p "$(dirname "$CONF_FILE")"
    cat "$new_block_file" > "$CONF_FILE"
  else
    cp "$CONF_FILE" "$backup_file"
    awk -v app_id="${APP_ID}" -v block_file="$new_block_file" '
      BEGIN {
        begin_marker = "# BEGIN libscript-managed: " app_id
        end_marker = "# END libscript-managed: " app_id
        in_block = 0
        replaced = 0
      }
      $0 == begin_marker {
        in_block = 1
        while ((getline line < block_file) > 0) {
          print line
        }
        close(block_file)
        replaced = 1
        next
      }
      $0 == end_marker {
        in_block = 0
        next
      }
      !in_block {
        print $0
      }
      END {
        if (!replaced) {
          print ""
          while ((getline line < block_file) > 0) {
            print line
          }
          close(block_file)
        }
      }
    ' "$backup_file" > "$CONF_FILE"
  fi

  rm -f "$new_block_file"
}

## Validates syntax and rolls back if necessary
test_and_reload() {
  backup_file="${CONF_FILE}.bak"
  test_cmd=""
  reload_cmd=""

  if [ "$PROXY_ENGINE" = "nginx" ]; then
    printf '[INFO] Testing nginx configuration...\n'
    if nginx -t; then
      printf '[INFO] Syntax OK. Reloading...\n'
      nginx -s reload || true
      rm -f "$backup_file"
      printf '[PASS] Interpolation successful.\n'
    else
      printf '[ERROR] Syntax test failed. Rolling back changes.\n' >&2
      if [ -f "$backup_file" ]; then
        mv "$backup_file" "$CONF_FILE"
      else
        rm -f "$CONF_FILE"
      fi
      exit 1
    fi
  elif [ "$PROXY_ENGINE" = "apache2" ]; then
    printf '[INFO] Testing apache2 configuration...\n'
    if apache2ctl configtest || httpd -t; then
      printf '[INFO] Syntax OK. Reloading...\n'
      apache2ctl graceful || httpd -k restart || true
      rm -f "$backup_file"
      printf '[PASS] Interpolation successful.\n'
    else
      printf '[ERROR] Syntax test failed. Rolling back changes.\n' >&2
      if [ -f "$backup_file" ]; then
        mv "$backup_file" "$CONF_FILE"
      else
        rm -f "$CONF_FILE"
      fi
      exit 1
    fi
  fi
}

## Main execution flow
main() {
  parse_args "$@"
  validate_args
  interpolate_block
  test_and_reload
}

main "$@"
