#!/bin/sh
# ## Overview
# Generic setup module for Kotlin.
#
# ## Usage
# Installs Kotlin by downloading official zips from GitHub or delegating to system/asdf/mise.


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

KOTLIN_INSTALL_METHOD="${KOTLIN_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript-native}}"
KOTLIN_VERSION="${KOTLIN_VERSION:-1.9.20}"
ACTION="${ACTION:-install}"

resolve_exact_version() {
  if [ "${KOTLIN_VERSION}" = "latest" ]; then
    EXACT_VERSION="1.9.20"
  else
    EXACT_VERSION="${KOTLIN_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "$KOTLIN_INSTALL_METHOD" = "mise" ]; then
      mise ls kotlin
    elif [ "$KOTLIN_INSTALL_METHOD" = "asdf" ]; then
      asdf list kotlin
    elif [ "$KOTLIN_INSTALL_METHOD" = "system" ]; then
      kotlin -version || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/kotlin/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$KOTLIN_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote kotlin
    elif [ "$KOTLIN_INSTALL_METHOD" = "asdf" ]; then
      asdf list all kotlin
    elif [ "$KOTLIN_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      curl -sL "https://api.github.com/repos/JetBrains/kotlin/releases" | grep -o '"tag_name": "v[^"]*"' | sed 's/"tag_name": "v//' | sed 's/"//' | head -n 100
    fi
    exit 0
    ;;
  use)
    if [ "$KOTLIN_INSTALL_METHOD" = "mise" ]; then
      mise use "kotlin@${KOTLIN_VERSION}"
    elif [ "$KOTLIN_INSTALL_METHOD" = "asdf" ]; then
      asdf global kotlin "${KOTLIN_VERSION}"
    elif [ "$KOTLIN_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "kotlin" "${KOTLIN_VERSION}" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  download|install|*)
    if [ "$KOTLIN_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'kotlin'
    elif [ "$KOTLIN_INSTALL_METHOD" = "mise" ]; then
      mise install "kotlin@${KOTLIN_VERSION}"
    elif [ "$KOTLIN_INSTALL_METHOD" = "asdf" ]; then
      asdf install kotlin "${KOTLIN_VERSION}"
    else
      libscript_depends 'curl' 'unzip'
      resolve_exact_version
      
      KOTLIN_DIR=$(libscript_get_version_dir "kotlin" "${EXACT_VERSION}")
      
      if [ -x "${KOTLIN_DIR}/bin/kotlin" ]; then
        libscript_symlink_alias "kotlin" "${KOTLIN_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      KOTLIN_URL="https://github.com/JetBrains/kotlin/releases/download/v${EXACT_VERSION}/kotlin-compiler-${EXACT_VERSION}.zip"
      KOTLIN_ZIP=$(mktemp)
      libscript_download "${KOTLIN_URL}" "${KOTLIN_ZIP}"
      
      # Extract into KOTLIN_DIR. The zip contains a 'kotlinc' directory.
      TMP_DIR=$(mktemp -d)
      unzip -q -o "${KOTLIN_ZIP}" -d "${TMP_DIR}"
      rm -f "${KOTLIN_ZIP}"
      
      mkdir -p "${KOTLIN_DIR}"
      # Move contents of kotlinc into KOTLIN_DIR
      if [ -d "${TMP_DIR}/kotlinc" ]; then
        cp -a "${TMP_DIR}/kotlinc/"* "${KOTLIN_DIR}/"
      else
        cp -a "${TMP_DIR}/"* "${KOTLIN_DIR}/"
      fi
      rm -rf "${TMP_DIR}"
      
      libscript_symlink_alias "kotlin" "${KOTLIN_VERSION}" "${EXACT_VERSION}"
    fi
    ;;
esac
