#!/bin/sh
# ## Overview
# Network control library module for iis.
#
# ## Usage
# This script provides internal functions and should not be executed directly.

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
else
  export THIS_FILE="${0}"
fi

printf 'IIS is a Windows-only feature.\n' >&2
exit 1
