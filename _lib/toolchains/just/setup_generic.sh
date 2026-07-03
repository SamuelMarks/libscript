#!/bin/sh
# ## Overview
# Generic setup script for the just component.
# It provides fallback installation logic and cross-platform installation steps
# when a more specific OS/distribution setup script is not available.
#
# ## Usage
# This script is typically called internally by the component lifecycle.


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

JUST_INSTALL_METHOD="${JUST_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript-native}}"
JUST_VERSION="${JUST_VERSION:-latest}"
ACTION="${ACTION:-install}"

resolve_exact_version() {
  if [ "${JUST_VERSION}" = "latest" ]; then
    EXACT_VERSION="1.39.0"
  else
    EXACT_VERSION="${JUST_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "$JUST_INSTALL_METHOD" = "mise" ]; then
      mise ls just
    elif [ "$JUST_INSTALL_METHOD" = "asdf" ]; then
      asdf list just
    elif [ "$JUST_INSTALL_METHOD" = "system" ]; then
      just --version || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/just/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$JUST_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote just
    elif [ "$JUST_INSTALL_METHOD" = "asdf" ]; then
      asdf list all just
    elif [ "$JUST_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      curl -sL "https://api.github.com/repos/casey/just/releases" | grep -o '"tag_name": "[^"]*"' | sed 's/"tag_name": "//' | sed 's/"//' | head -n 100
    fi
    exit 0
    ;;
  use)
    if [ "$JUST_INSTALL_METHOD" = "mise" ]; then
      mise use "just@${JUST_VERSION}"
    elif [ "$JUST_INSTALL_METHOD" = "asdf" ]; then
      asdf global just "${JUST_VERSION}"
    elif [ "$JUST_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "just" "${JUST_VERSION}" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  download|install|*)
    if [ "$JUST_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'just'
    elif [ "$JUST_INSTALL_METHOD" = "mise" ]; then
      mise install "just@${JUST_VERSION}"
    elif [ "$JUST_INSTALL_METHOD" = "asdf" ]; then
      asdf install just "${JUST_VERSION}"
    else
      libscript_depends 'curl' 'tar'
      resolve_exact_version
      
      JUST_DIR=$(libscript_get_version_dir "just" "${EXACT_VERSION}")
      bin_dir="${JUST_DIR}/bin"
      
      if [ -x "${bin_dir}/just" ]; then
        libscript_symlink_alias "just" "${JUST_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      TARGET_OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
      TARGET_ARCH="$(uname -m)"
      
      if [ "${TARGET_ARCH}" = "amd64" ] || [ "${TARGET_ARCH}" = "x86_64" ]; then arch="x86_64"; else arch="${TARGET_ARCH}"; fi
      if [ "${TARGET_ARCH}" = "arm64" ] || [ "${TARGET_ARCH}" = "aarch64" ]; then arch="aarch64"; fi

      case "${TARGET_OS}" in
        macos*|darwin*) os_name="apple-darwin" ;;
        linux*) os_name="unknown-linux-musl" ;;
        *) printf '%s\n' "[ERROR] Unsupported OS for direct download: ${TARGET_OS}"; exit 1 ;;
      esac

      tar_name="just-${EXACT_VERSION}-${arch}-${os_name}"
      dl_url="https://github.com/casey/just/releases/download/${EXACT_VERSION}/${tar_name}.tar.gz"
      
      mkdir -p "${bin_dir}"
      libscript_download "${dl_url}" "/tmp/${tar_name}.tar.gz"
      
      tar -xzf "/tmp/${tar_name}.tar.gz" -C "${bin_dir}" just
      rm -f "/tmp/${tar_name}.tar.gz"
      
      chmod +x "${bin_dir}/just"
      
      libscript_symlink_alias "just" "${JUST_VERSION}" "${EXACT_VERSION}"
    fi
    ;;
esac
