#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145



set -feu
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE}"

elif [ "${ZSH_VERSION-}" ]; then
  this_file="${0}"

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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
. "${SCRIPT_NAME}"

GO_INSTALL_METHOD="${GO_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-system}}"
GO_VERSION="${GO_VERSION:-latest}"
if [ "${GO_VERSION}" = "latest" ] || [ "${GO_VERSION}" = "stable" ]; then
  GO_VERSION=$(curl -sL "https://go.dev/VERSION?m=text" | head -n 1 | sed 's/^go//')
fi
if [ "${GO_INSTALL_METHOD}" = 'system' ]; then
  depends 'go'
else
  depends 'curl' 'tar'
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
  libscript_download "https://go.dev/dl/${archive}" "/tmp/${archive}"
  priv rm -rf /usr/local/go
  priv tar -C /usr/local -xzf "/tmp/${archive}"
  # shellcheck disable=SC2016
  echo 'export PATH=$PATH:/usr/local/go/bin' > /tmp/go_path.sh
  priv cp /tmp/go_path.sh /etc/profile.d/go.sh || true
fi
