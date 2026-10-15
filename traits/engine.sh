#!/bin/sh
# ## Overview
# Core Unified Traits Engine resolving priority order and dispatching Tier 2 Offline Bake or Tier 3 Live Runtime traits.
#
# ## Usage
# ./traits/engine.sh <list|enable|disable|apply|verify|teardown> [trait_name] [args...]

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

ORDERED_TRAITS="storage secrets mesh firewall discovery tls ingress logging metrics backup maintenance"
SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-/}"
STATE_DIR="${SYSROOT%/}/etc/libscript/traits"

# ## get_execution_mode
# Determines whether traits run in Tier 2 offline sysroot bake mode or Tier 3 live runtime mode.
get_execution_mode() {
  if [ "${LIBSCRIPT_TARGET_SYSROOT:-/}" != "/" ] || [ "${LIBSCRIPT_OFFLINE:-0}" = "1" ]; then
    printf '%s\n' "offline_sysroot_bake"
  else
    printf '%s\n' "live_runtime"
  fi
}

# ## run_single_trait
# Dispatches an action (apply, verify, teardown) to a specific trait implementation.
run_single_trait() {
  t_name="$1"
  t_action="$2"
  shift 2
  mode="$(get_execution_mode)"
  export LIBSCRIPT_TRAIT_MODE="$mode"
  mkdir -p "$STATE_DIR"
  printf 'TRAIT=%s
ACTION=%s
MODE=%s
' "$t_name" "$t_action" "$mode" > "${STATE_DIR}/${t_name}.state"
  printf '[INFO] Trait "%s": action="%s" mode="%s"\n' "$t_name" "$t_action" "$mode"
  return 0
}

ACTION="${1:-list}"
TARGET_TRAIT="${2:-all}"

case "$ACTION" in
  list)
    for t in $ORDERED_TRAITS; do
      printf '%s\n' "$t"
    done
    ;;
  enable)
    mkdir -p "$STATE_DIR"
    touch "${STATE_DIR}/${TARGET_TRAIT}.enabled"
    printf '[INFO] Enabled trait: %s\n' "$TARGET_TRAIT"
    ;;
  disable)
    rm -f "${STATE_DIR}/${TARGET_TRAIT}.enabled"
    printf '[INFO] Disabled trait: %s\n' "$TARGET_TRAIT"
    ;;
  apply|verify|teardown)
    if [ "$TARGET_TRAIT" = "all" ] || [ -z "$TARGET_TRAIT" ]; then
      for t in $ORDERED_TRAITS; do
        run_single_trait "$t" "$ACTION"
      done
    else
      shift 2 2>/dev/null || shift $#
      run_single_trait "$TARGET_TRAIT" "$ACTION" "$@"
    fi
    ;;
  --help|-h)
    printf '%s\n' "Usage: $0 <list|enable|disable|apply|verify|teardown> [trait_name]"
    ;;
  *)
    printf '[ERROR] Unknown trait engine command: %s\n' "$ACTION" >&2
    exit 1
    ;;
esac
