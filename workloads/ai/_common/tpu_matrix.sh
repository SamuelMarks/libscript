#!/bin/sh
# ## Overview
# Orchestrates isolated 7-backend Google Cloud TPU /dev/shm uv virtualenvs, watermark eviction, --fresh-vm-per-backend cycling, SKU runtime resolution, and multi-host lockstep environment synthesis.
#
# ## Usage
# SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/workloads/ai/_common/tpu_matrix.sh"; export SCRIPT_NAME; . "${SCRIPT_NAME}"
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

for _tm_lib in engine/common/log.sh engine/common/python_env.sh engine/common/remote_sync.sh engine/common/tfrc_guard.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_tm_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _tm_lib || true

TPU_ALL_BACKENDS='hf_transformers,pytorch_native,keras_jax,keras_tensorflow,keras_pytorch,maxtext,jax_native'
export TPU_ALL_BACKENDS

# ## libscript_tpu_resolve_runtime_version
# Maps a Cloud TPU accelerator SKU (v4, v5e/v5litepod, v5p, v6e) to its canonical TPU VM OS image when runtime_ver is empty or 'auto'.
libscript_tpu_resolve_runtime_version() {
  _tm_sku="${1:-${TPU_ACCELERATOR_TYPE:-v4-8}}"
  _tm_ver="${2:-auto}"
  if [ -n "${_tm_ver}" ] && [ "${_tm_ver}" != 'auto' ]; then
    printf '%s\n' "${_tm_ver}"
    return 0
  fi
  case "${_tm_sku}" in
    v2-*|v3-*|v4-*) printf '%s\n' 'tpu-ubuntu2204-base' ;;
    v5litepod-*|v5e-*) printf '%s\n' 'v2-alpha-tpuv5-lite' ;;
    v5p-*) printf '%s\n' 'v2-alpha-tpuv5' ;;
    v6e-*) printf '%s\n' 'v2-alpha-tpuv6e' ;;
    *) printf '%s\n' 'tpu-ubuntu2204-base' ;;
  esac
}

# ## libscript_tpu_family_label
# Emits the canonical 5-family study comparison group label for one of the 7 Gemma 4 TPU backend cells.
libscript_tpu_family_label() {
  case "${1:-}" in
    hf_transformers) printf '%s\n' 'Hugging Face Transformers [which wraps PyTorch]' ;;
    pytorch_native) printf '%s\n' 'PyTorch [native]' ;;
    keras_jax|keras_tensorflow|keras_pytorch) printf '%s\n' 'Keras [and its JAX, TensorFlow, and PyTorch backends]' ;;
    maxtext) printf '%s\n' 'MaxText [which wraps JAX]' ;;
    jax_native) printf '%s\n' 'JAX [native]' ;;
    *) printf '%s\n' 'Custom' ;;
  esac
}

# ## libscript_tpu_ensure_host_tools
# Idempotently provisions required Tier 1 _lib/ CLI components when absent from PATH.
libscript_tpu_ensure_host_tools() {
  _tm_need_gcloud="${1:-0}"
  for _tm_pair in 'jq:jq:latest' 'uv:uv:latest' 'python3:python:3.12' 'sqlite3:sqlite:latest' 'duckdb:duckdb:latest' 'huggingface-cli:huggingface-cli:latest'; do
    _tm_bin=$(printf '%s' "${_tm_pair}" | cut -d':' -f1)
    _tm_comp=$(printf '%s' "${_tm_pair}" | cut -d':' -f2)
    _tm_ver_req=$(printf '%s' "${_tm_pair}" | cut -d':' -f3)
    if command -v "${_tm_bin}" >/dev/null 2>&1; then
      continue
    fi
    if [ "${_tm_comp}" = 'duckdb' ] || [ "${_tm_comp}" = 'huggingface-cli' ] || [ "${_tm_comp}" = 'sqlite' ]; then
      if [ "${GEMMA_4_SQL_SYNTHETIC_FIXTURES:-0}" = '1' ] || [ "${GEMMA_4_SQL_DRY_RUN:-0}" = '1' ]; then
        continue
      fi
    fi
    STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install "${_tm_comp}" "${_tm_ver_req}" >/dev/null 2>&1 || true
  done
  if [ "${_tm_need_gcloud}" = '1' ] && ! command -v gcloud >/dev/null 2>&1; then
    STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install gcp-cli latest >/dev/null 2>&1 || true
  fi
}

