#!/bin/sh
set -e
if command -v apk >/dev/null 2>&1; then apk --version; else echo "apk skipped"; fi
