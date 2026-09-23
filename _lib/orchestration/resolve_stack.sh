#!/bin/sh
# ## Overview
# A portable dependency resolver and execution plan generator using jq on Unix-like systems.
# Supports both traditional install.json application stacks and declarative os-config.json profiles.
# Emits flat, topologically sorted execution-plan.json.
#
# ## Usage
# Run `resolve_stack.sh <path_to_config.json> [output_plan.json]` to compute an execution sequence.

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
' "Usage: ${THIS_FILE} <path_to_config.json> [output_plan.json]"
  printf '%s
' "Resolves component dependencies and emits an execution plan."
  exit 0
fi

if [ -z "${1:-}" ]; then
  printf '[ERROR] Missing required configuration file argument.
' >&2
  printf 'Usage: %s <path_to_config.json> [output_plan.json]
' "${THIS_FILE}" >&2
  exit 1
fi

CONFIG_FILE="$1"
OUTPUT_FILE="${2:-}"

if [ ! -f "$CONFIG_FILE" ]; then
  printf '[ERROR] Configuration file does not exist: %s
' "$CONFIG_FILE" >&2
  exit 1
fi

# Determine OS
if [ -z "${LIBSCRIPT_TARGET_OS:-}" ]; then
  OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
  case "$OS_NAME" in
    linux*) TARGET_OS="linux" ;;
    darwin*) TARGET_OS="darwin" ;;
    freebsd*) TARGET_OS="freebsd" ;;
    msys*|cygwin*|mingw*) TARGET_OS="windows" ;;
    *) TARGET_OS="$OS_NAME" ;;
  esac
else
  TARGET_OS="$LIBSCRIPT_TARGET_OS"
fi

if ! command -v jq >/dev/null 2>&1; then
  printf '[ERROR] jq is required but not installed.
' >&2
  exit 1
fi

# Find all manifests within _lib
MANIFEST_ARGS=""
tmp_manifests=$(mktemp 2>/dev/null || printf '%s' "/tmp/libscript_manifests.$$")
find "${LIBSCRIPT_ROOT_DIR}/_lib" -name "manifest.json" 2>/dev/null > "$tmp_manifests" || true
if [ -f "$tmp_manifests" ]; then
  while IFS= read -r m; do
    [ -n "$m" ] && MANIFEST_ARGS="${MANIFEST_ARGS} \"${m}\""
  done < "$tmp_manifests"
  rm -f "$tmp_manifests"
fi

# If no manifests found or empty, safely provide an empty list
if [ -z "$MANIFEST_ARGS" ]; then
  SOLVER_CMD="jq --arg target_os \"$TARGET_OS\" -n '{config: input, manifests: []}' \"$CONFIG_FILE\""
else
  SOLVER_CMD="jq --arg target_os \"$TARGET_OS\" -n '{config: input, manifests: [inputs]}' \"$CONFIG_FILE\" $MANIFEST_ARGS"
fi

# Execute resolution
if [ -n "$OUTPUT_FILE" ]; then
  OUT_DIR=$(dirname -- "$OUTPUT_FILE")
  if [ ! -d "$OUT_DIR" ]; then
    mkdir -p "$OUT_DIR"
  fi
  # shellcheck disable=SC2086
  sh -c "$SOLVER_CMD" | jq -L "${LIBSCRIPT_ROOT_DIR}/_lib/utilities" -L "${SCRIPT_DIR}" --arg target_os "$TARGET_OS" -r -f "${SCRIPT_DIR}/resolve_stack.jq" > "$OUTPUT_FILE"
  printf '[INFO] Execution plan generated at %s
' "$OUTPUT_FILE"
else
  # shellcheck disable=SC2086
  sh -c "$SOLVER_CMD" | jq -L "${LIBSCRIPT_ROOT_DIR}/_lib/utilities" -L "${SCRIPT_DIR}" --arg target_os "$TARGET_OS" -r -f "${SCRIPT_DIR}/resolve_stack.jq"
fi
