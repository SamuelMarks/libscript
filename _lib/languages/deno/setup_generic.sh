#!/bin/sh
# ## Overview
# Generic setup module for Deno.
#
# ## Usage
# Installs Deno via official release binaries on GitHub or uses asdf/mise.


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

DENO_INSTALL_METHOD="${DENO_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript-native}}"
DENO_VERSION="${DENO_VERSION:-latest}"
ACTION="${ACTION:-install}"

resolve_exact_version() {
  if [ "${DENO_VERSION}" = "latest" ]; then
    # Use api to get latest version
    EXACT_VERSION=$(curl -s https://api.github.com/repos/denoland/deno/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
  else
    EXACT_VERSION=$(printf '%s\n' "$DENO_VERSION" | sed 's/^v//')
  fi
}

case "$ACTION" in
  ls)
    if [ "$DENO_INSTALL_METHOD" = "mise" ]; then
      mise ls deno
    elif [ "$DENO_INSTALL_METHOD" = "asdf" ]; then
      asdf list deno
    elif [ "$DENO_INSTALL_METHOD" = "system" ]; then
      deno --version
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/deno/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$DENO_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote deno
    elif [ "$DENO_INSTALL_METHOD" = "asdf" ]; then
      asdf list all deno
    elif [ "$DENO_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      curl -sL https://api.github.com/repos/denoland/deno/releases | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/' | head -n 30
    fi
    exit 0
    ;;
  use)
    if [ "$DENO_INSTALL_METHOD" = "mise" ]; then
      mise use "deno@${DENO_VERSION}"
    elif [ "$DENO_INSTALL_METHOD" = "asdf" ]; then
      asdf global deno "${DENO_VERSION}"
    elif [ "$DENO_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "deno" "${DENO_VERSION}" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  download|install|*)
    if [ "$DENO_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'deno' || { printf '%s\n' "Deno package not widely available, defaulting to from-source"; exit 1; }
    elif [ "$DENO_INSTALL_METHOD" = "mise" ]; then
      mise install "deno@${DENO_VERSION}"
    elif [ "$DENO_INSTALL_METHOD" = "asdf" ]; then
      asdf install deno "${DENO_VERSION}"
    else
      libscript_depends 'curl' 'unzip'
      resolve_exact_version
      
      DENO_DIR=$(libscript_get_version_dir "deno" "${EXACT_VERSION}")
      export PATH="${DENO_DIR}/bin:${PATH}"
      
      if [ -x "${DENO_DIR}/bin/deno" ] && "${DENO_DIR}/bin/deno" --version | grep -q "${EXACT_VERSION}"; then
        libscript_symlink_alias "deno" "${DENO_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

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
      
      TARGET="${arch}-${os}"
      DOWNLOAD_URL="https://github.com/denoland/deno/releases/download/v${EXACT_VERSION}/deno-${TARGET}.zip?v=${EXACT_VERSION}"

      DENO_ZIP=$(mktemp)
      libscript_download "${DOWNLOAD_URL}" "${DENO_ZIP}"
      
      mkdir -p "${DENO_DIR}/bin"
      unzip -q "${DENO_ZIP}" -d "${DENO_DIR}/bin"
      chmod +x "${DENO_DIR}/bin/deno"
      rm -f "${DENO_ZIP}"
      
      libscript_symlink_alias "deno" "${DENO_VERSION}" "${EXACT_VERSION}"
    fi
    ;;
esac