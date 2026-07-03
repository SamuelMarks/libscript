#!/bin/sh
# ## Overview
# Generic setup module for Rust.
#
# ## Usage
# Installs Rust by downloading official rust-lang.org releases or via rustup/asdf/mise.


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

RUST_INSTALL_METHOD="${RUST_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript-native}}"
RUST_VERSION="${RUST_VERSION:-latest}"
if [ "${RUST_VERSION}" = "latest" ]; then
  RUST_VERSION="stable"
fi
ACTION="${ACTION:-install}"

resolve_exact_version() {
  if [ "${RUST_VERSION}" = "stable" ]; then
    EXACT_VERSION=$(curl -sL https://static.rust-lang.org/dist/channel-rust-stable.toml | grep -m 1 '^pkg_version' | cut -d '"' -f 2 | cut -d ' ' -f 1)
    if [ -z "${EXACT_VERSION}" ]; then EXACT_VERSION="1.77.0"; fi
  else
    EXACT_VERSION="${RUST_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "$RUST_INSTALL_METHOD" = "rustup" ]; then
      rustup toolchain list
    elif [ "$RUST_INSTALL_METHOD" = "mise" ]; then
      mise ls rust
    elif [ "$RUST_INSTALL_METHOD" = "asdf" ]; then
      asdf list rust
    elif [ "$RUST_INSTALL_METHOD" = "system" ]; then
      rustc --version
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/rust/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$RUST_INSTALL_METHOD" = "rustup" ]; then
      printf '%s\n' "Use rustup to see channels"
    elif [ "$RUST_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      printf '%b\n' 'stable\nbeta\nnightly' 
    fi
    exit 0
    ;;
  use)
    if [ "$RUST_INSTALL_METHOD" = "rustup" ]; then
      rustup default "${RUST_VERSION}"
    elif [ "$RUST_INSTALL_METHOD" = "mise" ]; then
      mise use "rust@${RUST_VERSION}"
    elif [ "$RUST_INSTALL_METHOD" = "asdf" ]; then
      asdf global rust "${RUST_VERSION}"
    elif [ "$RUST_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "rust" "${RUST_VERSION}" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  download|install|*)
    if [ "$RUST_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'rust'
    elif [ "$RUST_INSTALL_METHOD" = "rustup" ]; then
      if ! command -v rustup >/dev/null 2>&1; then
        INSTALL_SH=$(mktemp)
        libscript_download 'https://sh.rustup.rs' "${INSTALL_SH}"
        sh "${INSTALL_SH}" -y --default-toolchain "${RUST_VERSION}"
        rm -f "${INSTALL_SH}"
      else
        rustup toolchain install "${RUST_VERSION}"
      fi
    elif [ "$RUST_INSTALL_METHOD" = "mise" ]; then
      mise install "rust@${RUST_VERSION}"
    elif [ "$RUST_INSTALL_METHOD" = "asdf" ]; then
      asdf install rust "${RUST_VERSION}"
    else
      resolve_exact_version
      RUST_DIR=$(libscript_get_version_dir "rust" "${EXACT_VERSION}")
      export PATH="${RUST_DIR}/bin:${PATH}"
      
      if [ -x "${RUST_DIR}/bin/rustc" ] && "${RUST_DIR}/bin/rustc" --version | grep -q "${EXACT_VERSION}"; then
        libscript_symlink_alias "rust" "${RUST_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      libscript_depends 'curl' 'tar'
      
      os="$(uname -s | tr '[:upper:]' '[:lower:]')"
      case "${os}" in
        'darwin'*) os='apple-darwin' ;;
        *) os='unknown-linux-gnu' ;;
      esac
      arch="$(uname -m)"
      case "${arch}" in
        'x86_64') arch='x86_64' ;;
        'aarch64'|'arm64') arch='aarch64' ;;
        *) ;;
      esac
      
      # Using standalone rust installer
      TARGET="${arch}-${os}"
      # Provide fallback for aarch64 linux if glibc
      if [ "${os}" = "unknown-linux-gnu" ]; then
         TARGET="${arch}-unknown-linux-gnu"
      fi

      RUST_TARBALL=$(mktemp)
      libscript_download "https://static.rust-lang.org/dist/rust-${EXACT_VERSION}-${TARGET}.tar.gz" "${RUST_TARBALL}"
      
      TMP_EXTRACT=$(mktemp -d)
      tar -xzf "${RUST_TARBALL}" -C "${TMP_EXTRACT}"
      rm -f "${RUST_TARBALL}"
      
      mkdir -p "${RUST_DIR}"
      (
        cd "${TMP_EXTRACT}/rust-${EXACT_VERSION}-${TARGET}" || exit 1
        ./install.sh --prefix="${RUST_DIR}" --without=rust-docs
      )
      rm -rf "${TMP_EXTRACT}"
      
      libscript_symlink_alias "rust" "${RUST_VERSION}" "${EXACT_VERSION}"
    fi
    ;;
esac
