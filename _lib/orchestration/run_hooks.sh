#!/bin/sh
# ## Overview
# Executes defined lifecycle hooks from an install manifest on Unix-like systems.
# Supports both .hooks and .lifecycle_hooks (including under .infrastructure), working_dir, OS filtering, and conditional execution.
#
# ## Usage
# Run `run_hooks.sh <json_file> <hook_type>` (e.g. pre_install, post_install, build, db_migrate, seed, pre_start, post_start, pre_stop, post_stop, health) to parse and execute commands.

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
# @description Automatically handles run_hooks for the run_hooks.sh (orchestration) component.
# @file run_hooks.sh

case "${1:-}" in
  --help|-h|"-?"|"/?")
    printf '%s\n' 'Usage: run_hooks.sh <json_file> <hook_type>'
    printf '%s\n' 'Supported hook types: pre_install, post_install, build, db_migrate, seed, pre_start, post_start, pre_stop, post_stop, health'
    exit 0
    ;;
esac

JSON_FILE="${1:-}"
HOOK_TYPE="${2:-}"

SCRIPT_DIR=$(cd "${SCRIPT_DIR}" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
# shellcheck disable=SC1090,SC1091
_ls_src_this="${THIS_FILE:-}"; _ls_src_dir="${SCRIPT_DIR:-}"
SCRIPT_NAME="$LIBSCRIPT_ROOT_DIR/_lib/_common/log.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true
[ -n "${_ls_src_this:-}" ] && THIS_FILE="$_ls_src_this"
[ -n "${_ls_src_dir:-}" ] && SCRIPT_DIR="$_ls_src_dir"

if [ -z "$JSON_FILE" ] || [ -z "$HOOK_TYPE" ] || [ ! -f "$JSON_FILE" ]; then
  exit 0
fi

MANIFEST_DIR=$(cd -- "$(dirname -- "$JSON_FILE")" && pwd)

if [ -f "$LIBSCRIPT_ROOT_DIR/_lib/_common/env_printer.sh" ]; then
  SCRIPT_NAME="$LIBSCRIPT_ROOT_DIR/_lib/_common/env_printer.sh"
  # shellcheck disable=SC1090
  . "$SCRIPT_NAME"
  unset SCRIPT_NAME || true
  libscript_hydrate_manifest_env "$JSON_FILE" || true
fi
if [ -n "${SERVICE_PATH:-}" ]; then
  export PATH="${SERVICE_PATH}:${PATH}"
fi
if [ -n "${SERVICE_EXTRA_PATH:-}" ]; then
  export PATH="${SERVICE_EXTRA_PATH}:${PATH}"
fi

if [ -z "${LIBSCRIPT_TARGET_OS:-}" ]; then
  OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
  case "$OS_NAME" in
    linux*) CURRENT_OS="linux" ;;
    darwin*) CURRENT_OS="darwin" ;;
    freebsd*) CURRENT_OS="freebsd" ;;
    msys*|cygwin*|mingw*) CURRENT_OS="windows" ;;
    *) CURRENT_OS="$OS_NAME" ;;
  esac
else
  CURRENT_OS="$LIBSCRIPT_TARGET_OS"
fi

HOOKS=$(jq -c --arg ht "$HOOK_TYPE" '((.hooks[$ht] // .infrastructure.hooks[$ht] // []) + (.lifecycle_hooks[$ht] // .infrastructure.lifecycle_hooks[$ht] // []))[]?' "$JSON_FILE" 2>/dev/null || true)

if [ -z "$HOOKS" ]; then
  exit 0
fi

# ## resolve_hook_path
# Resolves a path relative to the hook working directory if not absolute.
resolve_hook_path() {
  _hp="$1"
  _wd="$2"
  if [ "${_hp#/}" != "$_hp" ]; then
    printf '%s\n' "$_hp"
  else
    printf '%s\n' "${_wd}/${_hp}"
  fi
}

