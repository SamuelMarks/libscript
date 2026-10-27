#!/bin/sh
# ## Overview
# Provides a unified logging utility for LibScript (POSIX compliant).
# It defines standardized logging functions (debug, info, success, warn, error,
# step, create, reuse, upsert, daemon, route, build, db) that output structured
# messages in text or JSON format to standard error and optionally to a file.
#
# ## Usage
# Source this file to make `log_info`, `log_error`, etc. available.
# Configure behavior via `LIBSCRIPT_LOG_LEVEL`, `LIBSCRIPT_LOG_FORMAT`, and `LIBSCRIPT_LOG_FILE`.


set -feu
_log_caller_this="${THIS_FILE:-}"; _log_caller_dir="${SCRIPT_DIR:-}"
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
    [ -n "$_log_caller_this" ] && THIS_FILE="$_log_caller_this"
    [ -n "$_log_caller_dir" ] && SCRIPT_DIR="$_log_caller_dir"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
# LibScript Unified Logging Utility (POSIX)

# Levels: 0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR
LIBSCRIPT_LOG_LEVEL="${LIBSCRIPT_LOG_LEVEL:-1}"
LIBSCRIPT_LOG_FORMAT="${LIBSCRIPT_LOG_FORMAT:-text}"
LIBSCRIPT_LOG_FILE="${LIBSCRIPT_LOG_FILE:-}"

# ## _libscript_log_msg
# Formats and emits a timestamped log message at the specified severity level.
_libscript_log_msg() {
  level_name="${1:-}"
  level_num="${2:-}"
  msg="${3:-}"

  if [ "${level_num:-0}" -lt "$LIBSCRIPT_LOG_LEVEL" ]; then
    return
  fi

  timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)

  if [ "$LIBSCRIPT_LOG_FORMAT" = "json" ]; then
    if command -v jq >/dev/null 2>&1; then
      json_out=$(jq -n --arg ts "$timestamp" --arg lvl "$level_name" --arg msg "$msg" \
        '{timestamp: $ts, level: $lvl, message: $msg}')
    else
      clean_msg=$(printf '%s' "$msg" | sed 's/"/\\"/g')
      json_out="{\"timestamp\":\"$timestamp\",\"level\":\"$level_name\",\"message\":\"$clean_msg\"}"
    fi

    [ -n "$LIBSCRIPT_LOG_FILE" ] && printf '%s\n' "$json_out" >> "$LIBSCRIPT_LOG_FILE"
    printf '%s\n' "$json_out"
  else
    text_out="[$level_name] $msg"

    [ -n "$LIBSCRIPT_LOG_FILE" ] && printf '%s %s\n' "$timestamp" "$text_out" >> "$LIBSCRIPT_LOG_FILE"

    printf '%s\n' "$text_out" >&2
  fi
}

# ## log_debug
# Logs a debug message.
log_debug()   { _libscript_log_msg "DEBUG"   0 "${1:-}"; }
# ## log_info
# Logs an informational message.
log_info()    { _libscript_log_msg "INFO"    1 "${1:-}"; }
# ## log_success
# Logs a success confirmation message.
log_success() { _libscript_log_msg "SUCCESS" 2 "${1:-}"; }
# ## log_warn
# Logs a warning message.
log_warn()    { _libscript_log_msg "WARN"    3 "${1:-}"; }
# ## log_error
# Logs an error message.
log_error()   { _libscript_log_msg "ERROR"   4 "${1:-}"; }
# ## log_err
# Alias for log_error.
log_err()     { _libscript_log_msg "ERROR"   4 "${1:-}"; }
# ## log_step
# Logs a high-level execution step message.
log_step()    { _libscript_log_msg "STEP"    1 "${1:-}"; }
# ## log_create
# Logs a resource or artifact creation message.
log_create()  { _libscript_log_msg "CREATE"  1 "${1:-}"; }
# ## log_reuse
# Logs a resource or artifact reuse/confirmation message.
log_reuse()   { _libscript_log_msg "REUSE"   1 "${1:-}"; }
# ## log_upsert
# Logs a database or state upsert message.
log_upsert()  { _libscript_log_msg "UPSERT"  1 "${1:-}"; }
# ## log_daemon
# Logs a service daemon lifecycle action message.
log_daemon()  { _libscript_log_msg "DAEMON"  1 "${1:-}"; }
# ## log_route
# Logs an ingress route configuration message.
log_route()   { _libscript_log_msg "ROUTE"   1 "${1:-}"; }
# ## log_build
# Logs a frontend or application build message.
log_build()   { _libscript_log_msg "BUILD"   1 "${1:-}"; }
# ## log_db
# Logs a database provisioning or confirmation message.
log_db()      { _libscript_log_msg "DB"      1 "${1:-}"; }

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_log_caller_dir:-}" ] && SCRIPT_DIR="$_log_caller_dir"
[ -n "${_log_caller_this:-}" ] && THIS_FILE="$_log_caller_this"
unset _log_caller_this _log_caller_dir || true
