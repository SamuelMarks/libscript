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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR:-$(dirname "$this_file")/..}/_lib/_common/os_info.sh"
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
  priv() { "${PRIV}" "$@"; }
elif command -v su >/dev/null 2>&1; then
  priv() { priv_as root "$@"; }
else
  priv() { "$@"; }
fi
