#!/bin/sh

# shellcheck disable=SC2236
if [ ! -z "${BASH_VERSION+x}" ]; then
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

guard='H_'"$(printf '%s' "${this_file}" | sed 's/[^a-zA-Z0-9_]/_/g')"
if test "${guard}" ; then
  echo '[STOP]     processing '"${this_file}"
  return
else
  echo '[CONTINUE] processing '"${this_file}"
fi
export "${guard}"=1
curl -LsSf https://astral.sh/uv/install.sh | sh

uv python install "${PYTHON_VERSION}"
