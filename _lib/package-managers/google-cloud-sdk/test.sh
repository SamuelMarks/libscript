#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
else
  THIS_FILE="${0}"
fi

export STACK="${STACK:-}${THIS_FILE}:"
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(cd "$(dirname "$THIS_FILE")" && cd ../../../ && pwd)}"
export LIBSCRIPT_ROOT_DIR
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/test_base.sh"
export SCRIPT_NAME
. "${SCRIPT_NAME}"

log_info "Tests not implemented"
