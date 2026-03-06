#!/bin/sh
set -feu
echo "Validating phpBB installation..."
WWWROOT="${WWWROOT:-/var/www/phpbb}"
if [ -d "${WWWROOT}/phpbb" ] || [ -d "${WWWROOT}/install" ]; then
    echo "phpBB directory found at ${WWWROOT}"
    exit 0
else
    echo "phpBB directory not found at ${WWWROOT}"
    exit 1
fi
