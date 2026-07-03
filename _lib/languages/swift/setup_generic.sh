#!/bin/sh
# ## Overview
# Generic setup module for Swift.
#
# ## Usage
# Installs Swift by downloading release tarballs from swift.org or by delegating to system/mise/asdf.


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

SWIFT_INSTALL_METHOD="${SWIFT_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript-native}}"
SWIFT_VERSION="${SWIFT_VERSION:-5.10}"
ACTION="${ACTION:-install}"

resolve_exact_version() {
  if [ "${SWIFT_VERSION}" = "latest" ]; then
    EXACT_VERSION="5.10"
  else
    EXACT_VERSION="${SWIFT_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "$SWIFT_INSTALL_METHOD" = "mise" ]; then
      mise ls swift
    elif [ "$SWIFT_INSTALL_METHOD" = "asdf" ]; then
      asdf list swift
    elif [ "$SWIFT_INSTALL_METHOD" = "system" ]; then
      swift --version || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/swift/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$SWIFT_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote swift
    elif [ "$SWIFT_INSTALL_METHOD" = "asdf" ]; then
      asdf list all swift
    elif [ "$SWIFT_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      # Provide a basic list of known versions as a fallback.
      printf '%s\n' "5.9.2"
      printf '%s\n' "5.10"
      printf '%s\n' "5.10.1"
      printf '%s\n' "6.0"
    fi
    exit 0
    ;;
  use)
    if [ "$SWIFT_INSTALL_METHOD" = "mise" ]; then
      mise use "swift@${SWIFT_VERSION}"
    elif [ "$SWIFT_INSTALL_METHOD" = "asdf" ]; then
      asdf global swift "${SWIFT_VERSION}"
    elif [ "$SWIFT_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "swift" "${SWIFT_VERSION}" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  download|install|*)
    if [ "$SWIFT_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'swift'
    elif [ "$SWIFT_INSTALL_METHOD" = "mise" ]; then
      mise install "swift@${SWIFT_VERSION}"
    elif [ "$SWIFT_INSTALL_METHOD" = "asdf" ]; then
      asdf install swift "${SWIFT_VERSION}"
    else
      libscript_depends 'curl' 'tar'
      resolve_exact_version
      
      SWIFT_DIR=$(libscript_get_version_dir "swift" "${EXACT_VERSION}")
      
      if [ -x "${SWIFT_DIR}/usr/bin/swift" ]; then
        libscript_symlink_alias "swift" "${SWIFT_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      # Default to ubuntu22.04 for linux binaries as a generic approach
      # A production implementation would map more OSs.
      os="$(uname -s | tr '[:upper:]' '[:lower:]')"
      if [ "$os" = "darwin" ]; then
        # On macOS, Swift is usually managed by Xcode. Let's just log a warning and fall back to system
        printf '%s\n' "Swift on macOS should generally be installed via Xcode or system packages."
        libscript_depends 'swift'
        exit 0
      fi

      SWIFT_URL="https://download.swift.org/swift-${EXACT_VERSION}-release/ubuntu2204/swift-${EXACT_VERSION}-RELEASE/swift-${EXACT_VERSION}-RELEASE-ubuntu22.04.tar.gz"
      SWIFT_TARBALL=$(mktemp)
      libscript_download "${SWIFT_URL}" "${SWIFT_TARBALL}"
      
      mkdir -p "${SWIFT_DIR}"
      tar -C "${SWIFT_DIR}" --strip-components=1 -xzf "${SWIFT_TARBALL}"
      rm -f "${SWIFT_TARBALL}"
      
      libscript_symlink_alias "swift" "${SWIFT_VERSION}" "${EXACT_VERSION}"
    fi
    ;;
esac
