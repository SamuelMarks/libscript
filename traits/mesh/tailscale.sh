#!/bin/sh
# ## Overview
# Joins a node idempotently to a Tailscale tailnet overlay using a pre-authentication key.
#
# ## Usage
# ./traits/mesh/tailscale.sh [--authkey <key>]

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

# ## join_tailnet
# Brings up tailscale with the provided authkey if not already connected.
join_tailnet() {
  if command -v tailscale >/dev/null 2>&1 && [ "${LIBSCRIPT_TARGET_SYSROOT:-/}" = "/" ]; then
    tailscale status >/dev/null 2>&1 || tailscale up --authkey="${TAILSCALE_AUTHKEY:-}" --accept-routes
  fi
  printf '[INFO] Tailscale mesh trait applied.\n'
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 [--authkey <key>]"
  exit 0
fi

join_tailnet
