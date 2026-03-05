#!/bin/sh
set -feu
if command -v fluent-bit >/dev/null 2>&1; then
  fluent-bit --version
elif [ -x /opt/fluent-bit/bin/fluent-bit ]; then
  /opt/fluent-bit/bin/fluent-bit --version
else
  echo "fluent-bit not found"
  exit 1
fi
echo hello from fluent-bit