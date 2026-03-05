#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145


set -eu
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
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) ;;
esac
export STACK="${STACK:-}${this_file}"':'

STACK="${STACK:-:}${this_file}"':'
export STACK

_raw_dir="$( CDPATH='' cd -- "$( dirname -- "$( readlink -nf -- "${this_file}" )" )" && pwd)"

# If this_file resolves to netctl.sh, its dirname is the root. If it resolves to lib/prelude.sh, its dirname is lib.
case "$_raw_dir" in
  */lib) NETCTL_DIR="${NETCTL_DIR:-${_raw_dir%/*}}" ;;
  *) NETCTL_DIR="${NETCTL_DIR:-$_raw_dir}" ;;
esac

export NETCTL_DIR
