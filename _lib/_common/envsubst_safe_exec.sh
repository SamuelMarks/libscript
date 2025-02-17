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

envsubst_safe() {
  if [ "${#}" -gt 0 ] && [ -n "${1}" ]; then
    if [ -f "${1}" ]; then
      input_file="${1}"
    else
      input="${1}"
    fi
  else
    if [ -t 0 ]; then
      >&2 printf 'No input provided.\n'
      exit 2
    else
      input="$(cat)"
    fi
  fi

  temp_sed_cmds="$(mktemp)"
  trap 'rm -f "${temp_sed_cmds}"' EXIT HUP INT QUIT TERM

  env | while IFS='=' read -r var val; do
    case "${var}" in
      [[:alpha:]_]*)
          escaped_val=$(printf '%s' "${val}" | \
            sed -e 's/[\\&]/\\&/g')

          escaped_val=$(printf '%s' "${escaped_val}" | awk '{ gsub(/\n/, "\\\\n") }; 1')

          # shellcheck disable=SC2016
          printf 's|\\${%s}|%s|g\n' "${var}" "${escaped_val}" >> "${temp_sed_cmds}"
          printf 's|\\$%s\\([^a-zA-Z0-9_]\)|%s\\1|g\n' "${var}" "${escaped_val}" >> "${temp_sed_cmds}"
          printf 's|\\$%s$|%s|g\n' "${var}" "${escaped_val}" >> "${temp_sed_cmds}"
          ;;
      *)
        ;;
    esac
  done

  if [ -n "${input_file:-}" ]; then
    sed -f "${temp_sed_cmds}" "${input_file}"
  else
    printf '%s\n' "${input}" | sed -f "${temp_sed_cmds}"
  fi | awk '{ gsub(/\\n/, "\n") }; 1'
}

envsubst_safe "$@"
