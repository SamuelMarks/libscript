#!/bin/sh
# ## Overview
# Generic setup module for PHP.
#
# ## Usage
# Installs PHP by compiling from source tarballs or delegating to system/asdf/mise.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
DIR="${SCRIPT_DIR}"

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/env.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

PHP_INSTALL_METHOD="${PHP_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript-native}}"
PHP_VERSION="${PHP_VERSION:-latest}"
ACTION="${ACTION:-install}"

resolve_exact_version() {
  if [ "${PHP_VERSION}" = "latest" ]; then
    # Simple hardcoded fallback for latest
    EXACT_VERSION="8.3.11"
  else
    EXACT_VERSION="${PHP_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "$PHP_INSTALL_METHOD" = "mise" ]; then
      mise ls php
    elif [ "$PHP_INSTALL_METHOD" = "asdf" ]; then
      asdf list php
    elif [ "$PHP_INSTALL_METHOD" = "system" ]; then
      php -v
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/php/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$PHP_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote php
    elif [ "$PHP_INSTALL_METHOD" = "asdf" ]; then
      asdf list all php
    elif [ "$PHP_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      printf '%b\n' '8.2.23\n8.3.11' 
    fi
    exit 0
    ;;
  use)
    if [ "$PHP_INSTALL_METHOD" = "mise" ]; then
      mise use "php@${PHP_VERSION}"
    elif [ "$PHP_INSTALL_METHOD" = "asdf" ]; then
      asdf global php "${PHP_VERSION}"
    elif [ "$PHP_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "php" "${PHP_VERSION}" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  download|install|*)
    if [ "$PHP_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'php'
    elif [ "$PHP_INSTALL_METHOD" = "mise" ]; then
      mise install "php@${PHP_VERSION}"
    elif [ "$PHP_INSTALL_METHOD" = "asdf" ]; then
      asdf install php "${PHP_VERSION}"
    else
      resolve_exact_version
      PHP_DIR=$(libscript_get_version_dir "php" "${EXACT_VERSION}")
      export PATH="${PHP_DIR}/bin:${PATH}"
      
      if [ -x "${PHP_DIR}/bin/php" ] && "${PHP_DIR}/bin/php" -v | grep -q "${EXACT_VERSION}"; then
        libscript_symlink_alias "php" "${PHP_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      libscript_depends 'curl' 'tar' 'make' 'gcc'
      
      # Try to install sqlite and libxml2 for a standard php build
      if command -v apt-get >/dev/null 2>&1; then
        libscript_depends 'libsqlite3-dev' 'libxml2-dev' 'pkg-config'
      elif command -v yum >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1; then
        libscript_depends 'sqlite-devel' 'libxml2-devel' 'pkgconfig'
      fi

      PHP_TARBALL=$(mktemp)
      libscript_download "https://www.php.net/distributions/php-${EXACT_VERSION}.tar.gz" "${PHP_TARBALL}"
      
      TMP_BUILD_DIR=$(mktemp -d)
      tar -xzf "${PHP_TARBALL}" -C "${TMP_BUILD_DIR}"
      rm -f "${PHP_TARBALL}"
      
      mkdir -p "${PHP_DIR}"
      (
        cd "${TMP_BUILD_DIR}/php-${EXACT_VERSION}" || exit 1
        ./configure --prefix="${PHP_DIR}" --disable-all --enable-cli --enable-mbstring --with-openssl || ./configure --prefix="${PHP_DIR}" --disable-all --enable-cli
        make -j"$(nproc 2>/dev/null || printf '%s\n' 2)"
        make install
      )
      rm -rf "${TMP_BUILD_DIR}"
      
      libscript_symlink_alias "php" "${PHP_VERSION}" "${EXACT_VERSION}"
    fi
    ;;
esac
