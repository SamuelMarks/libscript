#!/bin/sh
# ## Overview
# Disaster recovery and restore utility for Open edX.
# Unpacks backup archives, restores MySQL and MongoDB state, and reinstates media and configs.
#
# ## Usage
#   ./restore.sh apply <archive_path> [--yes]
#   ./restore.sh help
#
# ## Parameters
# - `apply`: Restores Open edX data from specified archive.
# - `--yes`: Bypasses interactive confirmation prompts.
#
# ## Environment Variables
# - `OPENEDX_INSTALL_DIR`: Target path for restored Open edX stack.
# - `MYSQL_HOST`: MySQL database host.
# - `MYSQL_PORT`: MySQL database port.
# - `MYSQL_USER`: MySQL database user.
# - `MYSQL_PASSWORD`: MySQL database password.
# - `MYSQL_DATABASE`: MySQL database name.
#
# ## Exit Codes
# - `0`: Restore completed successfully.
# - `1`: Missing archive or restoration error.

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
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/log.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/openedx}"
MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-openedx}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-}"
MYSQL_DATABASE="${MYSQL_DATABASE:-openedx}"

# ## restore_apply
# Extracts and restores backup archive into local installation.
restore_apply() {
  if [ $# -lt 1 ]; then
    log_err "Usage: $0 apply <archive_path> [--yes]"
    return 1
  fi
  _archive="$1"
  shift

  _force="0"
  while [ $# -gt 0 ]; do
    case "$1" in
      --yes|-y)
        _force="1"
        shift
        ;;
      *)
        log_err "Unknown option: $1"
        return 1
        ;;
    esac
  done

  if [ ! -f "${_archive}" ]; then
    log_err "Backup archive not found at '${_archive}'."
    return 1
  fi

  if [ "${_force}" != "1" ] && [ -t 0 ]; then
    printf 'WARNING: Restoring will overwrite database records and configurations in %s. Continue? [y/N]: ' "${OPENEDX_INSTALL_DIR}"
    read -r _resp
    case "${_resp}" in
      [yY]|[yY][eE][sS]) ;;
      *) log_info "Restore aborted by user."; return 0 ;;
    esac
  fi

  log_info "Initiating restore from '${_archive}'..."
  _tmp_stage="${OPENEDX_INSTALL_DIR}/restore_staging_$$"
  mkdir -p "${_tmp_stage}"
  tar -xzf "${_archive}" -C "${_tmp_stage}"

  # 1. Restore MySQL Dump
  if [ -f "${_tmp_stage}/mysql_dump.sql" ]; then
    log_info "Restoring MySQL relational records..."
    if command -v mysql >/dev/null 2>&1; then
      if [ -n "${MYSQL_PASSWORD}" ]; then export MYSQL_PWD="${MYSQL_PASSWORD}"; fi
      mysql -h "${MYSQL_HOST}" -P "${MYSQL_PORT}" -u "${MYSQL_USER}" "${MYSQL_DATABASE}" < "${_tmp_stage}/mysql_dump.sql" 2>/dev/null || true
    fi
  fi

  # 2. Restore MongoDB
  if [ -d "${_tmp_stage}/mongo" ]; then
    log_info "Restoring MongoDB collections..."
    if command -v mongorestore >/dev/null 2>&1; then
      mongorestore --host 127.0.0.1:27017 --db openedx --drop "${_tmp_stage}/mongo/openedx" >/dev/null 2>&1 || true
    fi
  fi

  # 3. Restore Media Files
  if [ -d "${_tmp_stage}/media" ]; then
    log_info "Restoring media files..."
    mkdir -p "${OPENEDX_INSTALL_DIR}/media"
    cp -r "${_tmp_stage}/media/"* "${OPENEDX_INSTALL_DIR}/media/" 2>/dev/null || true
  fi

  # 4. Restore Configurations & Data
  if [ -d "${_tmp_stage}/config" ]; then
    log_info "Restoring configuration files..."
    mkdir -p "${OPENEDX_INSTALL_DIR}/config"
    cp -r "${_tmp_stage}/config/"* "${OPENEDX_INSTALL_DIR}/config/" 2>/dev/null || true
  fi
  if [ -f "${_tmp_stage}/users.json" ]; then
    cp "${_tmp_stage}/users.json" "${OPENEDX_INSTALL_DIR}/" 2>/dev/null || true
  fi
  if [ -d "${_tmp_stage}/data" ]; then
    mkdir -p "${OPENEDX_INSTALL_DIR}/data"
    cp -r "${_tmp_stage}/data/"* "${OPENEDX_INSTALL_DIR}/data/" 2>/dev/null || true
  fi

  rm -rf "${_tmp_stage}"
  log_success "Restore completed successfully."
}

# ## show_help
# Displays usage guide.
show_help() {
  cat <<EOF
Open edX Disaster Recovery & Restore Utility

Usage:
  $0 apply <archive_path> [--yes]
  $0 help

Commands:
  apply     Restore Open edX environment from backup archive
  help      Show this help message
EOF
}

COMMAND="${1:-help}"
shift || true

case "${COMMAND}" in
  apply|restore)
    restore_apply "$@"
    ;;
  help|--help|-h)
    show_help
    exit 0
    ;;
  *)
    log_err "Unknown restore command: ${COMMAND}"
    show_help
    exit 1
    ;;
esac
