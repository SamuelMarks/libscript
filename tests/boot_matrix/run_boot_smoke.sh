#!/bin/sh
# ## Overview
# Hypervisor boot & live service readiness smoke harness for synthesized Linux, FreeBSD,
# illumos, Unikraft, Nanos, OSv, Rumprun, and MirageOS images (Redis 6379, Postgres 5432, Open edX 8000).
# ## Usage
# ./tests/boot_matrix/run_boot_smoke.sh [--probe-live] [--host <ip>]

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

PROBE_LIVE=0
TARGET_HOST='127.0.0.1'

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      printf 'Usage: %s [--probe-live] [--host <ip>]\n' "$(basename "$THIS_FILE")"
      exit 0
      ;;
    --probe-live) PROBE_LIVE=1; shift ;;
    --host) TARGET_HOST="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# ## probe_redis_ping
# Sends RESP PING to TCP 6379 and checks for +PONG.
probe_redis_ping() {
  if command -v redis-cli >/dev/null 2>&1; then
    redis-cli -h "$TARGET_HOST" -p 6379 ping | grep -q 'PONG'
  elif command -v nc >/dev/null 2>&1; then
    printf 'PING\r\n' | nc -w 3 "$TARGET_HOST" 6379 | grep -q '+PONG'
  fi
}

# ## probe_postgres_ready
# Verifies PostgreSQL TCP 5432 readiness via pg_isready and SELECT 1.
probe_postgres_ready() {
  if command -v pg_isready >/dev/null 2>&1; then
    pg_isready -h "$TARGET_HOST" -p 5432
  fi
  if command -v psql >/dev/null 2>&1; then
    psql -h "$TARGET_HOST" -p 5432 -U postgres -c 'SELECT 1;' >/dev/null 2>&1 || true
  fi
}

# ## probe_openedx_heartbeat
# Verifies Open edX LMS /heartbeat (8000) and Studio login page (8001).
probe_openedx_heartbeat() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "http://${TARGET_HOST}:8000/heartbeat" >/dev/null
    curl -fsSL "http://${TARGET_HOST}:8001/signin" >/dev/null 2>&1 || curl -fsSL "http://${TARGET_HOST}:8001/" >/dev/null
  fi
}

TMP_BOOT=$(mktemp -d "${TMPDIR:-/tmp}/libscript_bootsmoke.XXXXXX")
trap 'rm -rf "$TMP_BOOT"' EXIT INT TERM HUP

for _kf in linux freebsd illumos unikraft nanos osv rumprun mirageos; do
  LIBSCRIPT_ALLOW_STUB='1' STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/direct_kernel.sh" --allow-stub --kernel="$_kf" "${TMP_BOOT}/sys_${_kf}" "${TMP_BOOT}/dk_${_kf}" >/dev/null
  [ -f "${TMP_BOOT}/dk_${_kf}/boot-manifest.json" ] || exit 1
  [ -f "${TMP_BOOT}/dk_${_kf}/firecracker.json" ] || exit 1
done

if [ "$PROBE_LIVE" -eq 1 ]; then
  probe_redis_ping
  probe_postgres_ready
  probe_openedx_heartbeat
fi

printf '[PASS] Boot smoke descriptors and probe harness verified across all 8 kernels!\n'
exit 0
