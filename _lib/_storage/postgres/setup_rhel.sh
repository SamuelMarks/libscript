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

REDHAT_SUPPORT_PRODUCT_VERSION="$(. /etc/os-release; printf '%s' "${REDHAT_SUPPORT_PRODUCT_VERSION}")"
export REDHAT_SUPPORT_PRODUCT_VERSION
VER="${REDHAT_SUPPORT_PRODUCT_VERSION%%.*}"
sudo dnf install -y \
  'https://download.postgresql.org/pub/repos/yum/reporpms/EL-'"${VER}"'-'"${ARCH}"'/pgdg-redhat-repo-latest.noarch.rpm'
sudo dnf -qy module disable 'postgresql'
sudo dnf install -y 'postgresql'"${POSTGRESQL_VERSION}"'-server'
sudo '/usr/pgsql-'"${POSTGRESQL_VERSION}"'/bin/postgresql-'"${POSTGRESQL_VERSION}"'-setup' initdb
sudo systemctl enable 'postgresql-'"${POSTGRESQL_VERSION}"
sudo systemctl start 'postgresql-'"${POSTGRESQL_VERSION}"

SCRIPT_NAME="${DIR}"'/user_db_setup.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
