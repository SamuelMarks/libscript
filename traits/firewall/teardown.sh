#!/bin/sh
# ## Overview
# Idempotently prunes LibScript-managed component firewall rules upon teardown or uninstall.
#
# ## Usage
# ./traits/firewall/teardown.sh [component]

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

# ## prune_firewall_rules
# Removes component-specific firewall rules or the managed firewall block.
prune_firewall_rules() {
  comp="${1:-}"
  sysroot="${LIBSCRIPT_TARGET_SYSROOT:-/}"
  nft_conf="${sysroot%/}/etc/nftables.conf"
  if [ -f "$nft_conf" ]; then
    if [ -n "$comp" ]; then
      grep -v "LibScript-Trait-${comp}-" "$nft_conf" > "${nft_conf}.tmp" && mv -f "${nft_conf}.tmp" "$nft_conf"
    else
      rm -f "$nft_conf"
    fi
  fi
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 [component]"
  exit 0
fi

prune_firewall_rules "${1:-}"
printf '[INFO] Pruned firewall rules for %s.\n' "${1:-all}"
