#!/bin/sh
# ## Overview
# Generic setup module for MySQL.
# 
# ## Usage
# Execute this script to perform cross-platform installation and configuration for MySQL.

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
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
export DIR="${SCRIPT_DIR}"

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/env.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

MYSQL_INSTALL_METHOD="$(libscript_resolve_install_method "MYSQL")"
ACTION="${ACTION:-install}"
VERSION="${MYSQL_VERSION:-8.4.11}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ]; then
    EXACT_VERSION="8.4.11"
  else
    EXACT_VERSION="${VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if command -v mysql >/dev/null 2>&1; then
      mysql --version
    else
      printf 'mysql not installed
'
    fi
    exit 0
    ;;
  ls-remote)
    printf '8.0.36
8.4.0
8.4.11
'
    exit 0
    ;;
  install)
    resolve_exact_version
    log_info "Installing MySQL (${VERSION}) via ${MYSQL_INSTALL_METHOD}..."
    if [ "$MYSQL_INSTALL_METHOD" = "system" ]; then
      if [ "${UNAME_LOWER}" = "freebsd" ]; then
        log_info "Installing MySQL on FreeBSD via pkg..."
        libscript_depends "databases/mysql84-server" || libscript_depends "mysql-server"
        if command -v sysrc >/dev/null 2>&1; then
          sysrc mysql_enable="YES" || true
        fi
      elif [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
        log_info "Installing MySQL on SunOS / OmniOS..."
        libscript_depends "database/mysql-80" || libscript_depends "mysql"
        if command -v svcadm >/dev/null 2>&1; then
          svcadm enable svc:/database/mysql:default 2>/dev/null || true
        fi
      else
        libscript_depends "mysql"
      fi
    else
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/mysql/${EXACT_VERSION}"
      mkdir -p "${TARGET_DIR}/bin"
      libscript_depends "mysql"
      if command -v mysqld >/dev/null 2>&1; then
        ln -sf "$(command -v mysqld)" "${TARGET_DIR}/bin/mysqld" 2>/dev/null || true
      fi
      if command -v mysql >/dev/null 2>&1; then
        ln -sf "$(command -v mysql)" "${TARGET_DIR}/bin/mysql" 2>/dev/null || true
      fi
      libscript_symlink_alias "mysql" "$VERSION" "${EXACT_VERSION}"
    fi

    # Initialize database if mysqld is available and data dir is specified/empty
    DATA_DIR="${MYSQL_DATA_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/mysql/data}"
    if [ ! -d "${DATA_DIR}" ] && command -v mysqld >/dev/null 2>&1; then
      log_info "Initializing MySQL data directory at ${DATA_DIR}..."
      mkdir -p "${DATA_DIR}"
      mysqld --initialize-insecure --datadir="${DATA_DIR}" 2>/dev/null || true
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
    export SCRIPT_NAME
    . "${SCRIPT_NAME}"
    service_name="${LIBSCRIPT_SERVICE_NAME:-mysql}"
    libscript_service "$ACTION" "$service_name" "$@"
    exit 0
    ;;
  install-service)
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
    export SCRIPT_NAME
    . "${SCRIPT_NAME}"
    service_name="${LIBSCRIPT_SERVICE_NAME:-mysql}"
    libscript_install_service "$service_name" "$@"
    exit 0
    ;;
  uninstall-service)
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
    export SCRIPT_NAME
    . "${SCRIPT_NAME}"
    service_name="${LIBSCRIPT_SERVICE_NAME:-mysql}"
    libscript_uninstall_service "$service_name" "$@"
    exit 0
    ;;
  uninstall)
    resolve_exact_version
    log_info "Uninstalling MySQL ${EXACT_VERSION}..."
    rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/mysql/${EXACT_VERSION}"
    rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/mysql/${VERSION}"
    exit 0
    ;;
  test)
    if command -v mysql >/dev/null 2>&1; then
      mysql --version
      exit 0
    elif command -v mysqld >/dev/null 2>&1; then
      mysqld --version
      exit 0
    else
      printf 'mysql binary not found in PATH
' >&2
      exit 1
    fi
    ;;
esac