# ## libscript_tpu_backend_spec
# Emits 'venv_group|cli_backend|keras_backend|runtime_ver|find_links|pip_pkgs|extra_env' for one of the 7 Gemma 4 TPU backends.
libscript_tpu_backend_spec() {
  _tm_bid="$1"
  _tm_shm="${2:-/dev/shm/libscript-tpu}"
  _tm_rt_cfg='auto'
  _tm_suite_json="${TPU_SUITE_MANIFEST_PATH:-${LIBSCRIPT_ROOT_DIR}/workloads/ai/_common/tpu_matrix_defaults.json}"
  if [ -f "${_tm_suite_json}" ] && command -v jq >/dev/null 2>&1; then
    _tm_cfg_rt=$(jq -r --arg b "${_tm_bid}" '([.tpu_matrix.backends[]? | select(.id == $b) | .tpu_runtime_version][0]) // "auto"' "${_tm_suite_json}" 2>/dev/null || printf 'auto')
    if [ -n "${_tm_cfg_rt}" ]; then
      _tm_rt_cfg="${_tm_cfg_rt}"
    fi
  fi
  _tm_rt=$(libscript_tpu_resolve_runtime_version "${TPU_ACCELERATOR_TYPE:-v4-8}" "${_tm_rt_cfg}")
  case "${_tm_bid}" in
    hf_transformers)
      printf 'pytorch-xla|hf_transformers||%s|-f https://storage.googleapis.com/libtpu-releases/index.html|torch torch_xla[tpu] transformers accelerate peft safetensors datasets duckdb|PJRT_DEVICE=TPU XLA_USE_BF16=1 HF_HOME=%s/cache/hf\n' "${_tm_rt}" "${_tm_shm}"
      ;;
    pytorch_native)
      printf 'pytorch-xla|pytorch_native||%s|-f https://storage.googleapis.com/libtpu-releases/index.html|torch torch_xla[tpu] transformers accelerate peft safetensors datasets duckdb|PJRT_DEVICE=TPU XLA_USE_BF16=1 HF_HOME=%s/cache/hf\n' "${_tm_rt}" "${_tm_shm}"
      ;;
    keras_jax)
      printf 'keras-jax|keras_jax|jax|%s|-f https://storage.googleapis.com/jax-releases/libtpu_releases.html|jax[tpu] keras>=3 keras-hub tensorflow-cpu duckdb|KERAS_BACKEND=jax JAX_PLATFORMS=tpu KERAS_HOME=%s/cache/keras\n' "${_tm_rt}" "${_tm_shm}"
      ;;
    keras_tensorflow)
      printf 'keras-tf|keras_tensorflow|tensorflow|%s||tensorflow-tpu keras>=3 keras-hub duckdb|KERAS_BACKEND=tensorflow KERAS_HOME=%s/cache/keras\n' "${_tm_rt}" "${_tm_shm}"
      ;;
    keras_pytorch)
      printf 'keras-torch|keras_pytorch|torch|%s|-f https://storage.googleapis.com/libtpu-releases/index.html|torch torch_xla[tpu] keras>=3 keras-hub tensorflow-cpu duckdb|KERAS_BACKEND=torch PJRT_DEVICE=TPU XLA_USE_BF16=1 KERAS_HOME=%s/cache/keras\n' "${_tm_rt}" "${_tm_shm}"
      ;;
    maxtext)
      printf 'maxtext|maxtext||%s|-f https://storage.googleapis.com/jax-releases/libtpu_releases.html|jax[tpu] flax optax orbax-checkpoint omegaconf einops grain aqt maxtext duckdb|JAX_PLATFORMS=tpu HF_HOME=%s/cache/hf\n' "${_tm_rt}" "${_tm_shm}"
      ;;
    jax_native)
      printf 'jax-native|jax_native||%s|-f https://storage.googleapis.com/jax-releases/libtpu_releases.html|jax[tpu] flax optax orbax-checkpoint grain datasets duckdb|JAX_PLATFORMS=tpu HF_HOME=%s/cache/hf\n' "${_tm_rt}" "${_tm_shm}"
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
# Idempotently builds a stamp-guarded uv virtualenv in /dev/shm and installs workspace requirements + TPU wheels + --no-deps -e workspace.
libscript_tpu_prepare_backend_venv() {
  _tm_bid="$1"
  _tm_ws="$2"
  _tm_shm_root="${3:-/dev/shm/libscript-tpu}"

  if ! command -v uv >/dev/null 2>&1; then
    STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install uv latest >&2 || true
  fi

  _tm_spec=$(libscript_tpu_backend_spec "${_tm_bid}" "${_tm_shm_root}")
  _tm_vgroup=$(printf '%s' "${_tm_spec}" | cut -d'|' -f1)
  _tm_flinks=$(printf '%s' "${_tm_spec}" | cut -d'|' -f5)
  _tm_pkgs=$(printf '%s' "${_tm_spec}" | cut -d'|' -f6)
  _tm_vdir="${_tm_shm_root}/venvs/${_tm_vgroup}"
  _tm_stamp_file="${_tm_vdir}/.libscript_wheels.sha256"

  _tm_dep_sig="${_tm_vgroup}|${_tm_flinks}|${_tm_pkgs}"
  for _tm_rf in pyproject.toml requirements.txt requirements-duckdb.txt requirements-pytorch.txt requirements-jax.txt requirements-keras.txt requirements-maxtext.txt; do
    if [ -f "${_tm_ws}/${_tm_rf}" ]; then
      _tm_rh=$(cksum "${_tm_ws}/${_tm_rf}" | awk '{print $1 "-" $2}')
      _tm_dep_sig="${_tm_dep_sig}|${_tm_rf}:${_tm_rh}"
    fi
  done
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

  if [ -f "${_tm_ws}/requirements.txt" ]; then
    uv pip install --python "${_tm_vdir}/bin/python" -r "${_tm_ws}/requirements.txt" >&2
  fi
  if [ -f "${_tm_ws}/requirements-duckdb.txt" ]; then
    uv pip install --python "${_tm_vdir}/bin/python" -r "${_tm_ws}/requirements-duckdb.txt" >&2
  fi

  _tm_app_deps='duckdb aiosqlite asyncpg fastapi uvicorn datasets sqlglot'
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

# ## libscript_tpu_secret_exports
# Builds shell-quoted credential exports (HF_TOKEN, KAGGLE_USERNAME, KAGGLE_KEY) for remote worker SSH execution without logging values.
libscript_tpu_secret_exports() {
  _tm_sec_out=''
  _tm_hft="${HF_TOKEN:-${HUGGING_FACE_HUB_TOKEN:-}}"
  if [ -n "${_tm_hft}" ]; then
    _tm_esc=$(printf '%s' "${_tm_hft}" | awk '{gsub(/\x27/, "\x27\\\x27\x27"); printf "%s", $0}')
    _tm_sec_out="export HF_TOKEN='${_tm_esc}' HUGGING_FACE_HUB_TOKEN='${_tm_esc}'; "
  fi
  if [ -n "${KAGGLE_USERNAME:-}" ]; then
    _tm_ku=$(printf '%s' "${KAGGLE_USERNAME}" | awk '{gsub(/\x27/, "\x27\\\x27\x27"); printf "%s", $0}')
    _tm_sec_out="${_tm_sec_out}export KAGGLE_USERNAME='${_tm_ku}'; "
  fi
  if [ -n "${KAGGLE_KEY:-}" ]; then
    _tm_kk=$(printf '%s' "${KAGGLE_KEY}" | awk '{gsub(/\x27/, "\x27\\\x27\x27"); printf "%s", $0}')
    _tm_sec_out="${_tm_sec_out}export KAGGLE_KEY='${_tm_kk}'; "
  fi
  printf '%s' "${_tm_sec_out}"
}

# ## libscript_tpu_bootstrap_remote
# Syncs LibScript and target workspace to all TPU VM workers and bootstraps Python 3.12, uv, jq, sqlite, duckdb, and huggingface-cli idempotently.
libscript_tpu_bootstrap_remote() {
  _tm_tpu="$1"
  _tm_repo="$2"
  _tm_tpu_cli="${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh"

  "${_tm_tpu_cli}" sync-repo "${_tm_tpu}" "${LIBSCRIPT_ROOT_DIR}" 'libscript' --all-workers
  if [ -n "${_tm_repo}" ] && [ -d "${_tm_repo}" ]; then
    "${_tm_tpu_cli}" sync-repo "${_tm_tpu}" "${_tm_repo}" 'workspace' --all-workers
  fi
  "${_tm_tpu_cli}" ssh "${_tm_tpu}" --all-workers --command="mkdir -p /dev/shm/libscript-tpu/venvs /dev/shm/libscript-tpu/cache/hf /dev/shm/libscript-tpu/cache/keras \"\$HOME/results/raw\" && \"\$HOME/libscript/libscript.sh\" install python 3.12 && \"\$HOME/libscript/libscript.sh\" install uv latest && \"\$HOME/libscript/libscript.sh\" install jq latest && \"\$HOME/libscript/libscript.sh\" install sqlite latest && \"\$HOME/libscript/libscript.sh\" install duckdb latest && \"\$HOME/libscript/libscript.sh\" install huggingface-cli latest"
}

# ## libscript_tpu_cycle_vm_for_backend
# Releases device locks or reprovisions a fresh TPU VM when --fresh-vm-per-backend or runtime change is requested.
libscript_tpu_cycle_vm_for_backend() {
  _tm_tpu="$1"
  _tm_bid="$2"
  _tm_repo="$3"
  _tm_cur_rt="${4:-}"
  _tm_tpu_cli="${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh"

  _tm_spec=$(libscript_tpu_backend_spec "${_tm_bid}")
  _tm_req_rt=$(printf '%s' "${_tm_spec}" | cut -d'|' -f4)
  if [ -z "${_tm_cur_rt}" ] && [ -n "${_tm_req_rt}" ]; then
    _tm_cur_topo=$("${_tm_tpu_cli}" topology-info "${_tm_tpu}" 2>/dev/null || printf '{}')
    _tm_cur_rt=$(printf '%s' "${_tm_cur_topo}" | jq -r '.runtime_version // ""' 2>/dev/null || true)
  fi

  _tm_need_cycle=0
  if [ "${TPU_FRESH_VM_PER_BACKEND:-0}" = '1' ] || [ "${TPU_FRESH_VM_PER_BACKEND:-false}" = 'true' ]; then
    _tm_need_cycle=1
  elif [ -n "${_tm_req_rt}" ] && [ -n "${_tm_cur_rt}" ] && [ "${_tm_req_rt}" != "${_tm_cur_rt}" ]; then
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
# Executes a command across all workers of a TPU VM slice simultaneously, forwarding credentials and failing if any worker fails.
libscript_tpu_run_lockstep() {
  _tm_tpu="$1"
  _tm_bid="$2"
  _tm_cmd="$3"
  _tm_log_dir="$4"
  _tm_tpu_cli="${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh"

  mkdir -p "${_tm_log_dir}"
  _tm_topo=$("${_tm_tpu_cli}" topology-info "${_tm_tpu}")
  _tm_wcnt=$(printf '%s' "${_tm_topo}" | jq -r '.worker_count // 1')
  _tm_env0=$(libscript_tpu_multihost_env "${_tm_bid}" "${_tm_topo}" '0')
  _tm_secrets=$(libscript_tpu_secret_exports)

  if [ "${_tm_wcnt}" -le 1 ]; then
    if ! "${_tm_tpu_cli}" ssh "${_tm_tpu}" --command="${_tm_secrets}export ${_tm_env0}; ${_tm_cmd}" > "${_tm_log_dir}/worker_0.log" 2>&1; then
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
  _tm_remote_wrap="${_tm_secrets}"'_wid="${TPU_WORKER_ID:-0}"; export '"${_tm_base_env}"' TPU_NUM_WORKERS='"${_tm_wcnt}"' TPU_WORKER_HOSTNAMES='"${_tm_ips}"' PROCESS_ID="${_wid}" NUM_PROCESSES='"${_tm_wcnt}"' '"${_tm_dist_extra}"'; '"${_tm_cmd}"
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
