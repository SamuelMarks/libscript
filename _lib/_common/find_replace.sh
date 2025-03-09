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

convert_newlines() {
    printf '%s' "$1" | awk '{
        gsub(/\\n/, "\n")
        printf "%s", $0
    }'
}

choose_delim() {
    for delim in @ % + - _ = : / \| \# \\; do
        case "$1$2" in
            *"$delim"*)
                continue
                ;;
            *)
                printf '%s' "$delim"
                return 0
                ;;
        esac
    done
    >&2 printf 'Error: Unable to find suitable delimiter.\n'
    exit 1
}

escape_search() {
    printf '%s' "$1" | sed -e 's/[.\[\*^$]/\\&/g' -e "s/[$delim\\\\]/\\\\&/g"
}

escape_replace() {
    printf '%s' "$1" | sed -e 's/[&]/\\&/g' -e "s/[$delim\\\\]/\\\\&/g" -e 's/$/\\n/g' -e 's/\\\\n$//'
}

find_replace() {
  if [ "$#" -ne 3 ]; then
      >&2 printf "Usage: find_replace 'search_string' 'replacement_string' filename"
      exit 1
  fi

  search_string="$1"
  replacement_string="$2"
  filename="$3"

  if [ ! -w "$filename" ]; then
      >&2 printf 'Error: Cannot write to file "%s".\n' "${filename}"
      exit 1
  fi

  search_plain="$(convert_newlines "$search_string")"
  replace_plain="$(convert_newlines "$replacement_string")"

  delim="$(choose_delim "$search_plain" "$replace_plain")"

  search_escaped="$(escape_search "$search_plain")"
  replace_escaped="$(escape_replace "$replace_plain")"

  ed_script=$(printf '1,$s%s%s%s%s%sg\nw\n' "$delim" "$search_escaped" "$delim" "$replace_escaped" "$delim")

  if printf '%s' "$ed_script" | ed -s "$filename"; then
      >&2 printf 'Error: Failed to process file.\n'
      exit 1
  fi
}
