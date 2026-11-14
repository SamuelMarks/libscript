#!/bin/sh
# ## Overview
# Builds a standalone single-process Redis unikernel image for Unikraft, Nanos/Ops,
# OSv, or Rumprun with fork()-less AOF-only persistence (`save ""`, `appendonly yes`).
# ## Usage
# ./_lib/caches/redis/unikernel_build.sh [staging_rootfs] [output_image] [ipv4_addr]

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

STAGE_ROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/redis-unikernel-root}}"
OUT_IMG="${2:-${LIBSCRIPT_ROOT_DIR}/build/images/unikernel/redis.unikernel.img}"
IPV4_ADDR="${3:-172.30.0.10}"
FRAMEWORK="${LIBSCRIPT_UNIKERNEL_FRAMEWORK:-unikraft}"

if [ "$FRAMEWORK" = "mirage" ] || [ "$FRAMEWORK" = "mirageos" ]; then
  printf '[ERROR] Redis C server cannot compile as an OCaml MirageOS library unikernel; choose unikraft, nanos, osv, or rumprun.\n' >&2
  exit 1
fi

mkdir -p "${STAGE_ROOT}/etc" "${STAGE_ROOT}/data" "$(dirname "$OUT_IMG")"

cat <<REDIS_CONF > "${STAGE_ROOT}/etc/redis.conf"
bind 0.0.0.0
protected-mode no
port ${REDIS_PORT:-6379}
daemonize no
supervised no
save ""
appendonly yes
appendfsync everysec
dir /data
REDIS_CONF

case "$FRAMEWORK" in
  unikraft)
    cat <<UK_REDIS > "${STAGE_ROOT}/Kraftfile"
spec: v0.6
name: libscript-redis
unikraft:
  version: stable
libraries:
  musl: stable
  lwip: stable
  redis:
    version: stable
    kconfig:
      CONFIG_LIBREDIS_SERVER: 'y'
      CONFIG_LIBREDIS_SERVER_MAIN_FUNCTION: 'y'
targets:
  - architecture: x86_64
    platform: qemu
  - architecture: x86_64
    platform: fc
cmd: ["/etc/redis.conf"]
rootfs: ${STAGE_ROOT}
UK_REDIS
    ;;
  nanos|ops)
    cat <<OPS_REDIS > "${STAGE_ROOT}/ops.redis.json"
{
  "Args": ["/usr/bin/redis-server", "/etc/redis.conf"],
  "Dirs": ["${STAGE_ROOT}"],
  "RunConfig": {
    "IPAddress": "${IPV4_ADDR}",
    "Ports": ["6379"],
    "Memory": "256M"
  }
}
OPS_REDIS
    ;;
  osv)
    cat <<OSV_REDIS > "${STAGE_ROOT}/usr.manifest"
/redis-server.so: \${MODULE_DIR}/redis-server.so
/etc/redis.conf: ${STAGE_ROOT}/etc/redis.conf
OSV_REDIS
    ;;
  rumprun)
    cat <<RUMP_REDIS > "${STAGE_ROOT}/rumprun-redis.json"
{
  "cmdline": "redis-server /etc/redis.conf",
  "net": {"if": "vioif0", "type": "inet", "method": "static", "addr": "${IPV4_ADDR}", "mask": "24"},
  "blk": {"source": "etfs", "path": "/dev/ld0a", "fstype": "blk", "mountpoint": "/data"}
}
RUMP_REDIS
    ;;
esac

STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/unikernel.sh" --framework="$FRAMEWORK" "$STAGE_ROOT" "$OUT_IMG"
exit 0
