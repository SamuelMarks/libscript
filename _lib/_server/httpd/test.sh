#!/bin/sh
set -feu
if command -v httpd >/dev/null 2>&1; then
  httpd -v
elif command -v apache2 >/dev/null 2>&1; then
  apache2 -v
else
  >&2 echo "httpd/apache2 not found"
  exit 1
fi
echo hello from httpd
