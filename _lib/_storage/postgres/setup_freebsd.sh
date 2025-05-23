#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
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

for lib in '_lib/_common/pkg_mgr.sh' '_lib/_common/priv.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

# depends 'postgresql'"${POSTGRESQL_VERSION}"'-server' 'postgresql'"${POSTGRESQL_VERSION}"'-client'
for pkg in 'postgresql'"${POSTGRESQL_VERSION}"'-server' 'postgresql'"${POSTGRESQL_VERSION}"'-client'; do
  if ! pkg info -e "${pkg}"; then
    priv pkg install -y "${pkg}"
  fi
done

priv sysrc postgresql_enable='YES'
if [ ! -d '/var/db/postgres/data'"${POSTGRESQL_VERSION}" ]; then
  priv /usr/local/etc/rc.d/postgresql initdb
fi
priv service postgresql status | grep -Fq ' server is running' || priv service postgresql start

SCRIPT_NAME="${DIR}"'/user_db_setup.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
