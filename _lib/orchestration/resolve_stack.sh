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
  printf '%s\n' "Usage: ${THIS_FILE} <path_to_config.json> [output_plan.json]"
  printf '%s\n' 'Resolves component dependencies and emits an execution plan.'
  exit 0
fi

if [ -z "${1:-}" ]; then
  printf '[ERROR] Missing required configuration file argument.\n' >&2
  printf 'Usage: %s <path_to_config.json> [output_plan.json]\n' "${THIS_FILE}" >&2
  exit 1
fi

CONFIG_FILE="$1"
OUTPUT_FILE="${2:-}"

if [ ! -f "$CONFIG_FILE" ]; then
  printf '[ERROR] Configuration file does not exist: %s\n' "$CONFIG_FILE" >&2
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
  printf '[ERROR] jq is required but not installed.\n' >&2
  exit 1
fi

# Check if config file is empty or whitespace-only
if [ ! -s "$CONFIG_FILE" ] || ! jq -e '.' "$CONFIG_FILE" >/dev/null 2>&1; then
  if [ -n "$OUTPUT_FILE" ]; then
    OUT_DIR=$(dirname -- "$OUTPUT_FILE")
    if [ ! -d "$OUT_DIR" ]; then
      mkdir -p "$OUT_DIR"
    fi
    printf '%s\n' '{"selected": [], "conflicts": [], "provided": [], "ports": []}' > "$OUTPUT_FILE"
  else
    printf '%s\n' '{"selected": [], "conflicts": [], "provided": [], "ports": []}'
  fi
  exit 0
fi

# Stream all manifests within _lib into a single temporary JSON array file
tmp_manifests=$(mktemp 2>/dev/null || printf '%s' "${TMPDIR:-/tmp}/libscript_manifests.$$")
trap 'rm -f "$tmp_manifests"' EXIT INT TERM
find "${LIBSCRIPT_ROOT_DIR}/_lib" -name "manifest.json" -exec jq -s '.' {} + 2>/dev/null | jq -s 'add // []' > "$tmp_manifests" 2>/dev/null || printf '[]\n' > "$tmp_manifests"
if [ ! -s "$tmp_manifests" ]; then
  printf '[]\n' > "$tmp_manifests"
fi

# Execute resolution
if [ -n "$OUTPUT_FILE" ]; then
  OUT_DIR=$(dirname -- "$OUTPUT_FILE")
  if [ ! -d "$OUT_DIR" ]; then
    mkdir -p "$OUT_DIR"
  fi
  jq --arg target_os "$TARGET_OS" --slurpfile manifests "$tmp_manifests" -n '{config: input, manifests: ($manifests[0] // [])}' "$CONFIG_FILE" | jq -L "${LIBSCRIPT_ROOT_DIR}/_lib/utilities" -L "${SCRIPT_DIR}" --arg target_os "$TARGET_OS" -r -f "${SCRIPT_DIR}/resolve_stack.jq" > "$OUTPUT_FILE"
  printf '[INFO] Execution plan generated at %s\n' "$OUTPUT_FILE"
else
  jq --arg target_os "$TARGET_OS" --slurpfile manifests "$tmp_manifests" -n '{config: input, manifests: ($manifests[0] // [])}' "$CONFIG_FILE" | jq -L "${LIBSCRIPT_ROOT_DIR}/_lib/utilities" -L "${SCRIPT_DIR}" --arg target_os "$TARGET_OS" -r -f "${SCRIPT_DIR}/resolve_stack.jq"
fi
rm -f "$tmp_manifests"
