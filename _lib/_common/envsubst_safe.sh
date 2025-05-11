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

STACK="${STACK:-:}"
case "${STACK}" in
  *':'"${this_file}"':'*)
    #printf '[STOP]     processing "%s"\n' "${this_file}"
    return ;;
  *)
    #printf '[CONTINUE] processing "%s"\n' "${this_file}"
    ;;
esac
export STACK="${STACK:-}${this_file}"':'

# A safe version of `envsubst`
# If a var is not found it leaves it
# env -i BAR='haz'   "FOO ${BAR} CAN" -> "FOO haz CAN"
# env -i             "FOO ${BAR} CAN" -> "FOO ${BAR} CAN"
# recommend using within a `clear_environment` (`env -i`); see my `environ.sh`
envsubst_safe() {
  # Read input from file, argument, or stdin
  if [ "$#" -gt 0 ] && [ -n "${1}" ]; then
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

  # shellcheck disable=SC2016
  awk_script='
  BEGIN {
     for (name in ENVIRON) {
         env[name] = ENVIRON[name]
     }
  }

  {
     line = $0

     pos = 1

     while (pos <= length(line)) {
         if (substr(line, pos, 2) == "${") {
             match_var = match(substr(line, pos), /^\$\{[a-zA-Z_][a-zA-Z0-9_]*\}/)
             if (match_var) {
                 var = substr(line, pos, RLENGTH)
                 var_name = substr(var, 3, length(var) - 3)
                 if (var_name in env) {
                     replacement = env[var_name]
                 } else {
                     replacement = var
                 }
                 line = substr(line, 1, pos - 1) replacement substr(line, pos + RLENGTH)
                 pos += length(replacement)
                 continue
             }
         } else if (substr(line, pos, 1) == "$") {
             match_var = match(substr(line, pos), /^\$[a-zA-Z_][a-zA-Z0-9_]*/)
             if (match_var) {
                 var = substr(line, pos, RLENGTH)
                 var_name = substr(var, 2)
                 if (var_name in env) {
                     replacement = env[var_name]
                 } else {
                     replacement = var
                 }
                 line = substr(line, 1, pos - 1) replacement substr(line, pos + RLENGTH)
                 pos += length(replacement)
                 continue
             }
         }
         pos++
     }
     print line
  }
  ';
  if [ -n "${input_file:-}" ]; then
    awk -- "${awk_script}" "${input_file}"
  else
    printf '%s\n' "${input}" | awk -- "${awk_script}"
  fi
}
