#!/bin/sh
# ## Overview
# Generic setup module for Ruby.
#
# ## Usage
# Installs Ruby by compiling from source tarballs or by delegating to system/mise/asdf.


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

RUBY_INSTALL_METHOD="${RUBY_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript-native}}"
RUBY_VERSION="${RUBY_VERSION:-latest}"
ACTION="${ACTION:-install}"

resolve_exact_version() {
  if [ "${RUBY_VERSION}" = "latest" ] || [ "${RUBY_VERSION}" = "stable" ]; then
    RUBY_INDEX=$(mktemp)
    libscript_download 'https://cache.ruby-lang.org/pub/ruby/index.txt' "${RUBY_INDEX}"
    EXACT_VERSION=$(awk '{print $1}' < "${RUBY_INDEX}" | grep -E '^ruby-[0-9]+\.[0-9]+\.[0-9]+$' | tail -n 1 | sed 's/^ruby-//')
    rm -f "${RUBY_INDEX}"
    if [ -z "${EXACT_VERSION}" ]; then
      EXACT_VERSION="3.3.0"
    fi
  else
    EXACT_VERSION="${RUBY_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "$RUBY_INSTALL_METHOD" = "mise" ]; then
      mise ls ruby
    elif [ "$RUBY_INSTALL_METHOD" = "asdf" ]; then
      asdf list ruby
    elif [ "$RUBY_INSTALL_METHOD" = "system" ]; then
      ruby --version
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/ruby/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$RUBY_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote ruby
    elif [ "$RUBY_INSTALL_METHOD" = "asdf" ]; then
      asdf list all ruby
    elif [ "$RUBY_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      curl -sL https://cache.ruby-lang.org/pub/ruby/index.txt | awk '{print $1}' | grep -E '^ruby-[0-9]+\.[0-9]+\.[0-9]+$' | sed 's/^ruby-//' | sort -V
    fi
    exit 0
    ;;
  use)
    if [ "$RUBY_INSTALL_METHOD" = "mise" ]; then
      mise use "ruby@${RUBY_VERSION}"
    elif [ "$RUBY_INSTALL_METHOD" = "asdf" ]; then
      asdf global ruby "${RUBY_VERSION}"
    elif [ "$RUBY_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "ruby" "${RUBY_VERSION}" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  download|install|*)
    if [ "$RUBY_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'ruby'
    elif [ "$RUBY_INSTALL_METHOD" = "mise" ]; then
      mise install "ruby@${RUBY_VERSION}"
    elif [ "$RUBY_INSTALL_METHOD" = "asdf" ]; then
      asdf install ruby "${RUBY_VERSION}"
    else
      resolve_exact_version
      RUBY_DIR=$(libscript_get_version_dir "ruby" "${EXACT_VERSION}")
      export PATH="${RUBY_DIR}/bin:${PATH}"
      
      if [ -x "${RUBY_DIR}/bin/ruby" ] && "${RUBY_DIR}/bin/ruby" --version | grep -q "${EXACT_VERSION}"; then
        libscript_symlink_alias "ruby" "${RUBY_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      libscript_depends 'curl' 'tar' 'make' 'gcc'
      
      # Additional dependencies for full ruby functionality (zlib, openssl, libffi, libyaml)
      if command -v apt-get >/dev/null 2>&1; then
        libscript_depends 'libssl-dev' 'zlib1g-dev' 'libffi-dev' 'libyaml-dev'
      elif command -v yum >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1; then
        libscript_depends 'openssl-devel' 'zlib-devel' 'libffi-devel' 'libyaml-devel'
      fi

      RUBY_MAJOR=$(printf '%s\n' "${EXACT_VERSION}" | cut -d. -f1,2)
      RUBY_TARBALL=$(mktemp)
      libscript_download "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR}/ruby-${EXACT_VERSION}.tar.gz" "${RUBY_TARBALL}"
      
      TMP_BUILD_DIR=$(mktemp -d)
      tar -xzf "${RUBY_TARBALL}" -C "${TMP_BUILD_DIR}"
      rm -f "${RUBY_TARBALL}"
      
      mkdir -p "${RUBY_DIR}"
      (
        cd "${TMP_BUILD_DIR}/ruby-${EXACT_VERSION}" || exit 1
        ./configure --prefix="${RUBY_DIR}" --disable-install-doc
        make -j"$(nproc 2>/dev/null || printf '%s\n' 2)"
        make install
      )
      rm -rf "${TMP_BUILD_DIR}"
      
      libscript_symlink_alias "ruby" "${RUBY_VERSION}" "${EXACT_VERSION}"
    fi
    ;;
esac
