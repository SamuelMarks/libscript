#!/bin/sh
# ## Overview
# Generic setup module for hMailServer (Windows-native mail transfer agent).
#
# ## Usage
# Execute this script to install and configure hmailserver on the local system.

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

log_info "hMailServer is the native mail transfer agent for Microsoft Windows."
if [ "$(uname -s)" != "CYGWIN_NT" ] && [ "$(uname -s)" != "MINGW64_NT" ]; then
  if command -v exim >/dev/null 2>&1 || command -v exim4 >/dev/null 2>&1; then
    log_info "Mail transfer agent (exim) is already installed."
    exit 0
  fi
  log_info "On POSIX platforms, Exim is recommended. Invoking Exim setup..."
  "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/exim/setup.sh" "$@"
fi
