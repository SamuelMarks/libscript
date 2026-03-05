#!/bin/sh
set -feu
if command -v nginx >/dev/null 2>&1; then
  nginx -v
elif [ -x /usr/sbin/nginx ]; then
  /usr/sbin/nginx -v
elif [ -x /opt/homebrew/sbin/nginx ]; then
  /opt/homebrew/sbin/nginx -v
elif [ -x /usr/local/sbin/nginx ]; then
  /usr/local/sbin/nginx -v
else
  echo "nginx not found"
  exit 1
fi
