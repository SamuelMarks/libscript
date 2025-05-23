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

export NL='
'

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

# rm -f -- "${ENV_SAVED_FILE}"
# unset ENV_SAVED_FILE

object2key_val() {
  obj="$1"
  prefix="${2:-}"
  sq="'"
  q="${3:-$sq}"
  null_setter=''
  join_arr_on="${NL}"
  eq='='
  case "${prefix}" in
    'SET ')
      null_setter='=';
      join_arr_on=' ' ;;
    'setenv ') eq='' ;;
  esac

  printf '%s' "$obj" | jq --arg null_setter "${null_setter}" \
                          --arg join_arr_on "${join_arr_on}" \
                          --arg eq "${eq}" \
                          --arg lbrace '{' \
                          --arg prefix "${prefix}" \
                          --arg q "${q}" \
                          --arg sq "${sq}" \
                          --arg dq '"' \
                          -r '
    # Build the pattern dynamically using $sq and $dq
    ("^(" + "\\\\{" + "|" + $dq + "\\\\{" + "|" + $sq + "\\\\{" + ")") as $pattern_start |
    ("(" + "\\\\}" + "|" + "\\\\}" + $dq + "|" + "\\\\}" + $sq + ")$") as $pattern_end |
    ($pattern_start + ".*" + $pattern_end) as $full_pattern |

    def custom_format(value):
      if value == null then
        $null_setter+""
      elif value | type == "number" then
        "=\(value)"
      elif value | type == "string" then
        if value | any(.; test($full_pattern)) then
          $eq + $q + value + $q
        elif value | any(.; test("^[0-9]+$", $sq, $dq)) then
          $eq + value
        else
          $eq + $q + value + $q
        end
      elif value | type == "array" then
        $eq + $q + (value | join($join_arr_on)) + $q
      elif value | type == "object" then
        $eq + $q + "\(value)" + $q
      else
        $eq + "\(value)"
      end;
    to_entries[] | $prefix+"\(.key)\(custom_format(.value))"
  '
}
