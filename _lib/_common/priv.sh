#!/bin/sh
# ## Overview
# Detects and configures privilege escalation tools (sudo, doas, su).
# It exports the `priv` function to transparently execute commands with
# root privileges depending on the available system utility and user identity.
# 
# ## Usage
# Source this file and prefix commands requiring elevated rights with `priv`.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR:-$(dirname "$THIS_FILE")/..}/_lib/_common/os_info.sh"
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}" 2>/dev/null || true



if [ "${TARGET_OS}" = "windows" ] || [ "${TARGET_OS}" = "mingw" ] || [ "${TARGET_OS}" = "cygwin" ]; then
  PRIV=''
elif [ "${PRIV+x}" = 'x' ]; then
  true;
elif [ "$(id -u)" = "0" ]; then
  PRIV='';
elif command -v sudo >/dev/null 2>&1 ; then
  PRIV='sudo';
elif command -v doas >/dev/null 2>&1 ; then
  PRIV='doas';
else
  >&2 printf "Error: This script must be run as root or with sudo/doas privileges.\n"
  exit 1
fi
export PRIV;

if command -v sudo >/dev/null 2>&1; then
  priv_as() {
    user="${1}"
    shift
    sudo -u "${user}" "$@"
  }
elif command -v doas >/dev/null 2>&1; then
  priv_as() {
    user="${1}"
    shift
    doas -u "${user}" "$@"
  }
elif command -v su >/dev/null 2>&1; then
  priv_as() {
    user="${1}"
    shift
    cmd=""
    for arg; do
      escaped_arg=$(printf "%s" "$arg" | sed "s/'/'\"'\"'/g")
      cmd="${cmd}'${escaped_arg}' "
    done

    su - "${user}" -c "sh -c ${cmd}"
  }
else
  priv_as() {
    user="${1}"
    shift
    su "${user}" -- -x -c "$*"
  }
fi


if [ -n "${PRIV}" ]; then
  priv() { if [ "${LIBSCRIPT_SKIP_SYSTEM_DEPS:-0}" = "1" ]; then return 0; fi; "${PRIV}" "$@"; }
elif command -v su >/dev/null 2>&1; then
  priv() { if [ "${LIBSCRIPT_SKIP_SYSTEM_DEPS:-0}" = "1" ]; then return 0; fi; priv_as root "$@"; }
else
  priv() { if [ "${LIBSCRIPT_SKIP_SYSTEM_DEPS:-0}" = "1" ]; then return 0; fi; "$@"; }
fi
