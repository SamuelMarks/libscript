#!/bin/sh
# ## Overview
# Hardware-aware optimization module (`hw_tune.sh`).
# Automatically detects host CPU cores (`LIBSCRIPT_HW_CORES`), total RAM in MiB
# (`LIBSCRIPT_HW_MEM_MB`), and calculates optimal tuning parameters for databases
# (PostgreSQL `shared_buffers`, `effective_cache_size`, `maintenance_work_mem`, `work_mem`),
# caches (Redis/Valkey `maxmemory`), and web servers (Nginx `worker_processes`, `worker_connections`).
#
# ## Usage
# Source this file and call `libscript_detect_hardware` or `libscript_apply_hardware_tuning <component>`.

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
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"

# ## libscript_detect_hardware
# Detects available CPU cores and total system RAM in MiB, exporting hardware tuning variables.
libscript_detect_hardware() {
  _cores=2
  if command -v nproc >/dev/null 2>&1; then
    _cores=$(nproc 2>/dev/null || printf '2')
  elif command -v getconf >/dev/null 2>&1 && getconf _NPROCESSORS_ONLN >/dev/null 2>&1; then
    _cores=$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '2')
  elif command -v sysctl >/dev/null 2>&1; then
    _cores=$(sysctl -n hw.ncpu 2>/dev/null || printf '2')
  fi
  [ "$_cores" -ge 1 ] 2>/dev/null || _cores=2

  _mem_mb=2048
  if [ -r /proc/meminfo ]; then
    _mem_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || printf '2097152')
    _mem_mb=$((_mem_kb / 1024))
  elif command -v sysctl >/dev/null 2>&1; then
    _mem_bytes=$(sysctl -n hw.memsize 2>/dev/null || sysctl -n hw.physmem 2>/dev/null || printf '2147483648')
    _mem_mb=$((_mem_bytes / 1048576))
  fi
  [ "$_mem_mb" -ge 256 ] 2>/dev/null || _mem_mb=2048

  export LIBSCRIPT_HW_CORES="${LIBSCRIPT_HW_CORES:-$_cores}"
  export LIBSCRIPT_HW_MEM_MB="${LIBSCRIPT_HW_MEM_MB:-$_mem_mb}"

  _simd="generic"
  if [ -r /proc/cpuinfo ]; then
    if grep -q "avx512" /proc/cpuinfo 2>/dev/null; then
      _simd="avx512"
    elif grep -q "avx2" /proc/cpuinfo 2>/dev/null; then
      _simd="avx2"
    elif grep -q "asimd\|neon" /proc/cpuinfo 2>/dev/null; then
      _simd="neon"
    fi
  elif command -v sysctl >/dev/null 2>&1; then
    if [ "$(uname -m 2>/dev/null || true)" = "arm64" ] || [ "$(uname -m 2>/dev/null || true)" = "aarch64" ]; then
      _simd="neon"
    elif sysctl -n machdep.cpu.leaf7_features 2>/dev/null | grep -qi "AVX2"; then
      _simd="avx2"
    fi
  fi
  export LIBSCRIPT_HW_SIMD="${LIBSCRIPT_HW_SIMD:-$_simd}"

  _nvme=0
  if [ -d /sys/class/nvme ] || ls /dev/nvme* >/dev/null 2>&1; then
    _nvme=1
  elif [ "$(uname -s 2>/dev/null || true)" = "Darwin" ]; then
    _nvme=1
  fi
  export LIBSCRIPT_HW_NVME="${LIBSCRIPT_HW_NVME:-$_nvme}"
  if [ "$LIBSCRIPT_HW_NVME" = "1" ]; then
    export LIBSCRIPT_TUNE_PG_RANDOM_PAGE_COST="${LIBSCRIPT_TUNE_PG_RANDOM_PAGE_COST:-1.1}"
    export LIBSCRIPT_TUNE_PG_EFFECTIVE_IO_CONCURRENCY="${LIBSCRIPT_TUNE_PG_EFFECTIVE_IO_CONCURRENCY:-200}"
  else
    export LIBSCRIPT_TUNE_PG_RANDOM_PAGE_COST="${LIBSCRIPT_TUNE_PG_RANDOM_PAGE_COST:-4.0}"
    export LIBSCRIPT_TUNE_PG_EFFECTIVE_IO_CONCURRENCY="${LIBSCRIPT_TUNE_PG_EFFECTIVE_IO_CONCURRENCY:-2}"
  fi

  # PostgreSQL / relational DB auto-tuning (25% RAM for shared_buffers, 75% for effective_cache_size)
  _pg_shared=$((LIBSCRIPT_HW_MEM_MB / 4))
  [ "$_pg_shared" -lt 128 ] && _pg_shared=128
  _pg_cache=$((LIBSCRIPT_HW_MEM_MB * 3 / 4))
  [ "$_pg_cache" -lt 256 ] && _pg_cache=256
  _pg_maint=$((LIBSCRIPT_HW_MEM_MB / 16))
  [ "$_pg_maint" -lt 64 ] && _pg_maint=64
  [ "$_pg_maint" -gt 2048 ] && _pg_maint=2048
  _pg_work=$((LIBSCRIPT_HW_MEM_MB / (LIBSCRIPT_HW_CORES * 8)))
  [ "$_pg_work" -lt 4 ] && _pg_work=4

  export LIBSCRIPT_TUNE_PG_SHARED_BUFFERS="${LIBSCRIPT_TUNE_PG_SHARED_BUFFERS:-${_pg_shared}MB}"
  export LIBSCRIPT_TUNE_PG_EFFECTIVE_CACHE_SIZE="${LIBSCRIPT_TUNE_PG_EFFECTIVE_CACHE_SIZE:-${_pg_cache}MB}"
  export LIBSCRIPT_TUNE_PG_MAINTENANCE_WORK_MEM="${LIBSCRIPT_TUNE_PG_MAINTENANCE_WORK_MEM:-${_pg_maint}MB}"
  export LIBSCRIPT_TUNE_PG_WORK_MEM="${LIBSCRIPT_TUNE_PG_WORK_MEM:-${_pg_work}MB}"
  export LIBSCRIPT_TUNE_PG_MAX_WORKER_PROCESSES="${LIBSCRIPT_TUNE_PG_MAX_WORKER_PROCESSES:-${LIBSCRIPT_HW_CORES}}"

  # Nginx / Web Server auto-tuning
  _nginx_conns=$((LIBSCRIPT_HW_CORES * 1024))
  [ "$_nginx_conns" -lt 1024 ] && _nginx_conns=1024
  export LIBSCRIPT_TUNE_NGINX_WORKER_PROCESSES="${LIBSCRIPT_TUNE_NGINX_WORKER_PROCESSES:-${LIBSCRIPT_HW_CORES}}"
  export LIBSCRIPT_TUNE_NGINX_WORKER_CONNECTIONS="${LIBSCRIPT_TUNE_NGINX_WORKER_CONNECTIONS:-${_nginx_conns}}"

  # Redis / Valkey cache auto-tuning (50% RAM maxmemory)
  _cache_mb=$((LIBSCRIPT_HW_MEM_MB / 2))
  [ "$_cache_mb" -lt 128 ] && _cache_mb=128
  export LIBSCRIPT_TUNE_CACHE_MAXMEMORY="${LIBSCRIPT_TUNE_CACHE_MAXMEMORY:-${_cache_mb}mb}"
}

