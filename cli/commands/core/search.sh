#!/bin/sh
# ## Overview
# Provides search functionality to query available packages or configurations.
# 
# ## Usage
# Execute this script with search terms to find relevant resources.


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
if [ "$CMD" = "search" ]; then
  query="$1"
  if [ -z "$query" ]; then
    printf '%s\n' "Error: please provide a search query."
    exit 1
  fi
  printf '%s\n' "Searching for '$query'..."
  find_components | sort | while read -r comp; do
    desc=$(get_desc "$comp")
    if printf '%s\n' "$comp $desc" | grep -i "$query" >/dev/null 2>&1; then
      if [ -n "$desc" ]; then
        printf "  %-40s - %s\n" "$comp" "$desc"
      else
        printf "  %s\n" "$comp"
      fi
    fi
  done
  exit 0
fi
