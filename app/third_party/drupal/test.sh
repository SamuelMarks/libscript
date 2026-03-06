#!/bin/sh
set -feu
echo "Validating Drupal installation..."
WWWROOT="${WWWROOT:-/var/www/drupal}"
if [ -d "${WWWROOT}/core" ]; then
    echo "Drupal directory found at ${WWWROOT}"
    exit 0
else
    echo "Drupal directory not found at ${WWWROOT}"
    exit 1
fi
