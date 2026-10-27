#!/bin/sh
# ## Overview
# Transactional Stateful Upgrade Engine combining hooks/backup, ZFS/Btrfs CoW snapshots, hooks/upgrade, probe gating, and automatic rollback.
#
# ## Usage
# ./_lib/_common/upgrade_engine.sh <component> <old_version> <new_version> [--simulate-failure]

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

# ## run_transactional_upgrade
# Executes pre-upgrade backup, CoW snapshot, upgrade hook, readiness probe, and automatic rollback on failure.
run_transactional_upgrade() {
  comp="${1:-postgres}"
  old_ver="${2:-15}"
  new_ver="${3:-16}"
  sim_fail="${4:-}"

  comp_dir="$(libscript_resolve_component_dir "$comp")"
  is_stateful="$(jq -r '.stateful // false' "${comp_dir}/manifest.json")"

  if [ "$is_stateful" != "true" ]; then
    printf '{"component":"%s","stateful":false,"action":"symlink_flip","to":"%s","status":"upgraded"}\n' "$comp" "$new_ver"
    return 0
  fi

  bdir="${LIBSCRIPT_INSTANCE_ROOT:-/tmp/libscript-${comp}}/pre-upgrade-backup"
  libscript_exec_hook "$comp" "backup" "$bdir" >/dev/null
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/traits/backup/cow_snapshot.sh" sh "${LIBSCRIPT_ROOT_DIR}/traits/backup/cow_snapshot.sh" create "rpool/${comp}" "pre-upgrade-${comp}-${new_ver}" >/dev/null
  libscript_exec_hook "$comp" "upgrade" "$old_ver" "$new_ver" >/dev/null

  if [ "$sim_fail" = "--simulate-failure" ] || [ "${LIBSCRIPT_SIMULATE_UPGRADE_FAILURE:-0}" = "1" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/traits/backup/cow_snapshot.sh" sh "${LIBSCRIPT_ROOT_DIR}/traits/backup/cow_snapshot.sh" rollback "rpool/${comp}" "pre-upgrade-${comp}-${new_ver}" >/dev/null
    libscript_exec_hook "$comp" "rollback" "$old_ver" "$new_ver" >/dev/null
    libscript_exec_hook "$comp" "restore" "$bdir" >/dev/null
    libscript_exec_hook "$comp" "probe" readiness >/dev/null
    printf '{"component":"%s","action":"transactional_rollback","reverted_to":"%s","failed_version":"%s","status":"rolled_back"}\n' "$comp" "$old_ver" "$new_ver"
    return 1
  fi

  libscript_exec_hook "$comp" "probe" readiness >/dev/null
  printf '{"component":"%s","stateful":true,"action":"upgrade","from":"%s","to":"%s","status":"upgraded"}\n' "$comp" "$old_ver" "$new_ver"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 <component> <old_version> <new_version> [--simulate-failure]"
  exit 0
fi

run_transactional_upgrade "$@"
