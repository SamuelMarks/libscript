#!/bin/sh
# ## Overview
# A robust, cross-platform string replacement utility powered by `awk`.
# Unlike `sed`, this function performs literal string replacements (including multi-line)
# without requiring regular expressions or complex escaping of special characters.
# 
# ## Usage
# Source this file and call `find_replace "search_string" "replacement_string" "filename"`.
# It outputs the modified content to stdout without altering the original file in place.


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
# ## find_replace
# Executes find_replace functionality.
find_replace() {
  if [ "$#" -ne 3 ]; then
    >&2 printf 'Usage: find_replace '"'"'find'"'"' '"'"'replace'"'"' filename'
    exit 1
  fi

  search_string="${1}"
  replacement_string="${2}"
  filename="${3}"

  if [ ! -r "${filename}" ]; then
    >&2 printf 'Error: Cannot read file "%s"\n' "${filename}"
    exit 1
  fi

  awk_script=$(cat << 'EOF_AWK'
      { rec = rec $0 RS }
      END {
          old = ENVIRON["old"]
          new = ENVIRON["new"]
          lgth = length(old)

          while ( beg = index(rec, old) ) {
              print substr(rec, 1, beg-1) new
              rec = substr(rec, beg+lgth)
          }

          print rec
      }
EOF_AWK
  )

  new_content="$(mktemp)"
  trap 'rm -f -- "${new_content}"' EXIT HUP INT QUIT TERM

  if old="$search_string" new="$replacement_string" awk -v ORS= -- "${awk_script}" "${filename}" > "${new_content}"; then
    cat -- "${new_content}"
  else
    >&2 printf 'Error: Failed to process "%s"\n' "${filename}"
    exit 1
  fi
}
