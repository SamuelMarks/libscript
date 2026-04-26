#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'
# Resolve component directory and root
DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"
export LIBSCRIPT_ROOT_DIR

# Common directories
LIBSCRIPT_BUILD_DIR="${LIBSCRIPT_BUILD_DIR:-${TMPDIR:-/tmp}/libscript_build}"
LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"
export LIBSCRIPT_BUILD_DIR LIBSCRIPT_DATA_DIR

# Common path setup
PATH="${HOME}/.cargo/bin:${HOME}/.local/share/fnm/aliases/default/bin:${LIBSCRIPT_DATA_DIR}/bin:${PATH}"
export PATH

[ -d "${LIBSCRIPT_BUILD_DIR}" ] || mkdir -p -- "${LIBSCRIPT_BUILD_DIR}"
[ -d "${LIBSCRIPT_DATA_DIR}" ] || mkdir -p -- "${LIBSCRIPT_DATA_DIR}"

# Source component-specific environment if exists
env_script="${DIR}"'/env.sh'
if [ -f "${env_script}" ]; then
  SCRIPT_NAME="${env_script}"
  export SCRIPT_NAME
  . "${SCRIPT_NAME}"
fi

# -----------------------------------------------------------------------------
# Testing Assertions
# -----------------------------------------------------------------------------

# Usage: assert_version <cmd> <expected_pattern>
assert_version() {
  cmd="${1:-}"
  expected="${2:-}"
  if [ -z "$cmd" ] || ! command -v "$cmd" >/dev/null 2>&1; then
    printf "[FAIL] %s command not found\n" "$cmd" >&2
    return 1
  fi
  version=$("$cmd" --version 2>&1 | head -n 1)
  if echo "$version" | grep -qi "$expected"; then
    printf "[PASS] %s version check: %s\n" "$cmd" "$version" >&2
  else
    printf "[FAIL] %s version check failed. Expected pattern: %s, Got: %s\n" "$cmd" "$expected" "$version" >&2
    return 1
  fi
}

# Usage: assert_service_up <host> <port> [timeout]
assert_service_up() {
  host="${1:-}"
  port="${2:-}"
  timeout="${3:-10}"
  printf "[INFO] Waiting for service at %s:%s (timeout %ss)...\n" "$host" "$port" "$timeout" >&2
  if command -v nc >/dev/null 2>&1; then
    for i in $(seq 1 "$timeout"); do
      if nc -z "$host" "$port" >/dev/null 2>&1; then
        printf "[PASS] Service at %s:%s is UP\n" "$host" "$port" >&2
        return 0
      fi
      sleep 1
    done
  else
    printf "[WARN] nc not found, skipping service check for %s:%s\n" "$host" "$port" >&2
  fi
  printf "[FAIL] Service at %s:%s is DOWN\n" "$host" "$port" >&2
  return 1
}

# Usage: assert_exists <path>
assert_exists() {
  if [ -e "${1:-}" ]; then
    printf "[PASS] Exists: %s\n" "${1:-}" >&2
  else
    printf "[FAIL] MISSING: %s\n" "${1:-}" >&2
    return 1
  fi
}
