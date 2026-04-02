#!/bin/sh
# LibScript Unified Logging Utility (POSIX)

# Levels: 0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR
LIBSCRIPT_LOG_LEVEL="${LIBSCRIPT_LOG_LEVEL:-1}"
LIBSCRIPT_LOG_FORMAT="${LIBSCRIPT_LOG_FORMAT:-text}"
LIBSCRIPT_LOG_FILE="${LIBSCRIPT_LOG_FILE:-}"

_libscript_log_msg() {
  level_name="$1"
  level_num="$2"
  msg="$3"
  
  if [ "$level_num" -lt "$LIBSCRIPT_LOG_LEVEL" ]; then
    return
  fi

  timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)

  if [ "$LIBSCRIPT_LOG_FORMAT" = "json" ]; then
    # Simple JSON construction without requiring jq for the log itself if possible,
    # but jq is safer for escaping. Fallback to manual if jq missing.
    if command -v jq >/dev/null 2>&1; then
      json_out=$(jq -n --arg ts "$timestamp" --arg lvl "$level_name" --arg msg "$msg" \
        '{timestamp: $ts, level: $lvl, message: $msg}')
    else
      # Manual escape (basic)
      clean_msg=$(printf '%s' "$msg" | sed 's/"/\\"/g')
      json_out="{\"timestamp\":\"$timestamp\",\"level\":\"$level_name\",\"message\":\"$clean_msg\"}"
    fi
    
    [ -n "$LIBSCRIPT_LOG_FILE" ] && printf '%s\n' "$json_out" >> "$LIBSCRIPT_LOG_FILE"
    printf '%s\n' "$json_out"
  else
    # Text format: [LEVEL] Message
    text_out="[$level_name] $msg"
    
    [ -n "$LIBSCRIPT_LOG_FILE" ] && printf '%s %s\n' "$timestamp" "$text_out" >> "$LIBSCRIPT_LOG_FILE"
    
    # Use stderr for logs to keep stdout clean for data/piping
    printf '%s\n' "$text_out" >&2
  fi
}

log_debug()   { _libscript_log_msg "DEBUG"   0 "$1"; }
log_info()    { _libscript_log_msg "INFO"    1 "$1"; }
log_success() { _libscript_log_msg "SUCCESS" 2 "$1"; }
log_warn()    { _libscript_log_msg "WARN"    3 "$1"; }
log_error()   { _libscript_log_msg "ERROR"   4 "$1"; }
