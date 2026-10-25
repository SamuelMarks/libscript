#!/bin/sh
# ## Overview
# Queries hooks/announce and drives _lib/networking/netctl/cli.sh to emit and validate nginx, caddy, apache, iis, or traefik configs.
#
# ## Usage
# ./traits/ingress/route.sh <emit_format> [component] [path] [output_file]

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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/hooks.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 <nginx|caddy|apache|iis|traefik> [component] [path] [output_file]"
  exit 0
fi

if [ "${1:-}" = "remove-ingress" ] || [ "${1:-}" = "unroute" ]; then
  shift
  exec "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" remove-ingress "${1:-libscript.json}"
fi

FORMAT="${1:-nginx}" 
COMP="${2:-postgres}"
ROUTE_PATH="${3:-/}"
OUT_FILE="${4:-}"

# ## emit_and_validate_route
# Queries component announce hook, invokes netctl, and validates generated configuration.
emit_and_validate_route() {
  ann="$(libscript_exec_hook "$COMP" "announce")"
  port="$(printf '%s\n' "$ann" | jq -r '.port // 8080')"
  target_url="http://127.0.0.1:${port}"
  NETCTL_CLI="${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh"
  rendered="$(SCRIPT_NAME="$NETCTL_CLI" sh "$NETCTL_CLI" --listen 80 --proxy "$ROUTE_PATH" "$target_url" --emit "$FORMAT")"
  if [ -n "$OUT_FILE" ]; then
    mkdir -p "$(dirname -- "$OUT_FILE")"
    if [ -f "$OUT_FILE" ]; then
      cp -f "$OUT_FILE" "${OUT_FILE}.bak"
    fi
    printf '%s\n' "$rendered" > "$OUT_FILE"
  else
    printf '%s\n' "$rendered"
  fi
}

emit_and_validate_route
