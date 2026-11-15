#!/bin/sh
# ## Overview
# Orchestrates isolated 7-backend Google Cloud TPU /dev/shm uv virtualenvs, watermark eviction, --fresh-vm-per-backend cycling, and multi-host lockstep environment synthesis.
#
# ## Usage
# SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/ml-training/_common/tpu_matrix.sh"; export SCRIPT_NAME; . "${SCRIPT_NAME}"
set -feu
_tm_caller_this="${THIS_FILE:-}"; _tm_caller_dir="${SCRIPT_DIR:-}"
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
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2; fi
    if [ -n "${_tm_caller_dir}" ]; then SCRIPT_DIR="${_tm_caller_dir}"; fi; if [ -n "${_tm_caller_this}" ]; then THIS_FILE="${_tm_caller_this}"; fi; unset _tm_caller_this _tm_caller_dir || true
    if (return 0 2>/dev/null); then return 0; else exit 0; fi ;;
  *) if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

for _tm_lib in _lib/_common/log.sh _lib/_common/python_env.sh _lib/_common/remote_sync.sh _lib/ml-training/_common/tfrc_guard.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_tm_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _tm_lib || true

TPU_ALL_BACKENDS='hf_transformers,pytorch_native,keras_jax,keras_tensorflow,keras_pytorch,maxtext,jax_native'
export TPU_ALL_BACKENDS

# ## libscript_tpu_backend_spec
# Emits 'venv_group|cli_backend|keras_backend|runtime_ver|find_links|pip_pkgs|extra_env' for one of the 7 Gemma 4 TPU backends.
libscript_tpu_backend_spec() {
  _tm_bid="$1"
  _tm_shm="${2:-/dev/shm/libscript-tpu}"
  _tm_rt='auto'
  _tm_suite_json="${TPU_SUITE_MANIFEST_PATH:-${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/gemma-tpu-suite/gemma-tpu.suite.json}"
  if [ -f "${_tm_suite_json}" ] && command -v jq >/dev/null 2>&1; then
    _tm_cfg_rt=$(jq -r --arg b "${_tm_bid}" '([.tpu_matrix.backends[]? | select(.id == $b) | .tpu_runtime_version][0]) // "auto"' "${_tm_suite_json}" 2>/dev/null || printf 'auto')
    if [ -n "${_tm_cfg_rt}" ]; then
      _tm_rt="${_tm_cfg_rt}"
    fi
  fi
  case "${_tm_bid}" in
    hf_transformers)
      printf 'pytorch-xla|pytorch_hf||%s|-f https://storage.googleapis.com/libtpu-releases/index.html|torch torch_xla[tpu] transformers accelerate peft safetensors datasets|PJRT_DEVICE=TPU XLA_USE_BF16=1 HF_HOME=%s/cache/hf\n' "${_tm_rt}" "${_tm_shm}"
      ;;
    pytorch_native)
      printf 'pytorch-xla|pytorch_native||%s|-f https://storage.googleapis.com/libtpu-releases/index.html|torch torch_xla[tpu] transformers accelerate peft safetensors datasets|PJRT_DEVICE=TPU XLA_USE_BF16=1 HF_HOME=%s/cache/hf\n' "${_tm_rt}" "${_tm_shm}"
      ;;
    keras_jax)
      printf 'keras-jax|keras|jax|%s|-f https://storage.googleapis.com/jax-releases/libtpu_releases.html|jax[tpu] keras>=3 keras-hub keras-nlp tensorflow-cpu|KERAS_BACKEND=jax JAX_PLATFORMS=tpu KERAS_HOME=%s/cache/keras\n' "${_tm_rt}" "${_tm_shm}"
      ;;
    keras_tensorflow)
      printf 'keras-tf|keras|tensorflow|%s||tensorflow-tpu keras>=3 keras-hub keras-nlp|KERAS_BACKEND=tensorflow KERAS_HOME=%s/cache/keras\n' "${_tm_rt}" "${_tm_shm}"
      ;;
    keras_pytorch)
      printf 'keras-torch|keras|torch|%s|-f https://storage.googleapis.com/libtpu-releases/index.html|torch torch_xla[tpu] keras>=3 keras-hub keras-nlp tensorflow-cpu|KERAS_BACKEND=torch PJRT_DEVICE=TPU XLA_USE_BF16=1 KERAS_HOME=%s/cache/keras\n' "${_tm_rt}" "${_tm_shm}"
      ;;
    maxtext)
      printf 'maxtext|maxtext||%s|-f https://storage.googleapis.com/jax-releases/libtpu_releases.html|jax[tpu] flax optax orbax-checkpoint omegaconf einops grain aqt maxtext|JAX_PLATFORMS=tpu HF_HOME=%s/cache/hf\n' "${_tm_rt}" "${_tm_shm}"
      ;;
    jax_native)
      printf 'jax-native|jax||%s|-f https://storage.googleapis.com/jax-releases/libtpu_releases.html|jax[tpu] flax optax orbax-checkpoint grain datasets|JAX_PLATFORMS=tpu HF_HOME=%s/cache/hf\n' "${_tm_rt}" "${_tm_shm}"
      ;;
    *)
      log_error "Unsupported TPU matrix backend identifier: ${_tm_bid}"
      return 1
      ;;
  esac
}

