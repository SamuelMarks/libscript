#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
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
for lib in 'stacks/cms/wordpress/setup_generic.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

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
  if ! priv chown -R www-data:www-data "${WWWROOT}/wp-content/plugins/woocommerce" ; then
    true
  fi
fi

echo "WooCommerce setup complete on ${SERVER_NAME:-localhost}"
