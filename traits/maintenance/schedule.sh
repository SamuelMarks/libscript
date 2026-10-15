#!/bin/sh
# ## Overview
# Registers recurring execution of hooks/maintenance.sh and traits/backup/orchestrate.sh via systemd timers or cron.
#
# ## Usage
# ./traits/maintenance/schedule.sh [cron_expr]

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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

# ## install_maintenance_schedule
# Emits /etc/cron.d/libscript-maintenance and systemd timer units idempotently.
install_maintenance_schedule() {
  schedule_expr="${1:-0 3 * * *}"
  sysroot="${LIBSCRIPT_TARGET_SYSROOT:-/}"
  cron_dir="${sysroot%/}/etc/cron.d"
  mkdir -p "$cron_dir"
  cron_file="${cron_dir}/libscript-maintenance"
  {
    printf '# BEGIN libscript-maintenance\n'
    printf '%s root %s/traits/backup/orchestrate.sh\n' "$schedule_expr" "$LIBSCRIPT_ROOT_DIR"
    printf '# END libscript-maintenance\n'
  } > "$cron_file"
  printf '[INFO] Scheduled maintenance written to %s.\n' "$cron_file"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 [cron_expr]"
  exit 0
fi

install_maintenance_schedule "${1:-0 3 * * *}"
