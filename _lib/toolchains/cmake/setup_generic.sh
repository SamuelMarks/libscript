#!/bin/sh
# ## Overview
# Generic setup script for the cmake component.
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

CMAKE_INSTALL_METHOD="${CMAKE_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript-native}}"
CMAKE_VERSION="${CMAKE_VERSION:-latest}"
ACTION="${ACTION:-install}"

resolve_exact_version() {
  if [ "${CMAKE_VERSION}" = "latest" ]; then
    EXACT_VERSION="3.31.2"
  else
    EXACT_VERSION="${CMAKE_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "$CMAKE_INSTALL_METHOD" = "mise" ]; then
      mise ls cmake
    elif [ "$CMAKE_INSTALL_METHOD" = "asdf" ]; then
      asdf list cmake
    elif [ "$CMAKE_INSTALL_METHOD" = "system" ]; then
      cmake --version || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/cmake/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$CMAKE_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote cmake
    elif [ "$CMAKE_INSTALL_METHOD" = "asdf" ]; then
      asdf list all cmake
    elif [ "$CMAKE_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      curl -sL "https://api.github.com/repos/Kitware/CMake/releases" | grep -o '"tag_name": "v[^"]*"' | sed 's/"tag_name": "v//' | sed 's/"//' | head -n 100
    fi
    exit 0
    ;;
  use)
    if [ "$CMAKE_INSTALL_METHOD" = "mise" ]; then
      mise use "cmake@${CMAKE_VERSION}"
    elif [ "$CMAKE_INSTALL_METHOD" = "asdf" ]; then
      asdf global cmake "${CMAKE_VERSION}"
    elif [ "$CMAKE_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "cmake" "${CMAKE_VERSION}" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  download|install|*)
    if [ "$CMAKE_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'cmake'
    elif [ "$CMAKE_INSTALL_METHOD" = "mise" ]; then
      mise install "cmake@${CMAKE_VERSION}"
    elif [ "$CMAKE_INSTALL_METHOD" = "asdf" ]; then
      asdf install cmake "${CMAKE_VERSION}"
    else
      libscript_depends 'curl' 'tar'
      resolve_exact_version
      
      CMAKE_DIR=$(libscript_get_version_dir "cmake" "${EXACT_VERSION}")
      
      if [ -x "${CMAKE_DIR}/bin/cmake" ] || [ -x "${CMAKE_DIR}/CMake.app/Contents/bin/cmake" ]; then
        libscript_symlink_alias "cmake" "${CMAKE_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      TARGET_OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
      TARGET_ARCH="$(uname -m)"
      
      if [ "${TARGET_ARCH}" = "amd64" ] || [ "${TARGET_ARCH}" = "x86_64" ]; then arch="x86_64"; else arch="${TARGET_ARCH}"; fi
      if [ "${TARGET_ARCH}" = "arm64" ] || [ "${TARGET_ARCH}" = "aarch64" ]; then arch="aarch64"; fi

      case "${TARGET_OS}" in
        macos*|darwin*)
          os_name="macos-universal"
          tar_name="cmake-${EXACT_VERSION}-${os_name}"
          ;;
        linux*)
          os_name="linux-${arch}"
          tar_name="cmake-${EXACT_VERSION}-${os_name}"
          ;;
        *) printf '%s\n' "[ERROR] Unsupported OS for direct download: ${TARGET_OS}"; exit 1 ;;
      esac

      dl_url="https://github.com/Kitware/CMake/releases/download/v${EXACT_VERSION}/${tar_name}.tar.gz"
      
      CMAKE_TARBALL=$(mktemp)
      libscript_download "${dl_url}" "${CMAKE_TARBALL}"
      
      TMP_DIR=$(mktemp -d)
      tar -xzf "${CMAKE_TARBALL}" -C "${TMP_DIR}"
      rm -f "${CMAKE_TARBALL}"
      
      mkdir -p "${CMAKE_DIR}"
      if echo "${TARGET_OS}" | grep -q "^darwin" || printf '%s\n' "${TARGET_OS}" | grep -q "^macos"; then
        cp -R "${TMP_DIR}/${tar_name}/CMake.app/Contents/"* "${CMAKE_DIR}/"
      else
        cp -R "${TMP_DIR}/${tar_name}/"* "${CMAKE_DIR}/"
      fi
      
      rm -rf "${TMP_DIR}"
      
      libscript_symlink_alias "cmake" "${CMAKE_VERSION}" "${EXACT_VERSION}"
    fi
    ;;
esac
