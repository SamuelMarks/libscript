#!/bin/sh
# ## Overview
# Maintains an atomic block (# BEGIN libscript-discovery ... # END libscript-discovery) in /etc/hosts.
#
# ## Usage
# ./traits/discovery/hosts.sh <ip_address> <fqdn>

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

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 <ip_address> <fqdn>"
  exit 0
fi

IP_ADDR="${1:-100.64.0.1}"
FQDN="${2:-postgres.cluster.internal}"
SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-/}"
HOSTS_FILE="${SYSROOT%/}/etc/hosts"
mkdir -p "${SYSROOT%/}/etc"
touch "$HOSTS_FILE"

# ## update_hosts_block
# Updates the libscript-discovery block in /etc/hosts idempotently.
update_hosts_block() {
  if grep -q "^${IP_ADDR}[[:space:]]*${FQDN}$" "$HOSTS_FILE" 2>/dev/null; then
    return 0
  fi
  if ! grep -q "^# BEGIN libscript-discovery$" "$HOSTS_FILE" 2>/dev/null; then
    {
      printf '# BEGIN libscript-discovery\n'
      printf '%s %s\n' "$IP_ADDR" "$FQDN"
      printf '# END libscript-discovery\n'
    } >> "$HOSTS_FILE"
  else
    awk -v line="${IP_ADDR} ${FQDN}" '
      $0 == "# END libscript-discovery" { print line }
      { print }
    ' "$HOSTS_FILE" > "${HOSTS_FILE}.tmp" && mv -f "${HOSTS_FILE}.tmp" "$HOSTS_FILE"
  fi
}

update_hosts_block
printf '[INFO] Mapped %s -> %s in %s.\n' "$FQDN" "$IP_ADDR" "$HOSTS_FILE"
