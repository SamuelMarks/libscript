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

  # shellcheck disable=SC2016
  awk_script='{ rec = rec $0 RS }
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
   '

  new_content="$(mktemp)"
  trap 'rm -f -- "${new_content}"' EXIT HUP INT QUIT TERM

  if old="$search_string" new="$replacement_string" awk -v ORS= -- "${awk_script}" "${filename}" > "${new_content}"; then
    cat -- "${new_content}"
  else
    >&2 printf 'Error: Failed to process "%s"\n' "${filename}"
    exit 1
  fi
}
