#!/bin/sh
# ## Overview
# Unified declarative Machine Learning CLI orchestrator (train, infer, serve-ml, eval-ml, benchmark-ml) supporting local hardware, Cloud TPU VMs, and TFRC zero-cost 7-backend evaluation.
#
# ## Usage
# Run via libscript.sh <train|infer|serve-ml|eval-ml|benchmark-ml> [libscript.json] [--tfrc-only] [--tfrc-config=<path>] [--backends=<csv|all>] [--dry-run]
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
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2; fi
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

_ls_src_this="${THIS_FILE:-}"
_ls_src_dir="${SCRIPT_DIR:-}"
for _ml_lib in engine/common/log.sh engine/common/os_info.sh engine/common/tfrc_guard.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_ml_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _ml_lib || true
if [ -n "${_ls_src_this}" ]; then THIS_FILE="${_ls_src_this}"; fi
if [ -n "${_ls_src_dir}" ]; then SCRIPT_DIR="${_ls_src_dir}"; fi

ACTION="${1:-train}"
shift || true

JSON_FILE=''
DRY_RUN_FLAG=0
TARGET_OVERRIDE=''
BACKEND_OVERRIDE=''
BACKENDS_MATRIX=''
WORKLOADS_CSV=''
CMD_OVERRIDE=''
CMD_TEMPLATE=''
FRESH_VM='0'
RESUME_FLAG='1'

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN_FLAG=1; shift ;;
    --target=*) TARGET_OVERRIDE="${1#*=}"; shift ;;
    --target) TARGET_OVERRIDE="$2"; shift 2 ;;
    --backend=*) BACKEND_OVERRIDE="${1#*=}"; shift ;;
    --backend) BACKEND_OVERRIDE="$2"; shift 2 ;;
    --backends=*) BACKENDS_MATRIX="${1#*=}"; shift ;;
    --backends) BACKENDS_MATRIX="$2"; shift 2 ;;
    --workloads=*|--subsuites=*) WORKLOADS_CSV="${1#*=}"; shift ;;
    --workloads|--subsuites) WORKLOADS_CSV="$2"; shift 2 ;;
    --command=*) CMD_OVERRIDE="${1#*=}"; shift ;;
    --command) CMD_OVERRIDE="$2"; shift 2 ;;
    --command-template=*) CMD_TEMPLATE="${1#*=}"; shift ;;
    --command-template) CMD_TEMPLATE="$2"; shift 2 ;;
    --tfrc-only) TFRC_STRICT='1'; export TFRC_STRICT; shift ;;
    --tfrc-config=*) TFRC_CONFIG="${1#*=}"; TFRC_STRICT='1'; export TFRC_CONFIG TFRC_STRICT; shift ;;
    --tfrc-config) TFRC_CONFIG="$2"; TFRC_STRICT='1'; export TFRC_CONFIG TFRC_STRICT; shift 2 ;;
    --fresh-vm-per-backend) FRESH_VM='1'; TPU_FRESH_VM_PER_BACKEND='1'; export TPU_FRESH_VM_PER_BACKEND; shift ;;
    --resume) RESUME_FLAG='1'; shift ;;
    --no-resume) RESUME_FLAG='0'; shift ;;
    --max-ttl-minutes=*) TFRC_MAX_TTL_MINUTES="${1#*=}"; export TFRC_MAX_TTL_MINUTES; shift ;;
    --max-ttl-minutes) TFRC_MAX_TTL_MINUTES="$2"; export TFRC_MAX_TTL_MINUTES; shift 2 ;;
    --gcs-bucket=*) GCS_BUCKET="${1#*=}"; BUCKET_NAME="${GCS_BUCKET#gs://}"; TFRC_STORAGE_MODE='same_region_gcs'; TFRC_EXPLICIT_GCS_BUCKET='1'; export GCS_BUCKET BUCKET_NAME TFRC_STORAGE_MODE TFRC_EXPLICIT_GCS_BUCKET; shift ;;
    --gcs-bucket) GCS_BUCKET="$2"; BUCKET_NAME="${GCS_BUCKET#gs://}"; TFRC_STORAGE_MODE='same_region_gcs'; TFRC_EXPLICIT_GCS_BUCKET='1'; export GCS_BUCKET BUCKET_NAME TFRC_STORAGE_MODE TFRC_EXPLICIT_GCS_BUCKET; shift 2 ;;
    *.json) JSON_FILE="$1"; shift ;;
    *)
      if [ -z "${JSON_FILE}" ] && [ -f "$1" ]; then
        JSON_FILE="$1"
      fi
      shift
      ;;
  esac
