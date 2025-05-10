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

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'

export POSTGRES_URL="${POSTGRES_URL:-1}"
export POSTGRES_VERSION="${POSTGRES_URL_VERSION:-${POSTGRES_VERSION:-${POSTGRESQL_VERSION:-16}}}"
export POSTGRESQL_VERSION="${POSTGRES_VERSION}"
if [ ! -z "${POSTGRES_PASSWORD_FILE+x}" ] && [ -n "${POSTGRES_PASSWORD_FILE}" ] && [ -f "${POSTGRES_PASSWORD_FILE}" ]; then
  pass_contents="$(cat -- "${POSTGRES_PASSWORD_FILE}"; printf 'a')"
  pass_contents="${pass_contents%a}"
  # TODO(security): Audit
  export POSTGRES_PASSWORD="${pass_contents}"
fi
export POSTGRES_SERVICE_USER="${POSTGRES_SERVICE_USER:-postgres}"
export POSTGRES_SERVICE_GROUP="${POSTGRES_SERVICE_GROUP:-${POSTGRES_SERVICE_USER}}"
