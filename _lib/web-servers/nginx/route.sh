#!/bin/sh
# shellcheck disable=SC3054,SC3040,SC2296,SC2128,SC2039,SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145


set -e

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