# ## libscript_apply_hardware_tuning
# Writes idempotent hardware-tuned configuration snippets for a component into the target sysroot.
libscript_apply_hardware_tuning() {
  _ht_comp="${1:-}"
  _ht_sysroot="${2:-${LIBSCRIPT_TARGET_SYSROOT:-/}}"
  libscript_detect_hardware
  _ht_dir="${_ht_sysroot%/}/etc/libscript/${_ht_comp}"
  mkdir -p "$_ht_dir" 2>/dev/null || {
    _ht_dir="${TMPDIR:-/tmp}/libscript/hw_tune/${_ht_comp}"
    mkdir -p "$_ht_dir" 2>/dev/null || true
  }
  _ht_conf="${_ht_dir}/hardware-tuning.conf"
  case "$_ht_comp" in
    postgres|postgresql)
      cat <<EOF > "$_ht_conf"
# BEGIN libscript-managed: postgres-hardware-tuning
shared_buffers = ${LIBSCRIPT_TUNE_PG_SHARED_BUFFERS}
effective_cache_size = ${LIBSCRIPT_TUNE_PG_EFFECTIVE_CACHE_SIZE}
maintenance_work_mem = ${LIBSCRIPT_TUNE_PG_MAINTENANCE_WORK_MEM}
work_mem = ${LIBSCRIPT_TUNE_PG_WORK_MEM}
max_worker_processes = ${LIBSCRIPT_TUNE_PG_MAX_WORKER_PROCESSES}
random_page_cost = ${LIBSCRIPT_TUNE_PG_RANDOM_PAGE_COST}
effective_io_concurrency = ${LIBSCRIPT_TUNE_PG_EFFECTIVE_IO_CONCURRENCY}
# END libscript-managed: postgres-hardware-tuning
EOF
      ;;
    nginx)
      cat <<EOF > "$_ht_conf"
# BEGIN libscript-managed: nginx-hardware-tuning
worker_processes ${LIBSCRIPT_TUNE_NGINX_WORKER_PROCESSES};
# worker_connections ${LIBSCRIPT_TUNE_NGINX_WORKER_CONNECTIONS};
# END libscript-managed: nginx-hardware-tuning
EOF
      ;;
    redis|valkey)
      cat <<EOF > "$_ht_conf"
# BEGIN libscript-managed: ${_ht_comp}-hardware-tuning
maxmemory ${LIBSCRIPT_TUNE_CACHE_MAXMEMORY}
io-threads ${LIBSCRIPT_HW_CORES}
# END libscript-managed: ${_ht_comp}-hardware-tuning
EOF
      ;;
    *)
      cat <<EOF > "$_ht_conf"
# BEGIN libscript-managed: ${_ht_comp}-hardware-tuning
LIBSCRIPT_HW_CORES=${LIBSCRIPT_HW_CORES}
LIBSCRIPT_HW_MEM_MB=${LIBSCRIPT_HW_MEM_MB}
# END libscript-managed: ${_ht_comp}-hardware-tuning
EOF
      ;;
  esac
}
