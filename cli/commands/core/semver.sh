#!/bin/sh
# ## Overview
# Handles Semantic Versioning (SemVer) parsing and comparison operations.
# 
# ## Usage
# Execute this script to compare or validate version strings.


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
if [ "$CMD" = "semver" ]; then
  v1="$1"
  op="$2"
  v2="$3"
  if [ -z "$v1" ] || [ -z "$op" ] || [ -z "$v2" ]; then
    printf '%s\n' "Usage: $0 semver <v1> <operator> <v2>" >&2
    printf '%s\n' "Operators: = != > < >= <=" >&2
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
    *) printf '%s\n' "Unknown operator: $op" >&2; exit 1 ;;
  esac
fi
