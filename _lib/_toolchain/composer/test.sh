#!/bin/sh
set -feu
if command -v composer >/dev/null 2>&1; then
    echo "Composer found."
    composer --version
    exit 0
else
    echo "Composer not found."
    exit 1
fi