log_info "[HOOKS:${HOOK_TYPE}] Running ${HOOK_TYPE} lifecycle hooks from ${JSON_FILE}..."
while IFS= read -r hook <&3; do
  [ -n "$hook" ] || continue
  if printf '%s\n' "$hook" | grep -q '^{'; then
    NAME=$(printf '%s\n' "$hook" | jq -r '.name // "unnamed_hook"')
    cmd=$(printf '%s\n' "$hook" | jq -r '.command // empty')
    COND=$(printf '%s\n' "$hook" | jq -r '.condition // empty')
    RAW_WD=$(printf '%s\n' "$hook" | jq -r '.working_dir // .cwd // "."')

    # OS filter check
    OS_MATCH=$(printf '%s\n' "$hook" | jq -r --arg os "$CURRENT_OS" '
      (.os // .platform) as $p |
      if $p == null then "1"
      elif ($p | type) == "string" then (if ($p | ascii_downcase) == $os or ($p | ascii_downcase) == "all" or ($p | ascii_downcase) == "posix" or ($p | ascii_downcase) == "unix" then "1" else "0" end)
      elif ($p | type) == "array" then (if ([ $p[] | ascii_downcase ] | index($os) != null or index("all") != null or index("posix") != null or index("unix") != null) then "1" else "0" end)
      else "1" end
    ' 2>/dev/null || printf '1')

    if [ "$OS_MATCH" = "0" ]; then
      log_info "[HOOK:${HOOK_TYPE}] Skipping hook '$NAME': OS filter does not match $CURRENT_OS"
      continue
    fi

    if [ -z "$RAW_WD" ] || [ "$RAW_WD" = "." ]; then
      HOOK_WD="$MANIFEST_DIR"
    elif [ "${RAW_WD#/}" != "$RAW_WD" ]; then
      HOOK_WD="$RAW_WD"
    else
      HOOK_WD="${MANIFEST_DIR}/${RAW_WD}"
    fi

    if [ -n "$COND" ]; then
      if printf '%s\n' "$COND" | grep -q "^unless_exists "; then
        FILE=$(printf '%s\n' "$COND" | sed 's/^unless_exists //')
        TARGET_FILE=$(resolve_hook_path "$FILE" "$HOOK_WD")
        if [ -e "$TARGET_FILE" ] || [ -e "$FILE" ]; then
          log_info "[HOOK:${HOOK_TYPE}] Skipping hook '$NAME': $FILE exists"
          continue
        fi
      elif printf '%s\n' "$COND" | grep -q "^if_exists "; then
        FILE=$(printf '%s\n' "$COND" | sed 's/^if_exists //')
        TARGET_FILE=$(resolve_hook_path "$FILE" "$HOOK_WD")
        if [ ! -e "$TARGET_FILE" ] && [ ! -e "$FILE" ]; then
          log_info "[HOOK:${HOOK_TYPE}] Skipping hook '$NAME': $FILE does not exist"
          continue
        fi
      elif printf '%s\n' "$COND" | grep -q "^unless_command "; then
        CHK_CMD=$(printf '%s\n' "$COND" | sed 's/^unless_command //')
        if command -v "$CHK_CMD" >/dev/null 2>&1; then
          log_info "[HOOK:${HOOK_TYPE}] Skipping hook '$NAME': command $CHK_CMD already in PATH"
          continue
        fi
      fi
    fi

    if [ -n "$cmd" ]; then
      _h_start=$(date +%s 2>/dev/null || printf '0')
      log_info "[HOOK:${HOOK_TYPE}] ($NAME) working_dir=${HOOK_WD}: Executing hook..."
      _hook_path="${PATH:-/usr/bin:/bin}"
      for _hw_bin in "${MANIFEST_DIR}/.venv/bin" "${MANIFEST_DIR}/node_modules/.bin" "${HOOK_WD}/.venv/bin" "${HOOK_WD}/node_modules/.bin"; do
        if [ -d "$_hw_bin" ]; then
          case ":${_hook_path}:" in
            *":${_hw_bin}:"*) ;;
            *) _hook_path="${_hw_bin}:${_hook_path}" ;;
          esac
        fi
      done
      if ! (
        cd "$HOOK_WD"
        PATH="$_hook_path" sh -c "$cmd"
      ); then
        log_error "[HOOK:${HOOK_TYPE}] ($NAME) failed with non-zero exit status: $cmd"
        exit 1
      fi
      _h_end=$(date +%s 2>/dev/null || printf '0')
      _h_dur=$((_h_end - _h_start))
      log_info "[HOOK:${HOOK_TYPE}] ($NAME) completed in ${_h_dur}s"
    fi
  else
    cmd=$(printf '%s\n' "$hook" | sed 's/^"//; s/"$//')
    if [ -n "$cmd" ]; then
      _h_start=$(date +%s 2>/dev/null || printf '0')
      log_info "[HOOK:${HOOK_TYPE}] (inline) working_dir=${MANIFEST_DIR}: Executing hook..."
      _hook_path="${PATH:-/usr/bin:/bin}"
      for _hw_bin in "${MANIFEST_DIR}/.venv/bin" "${MANIFEST_DIR}/node_modules/.bin"; do
        if [ -d "$_hw_bin" ]; then
          case ":${_hook_path}:" in
            *":${_hw_bin}:"*) ;;
            *) _hook_path="${_hw_bin}:${_hook_path}" ;;
          esac
        fi
      done
      if ! (
        cd "$MANIFEST_DIR"
        PATH="$_hook_path" sh -c "$cmd"
      ); then
        log_error "[HOOK:${HOOK_TYPE}] (inline) failed with non-zero exit status: $cmd"
        exit 1
      fi
      _h_end=$(date +%s 2>/dev/null || printf '0')
      _h_dur=$((_h_end - _h_start))
      log_info "[HOOK:${HOOK_TYPE}] (inline) completed in ${_h_dur}s"
    fi
  fi
done 3<< EOF_HOOKS
$HOOKS
EOF_HOOKS
