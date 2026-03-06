#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145


set -feu
echo "Validating Nextcloud installation..."
WWWROOT="${WWWROOT:-/var/www/nextcloud}"
if [ -d "${WWWROOT}/core" ]; then
    echo "Nextcloud directory found at ${WWWROOT}"
    exit 0
else
    echo "Nextcloud directory not found at ${WWWROOT}"
    exit 1
fi