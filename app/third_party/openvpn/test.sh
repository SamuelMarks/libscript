#!/bin/sh
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
