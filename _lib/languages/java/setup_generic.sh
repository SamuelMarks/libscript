#!/bin/sh
# ## Overview
# Generic setup module for Java.
#
# ## Usage
# Installs Java by downloading Temurin from Adoptium or by delegating to system/mise/asdf.


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

JAVA_INSTALL_METHOD="${JAVA_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript-native}}"
JAVA_VERSION="${JAVA_VERSION:-17}"
if [ "${JAVA_VERSION}" = "latest" ]; then
  JAVA_VERSION="21"
fi
ACTION="${ACTION:-install}"

case "$ACTION" in
  ls)
    if [ "$JAVA_INSTALL_METHOD" = "mise" ]; then
      mise ls java
    elif [ "$JAVA_INSTALL_METHOD" = "asdf" ]; then
      asdf list java
    elif [ "$JAVA_INSTALL_METHOD" = "system" ]; then
      java -version
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/java/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$JAVA_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote java
    elif [ "$JAVA_INSTALL_METHOD" = "asdf" ]; then
      asdf list all java
    elif [ "$JAVA_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      printf '%b\n' '8\n11\n17\n21\n22'
    fi
    exit 0
    ;;
  use)
    if [ "$JAVA_INSTALL_METHOD" = "mise" ]; then
      mise use "java@${JAVA_VERSION}"
    elif [ "$JAVA_INSTALL_METHOD" = "asdf" ]; then
      asdf global java "${JAVA_VERSION}"
    elif [ "$JAVA_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      libscript_symlink_alias "java" "${JAVA_VERSION}" "${JAVA_VERSION}"
    fi
    exit 0
    ;;
  download|install|*)
    if [ "$JAVA_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'java'
    elif [ "$JAVA_INSTALL_METHOD" = "mise" ]; then
      mise install "java@${JAVA_VERSION}"
    elif [ "$JAVA_INSTALL_METHOD" = "asdf" ]; then
      asdf install java "${JAVA_VERSION}"
    else
      JAVA_DIR=$(libscript_get_version_dir "java" "${JAVA_VERSION}")
      export JAVA_HOME="${JAVA_DIR}"
      export PATH="${JAVA_DIR}/bin:${PATH}"
      
      if [ -x "${JAVA_DIR}/bin/java" ] && "${JAVA_DIR}/bin/java" -version 2>&1 | grep -q "\"${JAVA_VERSION}"; then
        libscript_symlink_alias "java" "${JAVA_VERSION}" "${JAVA_VERSION}"
        exit 0
      fi

      libscript_depends 'curl' 'tar'
      
      os="$(uname -s | tr '[:upper:]' '[:lower:]')"
      case "${os}" in
        'darwin'*) os='mac' ;;
        *) os='linux' ;;
      esac
      arch="$(uname -m)"
      case "${arch}" in
        'x86_64') arch='x64' ;;
        'aarch64'|'arm64') arch='aarch64' ;;
        *) ;;
      esac
      
      # Using Adoptium API for temurin jdk
      DOWNLOAD_URL="https://api.adoptium.net/v3/binary/latest/${JAVA_VERSION}/ga/${os}/${arch}/jdk/hotspot/normal/eclipse"
      
      JAVA_TARBALL=$(mktemp)
      libscript_download "${DOWNLOAD_URL}" "${JAVA_TARBALL}"
      
      mkdir -p "${JAVA_DIR}"
      if [ "${os}" = "mac" ]; then
        # macOS tarballs usually have a Contents/Home directory structure inside
        TMP_EXTRACT=$(mktemp -d)
        tar -xzf "${JAVA_TARBALL}" -C "${TMP_EXTRACT}"
        mv "${TMP_EXTRACT}"/*/Contents/Home/* "${JAVA_DIR}/" || mv "${TMP_EXTRACT}"/*/* "${JAVA_DIR}/"
        rm -rf "${TMP_EXTRACT}"
      else
        tar -xzf "${JAVA_TARBALL}" -C "${JAVA_DIR}" --strip-components=1
      fi
      rm -f "${JAVA_TARBALL}"
      
      libscript_symlink_alias "java" "${JAVA_VERSION}" "${JAVA_VERSION}"
    fi
    ;;
esac
