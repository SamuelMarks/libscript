#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE+x}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION+x}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

# Usage: ./find_replace_exec.sh "search_string" "replacement_string" filename

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)

SCRIPT_NAME="${DIR}"'/find_replace.sh'
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

find_replace "$@"
