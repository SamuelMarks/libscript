#!/bin/sh
# ## Overview
# Generates node WireGuard keypairs idempotently and renders wg0 peer configurations from .topology_state.json.
#
# ## Usage
# ./traits/mesh/wireguard.sh [node_index] [topology_state_file]

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

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 [node_index] [topology_state_file]"
  exit 0
fi

NODE_IDX="${1:-1}"
STATE_FILE="${2:-}"
SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-/}"
WG_DIR="${SYSROOT%/}/etc/wireguard"
mkdir -p "$WG_DIR"
chmod 0700 "$WG_DIR"

KEY_FILE="${WG_DIR}/libscript-mesh.key"
PUB_FILE="${WG_DIR}/libscript-mesh.pub"

# ## ensure_wg_keypair
# Generates WireGuard private and public keys idempotently with 0600 permissions.
ensure_wg_keypair() {
  umask 0077
  if [ ! -f "$KEY_FILE" ]; then
    if command -v wg >/dev/null 2>&1; then
      wg genkey > "$KEY_FILE"
      wg pubkey < "$KEY_FILE" > "$PUB_FILE"
    else
      printf 'LIBSCRIPT_MOCK_WG_PRIVKEY_NODE_%s\n' "$NODE_IDX" > "$KEY_FILE"
      printf 'LIBSCRIPT_MOCK_WG_PUBKEY_NODE_%s\n' "$NODE_IDX" > "$PUB_FILE"
    fi
    chmod 0600 "$KEY_FILE" "$PUB_FILE"
  fi
}

# ## render_wg0_conf
# Writes /etc/wireguard/wg0.conf with deterministic overlay IPv4/IPv6 and peer entries.
render_wg0_conf() {
  priv_key="$(cat "$KEY_FILE")"
  wg_conf="${WG_DIR}/wg0.conf"
  umask 0077
  {
    printf '# BEGIN libscript-managed: wireguard-mesh\n'
    printf '[Interface]\n'
    printf 'PrivateKey = %s\n' "$priv_key"
    printf 'Address = 100.64.0.%s/24, fd00:libscript::%s/64\n' "$NODE_IDX" "$NODE_IDX"
    printf 'ListenPort = 51820\n'
    if [ -n "$STATE_FILE" ] && [ -f "$STATE_FILE" ]; then
      jq -r '.nodes[] | select(.wireguard_pubkey != null) | "\(.node_id)	\(.wireguard_pubkey)	\(.mesh_ip // "100.64.0.2")	\(.public_ip // "127.0.0.1")"' "$STATE_FILE" | while IFS="$(printf '	')" read -r nid pub mip pip; do
        printf '
[Peer]
# Node: %s
PublicKey = %s
AllowedIPs = %s/32
Endpoint = %s:51820
PersistentKeepalive = 25
' "$nid" "$pub" "$mip" "$pip"
      done
    fi
    printf '# END libscript-managed: wireguard-mesh\n'
  } > "$wg_conf"
  chmod 0600 "$wg_conf"
}

ensure_wg_keypair
render_wg0_conf
printf '[INFO] WireGuard mesh configured at %s/wg0.conf (100.64.0.%s/24).\n' "$WG_DIR" "$NODE_IDX"