# ## libscript_tpu_evict_shm_if_needed
# Evicts previously completed /dev/shm venv groups when free tmpfs capacity falls below min_free_gb while preserving cache/{hf,keras}.
libscript_tpu_evict_shm_if_needed() {
  _tm_keep_group="$1"
  _tm_shm_root="${2:-/dev/shm/libscript-tpu}"
  _tm_min_gb="${3:-${TFRC_SHM_MIN_FREE_GB:-32}}"

  mkdir -p "${_tm_shm_root}/venvs" "${_tm_shm_root}/cache/hf" "${_tm_shm_root}/cache/keras"
  _tm_free_kb="${TPU_MOCK_SHM_FREE_KB:-}"
  if [ -z "${_tm_free_kb}" ]; then
    _tm_free_kb=$(df -Pk "${_tm_shm_root}" 2>/dev/null | awk 'NR==2 {print $4}' || printf '0')
  fi
  case "${_tm_free_kb}" in
    ''|*[!0-9]*) _tm_free_kb=0 ;;
  esac
  _tm_min_kb=$(( _tm_min_gb * 1024 * 1024 ))
  if [ "${_tm_free_kb}" -ge "${_tm_min_kb}" ]; then
    return 0
  fi

  printf '[TPU-MATRIX] /dev/shm free=%s KiB < watermark=%s KiB; evicting completed venvs (preserving cache/{hf,keras})...\n' "${_tm_free_kb}" "${_tm_min_kb}" >&2
  for _tm_vname in $(ls -1 "${_tm_shm_root}/venvs" 2>/dev/null || true); do
    _tm_vdir="${_tm_shm_root}/venvs/${_tm_vname}"
    [ -d "${_tm_vdir}" ] || continue
    if [ "${_tm_vname}" = "${_tm_keep_group}" ] || [ "${_tm_vname}" = 'tpu-telemetry' ]; then
      continue
    fi
    rm -rf "${_tm_vdir}"
    printf '[TPU-MATRIX] Evicted completed venv group: %s\n' "${_tm_vname}" >&2
  done
}

