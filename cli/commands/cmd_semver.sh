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
if [ "$cmd" = "semver" ]; then
  v1="$1"
  op="$2"
  v2="$3"
  if [ -z "$v1" ] || [ -z "$op" ] || [ -z "$v2" ]; then
    echo "Usage: $0 semver <v1> <operator> <v2>" >&2
    echo "Operators: = != > < >= <=" >&2
    exit 1
  fi
  res=$(awk -v v1="$v1" -v v2="$v2" '
    function cmp(a, b) {
      la=split(a, aa, /[^0-9]+/)
      lb=split(b, bb, /[^0-9]+/)
      len = la > lb ? la : lb
      for (i=1; i<=len; i++) {
        av = aa[i] + 0; bv = bb[i] + 0
        if (av < bv) return -1
        if (av > bv) return 1
      }
      return 0
    }
    BEGIN { print cmp(v1, v2) }
  ')
  case "$op" in
    "=")  [ "$res" -eq 0 ] && exit 0 || exit 1 ;;
    "!=") [ "$res" -ne 0 ] && exit 0 || exit 1 ;;
    ">")  [ "$res" -eq 1 ] && exit 0 || exit 1 ;;
    "<")  [ "$res" -eq -1 ] && exit 0 || exit 1 ;;
    ">=") [ "$res" -ge 0 ] && exit 0 || exit 1 ;;
    "<=") [ "$res" -le 0 ] && exit 0 || exit 1 ;;
    *) echo "Unknown operator: $op" >&2; exit 1 ;;
  esac
fi
