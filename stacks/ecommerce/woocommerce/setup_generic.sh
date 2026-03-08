#!/bin/sh
# shellcheck disable=SC3054,SC3040,SC2296,SC2128,SC2039,SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${0}"
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

# Delegate core WP setup
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/stacks/cms/wordpress/setup_generic.sh"
export SCRIPT_NAME
# shellcheck source=/dev/null
# shellcheck disable=SC1090,SC1091,SC2034
  . "${SCRIPT_NAME}"

# Install WooCommerce
WOOCOMMERCE_VERSION="${WOOCOMMERCE_VERSION:-latest}"
export WOOCOMMERCE_VERSION
WWWROOT="${WWWROOT:-/var/www/wordpress}"
export WWWROOT

PLUGIN_DIR="${WWWROOT}/wp-content/plugins/woocommerce"
if [ ! -d "${PLUGIN_DIR}" ]; then
  depends 'unzip'
  echo "Downloading WooCommerce (${WOOCOMMERCE_VERSION}) to ${WWWROOT}..."
  if [ "${WOOCOMMERCE_VERSION}" = "latest" ]; then
    dl_url="https://downloads.wordpress.org/plugin/woocommerce.zip"
  else
    dl_url="https://downloads.wordpress.org/plugin/woocommerce.${WOOCOMMERCE_VERSION}.zip"
  fi
  
  tmp_woo=$(mktemp)
  if command -v libscript_download >/dev/null 2>&1; then
    libscript_download "${dl_url}" "${tmp_woo}"
  else
    wget -qO "${tmp_woo}" "${dl_url}"
  fi
  priv unzip -q -o "${tmp_woo}" -d "${WWWROOT}/wp-content/plugins"
  rm -f "${tmp_woo}"
  priv chown -R www-data:www-data "${WWWROOT}/wp-content/plugins/woocommerce" || true
fi

echo "WooCommerce setup complete on ${SERVER_NAME:-localhost}"
