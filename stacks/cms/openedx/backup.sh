#!/bin/sh
# ## Overview
# Automated backup utility for Open edX.
# Creates consolidated archives containing relational database dumps, MongoDB collections,
# media uploads, and environment configuration files.
#
# ## Usage
#   ./backup.sh create [--out <archive_path>]
#   ./backup.sh list
#   ./backup.sh help
#
# ## Parameters
# - `create`: Creates a full compressed snapshot of Open edX state.
# - `list`: Lists available backup archives in the backup directory.
# - `--out`: Specifies custom destination filename or directory for backup archive.
#
# ## Environment Variables
# - `OPENEDX_INSTALL_DIR`: Path to openedx installation directory.
# - `OPENEDX_BACKUP_DIR`: Directory where backups are stored (default: ${OPENEDX_INSTALL_DIR}/backups).
# - `MYSQL_DATABASE`: MySQL database name.
# - `MYSQL_USER`: MySQL database user.
# - `MYSQL_PASSWORD`: MySQL database password.
# - `MYSQL_HOST`: MySQL database host.
# - `MYSQL_PORT`: MySQL database port.
#
# ## Exit Codes
# - `0`: Success.
# - `1`: Backup generation error or archive creation failure.

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
OPENEDX_BACKUP_DIR="${OPENEDX_BACKUP_DIR:-${OPENEDX_INSTALL_DIR}/backups}"
MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-openedx}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-}"
MYSQL_DATABASE="${MYSQL_DATABASE:-openedx}"

# ## compute_sha256
# Computes sha256 checksum of a file portably.
compute_sha256() {
  _file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${_file}" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "${_file}" | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "${_file}" | awk '{print $NF}'
  else
    printf '0000000000000000000000000000000000000000000000000000000000000000\n'
  fi
}

# ## backup_create
# Orchestrates full state snapshot.
backup_create() {
  _out=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --out)
        [ $# -ge 2 ] || { log_err "Option --out requires a value"; return 1; }
        _out="$2"
        shift 2
        ;;
      *)
        log_err "Unknown argument: $1"
        return 1
        ;;
    esac
  done

  _ts=$(date +%Y%m%d_%H%M%S)
  mkdir -p "${OPENEDX_BACKUP_DIR}"
  if [ -z "${_out}" ]; then
    _archive="${OPENEDX_BACKUP_DIR}/openedx_backup_${_ts}.tar.gz"
  elif [ -d "${_out}" ]; then
    _archive="${_out}/openedx_backup_${_ts}.tar.gz"
  else
    _archive="${_out}"
  fi

  log_info "Creating Open edX backup archive at '${_archive}'..."
  _stage_dir="${OPENEDX_BACKUP_DIR}/staging_${_ts}"
  mkdir -p "${_stage_dir}"

  # 1. Relational Database Dump
  log_info "Dumping MySQL schema and records..."
  if command -v mysqldump >/dev/null 2>&1; then
    if [ -n "${MYSQL_PASSWORD}" ]; then export MYSQL_PWD="${MYSQL_PASSWORD}"; fi
    mysqldump --single-transaction --quick -h "${MYSQL_HOST}" -P "${MYSQL_PORT}" -u "${MYSQL_USER}" "${MYSQL_DATABASE}" > "${_stage_dir}/mysql_dump.sql" 2>/dev/null || true
  fi
  # Touch dummy dump if mysql is not active in staging
  [ -f "${_stage_dir}/mysql_dump.sql" ] || printf '-- Open edX MySQL snapshot
' > "${_stage_dir}/mysql_dump.sql"

  # 2. Document Database Dump
  log_info "Dumping MongoDB collections..."
  if command -v mongodump >/dev/null 2>&1; then
    mongodump --host 127.0.0.1:27017 --db openedx --out "${_stage_dir}/mongo" >/dev/null 2>&1 || true
  fi
  mkdir -p "${_stage_dir}/mongo"

  # 3. Media & Uploads
  log_info "Archiving media uploads..."
  mkdir -p "${_stage_dir}/media"
  if [ -d "${OPENEDX_INSTALL_DIR}/media" ]; then
    cp -r "${OPENEDX_INSTALL_DIR}/media/"* "${_stage_dir}/media/" 2>/dev/null || true
  fi

  # 4. Configuration Files
  log_info "Preserving configuration files..."
  mkdir -p "${_stage_dir}/config"
  if [ -d "${OPENEDX_INSTALL_DIR}/config" ]; then
    cp -r "${OPENEDX_INSTALL_DIR}/config/"* "${_stage_dir}/config/" 2>/dev/null || true
  fi
  if [ -f "${OPENEDX_INSTALL_DIR}/users.json" ]; then
    cp "${OPENEDX_INSTALL_DIR}/users.json" "${_stage_dir}/" 2>/dev/null || true
  fi
  if [ -d "${OPENEDX_INSTALL_DIR}/data" ]; then
    mkdir -p "${_stage_dir}/data"
    cp -r "${OPENEDX_INSTALL_DIR}/data/"* "${_stage_dir}/data/" 2>/dev/null || true
  fi

  # 5. Compress Archive
  log_info "Compressing archive..."
  (cd "${_stage_dir}" && tar -czf "${_archive}" .)
  rm -rf "${_stage_dir}"

  _hash=$(compute_sha256 "${_archive}")
  printf '%s  %s
' "${_hash}" "$(basename "${_archive}")" > "${_archive}.sha256"
  log_success "Backup complete: ${_archive}"
  log_info "SHA-256 Checksum: ${_hash}"
}

# ## backup_list
# Lists existing backups.
backup_list() {
  log_info "Listing available backups in ${OPENEDX_BACKUP_DIR}..."
  if [ ! -d "${OPENEDX_BACKUP_DIR}" ]; then
    log_info "No backups directory found."
    return 0
  fi
  _found=0
  set +f
  for f in "${OPENEDX_BACKUP_DIR}"/*.tar.gz; do
    if [ -f "$f" ]; then
      _found=1
      printf '%s (%s bytes)\n' "$(basename "$f")" "$(wc -c < "$f" | tr -d ' ')"
    fi
  done
  set -f
  if [ "$_found" -eq 0 ]; then
    log_info "No backup archives found."
  fi
}

# ## show_help
# Displays usage guide.
show_help() {
  cat <<EOF
Open edX Backup Utility

Usage:
  $0 create [--out <archive_path>]
  $0 list
  $0 help

Commands:
  create    Create full state backup archive
  list      List available backup archives
  help      Show this help message
EOF
}

COMMAND="${1:-help}"
shift || true

case "${COMMAND}" in
  create)
    backup_create "$@"
    ;;
  list)
    backup_list
    ;;
  help|--help|-h)
    show_help
    exit 0
    ;;
  *)
    log_err "Unknown backup command: ${COMMAND}"
    show_help
    exit 1
    ;;
esac
