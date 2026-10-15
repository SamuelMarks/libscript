#!/bin/sh
# ## Overview
# Delegates safe template rendering to _lib/_common/envsubst_safe.sh and _lib/_common/find_replace.sh.
#
# ## Usage
# ./traits/secrets/render.sh <template_file> <output_file> [secrets_kv_file]

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

# ## print_usage
# Prints usage instructions for traits/secrets/render.sh.
print_usage() {
  printf '%s\n' "Usage: $0 <template_file> <output_file> [secrets_kv_file]"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  print_usage
  exit 0
fi

TPL_FILE="${1:-}"
OUT_FILE="${2:-}"
SECRETS_FILE="${3:-}"

if [ -z "$TPL_FILE" ] || [ -z "$OUT_FILE" ]; then
  print_usage >&2
  exit 1
fi

mkdir -p "$(dirname -- "$OUT_FILE")"
cp -f "$TPL_FILE" "$OUT_FILE"
chmod 0600 "$OUT_FILE" 2>/dev/null || true

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/find_replace.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

if [ -n "$SECRETS_FILE" ] && [ -f "$SECRETS_FILE" ]; then
  while IFS='=' read -r k v || [ -n "$k" ]; do
    case "$k" in
      ''|'#'*) continue ;;
    esac
    token="\${${k}}"
    find_replace "$token" "$v" "$OUT_FILE" > "${OUT_FILE}.tmp"
    mv -f "${OUT_FILE}.tmp" "$OUT_FILE"
  done < "$SECRETS_FILE"
else
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/envsubst_safe.sh"
  export SCRIPT_NAME
  "${LIBSCRIPT_ROOT_DIR}/_lib/_common/envsubst_safe.sh" "$TPL_FILE" "$OUT_FILE"
fi
