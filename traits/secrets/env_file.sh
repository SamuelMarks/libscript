#!/bin/sh
# ## Overview
# Ingests PaaS secrets_dir dotenv files without exporting variables into the process environment.
#
# ## Usage
# ./traits/secrets/env_file.sh <env_file_path>

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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

# ## read_env_secret_file
# Emits sanitized KEY=VALUE lines from a secrets_dir file.
read_env_secret_file() {
  ef="${1:-}"
  if [ ! -f "$ef" ]; then
    printf '[ERROR] Secret env file not found: %s\n' "$ef" >&2
    return 1
  fi
  grep -v '^[[:space:]]*#' "$ef" | grep '=' || true
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 <env_file_path>"
  exit 0
fi

read_env_secret_file "${1:-}"
