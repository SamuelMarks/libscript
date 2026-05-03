#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
_DIR=$(CDPATH='' cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
export DIR="${_DIR}"
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(D="${DIR}"; while [ ! -f "${D}"'/ROOT' ]; do D="$(dirname -- "${D}")"; done; printf '%s' "${D}")}"

for LIB in '_lib/_common/pkg_mgr.sh' '_lib/_common/priv.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
# shellcheck disable=SC1090,SC1091,SC2034
  . "${SCRIPT_NAME}"
done

export DIR="${_DIR}"
SCRIPT_NAME="${DIR}"'/env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091,SC2034
. "${SCRIPT_NAME}"

_DEL='postgres://'"${POSTGRES_USER?}"':'"${POSTGRES_PASSWORD?}"'@'"${POSTGRES_HOST?}"'/'"${POSTGRES_DB?}"
PID=
if ! dpkg -s -- 'postgresql-server-dev-'"${POSTGRESQL_VERSION}" >/dev/null 2>&1; then
  depends 'postgresql-common'
  if [ -x '/usr/share/postgresql-common/pgdg/apt.postgresql.org.sh' ]; then
    yes '' | priv '/usr/share/postgresql-common/pgdg/apt.postgresql.org.sh'
  else
    depends 'ca-certificates' 'gnupg'
    priv install -d '/usr/share/postgresql-common/pgdg'
    POSTGRES_KEY=$(mktemp)
    libscript_download 'https://www.postgresql.org/media/keys/ACCC4CF8.asc' "${POSTGRES_KEY}"
    priv cp "${POSTGRES_KEY}" '/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc'
    rm -f "${POSTGRES_KEY}"
    printf 'deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt %s-pgdg main\n' "$(. /etc/os-release && printf '%s' "${VERSION_CODENAME}")" | priv dd status='none' of='/etc/apt/sources.list.d/pgdg.list'
    priv apt-get update
  fi
  depends 'postgresql-server-dev-'"${POSTGRESQL_VERSION}" 'postgresql-'"${POSTGRESQL_VERSION}"
  # non systemd for environments like docker
  if [ ! "$(ps -q 1 -o comm=)" = 'systemd' ]; then
    if [ "${RUNLEVEL-}" ]; then
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
    [ -d '/var/LIB/postgresql/'"${POSTGRESQL_VERSION}" ] || mkdir -p -- '/var/LIB/postgresql/'"${POSTGRESQL_VERSION}"
    [ -d '/var/log/postgresql' ] || mkdir -p -- '/var/log/postgresql'
    PG_CONF="/etc/postgresql/${POSTGRESQL_VERSION}/main/postgresql.conf"
    if [ -f "${PG_CONF}" ]; then
      if [ -n "${POSTGRES_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
        priv sed -i "s|^#*unix_socket_directories = .*|unix_socket_directories = '${POSTGRES_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}'|" "${PG_CONF}"
      fi
      if [ -n "${POSTGRES_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ]; then
        priv sed -i "s|^#*listen_addresses = .*|listen_addresses = '${POSTGRES_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}'|" "${PG_CONF}"
      fi
      if [ -n "${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
        priv sed -i "s|^#*port = .*|port = ${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}|" "${PG_CONF}"
      fi
    fi
    priv_as "${POSTGRES_SERVICE_USER?}" \
      '/usr/LIB/postgresql/'"${POSTGRESQL_VERSION}"'/bin/postgres' \
        --single "${POSTGRES_SERVICE_USER?}" \
        -D '/var/LIB/postgresql/'"${POSTGRESQL_VERSION}"'/main' \
        -r '/var/log/postgresql/'"${POSTGRESQL_VERSION}"'-main.log' >'/var/log/postgresql/'"${POSTGRESQL_VERSION}"'-main.log0' 2>&1 &
    PID="$!"
    printf '%d' "${PID}" | priv dd status='none' of='/var/run/postgresql/'"${POSTGRESQL_VERSION}"'-main.pid'
  fi
fi

export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091,SC2034
. "${SCRIPT_NAME}"

if [ -n "${PID}" ]; then
  priv kill "${PID}"
  priv rm -- '/var/run/postgresql/'"${POSTGRESQL_VERSION}"'-main.pid'
  priv mv -- '/usr/sbin/policy-rc.d.prev' '/usr/sbin/policy-rc.d'
  export RUNLEVEL="${PREVIOUS_RUNLEVEL}"
  export PREVIOUS_RUNLEVEL=
fi

if [ -n "${POSTGRES_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "unix:${POSTGRES_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${POSTGRES_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${POSTGRES_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
fi
