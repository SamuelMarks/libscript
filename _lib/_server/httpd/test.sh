#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145


set -feu
if command -v httpd >/dev/null 2>&1; then
  httpd -v
elif command -v apache2 >/dev/null 2>&1; then
  apache2 -v
elif [ -x /usr/sbin/apache2 ]; then
  /usr/sbin/apache2 -v
elif [ -x /usr/sbin/httpd ]; then
  /usr/sbin/httpd -v
elif [ -x /opt/homebrew/bin/httpd ]; then
  /opt/homebrew/bin/httpd -v
elif [ -x /usr/local/bin/httpd ]; then
  /usr/local/bin/httpd -v
else
  >&2 echo "httpd/apache2 not found"
  exit 1
fi
echo hello from httpd
