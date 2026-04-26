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
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR:-$(cd "$(dirname "$this_file")/../../.." && pwd)}/_lib/_common/pkg_mgr.sh"
# shellcheck disable=SC1090,SC1091,SC2034
. "${SCRIPT_NAME}"

if ! command -v curl >/dev/null 2>&1; then
  if ! depends 'curl'; then
    echo "Attempting static binary download for curl..."
    ARCH=$(uname -m)
    case "$ARCH" in
      x86_64) BARCH="amd64" ;;
      aarch64|arm64) BARCH="arm64" ;;
      armv7l) BARCH="arm" ;;
      i386|i686) BARCH="i386" ;;
      *) BARCH="amd64" ;;
    esac
    libscript_download "https://github.com/moparisthebest/static-curl/releases/latest/download/curl-${BARCH}" "/tmp/curl" || { echo "Failed to download static curl"; exit 1; }
    chmod +x /tmp/curl
    if [ -w /usr/local/bin ]; then
      mv /tmp/curl /usr/local/bin/curl
    else
      mkdir -p ~/.local/bin
      mv /tmp/curl ~/.local/bin/curl
    fi
  fi
fi
