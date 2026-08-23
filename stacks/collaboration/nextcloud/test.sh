#!/bin/sh
# ## Overview
# Implements automated tests to verify the correctness of the Nextcloud collaboration platform stack.
# 
# ## Usage
# Execute this script to run the test suite for nextcloud.


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
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

export LIBSCRIPT_ROOT_DIR
for LIB in "_lib/_common/test_base.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done


set -feu
printf '%s\n' "Validating Nextcloud installation..."
NEXTCLOUD_WWWROOT="${NEXTCLOUD_WWWROOT:-/var/www/nextcloud}"
if [ -d "${NEXTCLOUD_WWWROOT}/core" ]; then
    printf '%s\n' "Nextcloud directory found at ${NEXTCLOUD_WWWROOT}"
    exit 0
else
    printf '%s\n' "Nextcloud directory not found at ${NEXTCLOUD_WWWROOT}"
    exit 1
fi
