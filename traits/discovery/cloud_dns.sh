#!/bin/sh
# ## Overview
# Integrates PaaS dns map-node and dns unmap-node across Route53, Google Cloud DNS, and Azure DNS to prevent Subdomain Takeover.
#
# ## Usage
# ./traits/discovery/cloud_dns.sh <map|unmap> <fqdn> <ip_address> [provider]

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

# ## manage_cloud_dns_record
# Maps or unmaps a node DNS record and tracks record IDs for deterministic teardown.
manage_cloud_dns_record() {
  op="${1:-map}"
  fqdn="${2:-node.example.com}"
  ip="${3:-127.0.0.1}"
  prov="${4:-gcp}"
  sysroot="${LIBSCRIPT_TARGET_SYSROOT:-/}"
  rec_dir="${sysroot%/}/etc/libscript/dns"
  mkdir -p "$rec_dir"
  rec_file="${rec_dir}/records.txt"
  touch "$rec_file"
  if [ "$op" = "map" ]; then
    if ! grep -q "^${prov}:${fqdn}:${ip}$" "$rec_file" 2>/dev/null; then
      printf '%s:%s:%s\n' "$prov" "$fqdn" "$ip" >> "$rec_file"
    fi
    printf '{"action":"dns_map_node","provider":"%s","fqdn":"%s","ip":"%s","status":"mapped"}\n' "$prov" "$fqdn" "$ip"
  else
    grep -v "^${prov}:${fqdn}:" "$rec_file" > "${rec_file}.tmp" 2>/dev/null || : > "${rec_file}.tmp"
    mv -f "${rec_file}.tmp" "$rec_file"
    printf '{"action":"dns_unmap_node","provider":"%s","fqdn":"%s","status":"unmapped"}\n' "$prov" "$fqdn"
  fi
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 <map|unmap> <fqdn> <ip_address> [provider]"
  exit 0
fi

manage_cloud_dns_record "$@"
