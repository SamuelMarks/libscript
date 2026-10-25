#!/bin/sh
# ## Overview
# Debian-specific setup script for PostgreSQL.
#
# ## Usage
# Installs PostgreSQL from the official `apt.postgresql.org` repository or reuses an active cluster.


set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
_DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
export DIR="${_DIR}"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

for LIB in "_lib/_common/log.sh" "_lib/_common/pkg_mgr.sh" "_lib/_common/priv.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

export DIR="${_DIR}"
SCRIPT_NAME="${DIR}"'/env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"

# ## _pg_debian_is_active
# Checks whether a PostgreSQL cluster is already installed and accepting connections on the target port or socket.
_pg_debian_is_active() {
  _pg_port="${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-5432}}"
  if command -v psql >/dev/null 2>&1; then
    if command -v pg_isready >/dev/null 2>&1 && pg_isready -h 127.0.0.1 -p "${_pg_port}" -q 2>/dev/null; then
      return 0
    fi
    if command -v pg_isready >/dev/null 2>&1 && pg_isready -q 2>/dev/null; then
      return 0
    fi
    if priv_as "${POSTGRES_SERVICE_USER:-postgres}" psql -tAc "SELECT 1" >/dev/null 2>&1; then
      return 0
    fi
  fi
  return 1
}

if [ "${FORCE_REINSTALL:-0}" != "1" ] && _pg_debian_is_active; then
  log_info "[REUSE] PostgreSQL cluster already active on port ${POSTGRES_LISTEN_PORT:-5432}."
  if [ "$(ps -q 1 -o comm= 2>/dev/null || true)" = 'systemd' ] && command -v systemctl >/dev/null 2>&1; then
    priv systemctl enable postgresql >/dev/null 2>&1 || true
    priv systemctl start postgresql >/dev/null 2>&1 || true
  fi
  exit 0
fi

_DEL='postgres://'"${POSTGRES_USER?}"':'"${POSTGRES_PASSWORD?}"'@'"${POSTGRES_HOST?}"'/'"${POSTGRES_DB?}"
PID=
# ## _pg_debian_cleanup
# Restores policy-rc.d and stops single-user postgres if interrupted.
_pg_debian_cleanup() {
  if [ -n "${PID:-}" ]; then
    priv kill "${PID}" 2>/dev/null || true
    priv rm -f -- '/var/run/postgresql/'"${POSTGRES_VERSION}"'-main.pid' 2>/dev/null || true
    PID=
  fi
  if [ -f '/usr/sbin/policy-rc.d.prev' ]; then
    priv mv -- '/usr/sbin/policy-rc.d.prev' '/usr/sbin/policy-rc.d' 2>/dev/null || true
  fi
}
trap '_pg_debian_cleanup' EXIT HUP INT QUIT TERM
if ! dpkg -s -- 'postgresql-'"${POSTGRES_VERSION}" >/dev/null 2>&1; then
  libscript_depends 'postgresql-common'
  if [ -x '/usr/share/postgresql-common/pgdg/apt.postgresql.org.sh' ]; then
    yes '' | priv '/usr/share/postgresql-common/pgdg/apt.postgresql.org.sh'
  else
    libscript_depends 'ca-certificates' 'gnupg'
    priv install -d '/usr/share/postgresql-common/pgdg'
    POSTGRES_KEY=$(mktemp)
    libscript_download 'https://www.postgresql.org/media/keys/ACCC4CF8.asc' "${POSTGRES_KEY}"
    priv cp "${POSTGRES_KEY}" '/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc'
    rm -f "${POSTGRES_KEY}"
    printf 'deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt %s-pgdg main\n' "$(. /etc/os-release && printf '%s' "${VERSION_CODENAME}")" | priv dd status='none' of='/etc/apt/sources.list.d/pgdg.list'
    pkg_mgr update
  fi
  libscript_depends 'postgresql-server-dev-'"${POSTGRES_VERSION}" 'postgresql-'"${POSTGRES_VERSION}"
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
    [ -d '/var/lib/postgresql/'"${POSTGRES_VERSION}" ] || mkdir -p -- '/var/lib/postgresql/'"${POSTGRES_VERSION}"
    [ -d '/var/log/postgresql' ] || mkdir -p -- '/var/log/postgresql'
    PG_CONF="/etc/postgresql/${POSTGRES_VERSION}/main/postgresql.conf"
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
      '/usr/lib/postgresql/'"${POSTGRES_VERSION}"'/bin/postgres' \
        --single "${POSTGRES_SERVICE_USER?}" \
        -D '/var/lib/postgresql/'"${POSTGRES_VERSION}"'/main' \
        -r '/var/log/postgresql/'"${POSTGRES_VERSION}"'-main.log' >'/var/log/postgresql/'"${POSTGRES_VERSION}"'-main.log0' 2>&1 &
    PID="$!"
    printf '%d' "${PID}" | priv dd status='none' of='/var/run/postgresql/'"${POSTGRES_VERSION}"'-main.pid'
  else
    priv systemctl enable --now postgresql >/dev/null 2>&1 || priv service postgresql start >/dev/null 2>&1 || true
  fi
fi

export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"

if [ -n "${PID}" ]; then
  priv kill "${PID}"
  priv rm -f -- '/var/run/postgresql/'"${POSTGRES_VERSION}"'-main.pid'
  priv mv -- '/usr/sbin/policy-rc.d.prev' '/usr/sbin/policy-rc.d'
  export RUNLEVEL="${PREVIOUS_RUNLEVEL}"
  export PREVIOUS_RUNLEVEL=
fi

if [ -n "${POSTGRES_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" --listen "unix:${POSTGRES_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${POSTGRES_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" --listen "${POSTGRES_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" --listen "${POSTGRES_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
fi
