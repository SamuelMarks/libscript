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

if [ "${PRIV+x}" = 'x' ]; then
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
