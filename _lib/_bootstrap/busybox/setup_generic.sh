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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
. "${SCRIPT_NAME}"

if ! command -v busybox >/dev/null 2>&1; then
  if ! depends 'busybox'; then
    echo "Attempting static binary download for busybox..."
    ARCH=$(uname -m)
    case "$ARCH" in
      x86_64) BARCH="x86_64" ;;
      aarch64|arm64) BARCH="aarch64" ;;
      armv7l) BARCH="armv7l" ;;
      i386|i686) BARCH="i686" ;;
      *) BARCH="x86_64" ;;
    esac
    libscript_download "https://busybox.net/downloads/binaries/1.35.0-${BARCH}-linux-musl/busybox" "/tmp/busybox" || { echo "Failed to download busybox"; exit 1; }
    chmod +x /tmp/busybox
    if [ -w /usr/local/bin ]; then
      mv /tmp/busybox /usr/local/bin/busybox
    else
      mkdir -p ~/.local/bin
      mv /tmp/busybox ~/.local/bin/busybox
    fi
  fi
fi
