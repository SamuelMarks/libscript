#!/bin/sh
# ## Overview
# Generic uninstallation handler for rosbe isolated version directories.
#
# ## Usage
# ./_lib/toolchains/rosbe/uninstall_generic.sh

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

ROSBE_VERSION="${ROSBE_VERSION:-${LIBSCRIPT_ROSBE_VERSION:-2.2.1}}"
[ "$ROSBE_VERSION" = 'latest' ] && ROSBE_VERSION='2.2.1'
TARGET_INSTALL_DIR="${LIBSCRIPT_ROSBE_INSTALL_DIR:-${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/rosbe/${ROSBE_VERSION}}"
if [ -d "$TARGET_INSTALL_DIR" ]; then
  rm -rf "$TARGET_INSTALL_DIR"
fi
rm -f "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/bin/rosbe" 2>/dev/null || true
printf '[OK] Uninstalled rosbe %s.\n' "$ROSBE_VERSION"
