#!/bin/sh
# ## Overview
# Linear execution plan runner for LibScript builds.
# Reads a deterministic execution-plan.json, iterates over stages and tasks,
# checks and updates idempotency stage stamp files, and orchestrates task executions.
#
# ## Usage
# Run `execute_plan.sh <path_to_execution_plan.json> [--dry-run]` to process tasks sequentially.

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

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s
' "Usage: ${THIS_FILE} <path_to_execution_plan.json> [--dry-run]"
  printf '%s
' "Executes a linear build execution plan step-by-step with stamp tracking."
  exit 0
fi

if [ -z "${1:-}" ]; then
  printf '[ERROR] Missing required execution plan argument.
' >&2
  printf 'Usage: %s <path_to_execution_plan.json> [--dry-run]
' "${THIS_FILE}" >&2
  exit 1
fi

PLAN_FILE="$1"
DRY_RUN=0

if [ "${2:-}" = "--dry-run" ]; then
  DRY_RUN=1
fi

if [ ! -f "$PLAN_FILE" ]; then
  printf '[ERROR] Execution plan file not found: %s
' "$PLAN_FILE" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  printf '[ERROR] jq is required but not installed.
' >&2
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

    # Check if task already completed
    if [ -f "$STAMP_FILE" ]; then
      printf '[SKIP]  Task "%s" (%s) already satisfied by %s
' "$TASK_NAME" "$TASK_ACTION" "$TASK_STAMP"
    else
      printf '[RUN]   Task "%s" (%s) [%s]
' "$TASK_NAME" "$TASK_ACTION" "$TASK_COMP"
      if [ "$DRY_RUN" -eq 1 ]; then
        printf '[DRYRUN] Would execute %s on %s and touch %s
' "$TASK_ACTION" "$TASK_COMP" "$STAMP_FILE"
      else
        # Locate task executable script if present
        EXEC_SCRIPT="${LIBSCRIPT_ROOT_DIR}/${TASK_COMP}/setup.sh"
        if [ -f "$EXEC_SCRIPT" ]; then
          # Extract environment variables from task definition
          ENV_JSON=$(jq -c ".stages[$STAGE_IDX].tasks[$TASK_IDX].env // {}" "$PLAN_FILE")
          # Run task script with sysroot context
          LIBSCRIPT_TARGET_SYSROOT="$TARGET_SYSROOT" 
            LIBSCRIPT_STAGE="$STAGE_NAME" 
            sh "$EXEC_SCRIPT" "$TASK_ACTION"
        else
          printf '[INFO]  No leaf script %s; registering step completion
' "$EXEC_SCRIPT"
        fi
        # Atomically record stage completion stamp
        date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
        mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
        printf '[OK]    Completed "%s" -> %s
' "$TASK_NAME" "$TASK_STAMP"
      fi
    fi

    TASK_IDX=$((TASK_IDX + 1))
  done

  STAGE_IDX=$((STAGE_IDX + 1))
done

printf '
[SUCCESS] All execution plan stages processed successfully.
'
