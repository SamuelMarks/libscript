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
  printf '[STOP]   processing "%s"\n' "${this_file}"
  return ;;
  *)
  printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
STACK="${STACK}${this_file}"':'
export STACK

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

  awk_script='
  BEGIN {
    search = ARGV[1]
    replace = ARGV[2]

    delete ARGV[1]
    delete ARGV[2]
  }
  {
     file_content = file_content $0 "\n"
  }
  END {
    result = ""
    pos = 1
    search_len = length(search)
    content_len = length(file_content)

    while (pos <= content_len) {
      idx = index(substr(file_content, pos), search)
      if (idx == 0) {
        result = result substr(file_content, pos)
        break
      } else {
        idx = idx + pos - 1
        result = result substr(file_content, pos, idx - pos) replace
        pos = idx + search_len
      }
    }

    printf "%s", result
  }
  '

  new_content="$(mktemp)"
  trap 'rm -f -- "${new_content}"' EXIT HUP INT QUIT TERM
  if awk -- "${awk_script}" "${search_string}" "${replacement_string}" "${filename}" > "${new_content}"; then
    cat -- "${new_content}"
  else
    >&2 printf 'Error: Failed to process "%s"\n' "${filename}"
    exit 1
  fi
}
