#!/bin/sh
# ## Overview
# A safe, POSIX-compliant alternative to GNU `envsubst` powered by `awk`.
# Unlike standard `envsubst`, if an environment variable is not found,
# it safely leaves the original variable reference intact (e.g. `${VAR}`) 
# rather than replacing it with an empty string.
# 
# ## Usage
# Source this file and call `envsubst_safe` passing either a string, a file path,
# or piping content via stdin. It is recommended to use within a cleared environment
# (see `environ.sh`) to prevent accidental substitution of ambient variables.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
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