# ## libscript_tpu_prepare_backend_venv
# Idempotently builds a stamp-guarded uv virtualenv in /dev/shm and installs TPU wheels followed by --no-deps -e workspace.
libscript_tpu_prepare_backend_venv() {
  _tm_bid="$1"
  _tm_ws="$2"
  _tm_shm_root="${3:-/dev/shm/libscript-tpu}"

  _tm_spec=$(libscript_tpu_backend_spec "${_tm_bid}" "${_tm_shm_root}")
  _tm_vgroup=$(printf '%s' "${_tm_spec}" | cut -d'|' -f1)
  _tm_flinks=$(printf '%s' "${_tm_spec}" | cut -d'|' -f5)
  _tm_pkgs=$(printf '%s' "${_tm_spec}" | cut -d'|' -f6)
  _tm_vdir="${_tm_shm_root}/venvs/${_tm_vgroup}"
  _tm_stamp_file="${_tm_vdir}/.libscript_wheels.sha256"

  _tm_dep_sig="${_tm_vgroup}|${_tm_flinks}|${_tm_pkgs}"
  if [ -f "${_tm_ws}/pyproject.toml" ]; then
    _tm_pyproj_h=$(cksum "${_tm_ws}/pyproject.toml" | awk '{print $1 "-" $2}')
    _tm_dep_sig="${_tm_dep_sig}|${_tm_pyproj_h}"
  fi
  _tm_stamp=$(printf '%s' "${_tm_dep_sig}" | cksum | awk '{print $1 "-" $2}')

  if [ -f "${_tm_stamp_file}" ] && [ -x "${_tm_vdir}/bin/python" ]; then
    _tm_prev=$(cat "${_tm_stamp_file}" 2>/dev/null || true)
    if [ "${_tm_prev}" = "${_tm_stamp}" ]; then
      printf '[TPU-MATRIX] Reusing isolated venv %s for backend %s (stamp=%s).\n' "${_tm_vdir}" "${_tm_bid}" "${_tm_stamp}" >&2
      printf '%s\n' "${_tm_vdir}"
      return 0
    fi
  fi

  libscript_tpu_evict_shm_if_needed "${_tm_vgroup}" "${_tm_shm_root}" "${TFRC_SHM_MIN_FREE_GB:-32}"

  LIBSCRIPT_PYTHON_VENV_BACKEND='uv'
  export LIBSCRIPT_PYTHON_VENV_BACKEND
  libscript_python_venv "${_tm_vdir}" "${TPU_PYTHON_VERSION:-3.12}" >&2

  _tm_app_deps='duckdb aiosqlite asyncpg fastapi uvicorn datasets'
  # shellcheck disable=SC2086
  uv pip install --python "${_tm_vdir}/bin/python" ${_tm_flinks} ${_tm_app_deps} ${_tm_pkgs} >&2
  if [ -f "${_tm_ws}/pyproject.toml" ] || [ -f "${_tm_ws}/setup.py" ]; then
    uv pip install --python "${_tm_vdir}/bin/python" --no-deps -e "${_tm_ws}" >&2
  fi

  printf '%s\n' "${_tm_stamp}" > "${_tm_stamp_file}.tmp"
  mv -f "${_tm_stamp_file}.tmp" "${_tm_stamp_file}"
  printf '%s\n' "${_tm_vdir}"
}

# ## libscript_tpu_multihost_env
# Synthesizes space-separated KEY=VALUE exports for single-host or multi-host lockstep worker execution.
libscript_tpu_multihost_env() {
  _tm_bid="$1"
  _tm_topo_json="$2"
  _tm_widx="${3:-0}"
  _tm_shm_root="${4:-/dev/shm/libscript-tpu}"

  _tm_spec=$(libscript_tpu_backend_spec "${_tm_bid}" "${_tm_shm_root}")
  _tm_base_env=$(printf '%s' "${_tm_spec}" | cut -d'|' -f7)

  _tm_wcnt=$(printf '%s' "${_tm_topo_json}" | jq -r '.worker_count // 1' 2>/dev/null || printf '1')
  _tm_ip0=$(printf '%s' "${_tm_topo_json}" | jq -r '.worker0_internal_ip // "127.0.0.1"' 2>/dev/null || printf '127.0.0.1')
  _tm_ips=$(printf '%s' "${_tm_topo_json}" | jq -r '.worker_ips // "127.0.0.1"' 2>/dev/null || printf '127.0.0.1')

  _tm_out="${_tm_base_env} TPU_WORKER_ID=${_tm_widx} TPU_NUM_WORKERS=${_tm_wcnt} TPU_WORKER_HOSTNAMES=${_tm_ips}"
  if [ "${_tm_wcnt}" -gt 1 ]; then
    case "${_tm_bid}" in
      jax_native|maxtext|keras_jax)
        _tm_out="${_tm_out} JAX_COORDINATOR_ADDRESS=${_tm_ip0}:8476 MEGASCALE_COORDINATOR_ADDRESS=${_tm_ip0}:8476 PROCESS_ID=${_tm_widx} NUM_PROCESSES=${_tm_wcnt}"
        ;;
      hf_transformers|pytorch_native|keras_pytorch)
        _tm_out="${_tm_out} PJRT_DEVICE=TPU MASTER_ADDR=${_tm_ip0} MASTER_PORT=8477 PT_XLA_PJRT_DIST_SERVICE_ADDR=${_tm_ip0}:8477"
        ;;
    esac
  fi
  printf '%s\n' "${_tm_out}"
}

