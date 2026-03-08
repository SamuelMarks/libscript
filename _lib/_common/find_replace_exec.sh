#!/bin/sh
# shellcheck disable=SC3054,SC3040,SC2296,SC2128,SC2039,SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145



set -feu
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE}"

elif [ "${ZSH_VERSION-}" ]; then
  this_file="${0}"

else
  this_file="${0}"
fi

# Usage: ./find_replace_exec.sh "search_string" "replacement_string" filename

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)

SCRIPT_NAME="${DIR}"'/find_replace.sh'
# shellcheck disable=SC1090,SC1091,SC2034
. "${SCRIPT_NAME}"

find_replace "$@"
