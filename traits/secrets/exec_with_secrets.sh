#!/bin/sh
# ## Overview
# Zero-Env-Leak wrapper streaming secrets via 0700 RAM-backed storage or 0600 FIFO without polluting /proc/<pid>/environ.
#
# ## Usage
# ./traits/secrets/exec_with_secrets.sh --source <secrets_file> --template <tpl> --output <out> [-- <cmd> [args...]]

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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

if [ -d "/dev/shm" ] && [ -w "/dev/shm" ]; then
  RAM_BASE='/dev/shm'
else
  RAM_BASE="${TMPDIR:-/tmp}"
fi

SECRET_WORK_DIR="$(mktemp -d "${RAM_BASE}/libscript-sec.XXXXXX")"
chmod 0700 "$SECRET_WORK_DIR"
FIFO_PATH="${SECRET_WORK_DIR}/secret.pipe"

# ## cleanup_secret_pipe
# Shreds and removes temporary secret directory and FIFO on exit or signal.
cleanup_secret_pipe() {
  rm -rf "$SECRET_WORK_DIR"
}
trap cleanup_secret_pipe EXIT INT TERM

SOURCE_FILE=""
TPL_FILE=""
OUT_FILE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --source) SOURCE_FILE="$2"; shift 2 ;;
    --template) TPL_FILE="$2"; shift 2 ;;
    --output) OUT_FILE="$2"; shift 2 ;;
    --) shift; break ;;
    --help|-h)
      printf '%s\n' "Usage: $0 --source <secrets_file> [--template <tpl> --output <out>] [-- <cmd> [args...]]"
      exit 0
      ;;
    *) break ;;
  esac
done

STAGE_FILE="${SECRET_WORK_DIR}/secret.kv"
umask 0077
if [ -n "$SOURCE_FILE" ] && [ -f "$SOURCE_FILE" ]; then
  cp -f "$SOURCE_FILE" "$STAGE_FILE"
else
  : > "$STAGE_FILE"
fi
chmod 0600 "$STAGE_FILE"

if [ -n "$TPL_FILE" ] && [ -n "$OUT_FILE" ]; then
  SCRIPT_NAME="${SCRIPT_DIR}/render.sh"
  export SCRIPT_NAME
  sh "${SCRIPT_DIR}/render.sh" "$TPL_FILE" "$OUT_FILE" "$STAGE_FILE"
fi

if [ $# -gt 0 ]; then
  mkfifo -m 0600 "$FIFO_PATH" 2>/dev/null || cp -f "$STAGE_FILE" "$FIFO_PATH"
  if [ -p "$FIFO_PATH" ]; then
    cat "$STAGE_FILE" > "$FIFO_PATH" &
  fi
  "$@" --secrets-file "$FIFO_PATH"
fi