done

if [ -z "${JSON_FILE}" ]; then
  if [ -f 'libscript.json' ]; then
    JSON_FILE='libscript.json'
  elif [ -f 'install.json' ]; then
    JSON_FILE='install.json'
  fi
fi

MANIFEST_DIR=$(pwd)
if [ -n "${JSON_FILE}" ] && [ -f "${JSON_FILE}" ]; then
  MANIFEST_DIR=$(cd -- "$(dirname -- "${JSON_FILE}")" && pwd)
fi

ML_BACKEND=''
ML_TARGET='local'
ML_TRAIN_CMD=''
ML_INFER_CMD=''
ML_BENCH_CMD=''
ML_ETL_CMD=''
ML_MODEL_NAME=''

if [ -n "${JSON_FILE}" ] && [ -f "${JSON_FILE}" ] && command -v jq >/dev/null 2>&1; then
  ML_BACKEND=$(jq -r '.ml.backend // .training.backend // .inference.backend // .models.backend // empty' "${JSON_FILE}" 2>/dev/null || true)
  ML_TARGET=$(jq -r '.ml.target // .training.target // .inference.target // "local"' "${JSON_FILE}" 2>/dev/null || printf 'local')
  ML_TRAIN_CMD=$(jq -r '.ml.train_command // .ml.command // .training.command // empty' "${JSON_FILE}" 2>/dev/null || true)
  ML_INFER_CMD=$(jq -r '.ml.infer_command // .ml.serve_command // .inference.command // empty' "${JSON_FILE}" 2>/dev/null || true)
  ML_BENCH_CMD=$(jq -r '.ml.benchmark_command // .ml.eval_command // empty' "${JSON_FILE}" 2>/dev/null || true)
  ML_ETL_CMD=$(jq -r '.ml.etl_command // empty' "${JSON_FILE}" 2>/dev/null || true)
  ML_MODEL_NAME=$(jq -r '.ml.model // .ml.model_name // .models[0].name? // empty' "${JSON_FILE}" 2>/dev/null || true)
  _m_tfrc=$(jq -r '.ml.tfrc_only // false' "${JSON_FILE}" 2>/dev/null || printf 'false')
  if [ "${_m_tfrc}" = 'true' ]; then
    TFRC_STRICT='1'
    export TFRC_STRICT
  fi
  _m_tcfg=$(jq -r '.ml.tfrc_config // empty' "${JSON_FILE}" 2>/dev/null || true)
  if [ -n "${_m_tcfg}" ] && [ -z "${TFRC_CONFIG:-}" ]; then
    TFRC_CONFIG="${_m_tcfg}"
    export TFRC_CONFIG
  fi

  for _kv in $(jq -r '(.ml // {}) | to_entries[] | select((.value | type) == "string" or (.value | type) == "number") | "\(.key)=\(.value)"' "${JSON_FILE}" 2>/dev/null || true); do
    _k="${_kv%%=*}"
    _v="${_kv#*=}"
    case "${_k}" in
      tpu_name) export TPU_NAME="${_v}" ;;
      tpu_zone) export TPU_ZONE="${_v}"; export GCP_ZONE="${_v}" ;;
      tpu_type|accelerator_type) export TPU_ACCELERATOR_TYPE="${_v}" ;;
      tpu_scheduling_type) export TPU_SCHEDULING_TYPE="${_v}" ;;
      gcp_project|project_id) export GCP_PROJECT_ID="${_v}" ;;
      bucket|bucket_name) export BUCKET_NAME="${_v}" ;;
      docker_image) export DOCKER_IMAGE="${_v}" ;;
      num_slices|slices) export NUM_SLICES="${_v}"; export TPU_SLICE_COUNT="${_v}" ;;
    esac
  done
