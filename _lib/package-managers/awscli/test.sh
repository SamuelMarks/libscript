#!/bin/sh

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
else
  THIS_FILE="${0}"
fi

export STACK="${STACK:-}${THIS_FILE}:"
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(cd "$(dirname "$THIS_FILE")" && cd ../../../ && pwd)}"
export LIBSCRIPT_ROOT_DIR

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/test_base.sh"
export SCRIPT_NAME
. "${SCRIPT_NAME}"

echo "Tests not implemented"
