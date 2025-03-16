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

_DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
export DIR="${_DIR}"

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"
export LIBSCRIPT_ROOT_DIR
LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"
export LIBSCRIPT_DATA_DIR

for lib in 'env.sh' '_lib/_common/settings_updater.sh'; do
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

# Defined here so ? throws errors early
conn='postgres://'"${POSTGRES_USER?}"':'"${POSTGRES_PASSWORD?}"'@'"${POSTGRES_HOST?}"'/'"${POSTGRES_DB?}"

if ! id "${POSTGRES_SERVICE_USER?}" >/dev/null 2>&1; then
  priv adduser --disabled-password --gecos "" "${POSTGRES_SERVICE_USER}"
  printf '%s:%s\n' "${POSTGRES_SERVICE_USER}" "${POSTGRES_SERVICE_USER_PASSWORD:-${POSTGRES_SERVICE_USER}}" | priv chpasswd
fi

if ! id "${POSTGRES_USER?}" >/dev/null 2>&1; then
  priv adduser --disabled-password --gecos "" "${POSTGRES_USER}"
  printf '%s:%s\n' "${POSTGRES_USER}" "${POSTGRES_PASSWORD:-${POSTGRES_USER}}" | priv chpasswd
fi

if [ "${POSTGRES_HOST}" = 'localhost' ]; then
  host_flag=''
else
  host_flag=' -h '"${POSTGRES_HOST}"' '
fi

if priv_as "${POSTGRES_SERVICE_USER}" psql"${host_flag}" -t -c '\du' | grep -Fq "${POSTGRES_USER?}"; then
  true
else
  priv_as "${POSTGRES_SERVICE_USER}" createuser"${host_flag}" "${POSTGRES_USER?}"
  if [ -n "${POSTGRES_PASSWORD?}" ]; then
    priv_as "${POSTGRES_SERVICE_USER}" psql"${host_flag}" -c 'ALTER USER '"${POSTGRES_USER?}"' PASSWORD '"'${POSTGRES_PASSWORD?}'"';';
  fi
fi

if priv_as "${POSTGRES_SERVICE_USER}" psql"${host_flag}" -lqt | cut -d \| -f 1 | grep -Fqw "${POSTGRES_DB?}"; then
  true
else
  priv_as "${POSTGRES_SERVICE_USER}" createdb"${host_flag}" "${POSTGRES_DB?}" --owner "${POSTGRES_USER?}"
fi

[ -d "${LIBSCRIPT_DATA_DIR}" ] || mkdir -p -- "${LIBSCRIPT_DATA_DIR}"
for key in 'POSTGRES_URL' 'DATABASE_URL'; do
  lang_export 'cmd' "${key}" "${conn}" >> "${LIBSCRIPT_DATA_DIR}"'/dyn_env.cmd'
  lang_export 'sh' "${key}" "${conn}" >> "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh'
  lang_export 'sqlite' "${key}" "${conn}"
done
