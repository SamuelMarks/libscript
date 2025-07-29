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
export LIBSCRIPT_ROOT_DIR
LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"
export LIBSCRIPT_DATA_DIR

for lib in 'env.sh' '_lib/_common/settings_updater.sh' '_lib/_common/priv.sh' '_lib/_common/pkg_mgr.sh'; do
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

if ! id "${POSTGRES_USER?}" >/dev/null 2>&1; then
  if [ -f '/usr/sbin/pw' ]; then
    priv pw user add -n "${POSTGRES_USER?}"
    printf '%s\n' "${POSTGRES_PASSWORD:-${POSTGRES_USER}}" | priv pw usermod "${POSTGRES_USER?}" -h 0
  else
    if [ -s '/usr/sbin/adduser' ] || command -v -- 'add_user' >/dev/null 2>&1 ; then
      priv adduser "${POSTGRES_USER?}"
    elif [ -s '/usr/bin/dscl' ] || command -v -- 'dscl' >/dev/null 2>&1 ; then
      if ! dscl . -read /Users/postgres >/dev/null 2>&1; then
#        priv sysadminctl -addUser postgres \
#                         -fullName "PostgreSQL User ${POSTGRES_USER?}" \
#                         -UID 502 \
#                         -GID 20 \
#                         -shell /bin/bash \
#                         -password "${POSTGRES_PASSWORD:-${POSTGRES_USER}}" \
#                         -home /Users/postgres
        priv dscl . -create /Users/"${POSTGRES_SERVICE_USER}" IsHidden 1
        priv dscl . -create /Users/"${POSTGRES_SERVICE_USER}" UserShell /bin/bash
        priv dscl . -create /Users/"${POSTGRES_SERVICE_USER}" RealName "PostgreSQL User ${POSTGRES_USER?}"
        priv dscl . -create /Users/"${POSTGRES_SERVICE_USER}" UniqueID "505"
        priv dscl . -create /Users/"${POSTGRES_SERVICE_USER}" PrimaryGroupID "20" # 'staff' group
        priv dscl . -create /Users/"${POSTGRES_SERVICE_USER}" NFSHomeDirectory /Users/"${POSTGRES_SERVICE_USER}"
        priv dscl . -passwd /Users/"${POSTGRES_SERVICE_USER}" "${POSTGRES_SERVICE_PASSWORD:-${POSTGRES_PASSWORD:-${POSTGRES_USER}}}"
        priv createhomedir -u "${POSTGRES_SERVICE_USER}" -c
        if psql "${POSTGRES_SERVICE_USER}" -c 'CREATE ROLE tmp0 LOGIN SUPERUSER;'; then
          if psql "${POSTGRES_SERVICE_USER}" -U tmp0 -c 'ALTER USER '"$USER"' RENAME TO '"${POSTGRES_SERVICE_USER}"';'; then
            priv_as "${POSTGRES_SERVICE_USER}" psql "${POSTGRES_SERVICE_USER}" -c 'DROP ROLE tmp0;'
          fi
        fi
      fi
    else
      >&2 printf 'NotImplemented'
      exit 5
    fi
    if command -v -- 'chpasswd' >/dev/null 2>&1; then
      printf '%s:%s\n' "${POSTGRES_USER}" "${POSTGRES_PASSWORD:-${POSTGRES_USER}}" | priv chpasswd
    fi
  fi
fi

if [ "${POSTGRES_HOST}" = 'localhost' ]; then
  host_flag=''
else
  host_flag=' -h '"${POSTGRES_HOST}"' '
fi

user_present="$(priv_as "${POSTGRES_SERVICE_USER}" psql"${host_flag}" -tc "SELECT 1 FROM pg_roles WHERE rolname = '""${POSTGRES_USER?}""';")"
if [ "$user_present" -eq 1 ]; then
  true
else
  (
  set +f
  set -- '/var/log/postgresql/'"${POSTGRESQL_VERSION}"'-main.log'*
  if [ -f "${1}" ]; then
    cat -- "${@}"
  fi
  )
  priv_as "${POSTGRES_SERVICE_USER}" createuser"${host_flag}" "${POSTGRES_USER?}"
  if [ -n "${POSTGRES_PASSWORD?}" ]; then
    priv_as "${POSTGRES_SERVICE_USER}" psql"${host_flag}" -c 'ALTER USER '"${POSTGRES_USER?}"' PASSWORD '"'${POSTGRES_PASSWORD?}'"';';
  fi
fi

db_present="$(priv_as "${POSTGRES_SERVICE_USER}" psql"${host_flag}" -tc "SELECT 1 FROM pg_database WHERE datname = '""${POSTGRES_DB?}""';")"
if [ "$db_present" -eq 1 ]; then
  true
else
  priv_as "${POSTGRES_SERVICE_USER}" createdb"${host_flag}" "${POSTGRES_DB?}" --owner "${POSTGRES_USER?}"
fi

[ -d "${LIBSCRIPT_DATA_DIR?}" ] || mkdir -p -- "${LIBSCRIPT_DATA_DIR}"
for key in 'POSTGRES_URL' 'DATABASE_URL'; do
  lang_export 'cmd' "${key}" "${conn}" >> "${LIBSCRIPT_DATA_DIR}"'/dyn_env.cmd'
  lang_export 'sh' "${key}" "${conn}" >> "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh'
  lang_export 'sqlite' "${key}" "${conn}"
done
