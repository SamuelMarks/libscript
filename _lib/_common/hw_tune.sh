#!/bin/sh
# ## Overview
# Hardware-aware optimization module (`hw_tune.sh`). Detects host CPU cores, RAM, and calculates optimal daemon tuning parameters.
# ## Usage
# Source this file and call `libscript_detect_hardware` or `libscript_apply_hardware_tuning <component>`.
set -feu
_hw_tune_caller_this="${THIS_FILE:-}"; _hw_tune_caller_dir="${SCRIPT_DIR:-}"
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
    [ -n "${_hw_tune_caller_this:-}" ] && THIS_FILE="$_hw_tune_caller_this"
    [ -n "${_hw_tune_caller_dir:-}" ] && SCRIPT_DIR="$_hw_tune_caller_dir"
    unset SCRIPT_NAME || true; if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

if [ -z "${UNAME:-}" ] || [ -z "${ARCH:-}" ]; then
  _hwt_oi_this="${THIS_FILE}"
  _hwt_oi_dir="${SCRIPT_DIR}"
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/os_info.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
  THIS_FILE="${_hwt_oi_this}"
  SCRIPT_DIR="${_hwt_oi_dir}"
  unset _hwt_oi_this _hwt_oi_dir || true
fi

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

  _cpu_model='unknown-cpu'
  if [ -r /proc/cpuinfo ]; then
    _cpu_model=$(awk -F: '/^(model name|Hardware|Processor)[[:space:]]*:/ {sub(/^[[:space:]]+/, "", $2); print $2; exit}' /proc/cpuinfo 2>/dev/null || true)
  elif command -v sysctl >/dev/null 2>&1; then
    _cpu_model=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || sysctl -n hw.model 2>/dev/null || true)
  fi
  [ -n "$_cpu_model" ] || _cpu_model="${ARCH:-unknown}-cpu"
  export LIBSCRIPT_HW_CPU_MODEL="${LIBSCRIPT_HW_CPU_MODEL:-$_cpu_model}"

  _phys_cores="$_cores"
  if [ -r /proc/cpuinfo ]; then
    _pc=$(awk -F: '
      /^physical id[[:space:]]*:/ { pid=$2; gsub(/[[:space:]]+/, "", pid) }
      /^core id[[:space:]]*:/ { cid=$2; gsub(/[[:space:]]+/, "", cid); seen[pid ":" cid]=1 }
      END { n=0; for (k in seen) n++; if (n > 0) print n }
    ' /proc/cpuinfo 2>/dev/null || true)
    if [ -n "$_pc" ] && [ "$_pc" -ge 1 ] 2>/dev/null; then
      _phys_cores="$_pc"
    fi
  elif command -v sysctl >/dev/null 2>&1; then
    _pc=$(sysctl -n hw.physicalcpu 2>/dev/null || true)
    if [ -n "$_pc" ] && [ "$_pc" -ge 1 ] 2>/dev/null; then
      _phys_cores="$_pc"
    fi
  fi
  export LIBSCRIPT_HW_PHYS_CORES="${LIBSCRIPT_HW_PHYS_CORES:-$_phys_cores}"

  _perf_cores="$_phys_cores"
  if [ "${UNAME:-}" = "Darwin" ] && command -v sysctl >/dev/null 2>&1; then
    _pfc=$(sysctl -n hw.perflevel0.physicalcpu 2>/dev/null || true)
    if [ -n "$_pfc" ] && [ "$_pfc" -ge 1 ] 2>/dev/null; then
      _perf_cores="$_pfc"
    fi
  fi
  export LIBSCRIPT_HW_PERF_CORES="${LIBSCRIPT_HW_PERF_CORES:-$_perf_cores}"

  _numa_nodes=1
  if [ -d /sys/devices/system/node ]; then
    _nn=$(find /sys/devices/system/node -maxdepth 1 -type d -name 'node[0-9]*' 2>/dev/null | wc -l | awk '{print $1+0}')
    [ "$_nn" -ge 1 ] && _numa_nodes="$_nn"
  fi
  export LIBSCRIPT_HW_NUMA_NODES="${LIBSCRIPT_HW_NUMA_NODES:-$_numa_nodes}"

  _simd='generic'
  if [ -r /proc/cpuinfo ]; then
    if grep -q "avx512" /proc/cpuinfo 2>/dev/null; then
      _simd='avx512'
    elif grep -q "avx2" /proc/cpuinfo 2>/dev/null; then
      _simd='avx2'
    elif grep -Eq "asimd|neon" /proc/cpuinfo 2>/dev/null; then
      _simd='neon'
    fi
  elif command -v sysctl >/dev/null 2>&1; then
    if [ "${ARCH:-}" = "arm64" ] || [ "${ARCH:-}" = "aarch64" ]; then
      _simd='neon'
    elif sysctl -n machdep.cpu.leaf7_features 2>/dev/null | grep -qi "AVX2"; then
      _simd='avx2'
    fi
  fi
  export LIBSCRIPT_HW_SIMD="${LIBSCRIPT_HW_SIMD:-$_simd}"

  _nvme=0
  if [ -d /sys/class/nvme ] || ls /dev/nvme* >/dev/null 2>&1; then
    _nvme=1
  elif [ "${UNAME:-}" = "Darwin" ]; then
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

# ## libscript_detect_ac_power
# Detects whether the host is running on AC mains power (`true`, `false`, or `unknown`) and exports `LIBSCRIPT_HW_AC_POWER`.
libscript_detect_ac_power() {
  _ac_state='unknown'
  if [ "${UNAME:-}" = "Darwin" ] && command -v pmset >/dev/null 2>&1; then
    _pm_out=$(pmset -g batt 2>/dev/null || true)
    case "${_pm_out}" in
      *'AC Power'*) _ac_state='true' ;;
      *'Battery Power'*) _ac_state='false' ;;
    esac
  elif [ "${UNAME:-}" = "Linux" ] && [ -d /sys/class/power_supply ]; then
    for _ps in /sys/class/power_supply/*/online; do
      if [ -r "${_ps}" ]; then
        _val=$(head -n 1 "${_ps}" 2>/dev/null || printf '')
        if [ "${_val}" = "1" ]; then
          _ac_state='true'
          break
        elif [ "${_val}" = "0" ] && [ "${_ac_state}" = "unknown" ]; then
          _ac_state='false'
        fi
      fi
    done
  fi
  export LIBSCRIPT_HW_AC_POWER="${LIBSCRIPT_HW_AC_POWER:-${_ac_state}}"
}

# ## libscript_prepare_benchmark_host
# Standardizes the host OS and CPU environment for reproducible compiler benchmarking (verifies AC power, pins single-TU parallelism to -j1, locks CPU governor, disables ASLR, and disables swap when LIBSCRIPT_BENCH_PREPARE_HOST=1).
libscript_prepare_benchmark_host() {
  libscript_detect_hardware
  libscript_detect_ac_power
  if [ "${LIBSCRIPT_BENCH_REQUIRE_AC_POWER:-0}" = "1" ] && [ "${LIBSCRIPT_HW_AC_POWER}" = "false" ]; then
    printf '[ERROR] [HW-TUNE] Host is running on battery power; AC power is required for thermal stability.\n' >&2
    return 1
  fi
  if [ "${LIBSCRIPT_BENCH_SERIAL_SINGLE_TU:-0}" = "1" ]; then
    export MAKEFLAGS='-j1'
    export CMAKE_BUILD_PARALLEL_LEVEL='1'
  fi
  if [ "${LIBSCRIPT_DRY_RUN:-0}" = "1" ] || [ "${LIBSCRIPT_BENCH_PREPARE_HOST:-0}" != "1" ]; then
    return 0
  fi
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/priv.sh" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/priv.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090,SC1091
    . "${SCRIPT_NAME}"
  fi
  if [ "${UNAME:-}" = "Linux" ]; then
    if command -v cpupower >/dev/null 2>&1; then
      priv cpupower frequency-set --governor performance >/dev/null 2>&1 || true
    fi
    if [ -w /proc/sys/kernel/randomize_va_space ]; then
      printf '0\n' > /proc/sys/kernel/randomize_va_space 2>/dev/null || true
    else
      printf '0\n' | priv tee /proc/sys/kernel/randomize_va_space >/dev/null 2>&1 || true
    fi
    if command -v swapoff >/dev/null 2>&1; then
      priv swapoff -a >/dev/null 2>&1 || true
    fi
  fi
}

# ## libscript_drop_benchmark_caches
# Flushes filesystem buffers and drops kernel page cache, dentries, and inodes prior to a benchmark run when LIBSCRIPT_BENCH_DROP_CACHES=1.
libscript_drop_benchmark_caches() {
  if [ "${LIBSCRIPT_DRY_RUN:-0}" = "1" ] || [ "${LIBSCRIPT_BENCH_DROP_CACHES:-0}" != "1" ]; then
    return 0
  fi
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/priv.sh" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/priv.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090,SC1091
    . "${SCRIPT_NAME}"
  fi
  sync 2>/dev/null || true
  if [ "${UNAME:-}" = "Linux" ]; then
    if [ -w /proc/sys/vm/drop_caches ]; then
      printf '3\n' > /proc/sys/vm/drop_caches 2>/dev/null || true
    else
      printf '3\n' | priv tee /proc/sys/vm/drop_caches >/dev/null 2>&1 || true
    fi
  elif [ "${UNAME:-}" = "Darwin" ] && command -v purge >/dev/null 2>&1; then
    if [ "$(id -u 2>/dev/null || printf '1')" = "0" ]; then
      purge >/dev/null 2>&1 || true
    fi
  fi
}

# ## libscript_emit_hw_manifest_json
# Emits a deterministic host hardware and toolchain JSON manifest (CPU/SoC, core counts, RAM GiB, AC power, OS/kernel, rustc, clang, gcc, llvm, libgccjit, python3, jax/jaxlib) to the specified output file.
libscript_emit_hw_manifest_json() {
  _ehm_out="${1}"
  _ehm_py="${2:-python3}"
  libscript_detect_hardware
  libscript_detect_ac_power
  mkdir -p "$(dirname -- "$_ehm_out")"

  _ehm_ram_gib=$(awk -v m="${LIBSCRIPT_HW_MEM_MB}" 'BEGIN { printf "%.2f", m / 1024.0 }')
  _ehm_rustc='unavailable'
  if command -v rustc >/dev/null 2>&1; then
    _ehm_rustc=$(rustc -vV 2>/dev/null | awk 'NR==1 {printf "%s", $0}; /^host:/ {printf " (%s)", $2}; /^LLVM version:/ {printf " [LLVM %s]", $3}' || printf 'unavailable')
  fi
  _ehm_clang='unavailable'
  _cand_clang="${CLANG_MATCHED:-clang}"
  if command -v "${_cand_clang}" >/dev/null 2>&1 || [ -x "${_cand_clang}" ]; then
    _ehm_clang=$("${_cand_clang}" --version 2>/dev/null | head -n 1 | tr -d '\r' || printf 'unavailable')
  fi
  _ehm_gcc='unavailable'
  _cand_gcc="${GCC_MATCHED:-gcc}"
  if command -v "${_cand_gcc}" >/dev/null 2>&1 || [ -x "${_cand_gcc}" ]; then
    _ehm_gcc=$("${_cand_gcc}" --version 2>/dev/null | head -n 1 | tr -d '\r' || printf 'unavailable')
  fi
  _ehm_llvm='unavailable'
  if [ -n "${LLVM_PREFIX:-}" ] && [ -x "${LLVM_PREFIX}/bin/llvm-config" ]; then
    _ehm_llvm=$("${LLVM_PREFIX}/bin/llvm-config" --version 2>/dev/null | head -n 1 | tr -d '\r' || printf 'unavailable')
  elif command -v llvm-config >/dev/null 2>&1; then
    _ehm_llvm=$(llvm-config --version 2>/dev/null | head -n 1 | tr -d '\r' || printf 'unavailable')
  fi
  _ehm_libgccjit="${EDG_LIBGCCJIT_PATH:-unavailable}"
  _ehm_pyver='unavailable'
  _ehm_jax='unavailable'
  _ehm_jaxlib='unavailable'
  if command -v "$_ehm_py" >/dev/null 2>&1 || [ -x "$_ehm_py" ]; then
    _ehm_pyver=$("$_ehm_py" --version 2>&1 | head -n 1 | tr -d '\r' || printf 'unavailable')
    _ehm_jax=$("$_ehm_py" -c 'import jax; print(jax.__version__)' 2>/dev/null | tr -d '\r' || printf 'unavailable')
    _ehm_jaxlib=$("$_ehm_py" -c 'import jaxlib; print(jaxlib.__version__)' 2>/dev/null | tr -d '\r' || printf 'unavailable')
  fi

  _ehm_gov='unknown'
  if [ -r /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
    _ehm_gov=$(head -n 1 /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || printf 'unknown')
  fi
  _ehm_aslr='unknown'
  if [ -r /proc/sys/kernel/randomize_va_space ]; then
    _ehm_aslr=$(head -n 1 /proc/sys/kernel/randomize_va_space 2>/dev/null || printf 'unknown')
  fi

  _ehm_esc_cpu=$(printf '%s' "${LIBSCRIPT_HW_CPU_MODEL}" | sed 's/\\/\\\\/g; s/"/\\"/g')
  _ehm_esc_rustc=$(printf '%s' "${_ehm_rustc}" | sed 's/\\/\\\\/g; s/"/\\"/g')
  _ehm_esc_clang=$(printf '%s' "${_ehm_clang}" | sed 's/\\/\\\\/g; s/"/\\"/g')
  _ehm_esc_gcc=$(printf '%s' "${_ehm_gcc}" | sed 's/\\/\\\\/g; s/"/\\"/g')
  _ehm_esc_llvm=$(printf '%s' "${_ehm_llvm}" | sed 's/\\/\\\\/g; s/"/\\"/g')
  _ehm_esc_jit=$(printf '%s' "${_ehm_libgccjit}" | sed 's/\\/\\\\/g; s/"/\\"/g')
  _ehm_esc_py=$(printf '%s' "${_ehm_pyver}" | sed 's/\\/\\\\/g; s/"/\\"/g')

  cat <<EOF > "${_ehm_out}.tmp"
{
  "schema_version": "1.0.0",
  "os": "${UNAME:-unknown}",
  "os_lower": "${UNAME_LOWER:-unknown}",
  "arch": "${ARCH:-unknown}",
  "kernel_release": "${KERNEL_RELEASE:-unknown}",
  "cpu_model": "${_ehm_esc_cpu}",
  "logical_cores": ${LIBSCRIPT_HW_CORES},
  "physical_cores": ${LIBSCRIPT_HW_PHYS_CORES},
  "performance_cores": ${LIBSCRIPT_HW_PERF_CORES},
  "numa_nodes": ${LIBSCRIPT_HW_NUMA_NODES},
  "ram_mib": ${LIBSCRIPT_HW_MEM_MB},
  "ram_gib": ${_ehm_ram_gib},
  "ac_power": "${LIBSCRIPT_HW_AC_POWER}",
  "simd": "${LIBSCRIPT_HW_SIMD}",
  "nvme": ${LIBSCRIPT_HW_NVME},
  "cpu_governor": "${_ehm_gov}",
  "aslr_mode": "${_ehm_aslr}",
  "toolchains": {
    "rustc": "${_ehm_esc_rustc}",
    "clang": "${_ehm_esc_clang}",
    "gcc": "${_ehm_esc_gcc}",
    "llvm": "${_ehm_esc_llvm}",
    "libgccjit": "${_ehm_esc_jit}",
    "python3": "${_ehm_esc_py}",
    "jax": "${_ehm_jax}",
    "jaxlib": "${_ehm_jaxlib}"
  }
}
EOF
  mv -f "${_ehm_out}.tmp" "${_ehm_out}"
}

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_hw_tune_caller_dir:-}" ] && SCRIPT_DIR="$_hw_tune_caller_dir"
[ -n "${_hw_tune_caller_this:-}" ] && THIS_FILE="$_hw_tune_caller_this"
unset SCRIPT_NAME _hw_tune_caller_this _hw_tune_caller_dir || true
