#!/bin/sh
# ## Overview
# Generic setup module for Node.js.
#
# ## Usage
# Installs Node.js by downloading release tarballs from nodejs.org or using system/mise/asdf.


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

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

NODEJS_VERSION_LTS='22'
NODEJS_VERSION="${NODEJS_VERSION:-lts}"
if [ "${NODEJS_VERSION}" = 'lts' ]; then
  NODEJS_VERSION="${NODEJS_VERSION_LTS}"
fi

NODEJS_INSTALL_METHOD="${NODEJS_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript-native}}"
ACTION="${ACTION:-install}"

resolve_exact_version() {
  clean_version=$(printf '%s\n' "$NODEJS_VERSION" | sed 's/^v//')
  if [ "${clean_version}" = "latest" ] || [ "${clean_version}" = "lts" ]; then
    if [ "${clean_version}" = "latest" ]; then
      NODEJS_BASE_URL="https://nodejs.org/dist/latest"
    else
      NODEJS_BASE_URL="https://nodejs.org/dist/latest-v22.x"
    fi
    EXACT_VERSION=$(curl -s "${NODEJS_BASE_URL}/SHASUMS256.txt" | head -n 1 | grep -o 'node-v[0-9\.]*-' | sed 's/node-v//' | sed 's/-//')
  elif ! echo "${clean_version}" | grep -q '\.'; then
    NODEJS_BASE_URL="https://nodejs.org/dist/latest-v${clean_version}.x"
    EXACT_VERSION=$(curl -s "${NODEJS_BASE_URL}/SHASUMS256.txt" | head -n 1 | grep -o 'node-v[0-9\.]*-' | sed 's/node-v//' | sed 's/-//')
  else
    NODEJS_BASE_URL="https://nodejs.org/dist/v${clean_version}"
    EXACT_VERSION="${clean_version}"
  fi
}

case "$ACTION" in
  ls)
    if [ "$NODEJS_INSTALL_METHOD" = "mise" ]; then
      mise ls node
    elif [ "$NODEJS_INSTALL_METHOD" = "asdf" ]; then
      asdf list nodejs
    elif [ "$NODEJS_INSTALL_METHOD" = "system" ]; then
      node -v
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/nodejs/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$NODEJS_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote node
    elif [ "$NODEJS_INSTALL_METHOD" = "asdf" ]; then
      asdf list all nodejs
    elif [ "$NODEJS_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      curl -sL https://nodejs.org/dist/index.tab | awk 'NR>1 {print $1}' | sed 's/^v//'
    fi
    exit 0
    ;;
  use)
    if [ "$NODEJS_INSTALL_METHOD" = "mise" ]; then
      mise use "node@${NODEJS_VERSION}"
    elif [ "$NODEJS_INSTALL_METHOD" = "asdf" ]; then
      asdf global nodejs "${NODEJS_VERSION}"
    elif [ "$NODEJS_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "nodejs" "${NODEJS_VERSION}" "v${EXACT_VERSION}"
    fi
    exit 0
    ;;
  download|install|*)
    if [ "$NODEJS_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'nodejs'
    elif [ "$NODEJS_INSTALL_METHOD" = "mise" ]; then
      mise install "node@${NODEJS_VERSION}"
    elif [ "$NODEJS_INSTALL_METHOD" = "asdf" ]; then
      asdf install nodejs "${NODEJS_VERSION}"
    else
      libscript_depends 'curl' 'tar'
      resolve_exact_version
      NODE_DIR=$(libscript_get_version_dir "nodejs" "v${EXACT_VERSION}")
      export PATH="${NODE_DIR}/bin:${PATH}"
      
      if [ -x "${NODE_DIR}/bin/node" ]; then
        version=$("${NODE_DIR}/bin/node" --version)
        case "${version}" in
          v${EXACT_VERSION}*)
            libscript_symlink_alias "nodejs" "${NODEJS_VERSION}" "v${EXACT_VERSION}"
            exit 0
            ;;
        esac
      fi

      os="$(uname -s | tr '[:upper:]' '[:lower:]')"
      case "${os}" in
        'darwin'*) os='darwin' ;;
        *) os='linux' ;;
      esac
      arch="$(uname -m)"
      case "${arch}" in
        'x86_64') arch='x64' ;;
        'aarch64'|'arm64') arch='arm64' ;;
        *) ;;
      esac

      if [ ! -d "${NODE_DIR}" ]; then
        mkdir -p "${NODE_DIR}"
        TARBALL=$(mktemp)
        libscript_download "${NODEJS_BASE_URL}/node-v${EXACT_VERSION}-${os}-${arch}.tar.gz" "${TARBALL}"
        tar -xzf "${TARBALL}" -C "${NODE_DIR}" --strip-components=1
        rm -f "${TARBALL}"
      fi

      libscript_symlink_alias "nodejs" "${NODEJS_VERSION}" "v${EXACT_VERSION}"
    fi
    ;;
esac
