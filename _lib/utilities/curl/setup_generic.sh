#!/bin/sh
# shellcheck disable=SC3054,SC3040,SC2296,SC2128,SC2039,SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145


set -feu
if [ "${SCRIPT_NAME-}" ]; then this_file="${SCRIPT_NAME}"; else this_file="${0}"; fi
case "${STACK+x}" in *':'"${this_file}"':'*) if (return 0 2>/dev/null); then return; else exit 0; fi ;; esac
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
