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

for _hm_lib in "_lib/_common/log.sh" "_lib/_common/os_info.sh"; do
  if [ -f "${LIBSCRIPT_ROOT_DIR}/${_hm_lib}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_hm_lib}"
    export SCRIPT_NAME
    # shellcheck disable=SC1090,SC1091
    . "${SCRIPT_NAME}"
    unset SCRIPT_NAME || true
  fi
done

log_info 'hMailServer is the native mail transfer agent for Microsoft Windows.'
if [ "${UNAME:-}" != "CYGWIN_NT" ] && [ "${UNAME:-}" != "MINGW64_NT" ]; then
  if command -v exim >/dev/null 2>&1 || command -v exim4 >/dev/null 2>&1; then
    log_info 'Mail transfer agent (exim) is already installed.'
    exit 0
  fi
  log_info 'On POSIX platforms, Exim is recommended. Invoking Exim setup...'
  "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/exim/setup.sh" "$@"
fi
