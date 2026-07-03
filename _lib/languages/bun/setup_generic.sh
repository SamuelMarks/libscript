#!/bin/sh
# ## Overview
# Generic setup module for Bun.
#
# ## Usage
# Installs Bun by downloading release binaries from GitHub and supporting multiple installation methods (system, native, mise, asdf).


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

BUN_INSTALL_METHOD="${BUN_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript-native}}"
BUN_VERSION="${BUN_VERSION:-latest}"
ACTION="${ACTION:-install}"

resolve_exact_version() {
  if [ "${BUN_VERSION}" = "latest" ]; then
    # Use api to get latest version
    EXACT_VERSION=$(curl -s https://api.github.com/repos/oven-sh/bun/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
  elif [ "${BUN_VERSION}" = "canary" ]; then
    EXACT_VERSION="canary"
  else
    EXACT_VERSION=$(printf '%s\n' "$BUN_VERSION" | sed 's/^v//')
  fi
}

case "$ACTION" in
  ls)
    if [ "$BUN_INSTALL_METHOD" = "mise" ]; then
      mise ls bun
    elif [ "$BUN_INSTALL_METHOD" = "asdf" ]; then
      asdf list bun
    elif [ "$BUN_INSTALL_METHOD" = "system" ]; then
      bun --version
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/bun/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$BUN_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote bun
    elif [ "$BUN_INSTALL_METHOD" = "asdf" ]; then
      asdf list all bun
    elif [ "$BUN_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      curl -sL https://api.github.com/repos/oven-sh/bun/releases | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/' | head -n 30
    fi
    exit 0
    ;;
  use)
    if [ "$BUN_INSTALL_METHOD" = "mise" ]; then
      mise use "bun@${BUN_VERSION}"
    elif [ "$BUN_INSTALL_METHOD" = "asdf" ]; then
      asdf global bun "${BUN_VERSION}"
    elif [ "$BUN_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "bun" "${BUN_VERSION}" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  download|install|*)
    if [ "$BUN_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'bun' || { printf '%s\n' "Bun package not widely available, defaulting to from-source"; exit 1; }
    elif [ "$BUN_INSTALL_METHOD" = "mise" ]; then
      mise install "bun@${BUN_VERSION}"
    elif [ "$BUN_INSTALL_METHOD" = "asdf" ]; then
      asdf install bun "${BUN_VERSION}"
    else
      libscript_depends 'curl' 'unzip'
      resolve_exact_version
      
      BUN_DIR=$(libscript_get_version_dir "bun" "${EXACT_VERSION}")
      export PATH="${BUN_DIR}/bin:${PATH}"
      
      if [ -x "${BUN_DIR}/bin/bun" ] && "${BUN_DIR}/bin/bun" --version | grep -q "${EXACT_VERSION}"; then
        libscript_symlink_alias "bun" "${BUN_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      os="$(uname -s | tr '[:upper:]' '[:lower:]')"
      case "${os}" in
        'darwin'*) os='darwin' ;;
        *) os='linux' ;;
      esac
      arch="$(uname -m)"
      case "${arch}" in
        'x86_64') arch='x64' ;;
        'aarch64'|'arm64') arch='aarch64' ;;
        *) ;;
      esac
      
      # For Linux x64, Bun uses bun-linux-x64-baseline.zip by default unless specified
      TARGET="bun-${os}-${arch}"
      if [ "${EXACT_VERSION}" = "canary" ]; then
        DOWNLOAD_URL="https://github.com/oven-sh/bun/releases/download/canary/${TARGET}.zip?v=canary"
      else
        DOWNLOAD_URL="https://github.com/oven-sh/bun/releases/download/bun-v${EXACT_VERSION}/${TARGET}.zip?v=${EXACT_VERSION}"
      fi

      BUN_ZIP=$(mktemp)
      libscript_download "${DOWNLOAD_URL}" "${BUN_ZIP}"
      
      mkdir -p "${BUN_DIR}/bin"
      TMP_EXTRACT=$(mktemp -d)
      unzip -q "${BUN_ZIP}" -d "${TMP_EXTRACT}"
      mv "${TMP_EXTRACT}/${TARGET}/bun" "${BUN_DIR}/bin/"
      rm -f "${BUN_ZIP}"
      rm -rf "${TMP_EXTRACT}"
      
      libscript_symlink_alias "bun" "${BUN_VERSION}" "${EXACT_VERSION}"
    fi
    ;;
esac