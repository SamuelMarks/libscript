#!/bin/sh
set -feu
echo "Validating WooCommerce installation..."
WWWROOT="${WWWROOT:-/var/www/wordpress}"
if [ -d "${WWWROOT}/wp-content/plugins/woocommerce" ]; then
    echo "WooCommerce directory found at ${WWWROOT}/wp-content/plugins/woocommerce"
    exit 0
else
    echo "WooCommerce directory not found at ${WWWROOT}/wp-content/plugins/woocommerce"
    exit 1
fi
