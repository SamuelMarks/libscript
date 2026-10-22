#!/bin/sh
# ## Overview
# Disaster recovery and restore utility for Open edX.
# Unpacks backup archives, restores MySQL and MongoDB state, and reinstates media and configs.
#
# ## Usage
#   ./restore.sh [apply <archive_path> [--yes]|help]

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
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export DIR="${SCRIPT_DIR}"

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
BACKUP_HELPER="${SCRIPT_DIR}/backup_helper.sh"

# ## restore_apply
# Extracts and restores backup archive into local installation via backup_helper.sh.
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
      [yY]|[yY][eE][sS]) _force="1" ;;
      *) log_info "Restore aborted by user."; return 0 ;;
    esac
  fi

  log_info "Initiating restore from '${_archive}'..."
  "${BACKUP_HELPER}" restore "${_archive}" "${OPENEDX_INSTALL_DIR}" "${_force}"
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
