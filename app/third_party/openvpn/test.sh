#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145


set -feu
if command -v openvpn >/dev/null 2>&1; then
  openvpn --version
elif [ -x /usr/sbin/openvpn ]; then
  /usr/sbin/openvpn --version
elif [ -x /opt/homebrew/sbin/openvpn ]; then
  /opt/homebrew/sbin/openvpn --version
elif [ -x /usr/local/sbin/openvpn ]; then
  /usr/local/sbin/openvpn --version
else
  echo "openvpn not found"
  exit 1
fi
