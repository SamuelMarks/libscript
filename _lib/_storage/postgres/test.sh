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

_DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
export DIR="${_DIR}"
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_toolchain/wait4x/setup.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

export DIR="${_DIR}"
SCRIPT_NAME="${DIR}"'/env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

case "${POSTGRES_URL:-0}" in
    [[:digit:]])
      POSTGRES_URL='postgres://'"${POSTGRES_USER?}"':'"${POSTGRES_PASSWORD?}"'@'"${POSTGRES_HOST?}"'/'"${POSTGRES_DB?}" ;;
    *) ;;
esac
wait4x postgresql "${POSTGRES_URL}"'?sslmode=disable'
