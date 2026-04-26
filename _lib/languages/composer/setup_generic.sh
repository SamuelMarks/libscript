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

for lib in '_lib/_common/pkg_mgr.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

depends 'php'
depends 'curl'

COMPOSER_VERSION="${COMPOSER_VERSION:-latest}"

if ! command -v composer >/dev/null 2>&1; then
  echo "Installing Composer..."
  tmp_dir=$(mktemp -d)
  
  libscript_download "https://getcomposer.org/installer" "${tmp_dir}/composer-setup.php"
  
  if [ "${COMPOSER_VERSION}" = "latest" ]; then
    php "${tmp_dir}/composer-setup.php" --install-dir="${tmp_dir}" --filename=composer
  else
    php "${tmp_dir}/composer-setup.php" --install-dir="${tmp_dir}" --filename=composer --version="${COMPOSER_VERSION}"
  fi
  
  priv mv "${tmp_dir}/composer" /usr/local/bin/composer
  rm -rf "${tmp_dir}"
else
  echo "Composer is already installed."
fi
