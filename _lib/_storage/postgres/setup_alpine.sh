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

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)

SCRIPT_NAME="${DIR}"'/env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

apk add 'openrc' 'postgresql'"${POSTGRESQL_VERSION}" 'postgresql'"${POSTGRESQL_VERSION}"'-contrib' 'postgresql'"${POSTGRESQL_VERSION}"'-openrc'
existed=0
if [ -f /etc/init.d/postgresql ]; then
  existed=1
fi
if [ "${existed}" -ne 1 ]; then
  rc-update add 'postgresql'
fi

stdout="$(mktemp >/dev/null)"
stderr="$(mktemp >/dev/null)"
trap 'rm -f -- "${stdout}" "${stderr}"' EXIT HUP INT QUIT TERM

if ! rc-service postgresql start >"${stdout}" 2>"${stderr}"; then
  rc="${?}"
  if [ ! "${stderr}" = ' * WARNING: postgresql is already starting' ]; then
    >&2 printf '%s\n' "${stderr}"
    printf '%s\n' "${stdout}"
    exit "${rc}"
  fi
fi
