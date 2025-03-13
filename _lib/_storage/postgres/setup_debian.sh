#!/bin/sh

# shellcheck disable=SC2236
if [ ! -z "${SCRIPT_NAME+x}" ]; then
  printf 'SCRIPT_NAME was set to %s\n' "${SCRIPT_NAME}"
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

_DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
export DIR="${_DIR}"
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

for lib in '_lib/_common/pkg_mgr.sh' '_lib/_common/priv.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

export DIR="${_DIR}"
SCRIPT_NAME="${DIR}"'/env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
printf 'ghtis far\n'

if ! dpkg -s -- 'postgresql-server-dev-'"${POSTGRESQL_VERSION}" >/dev/null 2>&1; then
  printf 'depends\n'
  depends 'postgresql-common'
  echo 'executing'priv ' ''/usr/share/postgresql-common/pgdg/apt.postgresql.org.sh'
  yes '' | priv  '/usr/share/postgresql-common/pgdg/apt.postgresql.org.sh'
  depends 'postgresql-server-dev-'"${POSTGRESQL_VERSION}" 'postgresql-'"${POSTGRESQL_VERSION}"
fi

printf 'further\n'
SCRIPT_NAME="${DIR}"'/user_db_setup.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
