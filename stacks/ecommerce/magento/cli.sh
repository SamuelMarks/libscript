#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  # running as a sourced script
  :
else
  echo "$0: This script is not meant to be executed directly." >&2
  exit 1
fi
