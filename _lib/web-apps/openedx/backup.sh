#!/bin/sh
# ## Overview
# Automated backup utility for Open edX.
# Creates consolidated archives containing relational database dumps, MongoDB collections,
# media uploads, and environment configuration files.
#
# ## Usage
#   ./backup.sh [create|list|help] [--out <archive_path>]

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
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
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export DIR="${SCRIPT_DIR}"

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
BACKUP_HELPER="${SCRIPT_DIR}/backup_helper.sh"

# ## backup_create
# Orchestrates full state snapshot via backup_helper.sh.
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

  log_info 'Creating Open edX backup archive...'
  "${BACKUP_HELPER}" backup "${OPENEDX_BACKUP_DIR}" "${OPENEDX_INSTALL_DIR}" "${_out}"
}

# ## backup_list
# Lists existing backups.
backup_list() {
  log_info "Listing available backups in ${OPENEDX_BACKUP_DIR}..."
  if [ ! -d "${OPENEDX_BACKUP_DIR}" ]; then
    log_info 'No backups directory found.'
    return 0
  fi
  _found=0
  set +f
  for f in "${OPENEDX_BACKUP_DIR}"/*.tar.gz "${OPENEDX_BACKUP_DIR}"/*.zip; do
    if [ -f "$f" ]; then
      _found=1
      printf '%s (%s bytes)\n' "$(basename "$f")" "$(wc -c < "$f" | tr -d ' ')"
    fi
  done
  set -f
  if [ "$_found" -eq 0 ]; then
    log_info 'No backup archives found.'
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
