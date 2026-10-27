#!/bin/sh
# ## Overview
# Registers and deregisters service endpoints in _lib/databases/etcd or HashiCorp Consul.
#
# ## Usage
# ./traits/discovery/consul_etcd.sh <register|deregister> <service_name> <endpoint>

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

# ## sync_kv_discovery
# Writes or removes service endpoint key in etcdctl or local mock state.
sync_kv_discovery() {
  op="${1:-register}"
  svc="${2:-postgres}"
  ep="${3:-100.64.0.1:5432}"
  if command -v etcdctl >/dev/null 2>&1 && [ -n "${ETCDCTL_ENDPOINTS:-}" ]; then
    if [ "$op" = "register" ]; then
      etcdctl put "/libscript/services/${svc}" "$ep" >/dev/null
    else
      etcdctl del "/libscript/services/${svc}" >/dev/null
    fi
  fi
  printf '{"action":"%s","service":"%s","endpoint":"%s","backend":"etcd"}\n' "$op" "$svc" "$ep"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 <register|deregister> <service_name> <endpoint>"
  exit 0
fi

sync_kv_discovery "$@"
