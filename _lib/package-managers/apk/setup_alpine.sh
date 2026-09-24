#!/bin/sh
# ## Overview
# Alpine Linux setup module for apk package manager.
#
# ## Usage
# Executes native setup for apk on Alpine Linux.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"

for LIB in "_lib/_common/log.sh" "_lib/_common/paths.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

APK_BIN=$(command -v apk 2>/dev/null || printf '/sbin/apk')
if [ ! -x "$APK_BIN" ]; then
  log_error "apk executable not found on Alpine Linux"
  exit 1
fi

VERSION="${APK_VERSION:-latest}"
SYS_VER=$(apk --version 2>&1 | awk '{print $2}' | tr -d ',' || printf 'latest')
TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/apk/${SYS_VER}"

mkdir -p "${TARGET_DIR}/bin"
ln -sf "$APK_BIN" "${TARGET_DIR}/bin/apk"
libscript_symlink_alias "apk" "$VERSION" "$SYS_VER"
log_info "apk verified on Alpine Linux ($SYS_VER)"
