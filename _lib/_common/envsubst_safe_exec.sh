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

# A safe version of `envsubst` using awk
# Supports basic variable substitutions: $VAR and ${VAR}
envsubst_safe() {
  awk '
  BEGIN {
    # Load all environment variables into an array
    for (key in ENVIRON) {
      env[key] = ENVIRON[key]
    }
  }
  {
    line = $0
    # Pattern to match variable references: $VAR or ${VAR}
    var_pattern = "\\$({[a-zA-Z_][a-zA-Z0-9_]*}|[a-zA-Z_][a-zA-Z0-9_]*)"
    while (match(line, var_pattern)) {
      var_ref = substr(line, RSTART, RLENGTH)
      if (substr(var_ref, 2, 1) == "{") {
        var_name = substr(var_ref, 3, length(var_ref) - 3)
      } else {
        var_name = substr(var_ref, 2)
      }
      # Replace if variable is set, else leave it as is
      if (var_name in env) {
        var_value = env[var_name]
        line = substr(line, 1, RSTART - 1) var_value substr(line, RSTART + RLENGTH)
      } else {
        # Variable not set; leave the variable reference unchanged
        line = substr(line, 1, RSTART - 1) var_ref substr(line, RSTART + RLENGTH)
      }
    }
    print line
  }
  ' "$@"
}

envsubst_safe "$@"
