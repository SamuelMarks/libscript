#!/bin/sh

# shellcheck disable=SC2236
if [ ! -z "${SCRIPT_NAME+x}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ ! -z "${BASH_VERSION+x}" ]; then
  # shellcheck disable=SC3028 disable=SC3054
  this_file="${BASH_SOURCE[0]}"
  # shellcheck disable=SC3040
  set -o pipefail
elif [ ! -z "${ZSH_VERSION+x}" ]; then
  # shellcheck disable=SC2296
  this_file="${(%):-%x}"
  # shellcheck disable=SC3040
  set -o pipefail
else
  this_file="${0}"
fi
set -feu

STACK="${STACK:-:}"
case "${STACK}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    return ;;
  *)
    printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
STACK="${STACK}${this_file}"':'
export STACK

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
