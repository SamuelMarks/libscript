#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'
DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

for lib in '_lib/_common/pkg_mgr.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

GO_INSTALL_METHOD="${GO_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-system}}"
GO_VERSION="${GO_VERSION:-latest}"
if [ "${GO_VERSION}" = "latest" ] || [ "${GO_VERSION}" = "stable" ]; then
  GO_VER_FILE=$(mktemp)
  libscript_download "https://go.dev/VERSION?m=text" "${GO_VER_FILE}"
  GO_VERSION=$(head -n 1 < "${GO_VER_FILE}" | sed 's/^go//')
  rm -f "${GO_VER_FILE}"
fi
if [ "${GO_INSTALL_METHOD}" = 'system' ]; then
  depends 'go'
else
  depends 'tar'
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
  archive="go${GO_VERSION}.${os}-${arch}.tar.gz"
  GO_TARBALL=$(mktemp)
  libscript_download "https://go.dev/dl/${archive}" "${GO_TARBALL}"
  priv rm -rf /usr/local/go
  priv tar -C /usr/local -xzf "${GO_TARBALL}"
  rm -f "${GO_TARBALL}"
  # shellcheck disable=SC2016
  echo 'export PATH=$PATH:/usr/local/go/bin' > /tmp/go_path.sh
  priv cp /tmp/go_path.sh /etc/profile.d/go.sh || true
fi
