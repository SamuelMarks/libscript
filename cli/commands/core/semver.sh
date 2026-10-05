#!/bin/sh
# ## Overview
# Handles Semantic Versioning (SemVer) parsing and comparison operations.
# 
# ## Usage
# Execute this script to compare or validate version strings.


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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
if [ "${1:-}" = "semver" ]; then
  shift
fi
v1="${1:-}"
op="${2:-}"
v2="${3:-}"
if [ -z "$v1" ] || [ -z "$op" ] || [ -z "$v2" ]; then
  printf '%s\n' "Usage: $0 [semver] <v1> <operator> <v2>" >&2
  printf '%s\n' "Operators: = != > < >= <=" >&2
  exit 1
fi
  res=$(awk -v v1="$v1" -v v2="$v2" '
    BEGIN {
      la = split(v1, aa, /[^0-9]+/)
      lb = split(v2, bb, /[^0-9]+/)
      len = la > lb ? la : lb
      r = 0
      for (i = 1; i <= len; i++) {
        av = aa[i] + 0; bv = bb[i] + 0
        if (av < bv) { r = -1; break }
        if (av > bv) { r = 1; break }
      }
      print r
    }
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
