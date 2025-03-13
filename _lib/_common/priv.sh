#!/bin/sh

# shellcheck disable=SC2236
if [ ! -z "${SCRIPT_NAME+x}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ ! -z "${BASH_VERSION+x}" ]; then
  # shellcheck disable=SC3028 disable=SC3054
  this_file="${BASH_SOURCE[0]}"
  # shellcheck disable=SC3040
  set -o pipefail
elif [ ! -z "${ZSH_VERSION+x}" ]; then
  # shellcheck disable=SC2296
  this_file="${(%):-%x}"
  # shellcheck disable=SC3040
  set -o pipefail
else
  this_file="${0}"
fi
set -feu

STACK="${STACK:-:}"
case "${STACK}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    return ;;
  *)
    printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
STACK="${STACK}${this_file}"':'
export STACK

if [ ! -z "${PRIV+x}" ]; then
  true;
  printf '[priv.sh] 34\n'
elif [ "$(id -u)" = "0" ]; then
  PRIV='';
  printf '[priv.sh] 37\n'
elif command -v sudo >/dev/null 2>&1 ; then
  PRIV='sudo';
  printf '[priv.sh] 40\n'
else
  >&2 printf "Error: This script must be run as root or with sudo privileges.\n"
  exit 1
fi
export PRIV;

if [ -n "${PRIV}" ]; then
  priv() { "${PRIV}" "$@"; }
else
  priv() { "$@"; }
fi


if command -v sudo >/dev/null 2>&1; then
  priv_as() {
    user="${1}"
    shift
    sudo -u "${user}" "$@"
  }
else
  priv_as() {
    user="${1}"
    shift
    su "${user}" -- -x -c "$*"
  }
fi
