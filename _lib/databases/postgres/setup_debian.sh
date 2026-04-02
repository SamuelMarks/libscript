#!/bin/sh
# shellcheck disable=SC3054,SC3040,SC2296,SC2128,SC2039,SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145



set -feu
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE}"

elif [ "${ZSH_VERSION-}" ]; then
  this_file="${0}"

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
# shellcheck disable=SC1090,SC1091,SC2034
  . "${SCRIPT_NAME}"
done

export DIR="${_DIR}"
SCRIPT_NAME="${DIR}"'/env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091,SC2034
. "${SCRIPT_NAME}"

_del='postgres://'"${POSTGRES_USER?}"':'"${POSTGRES_PASSWORD?}"'@'"${POSTGRES_HOST?}"'/'"${POSTGRES_DB?}"
pid=
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
    [ -d '/var/lib/postgresql/'"${POSTGRESQL_VERSION}" ] || mkdir -p -- '/var/lib/postgresql/'"${POSTGRESQL_VERSION}"
    [ -d '/var/log/postgresql' ] || mkdir -p -- '/var/log/postgresql'
    pg_conf="/etc/postgresql/${POSTGRESQL_VERSION}/main/postgresql.conf"
    if [ -f "${pg_conf}" ]; then
      if [ -n "${POSTGRES_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
        priv sed -i "s|^#*unix_socket_directories = .*|unix_socket_directories = '${POSTGRES_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}'|" "${pg_conf}"
      fi
      if [ -n "${POSTGRES_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ]; then
        priv sed -i "s|^#*listen_addresses = .*|listen_addresses = '${POSTGRES_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}'|" "${pg_conf}"
      fi
      if [ -n "${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
        priv sed -i "s|^#*port = .*|port = ${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}|" "${pg_conf}"
      fi
    fi
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
# shellcheck disable=SC1090,SC1091,SC2034
. "${SCRIPT_NAME}"

if [ -n "${pid}" ]; then
  priv kill "${pid}"
  priv rm -- '/var/run/postgresql/'"${POSTGRESQL_VERSION}"'-main.pid'
  priv mv -- '/usr/sbin/policy-rc.d.prev' '/usr/sbin/policy-rc.d'
  export RUNLEVEL="${PREVIOUS_RUNLEVEL}"
  export PREVIOUS_RUNLEVEL=
fi

if [ -n "${POSTGRES_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
  "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "unix:${POSTGRES_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 || true
elif [ -n "${POSTGRES_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${POSTGRES_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 || true
elif [ -n "${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 || true
fi
