#!/bin/sh
# ## Overview
# Command-line interface for DuckDB.
#
# ## Usage
# Wraps the `duckdb` binary to provide execution (`execute`) and interactive (`repl`) commands.

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
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
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"

for LIB in _lib/_common/pkg_mgr.sh _lib/_common/log.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 <action> [args...]"
  printf '%s\n' "See README.md for details."
  exit 0
fi

# Ensure duckdb is available
if ! command -v duckdb >/dev/null 2>&1; then
  if [ -x "${LIBSCRIPT_ROOT_DIR}/installed/duckdb/bin/duckdb" ]; then
    export PATH="${LIBSCRIPT_ROOT_DIR}/installed/duckdb/bin:${PATH}"
  else
    log_error "duckdb not found. Please install the databases/duckdb component first."
    exit 1
  fi
fi

ACTION="${1:-}"

case "$ACTION" in
  execute)
    DB_PATH="${2:-:memory:}"
    QUERY="${3:-}"
    if [ -z "$QUERY" ]; then
      log_error "Usage: duckdb execute <db_path> <query>"
      exit 1
    fi
    log_info "Executing query on DuckDB $DB_PATH..."
    duckdb "$DB_PATH" -c "$QUERY"
    ;;
  repl)
    DB_PATH="${2:-:memory:}"
    log_info "Starting DuckDB REPL on $DB_PATH..."
    duckdb "$DB_PATH"
    ;;
  *)
    log_error "Unknown action: $ACTION. Supported: execute, repl."
    exit 1
    ;;
esac
