#!/bin/sh
set -feu
echo "Validating PrestaShop installation..."
WWWROOT="${WWWROOT:-/var/www/prestashop}"
if [ -d "${WWWROOT}/classes" ] || [ -d "${WWWROOT}/install" ]; then
    echo "PrestaShop directory found at ${WWWROOT}"
    exit 0
else
    echo "PrestaShop directory not found at ${WWWROOT}"
    exit 1
fi
