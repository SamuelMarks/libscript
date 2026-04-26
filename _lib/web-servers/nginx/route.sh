#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'
# Usage: ./libscript.sh route nginx <version> <domain> <location> <destination>
DOMAIN="$1"
LOCATION="$2"
DESTINATION="$3"

if [ -z "$DOMAIN" ] || [ -z "$LOCATION" ] || [ -z "$DESTINATION" ]; then
  echo "Usage: ./libscript.sh route nginx <version> <domain> <location> <destination>" >&2
  exit 1
fi

NGINX_CONF_DIR="${PREFIX:-$LIBSCRIPT_ROOT_DIR/installed/nginx}/conf"
mkdir -p "$NGINX_CONF_DIR/sites-available"
mkdir -p "$NGINX_CONF_DIR/sites-enabled"

CONF_FILE="$NGINX_CONF_DIR/sites-available/${DOMAIN}.conf"

if [ ! -f "$CONF_FILE" ]; then
  echo "server {" > "$CONF_FILE"
  echo "    listen 80;" >> "$CONF_FILE"
  echo "    server_name $DOMAIN;" >> "$CONF_FILE"
  echo "}" >> "$CONF_FILE"
fi

# Very simple proxy_pass injection for demo purposes
# In reality, this would use a more robust parser or template
TEMP_FILE="${CONF_FILE}.tmp"
awk -v loc="$LOCATION" -v dest="$DESTINATION" '
  /^}/ && !inserted {
    print "    location " loc " {"
    print "        proxy_pass " dest ";"
    print "        proxy_set_header Host $host;"
    print "        proxy_set_header X-Real-IP $remote_addr;"
    print "    }"
    inserted = 1
  }
  { print }
' "$CONF_FILE" > "$TEMP_FILE"

mv "$TEMP_FILE" "$CONF_FILE"
ln -sf "$CONF_FILE" "$NGINX_CONF_DIR/sites-enabled/${DOMAIN}.conf"

echo "Route added: $DOMAIN$LOCATION -> $DESTINATION"
# Assuming nginx is running or will be started
# if [ -x "${PREFIX:-$LIBSCRIPT_ROOT_DIR/installed/nginx}/bin/nginx" ]; then
#   ${PREFIX:-$LIBSCRIPT_ROOT_DIR/installed/nginx}/bin/nginx -s reload || true
# fi
