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
set -feux

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

_del='postgres://'"${POSTGRES_USER?}"':'"${POSTGRES_PASSWORD?}"'@'"${POSTGRES_HOST?}"'/'"${POSTGRES_DB?}"
pid=
if ! dpkg -s -- 'postgresql-server-dev-'"${POSTGRESQL_VERSION}" >/dev/null 2>&1; then
  depends 'postgresql-common'
  yes '' | priv '/usr/share/postgresql-common/pgdg/apt.postgresql.org.sh'
  depends 'postgresql-server-dev-'"${POSTGRESQL_VERSION}" 'postgresql-'"${POSTGRESQL_VERSION}"
  # non systemd for environments like docker
  if [ ! "$(ps -q 1 -o comm=)" = 'systemd' ]; then
    if [ ! -z "${RUNLEVEL+x}" ]; then
      export PREVIOUS_RUNLEVEL="${RUNLEVEL}"
    else
      export PREVIOUS_RUNLEVEL=
    fi
    export RUNLEVEL=1
    if [ -f '/usr/sbin/policy-rc.d' ]; then
      priv mv -- '/usr/sbin/policy-rc.d' '/usr/sbin/policy-rc.d.prev'
    else
      priv touch -- '/usr/sbin/policy-rc.d.prev'
    fi
    printf '#!/bin/sh\nexit 0' | priv dd status='none' of='/usr/sbin/policy-rc.d'
    priv chmod 755 '/usr/sbin/policy-rc.d'
    [ -d '/var/lib/postgresql/'"${POSTGRESQL_VERSION}" ] || mkdir -p -- '/var/lib/postgresql/'"${POSTGRESQL_VERSION}"
    [ -d '/var/log/postgresql' ] || mkdir -p -- '/var/log/postgresql'
    priv_as "${POSTGRES_SERVICE_USER?}" \
      '/usr/lib/postgresql/'"${POSTGRESQL_VERSION}"'/bin/postgres' \
        --single "${POSTGRES_SERVICE_USER?}" \
        -D '/var/lib/postgresql/'"${POSTGRESQL_VERSION}"'/main' \
        -r '/var/log/postgresql/'"${POSTGRESQL_VERSION}"'-main.log' >'/var/log/postgresql/'"${POSTGRESQL_VERSION}"'-main.log0' 2>&1 &
    pid="$!"
    printf '%d' "${pid}" | priv dd status='none' of='/var/run/postgresql/'"${POSTGRESQL_VERSION}"'-main.pid'
  fi
fi

SCRIPT_NAME="${DIR}"'/user_db_setup.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

if [ -n "${pid}" ]; then
  priv kill "${pid}"
  priv rm -- '/var/run/postgresql/'"${POSTGRESQL_VERSION}"'-main.pid'
  priv mv -- '/usr/sbin/policy-rc.d.prev' '/usr/sbin/policy-rc.d'
  export RUNLEVEL="${PREVIOUS_RUNLEVEL}"
  export PREVIOUS_RUNLEVEL=
fi