fi

if [ -n "${TARGET_OVERRIDE}" ]; then ML_TARGET="${TARGET_OVERRIDE}"; fi
if [ -n "${BACKEND_OVERRIDE}" ]; then ML_BACKEND="${BACKEND_OVERRIDE}"; fi
if [ -n "${ML_MODEL_NAME}" ] && [ -z "${MODEL_NAME:-}" ]; then
  MODEL_NAME="${ML_MODEL_NAME}"
  export MODEL_NAME
fi
export ML_TARGET

if libscript_tfrc_is_enabled; then
  libscript_tfrc_require_config "${MANIFEST_DIR}"
  libscript_tfrc_enforce_zero_cost_env
  if [ -n "${GCS_BUCKET:-}" ]; then
    libscript_tfrc_verify_gcs_bucket "${GCS_BUCKET}" "${TPU_ZONE:-$(jq -r '.grants[0].zone' "${TFRC_CONFIG}")}"
  fi
fi

if [ "${ACTION}" = 'benchmark-ml' ] || [ -n "${BACKENDS_MATRIX}" ]; then
  set -- tpu_matrix "--repo-dir=${MANIFEST_DIR}"
  if [ -n "${TFRC_CONFIG:-}" ]; then set -- "$@" "--tfrc-config=${TFRC_CONFIG}"; fi
  if [ -n "${MODEL_NAME:-}" ]; then set -- "$@" "--model=${MODEL_NAME}"; fi
  if [ -n "${BACKENDS_MATRIX}" ]; then set -- "$@" "--backends=${BACKENDS_MATRIX}"; fi
  if [ -n "${WORKLOADS_CSV}" ]; then set -- "$@" "--subsuites=${WORKLOADS_CSV}"; fi
  if [ -n "${CMD_TEMPLATE}" ]; then set -- "$@" "--command-template=${CMD_TEMPLATE}"; fi
  if [ "${FRESH_VM}" = '1' ]; then set -- "$@" '--fresh-vm-per-backend'; fi
  if [ "${RESUME_FLAG}" = '0' ]; then set -- "$@" '--no-resume'; fi
  if [ "${DRY_RUN_FLAG}" -eq 1 ]; then set -- "$@" '--dry-run'; fi
  STACK="${STACK%"${THIS_FILE}":}"
  export STACK
  if [ "${ML_TARGET}" = 'local' ] && ! libscript_tfrc_is_enabled; then
    exec "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment run gemma-tpu "$@"
  fi
  exec "${LIBSCRIPT_ROOT_DIR}/libscript.sh" rapid-experiment "$@"
fi

if [ -z "${ML_BACKEND}" ]; then
  if [ "${UNAME_LOWER:-}" = 'darwin' ] && [ "${ARCH:-}" = 'arm64' ]; then
    ML_BACKEND='mlx'
  else
    ML_BACKEND='pytorch'
  fi
fi

if [ "${ACTION}" = 'train' ] || [ "${ACTION}" = 'eval-ml' ]; then
  EXEC_CMD="${CMD_OVERRIDE:-${ML_TRAIN_CMD:-${ML_BENCH_CMD:-${ML_SCRIPT:-python train.py}}}}"
else
  if [ -n "${CMD_OVERRIDE}" ]; then
    EXEC_CMD="${CMD_OVERRIDE}"
  elif [ -n "${ML_INFER_CMD}" ]; then
    EXEC_CMD="${ML_INFER_CMD}"
  elif [ "${ML_BACKEND}" = 'ollama' ]; then
    EXEC_CMD="ollama run ${MODEL_NAME:-gemma2}"
  elif [ "${ML_BACKEND}" = 'vllm' ]; then
    EXEC_CMD="python -m vllm.entrypoints.openai.api_server --model ${MODEL_NAME:-google/gemma-2-2b-it}"
  else
    EXEC_CMD='python infer.py'
  fi
fi

log_info "ML Orchestrator: action=${ACTION} target=${ML_TARGET} backend=${ML_BACKEND} command='${EXEC_CMD}'"

