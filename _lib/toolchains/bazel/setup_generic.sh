#!/bin/sh
# ## Overview
# Generic setup script for the bazel component.
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

BAZEL_INSTALL_METHOD="${BAZEL_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript-native}}"
BAZEL_VERSION="${BAZEL_VERSION:-latest}"
ACTION="${ACTION:-install}"

resolve_exact_version() {
  if [ "${BAZEL_VERSION}" = "latest" ]; then
    EXACT_VERSION="v1.25.0" # Bazelisk version
  else
    EXACT_VERSION="${BAZEL_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "$BAZEL_INSTALL_METHOD" = "mise" ]; then
      mise ls bazel
    elif [ "$BAZEL_INSTALL_METHOD" = "asdf" ]; then
      asdf list bazel
    elif [ "$BAZEL_INSTALL_METHOD" = "system" ]; then
      bazel --version || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/bazel/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$BAZEL_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote bazel
    elif [ "$BAZEL_INSTALL_METHOD" = "asdf" ]; then
      asdf list all bazel
    elif [ "$BAZEL_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      curl -sL "https://api.github.com/repos/bazelbuild/bazelisk/releases" | grep -o '"tag_name": "v[^"]*"' | sed 's/"tag_name": "//' | sed 's/"//' | head -n 100
    fi
    exit 0
    ;;
  use)
    if [ "$BAZEL_INSTALL_METHOD" = "mise" ]; then
      mise use "bazel@${BAZEL_VERSION}"
    elif [ "$BAZEL_INSTALL_METHOD" = "asdf" ]; then
      asdf global bazel "${BAZEL_VERSION}"
    elif [ "$BAZEL_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "bazel" "${BAZEL_VERSION}" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  download|install|*)
    if [ "$BAZEL_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'bazel'
    elif [ "$BAZEL_INSTALL_METHOD" = "mise" ]; then
      mise install "bazel@${BAZEL_VERSION}"
    elif [ "$BAZEL_INSTALL_METHOD" = "asdf" ]; then
      asdf install bazel "${BAZEL_VERSION}"
    else
      libscript_depends 'curl'
      resolve_exact_version
      
      BAZEL_DIR=$(libscript_get_version_dir "bazel" "${EXACT_VERSION}")
      bin_dir="${BAZEL_DIR}/bin"
      
      if [ -x "${bin_dir}/bazel" ]; then
        libscript_symlink_alias "bazel" "${BAZEL_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      TARGET_OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
      TARGET_ARCH="$(uname -m)"
      
      if [ "${TARGET_ARCH}" = "x86_64" ]; then TARGET_ARCH="amd64"; fi
      if [ "${TARGET_ARCH}" = "aarch64" ] || [ "${TARGET_ARCH}" = "arm64" ]; then TARGET_ARCH="arm64"; fi

      case "${TARGET_OS}" in
        macos*|darwin*) os_name="darwin" ;;
        linux*) os_name="linux" ;;
        *) printf '%s\n' "[ERROR] Unsupported OS for direct download: ${TARGET_OS}"; exit 1 ;;
      esac

      dl_url="https://github.com/bazelbuild/bazelisk/releases/download/${EXACT_VERSION}/bazelisk-${os_name}-${TARGET_ARCH}"
      
      mkdir -p "${bin_dir}"
      libscript_download "${dl_url}" "${bin_dir}/bazel"
      chmod +x "${bin_dir}/bazel"
      
      libscript_symlink_alias "bazel" "${BAZEL_VERSION}" "${EXACT_VERSION}"
    fi
    ;;
esac
