#!/bin/sh
# ## Overview
# RHEL-specific setup script for PostgreSQL.
#
# ## Usage
# Installs PostgreSQL from the official PGDG repository and sets up systemd services.


set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
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

for LIB in '_lib/_common/pkg_mgr.sh' '_lib/_common/priv.sh'; do
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

if [ -n "${POSTGRES_VERSION:-}" ] && [ "${POSTGRES_VERSION}" != "latest" ]; then
  REDHAT_SUPPORT_PRODUCT_VERSION="$(. /etc/os-release; printf '%s' "${REDHAT_SUPPORT_PRODUCT_VERSION:-9}")"
  VER="${REDHAT_SUPPORT_PRODUCT_VERSION%%.*}"
  priv dnf install -y \
    'https://download.postgresql.org/pub/repos/yum/reporpms/EL-'"${VER}"'-'"${ARCH}"'/pgdg-redhat-repo-latest.noarch.rpm' 2>/dev/null || true
  priv dnf -qy module disable 'postgresql' 2>/dev/null || true
  if priv dnf install -y 'postgresql'"${POSTGRES_VERSION}"'-server' 2>/dev/null; then
    SERVICE_NAME="${LIBSCRIPT_SERVICE_NAME:-postgresql-${POSTGRES_VERSION}}"
    if [ -x '/usr/pgsql-'"${POSTGRES_VERSION}"'/bin/postgresql-'"${POSTGRES_VERSION}"'-setup' ]; then
      priv '/usr/pgsql-'"${POSTGRES_VERSION}"'/bin/postgresql-'"${POSTGRES_VERSION}"'-setup' initdb || true
    fi
  else
    priv dnf install -y postgresql-server postgresql-contrib
    SERVICE_NAME="${LIBSCRIPT_SERVICE_NAME:-postgresql}"
    priv /usr/bin/postgresql-setup --initdb 2>/dev/null || true
  fi
else
  priv dnf install -y postgresql-server postgresql-contrib
  SERVICE_NAME="${LIBSCRIPT_SERVICE_NAME:-postgresql}"
  priv /usr/bin/postgresql-setup --initdb 2>/dev/null || true
fi

priv systemctl enable "${SERVICE_NAME}" 2>/dev/null || true
priv systemctl start "${SERVICE_NAME}" 2>/dev/null || true

export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"

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
