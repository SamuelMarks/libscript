#!/bin/sh
# ## Overview
# Synthesizes a PostgreSQL unikernel appliance for OSv (ZFS shared-object appliance)
# or Nanos/Ops (ext4 volume appliance), rejecting strict fork()-less Rumprun/MirageOS targets.
# ## Usage
# ./_lib/databases/postgres/unikernel_build.sh [staging_rootfs] [output_image] [ipv4_addr]

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
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

STAGE_ROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/postgres-unikernel-root}}"
OUT_IMG="${2:-${LIBSCRIPT_ROOT_DIR}/build/images/unikernel/postgres.unikernel.img}"
IPV4_ADDR="${3:-172.30.0.11}"
FRAMEWORK="${LIBSCRIPT_UNIKERNEL_FRAMEWORK:-osv}"

case "$FRAMEWORK" in
  rumprun|mirage|mirageos|unikraft)
    printf '[ERROR] PostgreSQL requires multiprocess fork()/shared-memory semantics unsupported on %s. Select osv or nanos (or sqlite / hybrid ZFS datastore VM).\n' "$FRAMEWORK" >&2
    exit 1
    ;;
esac

mkdir -p "${STAGE_ROOT}/var/lib/postgresql/data" "${STAGE_ROOT}/etc/postgresql" "$(dirname "$OUT_IMG")"
cat <<PG_CONF > "${STAGE_ROOT}/etc/postgresql/postgresql.conf"
listen_addresses = '*'
port = 5432
max_connections = 64
shared_buffers = 128MB
dynamic_shared_memory_type = posix
PG_CONF

if [ "$FRAMEWORK" = "osv" ]; then
  cat <<OSV_PG > "${STAGE_ROOT}/Capstanfile"
base: cloudius/osv-zfs
cmdline: /usr/lib/postgresql/bin/postgres -D /var/lib/postgresql/data -c config_file=/etc/postgresql/postgresql.conf
OSV_PG
else
  cat <<OPS_PG > "${STAGE_ROOT}/ops.postgres.json"
{
  "Args": ["/usr/lib/postgresql/bin/postgres", "--single", "-D", "/var/lib/postgresql/data"],
  "Dirs": ["${STAGE_ROOT}"],
  "Mounts": {"pgdata": "/var/lib/postgresql/data"},
  "RunConfig": {
    "IPAddress": "${IPV4_ADDR}",
    "Ports": ["5432"],
    "Memory": "1024M"
  }
}
OPS_PG
fi

STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/unikernel.sh" --framework="$FRAMEWORK" "$STAGE_ROOT" "$OUT_IMG"
exit 0
