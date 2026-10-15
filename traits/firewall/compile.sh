#!/bin/sh
# ## Overview
# Compiles host firewall rules from hooks/announce into nftables/pf with Anti-Lockout Safeguards and Tier 2 offline sysroot support.
#
# ## Usage
# ./traits/firewall/compile.sh [component...]

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
  printf '%s\n' "Usage: $0 [component...]"
  exit 0
fi

SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-/}"
mkdir -p "${SYSROOT%/}/etc"
NFT_CONF="${SYSROOT%/}/etc/nftables.conf"
PF_CONF="${SYSROOT%/}/etc/pf.conf"

SSH_PORT="22"
if [ -n "${SSH_CONNECTION:-}" ]; then
  SSH_PORT="$(printf '%s\n' "$SSH_CONNECTION" | awk '{print $4}')"
  [ -z "$SSH_PORT" ] && SSH_PORT="22"
fi

# ## emit_anti_lockout_and_rules
# Emits nftables and pf configurations with anti-lockout rules and component announce ports.
emit_anti_lockout_and_rules() {
  {
    printf '# BEGIN libscript-managed: firewall\n'
    printf 'table inet libscript_filter {\n'
    printf '  chain input {\n'
    printf '    type filter hook input priority 0; policy drop;\n'
    printf '    iif "lo" accept\n'
    printf '    ct state established,related accept\n'
    printf '    tcp dport { %s, 5985, 5986, 3389, 8080 } accept comment "LibScript-Anti-Lockout"\n' "$SSH_PORT"
    for comp in "$@"; do
      ann="$(libscript_exec_hook "$comp" "announce" 2>/dev/null || true)"
      if [ -n "$ann" ]; then
        port="$(printf '%s\n' "$ann" | jq -r '.port // 0')"
        vis="$(printf '%s\n' "$ann" | jq -r '.visibility // "internal"')"
        if [ "$port" -gt 0 ]; then
          if [ "$vis" = "public" ]; then
            printf '    tcp dport %s accept comment "LibScript-Trait-%s-%s"\n' "$port" "$comp" "$port"
          else
            printf '    iifname "wg0" tcp dport %s accept comment "LibScript-Trait-%s-%s"\n' "$port" "$comp" "$port"
          fi
        fi
      fi
    done
    printf '  }\n'
    printf '}\n'
    printf '# END libscript-managed: firewall\n'
  } > "$NFT_CONF"

  {
    printf '# BEGIN libscript-managed: firewall\n'
    printf 'pass in quick on lo0 all\n'
    printf 'pass in quick proto tcp to any port { %s 5985 5986 3389 8080 } keep state\n' "$SSH_PORT"
    printf '# END libscript-managed: firewall\n'
  } > "$PF_CONF"
}

if [ $# -eq 0 ]; then
  emit_anti_lockout_and_rules "postgres" "nginx"
else
  emit_anti_lockout_and_rules "$@"
fi
printf '[INFO] Compiled firewall rules to %s and %s.\n' "$NFT_CONF" "$PF_CONF"
