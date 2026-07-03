#!/bin/sh
# ## Overview
# Generic setup script for the sbt component.
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

SBT_INSTALL_METHOD="${SBT_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript-native}}"
SBT_VERSION="${SBT_VERSION:-latest}"
ACTION="${ACTION:-install}"

resolve_exact_version() {
  if [ "${SBT_VERSION}" = "latest" ]; then
    EXACT_VERSION=$(curl -s https://api.github.com/repos/sbt/sbt/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
  else
    EXACT_VERSION="${SBT_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "$SBT_INSTALL_METHOD" = "mise" ]; then
      mise ls sbt
    elif [ "$SBT_INSTALL_METHOD" = "asdf" ]; then
      asdf list sbt
    elif [ "$SBT_INSTALL_METHOD" = "system" ]; then
      sbt --version
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/sbt/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$SBT_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote sbt
    elif [ "$SBT_INSTALL_METHOD" = "asdf" ]; then
      asdf list all sbt
    elif [ "$SBT_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      curl -sL https://api.github.com/repos/sbt/sbt/releases | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/' | head -n 30
    fi
    exit 0
    ;;
  use)
    if [ "$SBT_INSTALL_METHOD" = "mise" ]; then
      mise use "sbt@${SBT_VERSION}"
    elif [ "$SBT_INSTALL_METHOD" = "asdf" ]; then
      asdf global sbt "${SBT_VERSION}"
    elif [ "$SBT_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "sbt" "${SBT_VERSION}" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  download|install|*)
    if [ "$SBT_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'sbt' || { printf '%s\n' "SBT package not widely available via system."; exit 1; }
    elif [ "$SBT_INSTALL_METHOD" = "mise" ]; then
      mise install "sbt@${SBT_VERSION}"
    elif [ "$SBT_INSTALL_METHOD" = "asdf" ]; then
      asdf install sbt "${SBT_VERSION}"
    else
      libscript_depends 'curl' 'unzip' 'java'
      resolve_exact_version
      
      SBT_DIR=$(libscript_get_version_dir "sbt" "${EXACT_VERSION}")
      export PATH="${SBT_DIR}/bin:${PATH}"
      
      if [ -x "${SBT_DIR}/bin/sbt" ] && "${SBT_DIR}/bin/sbt" --version | grep -q "${EXACT_VERSION}"; then
        libscript_symlink_alias "sbt" "${SBT_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      DOWNLOAD_URL="https://github.com/sbt/sbt/releases/download/v${EXACT_VERSION}/sbt-${EXACT_VERSION}.zip"

      SBT_ZIP=$(mktemp)
      libscript_download "${DOWNLOAD_URL}" "${SBT_ZIP}"
      
      mkdir -p "${SBT_DIR}"
      TMP_EXTRACT=$(mktemp -d)
      unzip -q "${SBT_ZIP}" -d "${TMP_EXTRACT}"
      mv "${TMP_EXTRACT}/sbt/"* "${SBT_DIR}/" || mv "${TMP_EXTRACT}/sbt"/* "${SBT_DIR}/"
      rm -f "${SBT_ZIP}"
      rm -rf "${TMP_EXTRACT}"
      
      libscript_symlink_alias "sbt" "${SBT_VERSION}" "${EXACT_VERSION}"
    fi
    ;;
esac