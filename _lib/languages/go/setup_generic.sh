#!/bin/sh
# ## Overview
# Generic setup module for Go.
#
# ## Usage
# Installs Go by downloading release tarballs from go.dev or delegates to system/asdf/mise.


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

GO_INSTALL_METHOD="${GO_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript-native}}"
GO_VERSION="${GO_VERSION:-latest}"
ACTION="${ACTION:-install}"

resolve_exact_version() {
  if [ "${GO_VERSION}" = "latest" ] || [ "${GO_VERSION}" = "stable" ]; then
    GO_VER_FILE=$(mktemp)
    libscript_download "https://go.dev/VERSION?m=text" "${GO_VER_FILE}"
    EXACT_VERSION=$(head -n 1 < "${GO_VER_FILE}" | sed 's/^go//')
    rm -f "${GO_VER_FILE}"
  else
    EXACT_VERSION=$(printf '%s\n' "$GO_VERSION" | sed 's/^go//')
  fi
}

case "$ACTION" in
  ls)
    if [ "$GO_INSTALL_METHOD" = "mise" ]; then
      mise ls go
    elif [ "$GO_INSTALL_METHOD" = "asdf" ]; then
      asdf list golang
    elif [ "$GO_INSTALL_METHOD" = "system" ]; then
      go version
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/go/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$GO_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote go
    elif [ "$GO_INSTALL_METHOD" = "asdf" ]; then
      asdf list all golang
    elif [ "$GO_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      curl -sL "https://go.dev/dl/?mode=json&include=all" | grep -o '"version": "[^"]*"' | sed 's/"version": "go//' | sed 's/"//' | head -n 100
    fi
    exit 0
    ;;
  use)
    if [ "$GO_INSTALL_METHOD" = "mise" ]; then
      mise use "go@${GO_VERSION}"
    elif [ "$GO_INSTALL_METHOD" = "asdf" ]; then
      asdf global golang "${GO_VERSION}"
    elif [ "$GO_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "go" "${GO_VERSION}" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  download|install|*)
    if [ "$GO_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'go'
    elif [ "$GO_INSTALL_METHOD" = "mise" ]; then
      mise install "go@${GO_VERSION}"
    elif [ "$GO_INSTALL_METHOD" = "asdf" ]; then
      asdf install golang "${GO_VERSION}"
    else
      libscript_depends 'tar' 'curl'
      resolve_exact_version
      
      GO_DIR=$(libscript_get_version_dir "go" "${EXACT_VERSION}")
      export PATH="${GO_DIR}/bin:${PATH}"
      
      if [ -x "${GO_DIR}/bin/go" ] && "${GO_DIR}/bin/go" version | grep -q "go${EXACT_VERSION} "; then
        libscript_symlink_alias "go" "${GO_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      os="$(uname -s | tr '[:upper:]' '[:lower:]')"
      case "${os}" in
        'darwin'*) os='darwin' ;;
        'freebsd'*) os='freebsd' ;;
        *) os='linux' ;;
      esac
      arch="$(uname -m)"
      case "${arch}" in
        'x86_64') arch='amd64' ;;
        'aarch64'|'arm64') arch='arm64' ;;
        *) ;;
      esac
      
      archive="go${EXACT_VERSION}.${os}-${arch}.tar.gz"
      GO_TARBALL=$(mktemp)
      libscript_download "https://go.dev/dl/${archive}" "${GO_TARBALL}"
      
      mkdir -p "${GO_DIR}"
      # extract exactly into GO_DIR (stripping the toplevel go/ directory)
      tar -C "${GO_DIR}" --strip-components=1 -xzf "${GO_TARBALL}"
      rm -f "${GO_TARBALL}"
      
      libscript_symlink_alias "go" "${GO_VERSION}" "${EXACT_VERSION}"
    fi
    ;;
esac
