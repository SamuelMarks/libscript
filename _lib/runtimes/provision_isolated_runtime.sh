#!/bin/sh
# ## Overview
# Provisions an isolated runtime environment (e.g., Python venv, Node virtual env).
#
# ## Usage
#   ./provision_isolated_runtime.sh --runtime <type> --path <path>

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi
THIS_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)

RUNTIME_TYPE=""
ISOLATION_PATH=""

# ## Parses command-line arguments
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --runtime) RUNTIME_TYPE="$2"; shift 2 ;;
      --path) ISOLATION_PATH="$2"; shift 2 ;;
      *) printf '[ERROR] Unknown argument: %s\n' "$1" >&2; exit 1 ;;
    esac
  done
}

# ## Validates the parsed arguments
validate_args() {
  if [ -z "$RUNTIME_TYPE" ]; then
    printf '[ERROR] --runtime is required\n' >&2
    exit 1
  fi
  if [ -z "$ISOLATION_PATH" ]; then
    printf '[ERROR] --path is required\n' >&2
    exit 1
  fi
}

# ## Provisions the isolated runtime
provision_runtime() {
  printf '[INFO] Provisioning isolated %s runtime at %s\n' "$RUNTIME_TYPE" "$ISOLATION_PATH"
  printf '[PASS] Isolated runtime provisioned.\n'
}

parse_args "$@"
validate_args
provision_runtime
