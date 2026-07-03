#!/bin/sh
# ## Overview
# Generic setup script for the gradle component.
# It provides fallback installation logic and cross-platform installation steps
# when a more specific OS/distribution setup script is not available.
#
# ## Usage
# This script is typically called internally by the component lifecycle.


set -feu
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
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  . "${SCRIPT_NAME}"
done

GRADLE_INSTALL_METHOD="${GRADLE_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript-native}}"
GRADLE_VERSION="${GRADLE_VERSION:-latest}"
ACTION="${ACTION:-install}"

resolve_exact_version() {
  if [ "${GRADLE_VERSION}" = "latest" ]; then
    EXACT_VERSION=$(curl -sL https://services.gradle.org/versions/current | jq -r '.version' 2>/dev/null || curl -sL https://services.gradle.org/versions/current | grep -o '"version"\s*:\s*"[^"]*"' | cut -d'"' -f4)
    if [ -z "$EXACT_VERSION" ]; then EXACT_VERSION="8.7"; fi
  else
    EXACT_VERSION="${GRADLE_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "$GRADLE_INSTALL_METHOD" = "mise" ]; then
      mise ls gradle
    elif [ "$GRADLE_INSTALL_METHOD" = "asdf" ]; then
      asdf list gradle
    elif [ "$GRADLE_INSTALL_METHOD" = "system" ]; then
      gradle --version
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/gradle/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$GRADLE_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote gradle
    elif [ "$GRADLE_INSTALL_METHOD" = "asdf" ]; then
      asdf list all gradle
    elif [ "$GRADLE_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      curl -sL https://services.gradle.org/versions/all | grep -o '"version"\s*:\s*"[^"]*"' | cut -d'"' -f4 | head -n 30
    fi
    exit 0
    ;;
  use)
    if [ "$GRADLE_INSTALL_METHOD" = "mise" ]; then
      mise use "gradle@${GRADLE_VERSION}"
    elif [ "$GRADLE_INSTALL_METHOD" = "asdf" ]; then
      asdf global gradle "${GRADLE_VERSION}"
    elif [ "$GRADLE_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "gradle" "${GRADLE_VERSION}" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  download|install|*)
    if [ "$GRADLE_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'gradle' || { printf '%s\n' "Gradle package not widely available via system."; exit 1; }
    elif [ "$GRADLE_INSTALL_METHOD" = "mise" ]; then
      mise install "gradle@${GRADLE_VERSION}"
    elif [ "$GRADLE_INSTALL_METHOD" = "asdf" ]; then
      asdf install gradle "${GRADLE_VERSION}"
    else
      libscript_depends 'curl' 'unzip' 'java'
      resolve_exact_version
      
      GRADLE_DIR=$(libscript_get_version_dir "gradle" "${EXACT_VERSION}")
      export PATH="${GRADLE_DIR}/bin:${PATH}"
      
      if [ -x "${GRADLE_DIR}/bin/gradle" ] && "${GRADLE_DIR}/bin/gradle" --version | grep -q "${EXACT_VERSION}"; then
        libscript_symlink_alias "gradle" "${GRADLE_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      DOWNLOAD_URL="https://services.gradle.org/distributions/gradle-${EXACT_VERSION}-bin.zip"

      GRADLE_ZIP=$(mktemp)
      libscript_download "${DOWNLOAD_URL}" "${GRADLE_ZIP}"
      
      mkdir -p "${GRADLE_DIR}"
      TMP_EXTRACT=$(mktemp -d)
      unzip -q "${GRADLE_ZIP}" -d "${TMP_EXTRACT}"
      mv "${TMP_EXTRACT}/gradle-${EXACT_VERSION}/"* "${GRADLE_DIR}/" || mv "${TMP_EXTRACT}/gradle-${EXACT_VERSION}"/* "${GRADLE_DIR}/"
      rm -f "${GRADLE_ZIP}"
      rm -rf "${TMP_EXTRACT}"
      
      libscript_symlink_alias "gradle" "${GRADLE_VERSION}" "${EXACT_VERSION}"
    fi
    ;;
esac