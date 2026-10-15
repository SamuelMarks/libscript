#!/bin/sh
# ## Overview
# Fetches KV v2 secrets from OpenBao (_lib/security/openbao) or HashiCorp Vault and emits KEY=VALUE to stdout.
#
# ## Usage
# ./traits/secrets/openbao.sh <secret_path>

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

# ## fetch_openbao_kv
# Queries OpenBao/Vault KV v2 endpoint or falls back to local mock store during tests.
fetch_openbao_kv() {
  sec_path="${1:-secret/data/default}"
  if command -v bao >/dev/null 2>&1 && [ -n "${BAO_ADDR:-}" ]; then
    bao kv get -format=json "$sec_path" | jq -r '.data.data | to_entries[] | "\(.key)=\(.value)"'
  elif [ -n "${LIBSCRIPT_MOCK_OPENBAO_FILE:-}" ] && [ -f "${LIBSCRIPT_MOCK_OPENBAO_FILE}" ]; then
    cat "${LIBSCRIPT_MOCK_OPENBAO_FILE}"
  else
    printf 'OPENBAO_PATH=%s\n' "$sec_path"
  fi
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 <secret_path>"
  exit 0
fi

fetch_openbao_kv "${1:-secret/data/default}"
