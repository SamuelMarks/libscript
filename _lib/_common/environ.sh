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
    printf '[STOP]     processing "%s"\n' "${this_file}"
    return ;;
  *)
    printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
STACK="${STACK}${this_file}"':'
export STACK

save_environment() {
  env | while IFS='' read -r line || [ -n "${line}" ]; do
    case "${line}" in
      *=*)
        var_name="${line%%=*}"
        var_value="${line#*=}"
        # Validate variable name (POSIX compliant)
        if printf '%s\n' "${var_name}" | grep -Eq '^[A-Za-z_][A-Za-z0-9_]*$'; then
          var_value=$(printf '%s' "${var_value}" | sed "s/'/'\\\\''/g")
          printf 'export %s='"'"'%s'"'"'\n' "${var_name}" "${var_value}"
        fi
        ;;
    esac
  done
}

clear_environment() {
  PATH="${PATH}"':/usr/bin:/bin'
  export PATH
  for var_name in $( env | cut -d= -f1 ) ; do
    printf 'unsetting "%s"\n' "${var_name}"
    if printf '%s\n' "${var_name}" | grep -Eq '^[A-Za-z_][A-Za-z0-9_]*$'; then
      printf 'actually unset\n'
      unset -- "${var_name}" || true
    fi
  done
  PATH="${PATH}"':/usr/bin:/bin'
  export PATH
}

## Usage:

# ENV_SAVED_FILE="$(mktemp)"
# export ENV_SAVED_FILE
# save_environment >> "${ENV_SAVED_FILE}"

# clear_environment

## DO SOMETHING IN A `env -i` equivalent environment

## shellcheck disable=SC1090
# . "${ENV_SAVED_FILE}"

# rm -f "${ENV_SAVED_FILE}"
# unset ENV_SAVED_FILE

object2key_val() {
  obj="$1"
  prefix="${2:-}"
  sq="'"
  q="${3:-$sq}"
  s='='
  #s=''
  #if [ "${q}" = '"' ]; then s='=';  fi

  printf '%s' "$obj" | jq --arg q "${q}" --arg sq "${sq}" --arg dq '"' -r '
    def custom_format(value):
      if value == null then
        ""
      elif value | type == "number" then
        "\(value)"
      elif value | type == "string" then
        if value | any(.; test("^[0-9]+$", $sq, $dq)) then
          value
        else
          $q + value + $q
        end
      elif value | type == "array" then
        $q + (value | join(",")) + $q
      else
        "\(value)"
      end;
    to_entries[] | "'"${prefix}"'\(.key)'"${s}"'\(custom_format(.value))"
  '
}
