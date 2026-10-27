#!/bin/sh
# ## Overview
# Enumerates stateful components and active tenants and invokes hooks/backup and hooks/backup_tenant.
#
# ## Usage
# ./traits/backup/orchestrate.sh [dest_dir] [component...]

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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/hooks.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

# ## orchestrate_backups
# Runs physical backup hooks for stateful components into dest_dir.
orchestrate_backups() {
  dest_dir="${1:-${LIBSCRIPT_INSTANCE_ROOT:-/tmp}/backups}"
  shift 1 2>/dev/null || true
  mkdir -p "$dest_dir"
  if [ $# -eq 0 ]; then
    set -- "postgres" "redis"
  fi
  for comp in "$@"; do
    libscript_exec_hook "$comp" "backup" "$dest_dir"
  done
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 [dest_dir] [component...]"
  exit 0
fi

if [ -f "${1:-}" ] && case "${1:-}" in *.json) true ;; *) false ;; esac; then
  exec "${LIBSCRIPT_ROOT_DIR}/_lib/databases/export_db.sh" "$1" "${2:-/tmp/libscript_export_stage}"
fi
orchestrate_backups "$@"