if [ "${DRY_RUN_FLAG}" -eq 1 ]; then
  printf '[DRY-RUN] action=%s target=%s backend=%s command="%s"\n' "${ACTION}" "${ML_TARGET}" "${ML_BACKEND}" "${EXEC_CMD}"
  exit 0
fi

case "${ML_TARGET}" in
  local)
    if [ -n "${JSON_FILE}" ] && [ -f "${JSON_FILE}" ]; then
      deps=$("${LIBSCRIPT_ROOT_DIR}/engine/solver/resolve_stack.sh" "${JSON_FILE}" 2>/dev/null | jq -r '.selected[] | .name' 2>/dev/null || true)
      for _pkg in ${deps}; do
        for _cat_name in $(ls -1 "${LIBSCRIPT_ROOT_DIR}/_lib" 2>/dev/null || true); do
          _cat_dir="${LIBSCRIPT_ROOT_DIR}/_lib/${_cat_name}"
          [ -d "${_cat_dir}" ] || continue
          if [ -f "${_cat_dir}/${_pkg}/env.sh" ]; then
            SCRIPT_NAME="${_cat_dir}/${_pkg}/env.sh"
            export SCRIPT_NAME
            # shellcheck disable=SC1090
            . "${SCRIPT_NAME}" || true
          fi
        done
      done
      unset SCRIPT_NAME || true
    fi
    if [ -n "${ML_ETL_CMD}" ] && [ "${ACTION}" = 'train' ]; then
      log_info "Running ML ETL step: ${ML_ETL_CMD}"
      (cd "${MANIFEST_DIR}" && sh -c "${ML_ETL_CMD}")
    fi
    (cd "${MANIFEST_DIR}" && sh -c "${EXEC_CMD}")
    ;;
  gcp-tpu-vm|tpu-vm|tpu)
    export APP_DIR="${MANIFEST_DIR}"
    export ML_SCRIPT="${EXEC_CMD}"
    export WORKLOAD_CMD="${EXEC_CMD}"
    export TPU_BACKEND="${ML_BACKEND}"
    STACK="${STACK%"${THIS_FILE}":}"
    export STACK
    exec "${LIBSCRIPT_ROOT_DIR}/workloads/engine.sh" submit "${LIBSCRIPT_ROOT_DIR}/workloads/payloads/ai/gcp-tpu-vm/payload.json" --scheduler=tpu_vm
    ;;
  gcp-gpu-vm|gpu-vm|gpu)
    export APP_DIR="${MANIFEST_DIR}"
    export WORKLOAD_CMD="${EXEC_CMD}"
    STACK="${STACK%"${THIS_FILE}":}"
    export STACK
    exec "${LIBSCRIPT_ROOT_DIR}/workloads/payloads/ai/gcp-gpu-vm/deploy.sh"
    ;;
  gke-xpk|xpk)
    export TRAIN_SCRIPT="${EXEC_CMD}"
    export WORKLOAD_CMD="${EXEC_CMD}"
    STACK="${STACK%"${THIS_FILE}":}"
    export STACK
    if [ "${ACTION}" = 'train' ] || [ "${ACTION}" = 'eval-ml' ]; then
      exec "${LIBSCRIPT_ROOT_DIR}/workloads/engine.sh" submit "${LIBSCRIPT_ROOT_DIR}/workloads/payloads/ai/gke-xpk-training/payload.json" --scheduler=xpk
    else
      exec "${LIBSCRIPT_ROOT_DIR}/workloads/engine.sh" submit "${LIBSCRIPT_ROOT_DIR}/workloads/payloads/ai/gke-xpk-inference/payload.json" --scheduler=xpk
    fi
    ;;
  kubernetes|k8s)
    export WORKLOAD_CMD="${EXEC_CMD}"
    STACK="${STACK%"${THIS_FILE}":}"
    export STACK
    exec "${LIBSCRIPT_ROOT_DIR}/workloads/engine.sh" submit "${LIBSCRIPT_ROOT_DIR}/workloads/payloads/ai/vllm/payload.json" --scheduler=kubernetes
    ;;
  *)
    log_error "Unknown ML target: ${ML_TARGET}"
    exit 1
    ;;
esac
