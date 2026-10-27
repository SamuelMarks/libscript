#!/bin/sh
# ## Overview
# Verifies hooks/announce -> netctl emission across nginx, caddy, apache, iis, and traefik via traits/ingress/route.sh.
#
# ## Usage
# ./tests/test_ingress_netctl_bridge.sh

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

for fmt in nginx caddy apache iis traefik; do
  out="$(SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/traits/ingress/route.sh" sh "${LIBSCRIPT_ROOT_DIR}/traits/ingress/route.sh" "$fmt" postgres /api)"
  printf '%s\n' "$out" | grep -q '127.0.0.1:5432'
done

printf '[PASS] Ingress netctl bridge verified across nginx, caddy, apache, iis, and traefik.\n'
