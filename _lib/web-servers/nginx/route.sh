#!/bin/sh
# ## Overview
# Lifecycle script for route.sh.
#
# ## Usage
# Refer to the internal functions of route.sh for implementation details.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
# Usage: ./libscript.sh route nginx <version> <domain> <location> <destination>
DOMAIN="$1"
LOCATION="$2"
DESTINATION="$3"

if [ -z "$DOMAIN" ] || [ -z "$LOCATION" ] || [ -z "$DESTINATION" ]; then
  printf '%s\n' "Usage: ./libscript.sh route nginx <version> <domain> <location> <destination>" >&2
  exit 1
fi

NGINX_CONF_DIR="${PREFIX:-$LIBSCRIPT_ROOT_DIR/installed/nginx}/conf"
mkdir -p "$NGINX_CONF_DIR/sites-available"
mkdir -p "$NGINX_CONF_DIR/sites-enabled"

CONF_FILE="$NGINX_CONF_DIR/sites-available/${DOMAIN}.conf"

if [ ! -f "$CONF_FILE" ]; then
  printf '%s\n' "server {" > "$CONF_FILE"
  printf '%s\n' "    listen 80;" >> "$CONF_FILE"
  printf '%s\n' "    server_name $DOMAIN;" >> "$CONF_FILE"
  printf '%s\n' "}" >> "$CONF_FILE"
fi

# Very simple proxy_pass injection for demo purposes
# In reality, this would use a more robust parser or template
if grep -q "location $LOCATION {" "$CONF_FILE"; then
  log_info "Route $DOMAIN$LOCATION already exists in $CONF_FILE"
else
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
  log_info "Route added: $DOMAIN$LOCATION -> $DESTINATION"
fi

ln -sf "$CONF_FILE" "$NGINX_CONF_DIR/sites-enabled/${DOMAIN}.conf"

# Assuming nginx is running or will be started
# if [ -x "${PREFIX:-$LIBSCRIPT_ROOT_DIR/installed/nginx}/bin/nginx" ]; then
#   ${PREFIX:-$LIBSCRIPT_ROOT_DIR/installed/nginx}/bin/nginx -s reload || true
# fi
