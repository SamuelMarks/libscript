#!/bin/sh
# ## Overview
# Linear execution plan runner for LibScript multi-kernel and component builds.
# ## Usage
# ./_lib/orchestration/execute_plan.sh <path_to_execution_plan.json> [--dry-run]

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

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: ${THIS_FILE} <path_to_execution_plan.json> [--dry-run]"
  printf '%s\n' 'Executes a linear build execution plan step-by-step with stamp tracking.'
  exit 0
fi

if [ -z "${1:-}" ]; then
  printf '[ERROR] Missing required execution plan argument.\n' >&2
  exit 1
fi

PLAN_FILE="$1"
DRY_RUN=0
if [ "${2:-}" = "--dry-run" ] || [ "${LIBSCRIPT_DRY_RUN:-0}" = "1" ]; then
  DRY_RUN=1
fi

if [ ! -f "$PLAN_FILE" ]; then
  printf '[ERROR] Execution plan file not found: %s\n' "$PLAN_FILE" >&2
  exit 1
fi

# ## ensure_jq_available
# Ensures jq is available on PATH, bootstrapping _lib/utilities/jq automatically when absent.
ensure_jq_available() {
  if command -v jq >/dev/null 2>&1; then
    return 0
  fi
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1091
    . "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" >/dev/null 2>&1 || true
    unset SCRIPT_NAME || true
  fi
  if ! command -v jq >/dev/null 2>&1; then
    STACK="" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install jq latest >/dev/null 2>&1 || true
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh"
      export SCRIPT_NAME
      # shellcheck disable=SC1091
      . "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" >/dev/null 2>&1 || true
      unset SCRIPT_NAME || true
    fi
  fi
  command -v jq >/dev/null 2>&1
}

if ! ensure_jq_available; then
  printf '[ERROR] jq is required and could not be bootstrapped.\n' >&2
  exit 1
fi

TARGET_SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}"
STAMPS_DIR="${TARGET_SYSROOT}/var/lib/libscript/stamps"

if [ "$DRY_RUN" -eq 0 ] && [ ! -d "$STAMPS_DIR" ]; then
  mkdir -p "$STAMPS_DIR"
fi

TOTAL_STAGES=$(jq '.stages | length' "$PLAN_FILE")
STAGE_IDX=0

while [ "$STAGE_IDX" -lt "$TOTAL_STAGES" ]; do
  STAGE_NAME=$(jq -r ".stages[$STAGE_IDX].stage" "$PLAN_FILE")
  STAGE_DESC=$(jq -r ".stages[$STAGE_IDX].description // empty" "$PLAN_FILE")
  printf '\n[STAGE] === %s ===\n' "$STAGE_NAME"
  if [ -n "$STAGE_DESC" ]; then
    printf '[INFO]  %s\n' "$STAGE_DESC"
  fi

  TOTAL_TASKS=$(jq ".stages[$STAGE_IDX].tasks | length" "$PLAN_FILE")
  TASK_IDX=0

  while [ "$TASK_IDX" -lt "$TOTAL_TASKS" ]; do
    TASK_NAME=$(jq -r ".stages[$STAGE_IDX].tasks[$TASK_IDX].name" "$PLAN_FILE")
    TASK_COMP=$(jq -r ".stages[$STAGE_IDX].tasks[$TASK_IDX].component" "$PLAN_FILE")
    TASK_ACTION=$(jq -r ".stages[$STAGE_IDX].tasks[$TASK_IDX].action" "$PLAN_FILE")
    TASK_STAMP=$(jq -r ".stages[$STAGE_IDX].tasks[$TASK_IDX].stamp" "$PLAN_FILE")
    STAMP_FILE="${STAMPS_DIR}/${TASK_STAMP}"

    if [ -f "$STAMP_FILE" ]; then
      printf '[SKIP]  Task "%s" (%s) already satisfied by %s\n' "$TASK_NAME" "$TASK_ACTION" "$TASK_STAMP"
    else
      printf '[RUN]   Task "%s" (%s) [%s]\n' "$TASK_NAME" "$TASK_ACTION" "$TASK_COMP"
      if [ "$DRY_RUN" -eq 1 ]; then
        printf '[DRYRUN] Would execute %s on %s and touch %s\n' "$TASK_ACTION" "$TASK_COMP" "$STAMP_FILE"
      else
        EXEC_SCRIPT="${LIBSCRIPT_ROOT_DIR}/${TASK_COMP}/setup.sh"
        if [ -f "$EXEC_SCRIPT" ]; then
          ENV_JSON=$(jq -c ".stages[$STAGE_IDX].tasks[$TASK_IDX].env // {}" "$PLAN_FILE")
          ENV_LINES=$(jq -r ".stages[$STAGE_IDX].tasks[$TASK_IDX].env // {} | to_entries[] | select(.key | test(\"^[A-Za-z_][A-Za-z0-9_]*$\")) | \"\(.key)=\(.value)\"" "$PLAN_FILE")
          EFFECTIVE_ACTION="$TASK_ACTION"
          case "$TASK_COMP" in
            _lib/bootloaders*|_lib/freebsd|_lib/kernel|_lib/storage*|_lib/orchestration/fhs|_lib/orchestration/unikernel_pod)
              ;;
            *)
              if [ "$EFFECTIVE_ACTION" = "compile" ] || [ "$EFFECTIVE_ACTION" = "bootstrap" ]; then
                EFFECTIVE_ACTION='install'
              fi
              ;;
          esac
          (
            STACK=''
            export STACK
            export ENV_JSON
            LIBSCRIPT_TARGET_SYSROOT="$TARGET_SYSROOT"
            LIBSCRIPT_STAGE="$STAGE_NAME"
            export LIBSCRIPT_TARGET_SYSROOT LIBSCRIPT_STAGE
            if [ -n "$ENV_LINES" ]; then
              _old_ifs="$IFS"
              IFS='
'
              for _kv in $ENV_LINES; do
                [ -n "$_kv" ] && export "${_kv?}"
              done
              IFS="$_old_ifs"
            fi
            exec sh "$EXEC_SCRIPT" "$EFFECTIVE_ACTION"
          )
        else
          printf '[INFO]  No leaf script %s; registering step completion\n' "$EXEC_SCRIPT"
        fi
        date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
        mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
        printf '[OK]    Completed "%s" -> %s\n' "$TASK_NAME" "$TASK_STAMP"
      fi
    fi

    TASK_IDX=$((TASK_IDX + 1))
  done

  STAGE_IDX=$((STAGE_IDX + 1))
done

printf '\n[SUCCESS] All execution plan stages processed successfully.\n'
