#!/bin/sh
# ## Overview
# Core Unified Traits Engine resolving priority order and dispatching Tier 2 Offline Bake or Tier 3 Live Runtime traits,
# including manifest-driven storage, ingress, firewall, and secrets trait execution.
#
# ## Usage
# ./traits/engine.sh <list|enable|disable|apply|verify|teardown> [trait_name|all] [--manifest <libscript.json>] [args...]

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
STATE_DIR="${LIBSCRIPT_TRAIT_STATE_DIR:-${SYSROOT%/}/etc/libscript/traits}"
MANIFEST_FILE=""

# ## get_execution_mode
# Determines whether traits run in Tier 2 offline sysroot bake mode or Tier 3 live runtime mode.
get_execution_mode() {
  if [ "${LIBSCRIPT_TARGET_SYSROOT:-/}" != "/" ] || [ "${LIBSCRIPT_OFFLINE:-0}" = "1" ]; then
    printf '%s\n' "offline_sysroot_bake"
  else
    printf '%s\n' "live_runtime"
  fi
}

# ## ensure_state_dir
# Ensures a writable trait state directory exists, falling back to TMPDIR when unprivileged.
ensure_state_dir() {
  mkdir -p "$STATE_DIR" 2>/dev/null || {
    STATE_DIR="${TMPDIR:-/tmp}/libscript/traits"
    mkdir -p "$STATE_DIR" 2>/dev/null || true
  }
}

# ## run_single_trait
# Dispatches an action (apply, verify, teardown) to a specific trait implementation.
run_single_trait() {
  t_name="$1"
  t_action="$2"
  shift 2 2>/dev/null || true
  mode="$(get_execution_mode)"
  export LIBSCRIPT_TRAIT_MODE="$mode"
  ensure_state_dir
  printf 'TRAIT=%s\nACTION=%s\nMODE=%s\n' "$t_name" "$t_action" "$mode" > "${STATE_DIR}/${t_name}.state" 2>/dev/null || true
  printf '[INFO] Trait "%s": action="%s" mode="%s"\n' "$t_name" "$t_action" "$mode"

  if [ "${DRY_RUN:-false}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
    return 0
  fi

  case "$t_name" in
    storage)
      if [ "$t_action" = "apply" ]; then
        if [ $# -gt 0 ]; then
          "${SCRIPT_DIR}/storage/mount.sh" "$@"
        elif [ -n "$MANIFEST_FILE" ] && [ -f "$MANIFEST_FILE" ]; then
          "${LIBSCRIPT_ROOT_DIR}/libscript.sh" prepare-storage "$MANIFEST_FILE"
        fi
      fi
      ;;
    ingress)
      if [ -n "$MANIFEST_FILE" ] && [ -f "$MANIFEST_FILE" ]; then
        case "$t_action" in
          apply) "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" apply "$MANIFEST_FILE" --reload || true ;;
          teardown) "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" remove-ingress "$MANIFEST_FILE" --reload || true ;;
        esac
      elif [ $# -gt 0 ] && [ -x "${SCRIPT_DIR}/ingress/route.sh" ]; then
        "${SCRIPT_DIR}/ingress/route.sh" "$t_action" "$@" || true
      fi
      ;;
    firewall)
      if [ "$t_action" = "teardown" ] && [ -x "${SCRIPT_DIR}/firewall/teardown.sh" ] && [ $# -gt 0 ]; then
        "${SCRIPT_DIR}/firewall/teardown.sh" "$@" || true
      elif [ "$t_action" = "apply" ] && [ -x "${SCRIPT_DIR}/firewall/compile.sh" ] && [ $# -gt 0 ]; then
        "${SCRIPT_DIR}/firewall/compile.sh" "$@" || true
      fi
      ;;
  esac
  return 0
}

ACTION="${1:-list}"
shift 2>/dev/null || true
TARGET_TRAIT="all"

while [ $# -gt 0 ]; do
  case "$1" in
    --manifest=*)
      MANIFEST_FILE="${1#*=}"
      shift
      ;;
    --manifest)
      shift
      MANIFEST_FILE="${1:-}"
      [ $# -gt 0 ] && shift || true
      ;;
    *)
      if [ "$TARGET_TRAIT" = "all" ]; then
        TARGET_TRAIT="$1"
        shift
      else
        break
      fi
      ;;
  esac
done

case "$ACTION" in
  list)
    for t in $ORDERED_TRAITS; do
      printf '%s\n' "$t"
    done
    ;;
  enable)
    ensure_state_dir
    touch "${STATE_DIR}/${TARGET_TRAIT}.enabled"
    printf '[INFO] Enabled trait: %s\n' "$TARGET_TRAIT"
    ;;
  disable)
    ensure_state_dir
    rm -f "${STATE_DIR}/${TARGET_TRAIT}.enabled"
    printf '[INFO] Disabled trait: %s\n' "$TARGET_TRAIT"
    ;;
  apply|verify|teardown)
    if [ "$TARGET_TRAIT" = "all" ] || [ -z "$TARGET_TRAIT" ]; then
      for t in $ORDERED_TRAITS; do
        run_single_trait "$t" "$ACTION" "$@"
      done
    else
      run_single_trait "$TARGET_TRAIT" "$ACTION" "$@"
    fi
    ;;
  --help|-h)
    printf '%s\n' "Usage: $0 <list|enable|disable|apply|verify|teardown> [trait_name] [--manifest <libscript.json>]"
    ;;
  *)
    printf '[ERROR] Unknown trait engine command: %s\n' "$ACTION" >&2
    exit 1
    ;;
esac