# ## libscript_tpu_bootstrap_remote
# Syncs LibScript and target workspace to all TPU VM workers and bootstraps Python 3.12 + uv idempotently.
libscript_tpu_bootstrap_remote() {
  _tm_tpu="$1"
  _tm_repo="$2"
  _tm_tpu_cli="${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/gcp-tpu-vm/cli.sh"

  "${_tm_tpu_cli}" sync-repo "${_tm_tpu}" "${LIBSCRIPT_ROOT_DIR}" 'libscript' --all-workers
  if [ -n "${_tm_repo}" ] && [ -d "${_tm_repo}" ]; then
    "${_tm_tpu_cli}" sync-repo "${_tm_tpu}" "${_tm_repo}" 'workspace' --all-workers
  fi
  "${_tm_tpu_cli}" ssh "${_tm_tpu}" --all-workers --command="mkdir -p /dev/shm/libscript-tpu/venvs /dev/shm/libscript-tpu/cache/hf /dev/shm/libscript-tpu/cache/keras && ./libscript/libscript.sh install python 3.12 && ./libscript/libscript.sh install uv latest"
}

# ## libscript_tpu_cycle_vm_for_backend
# Releases device locks or reprovisions a fresh TPU VM when --fresh-vm-per-backend or runtime change is requested.
libscript_tpu_cycle_vm_for_backend() {
  _tm_tpu="$1"
  _tm_bid="$2"
  _tm_repo="$3"
  _tm_cur_rt="${4:-}"
  _tm_tpu_cli="${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/gcp-tpu-vm/cli.sh"

  _tm_spec=$(libscript_tpu_backend_spec "${_tm_bid}")
  _tm_req_rt=$(printf '%s' "${_tm_spec}" | cut -d'|' -f4)
  if [ -z "${_tm_cur_rt}" ] && [ -n "${_tm_req_rt}" ] && [ "${_tm_req_rt}" != 'auto' ]; then
    _tm_cur_topo=$("${_tm_tpu_cli}" topology-info "${_tm_tpu}" 2>/dev/null || printf '{}')
    _tm_cur_rt=$(printf '%s' "${_tm_cur_topo}" | jq -r '.runtime_version // ""' 2>/dev/null || true)
  fi

  _tm_need_cycle=0
  if [ "${TPU_FRESH_VM_PER_BACKEND:-0}" = '1' ] || [ "${TPU_FRESH_VM_PER_BACKEND:-false}" = 'true' ]; then
    _tm_need_cycle=1
  elif [ -n "${_tm_req_rt}" ] && [ "${_tm_req_rt}" != 'auto' ] && [ -n "${_tm_cur_rt}" ] && [ "${_tm_req_rt}" != "${_tm_cur_rt}" ]; then
    _tm_need_cycle=1
  fi

  if [ "${_tm_need_cycle}" -eq 0 ]; then
    "${_tm_tpu_cli}" release-locks "${_tm_tpu}"
    return 0
  fi

  printf '[TPU-MATRIX] Cycling fresh Cloud TPU VM %s for backend %s (runtime=%s)...\n' "${_tm_tpu}" "${_tm_bid}" "${_tm_req_rt}" >&2
  "${_tm_tpu_cli}" delete "${_tm_tpu}"
  if libscript_tfrc_is_enabled && [ -n "${TPU_ZONE:-}" ]; then
    libscript_tfrc_postflight_audit "${GCP_PROJECT_ID:-}" "${TPU_ZONE}" "${_tm_tpu}"
  fi
  TPU_VERSION="${_tm_req_rt}"
  export TPU_VERSION
  "${_tm_tpu_cli}" create "${_tm_tpu}"
  "${_tm_tpu_cli}" wait-ready "${_tm_tpu}"
  "${_tm_tpu_cli}" arm-ttl "${_tm_tpu}" --minutes "${TFRC_MAX_TTL_MINUTES:-180}"
  libscript_tpu_bootstrap_remote "${_tm_tpu}" "${_tm_repo}"
}

