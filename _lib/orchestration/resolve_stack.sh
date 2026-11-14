#!/bin/sh
# ## Overview
# Portable dependency resolver and multi-kernel execution plan generator using jq.
# ## Usage
# ./_lib/orchestration/resolve_stack.sh <path_to_config.json> [output_plan.json]

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

if [ -z "${UNAME_LOWER:-}" ]; then
  _rs_oi_this="${THIS_FILE}"
  _rs_oi_dir="${SCRIPT_DIR}"
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/os_info.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
  THIS_FILE="${_rs_oi_this}"
  SCRIPT_DIR="${_rs_oi_dir}"
  unset _rs_oi_this _rs_oi_dir || true
fi

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
  if ! command -v jq >/dev/null 2>&1; then
    printf '[ERROR] jq is required and could not be bootstrapped.\n' >&2
    return 1
  fi
  return 0
}

ensure_jq_available

if [ -z "${LIBSCRIPT_TARGET_OS:-}" ]; then
  OS_NAME="${UNAME_LOWER:-linux}"
  case "$OS_NAME" in
    linux*) TARGET_OS='linux' ;;
    darwin*) TARGET_OS='darwin' ;;
    freebsd*) TARGET_OS='freebsd' ;;
    sunos*|illumos*) TARGET_OS='sunos' ;;
    msys*|cygwin*|mingw*) TARGET_OS='windows' ;;
    *) TARGET_OS="$OS_NAME" ;;
  esac
else
  TARGET_OS="$LIBSCRIPT_TARGET_OS"
fi

if [ ! -s "$CONFIG_FILE" ] || ! jq -e '.' "$CONFIG_FILE" >/dev/null 2>&1; then
  if [ -n "$OUTPUT_FILE" ]; then
    OUT_DIR=$(dirname -- "$OUTPUT_FILE")
    mkdir -p "$OUT_DIR"
    printf '%s\n' '{"selected": [], "conflicts": [], "provided": [], "ports": []}' > "$OUTPUT_FILE"
  else
    printf '%s\n' '{"selected": [], "conflicts": [], "provided": [], "ports": []}'
  fi
  exit 0
fi

_rs_cache_dir="${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}"
mkdir -p "$_rs_cache_dir" 2>/dev/null || _rs_cache_dir="${TMPDIR:-/tmp}"
_rs_catalog="${_rs_cache_dir}/manifests_catalog_v2.json"
_rs_catalog_meta="${_rs_cache_dir}/manifests_catalog_v2.meta"
_rs_mf_count=$(find "${LIBSCRIPT_ROOT_DIR}/_lib" -name "manifest.json" 2>/dev/null | wc -l | tr -d ' ')
_rs_use_cache=0
if [ -s "$_rs_catalog" ] && [ -f "$_rs_catalog_meta" ] && [ "$(cat "$_rs_catalog_meta" 2>/dev/null || true)" = "$_rs_mf_count" ]; then
  _rs_newer=$(find "${LIBSCRIPT_ROOT_DIR}/_lib" -name "manifest.json" -newer "$_rs_catalog" 2>/dev/null | head -n 1 || true)
  if [ -z "$_rs_newer" ]; then
    _rs_use_cache=1
  fi
fi

if [ "$_rs_use_cache" -eq 1 ]; then
  tmp_manifests="$_rs_catalog"
else
  tmp_manifests=$(mktemp 2>/dev/null || printf '%s' "${TMPDIR:-/tmp}/libscript_manifests.$$")
  find "${LIBSCRIPT_ROOT_DIR}/_lib" -name "manifest.json" -exec jq '{ _manifest_dir: (input_filename | sub("^.*[/\\\\]_lib[/\\\\]"; "_lib/") | gsub("\\\\"; "/") | sub("/manifest\\.json$"; "")) } + .' {} + 2>/dev/null | jq -s '.' > "$tmp_manifests" 2>/dev/null || printf '[]\n' > "$tmp_manifests"
  if mv -f "$tmp_manifests" "$_rs_catalog" 2>/dev/null; then
    printf '%s\n' "$_rs_mf_count" > "$_rs_catalog_meta" 2>/dev/null || true
    tmp_manifests="$_rs_catalog"
  fi
fi

if [ -n "$OUTPUT_FILE" ]; then
  OUT_DIR=$(dirname -- "$OUTPUT_FILE")
  mkdir -p "$OUT_DIR"
  jq -s '{config: .[1], manifests: .[0]}' "$tmp_manifests" "$CONFIG_FILE" | jq -L "${LIBSCRIPT_ROOT_DIR}/_lib/utilities" -L "${SCRIPT_DIR}" --arg target_os "$TARGET_OS" -f "${SCRIPT_DIR}/resolve_stack.jq" > "$OUTPUT_FILE"
  printf '[INFO] Execution plan generated at %s\n' "$OUTPUT_FILE"
else
  jq -s '{config: .[1], manifests: .[0]}' "$tmp_manifests" "$CONFIG_FILE" | jq -L "${LIBSCRIPT_ROOT_DIR}/_lib/utilities" -L "${SCRIPT_DIR}" --arg target_os "$TARGET_OS" -r -f "${SCRIPT_DIR}/resolve_stack.jq"
fi

if [ "$tmp_manifests" != "$_rs_catalog" ]; then
  rm -f "$tmp_manifests"
fi
