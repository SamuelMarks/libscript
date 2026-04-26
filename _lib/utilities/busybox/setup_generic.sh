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
for lib in '_lib/_common/pkg_mgr.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

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