# ## libscript_tpu_run_lockstep
# Executes a command across all workers of a TPU VM slice simultaneously, capturing per-worker logs and failing if any worker fails.
libscript_tpu_run_lockstep() {
  _tm_tpu="$1"
  _tm_bid="$2"
  _tm_cmd="$3"
  _tm_log_dir="$4"
  _tm_tpu_cli="${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/gcp-tpu-vm/cli.sh"

  mkdir -p "${_tm_log_dir}"
  _tm_topo=$("${_tm_tpu_cli}" topology-info "${_tm_tpu}")
  _tm_wcnt=$(printf '%s' "${_tm_topo}" | jq -r '.worker_count // 1')
  _tm_env0=$(libscript_tpu_multihost_env "${_tm_bid}" "${_tm_topo}" '0')

  if [ "${_tm_wcnt}" -le 1 ]; then
    if ! "${_tm_tpu_cli}" ssh "${_tm_tpu}" --command="export ${_tm_env0}; ${_tm_cmd}" > "${_tm_log_dir}/worker_0.log" 2>&1; then
      return 1
    fi
    return 0
  fi

  _tm_ip0=$(printf '%s' "${_tm_topo}" | jq -r '.worker0_internal_ip // "127.0.0.1"')
  _tm_ips=$(printf '%s' "${_tm_topo}" | jq -r '.worker_ips // "127.0.0.1"')
  _tm_spec=$(libscript_tpu_backend_spec "${_tm_bid}")
  _tm_base_env=$(printf '%s' "${_tm_spec}" | cut -d'|' -f7)

  _tm_dist_extra=''
  case "${_tm_bid}" in
    jax_native|maxtext|keras_jax)
      _tm_dist_extra="JAX_COORDINATOR_ADDRESS=${_tm_ip0}:8476 MEGASCALE_COORDINATOR_ADDRESS=${_tm_ip0}:8476"
      ;;
    hf_transformers|pytorch_native|keras_pytorch)
      _tm_dist_extra="PJRT_DEVICE=TPU MASTER_ADDR=${_tm_ip0} MASTER_PORT=8477 PT_XLA_PJRT_DIST_SERVICE_ADDR=${_tm_ip0}:8477"
      ;;
  esac

  # shellcheck disable=SC2016
  _tm_remote_wrap='_wid="${TPU_WORKER_ID:-0}"; export '"${_tm_base_env}"' TPU_NUM_WORKERS='"${_tm_wcnt}"' TPU_WORKER_HOSTNAMES='"${_tm_ips}"' PROCESS_ID="${_wid}" NUM_PROCESSES='"${_tm_wcnt}"' '"${_tm_dist_extra}"'; '"${_tm_cmd}"
  if ! "${_tm_tpu_cli}" ssh "${_tm_tpu}" --all-workers --command="${_tm_remote_wrap}" > "${_tm_log_dir}/workers_all.log" 2>&1; then
    return 1
  fi
  return 0
}

STACK="${STACK%"${THIS_FILE}":}"
export STACK
if [ -n "${_tm_caller_dir}" ]; then SCRIPT_DIR="${_tm_caller_dir}"; fi
if [ -n "${_tm_caller_this}" ]; then THIS_FILE="${_tm_caller_this}"; fi
unset _tm_caller_this _tm_caller_dir || true
