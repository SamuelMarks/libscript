#!/bin/sh
# ## Overview
# Unified declarative Machine Learning CLI orchestrator (`train`, `infer`, `serve-ml`, `eval-ml`).
# Executes `.ml` / `.models` / `.training` / `.inference` workflows from `libscript.json` across
# local hardware (CPU, CUDA, Apple Silicon MLX, Ollama, vLLM) and cloud accelerators (GCP TPU VM, GCP GPU VM, GKE XPK).
#
# ## Usage
# Run via `libscript.sh train [libscript.json] [--dry-run]` or `libscript.sh infer [libscript.json] [--dry-run]`.

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

_ls_src_this="${THIS_FILE:-}"; _ls_src_dir="${SCRIPT_DIR:-}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true
[ -n "${_ls_src_this:-}" ] && THIS_FILE="$_ls_src_this"
[ -n "${_ls_src_dir:-}" ] && SCRIPT_DIR="$_ls_src_dir"

ACTION="${1:-train}"
shift || true

JSON_FILE=""
DRY_RUN=0
TARGET_OVERRIDE=""
BACKEND_OVERRIDE=""
CMD_OVERRIDE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --target) TARGET_OVERRIDE="$2"; shift 2 ;;
    --backend) BACKEND_OVERRIDE="$2"; shift 2 ;;
    --command) CMD_OVERRIDE="$2"; shift 2 ;;
    *.json) JSON_FILE="$1"; shift ;;
    *)
      if [ -z "$JSON_FILE" ] && [ -f "$1" ]; then
        JSON_FILE="$1"
      fi
      shift
      ;;
  esac
done

if [ -z "$JSON_FILE" ]; then
  if [ -f "libscript.json" ]; then
    JSON_FILE='libscript.json'
  elif [ -f "install.json" ]; then
    JSON_FILE='install.json'
  fi
fi

MANIFEST_DIR="$(pwd)"
if [ -n "$JSON_FILE" ] && [ -f "$JSON_FILE" ]; then
  MANIFEST_DIR=$(cd -- "$(dirname -- "$JSON_FILE")" && pwd)
fi

ML_BACKEND=""
ML_TARGET='local'
ML_TRAIN_CMD=""
ML_INFER_CMD=""
ML_ETL_CMD=""
ML_MODEL_NAME=""

if [ -n "$JSON_FILE" ] && [ -f "$JSON_FILE" ] && command -v jq >/dev/null 2>&1; then
  ML_BACKEND=$(jq -r '.ml.backend // .training.backend // .inference.backend // .models.backend // empty' "$JSON_FILE" 2>/dev/null || true)
  ML_TARGET=$(jq -r '.ml.target // .training.target // .inference.target // "local"' "$JSON_FILE" 2>/dev/null || printf 'local')
  ML_TRAIN_CMD=$(jq -r '.ml.train_command // .ml.command // .training.command // empty' "$JSON_FILE" 2>/dev/null || true)
  ML_INFER_CMD=$(jq -r '.ml.infer_command // .ml.serve_command // .inference.command // empty' "$JSON_FILE" 2>/dev/null || true)
  ML_ETL_CMD=$(jq -r '.ml.etl_command // empty' "$JSON_FILE" 2>/dev/null || true)
  ML_MODEL_NAME=$(jq -r '.ml.model // .ml.model_name // .models[0].name? // empty' "$JSON_FILE" 2>/dev/null || true)

  # Export optional cloud/accelerator fields from .ml block
  for _kv in $(jq -r '(.ml // {}) | to_entries[] | select((.value | type) == "string" or (.value | type) == "number") | "\(.key)=\(.value)"' "$JSON_FILE" 2>/dev/null || true); do
    _k="${_kv%%=*}"
    _v="${_kv#*=}"
    case "$_k" in
      tpu_name) export TPU_NAME="$_v" ;;
      tpu_zone) export TPU_ZONE="$_v"; export GCP_ZONE="$_v" ;;
      tpu_type|accelerator_type) export TPU_ACCELERATOR_TYPE="$_v" ;;
      gcp_project|project_id) export GCP_PROJECT_ID="$_v" ;;
      bucket|bucket_name) export BUCKET_NAME="$_v" ;;
      docker_image) export DOCKER_IMAGE="$_v" ;;
      num_slices|slices) export NUM_SLICES="$_v"; export TPU_SLICE_COUNT="$_v" ;;
    esac
  done
fi

[ -n "$TARGET_OVERRIDE" ] && ML_TARGET="$TARGET_OVERRIDE"
[ -n "$BACKEND_OVERRIDE" ] && ML_BACKEND="$BACKEND_OVERRIDE"
[ -n "$ML_MODEL_NAME" ] && [ -z "${MODEL_NAME:-}" ] && export MODEL_NAME="$ML_MODEL_NAME"

# Auto-detect backend if not set
if [ -z "$ML_BACKEND" ]; then
  if [ "$(uname -s | tr '[:upper:]' '[:lower:]')" = "darwin" ] && [ "$(uname -m)" = "arm64" ]; then
    ML_BACKEND='mlx'
  else
    ML_BACKEND='pytorch'
  fi
fi

if [ "$ACTION" = "train" ] || [ "$ACTION" = "eval-ml" ]; then
  EXEC_CMD="${CMD_OVERRIDE:-${ML_TRAIN_CMD:-${ML_SCRIPT:-python train.py}}}"
else
  if [ -n "$CMD_OVERRIDE" ]; then
    EXEC_CMD="$CMD_OVERRIDE"
  elif [ -n "$ML_INFER_CMD" ]; then
    EXEC_CMD="$ML_INFER_CMD"
  elif [ "$ML_BACKEND" = "ollama" ]; then
    EXEC_CMD="ollama run ${MODEL_NAME:-gemma2}"
  elif [ "$ML_BACKEND" = "vllm" ]; then
    EXEC_CMD="python -m vllm.entrypoints.openai.api_server --model ${MODEL_NAME:-google/gemma-2-2b-it}"
  else
    EXEC_CMD="python infer.py"
  fi
fi

log_info "ML Orchestrator: action=$ACTION target=$ML_TARGET backend=$ML_BACKEND command='$EXEC_CMD'"

if [ "$DRY_RUN" -eq 1 ]; then
  printf '[DRY-RUN] action=%s target=%s backend=%s command="%s"
' "$ACTION" "$ML_TARGET" "$ML_BACKEND" "$EXEC_CMD"
  exit 0
fi

case "$ML_TARGET" in
  local)
    # Source local dependency environments if resolved
    if [ -n "$JSON_FILE" ] && [ -f "$JSON_FILE" ]; then
      deps=$("${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/resolve_stack.sh" "$JSON_FILE" 2>/dev/null | jq -r '.selected[] | .name' 2>/dev/null || true)
      for _pkg in $deps; do
        for _cat_name in $(ls -1 "${LIBSCRIPT_ROOT_DIR}/_lib" 2>/dev/null || true); do
          _cat_dir="${LIBSCRIPT_ROOT_DIR}/_lib/${_cat_name}"
          if [ -f "${_cat_dir}/${_pkg}/env.sh" ]; then
            SCRIPT_NAME="${_cat_dir}/${_pkg}/env.sh"
            # shellcheck disable=SC1090
            . "${SCRIPT_NAME}" || true
          fi
        done
      done
    fi
    if [ -n "$ML_ETL_CMD" ] && [ "$ACTION" = "train" ]; then
      log_info "Running ML ETL step: $ML_ETL_CMD"
      (cd "$MANIFEST_DIR" && sh -c "$ML_ETL_CMD")
    fi
    (cd "$MANIFEST_DIR" && sh -c "$EXEC_CMD")
    ;;
  gcp-tpu-vm|tpu-vm|tpu)
    export APP_DIR="$MANIFEST_DIR"
    export ML_SCRIPT="$EXEC_CMD"
    export WORKLOAD_CMD="$EXEC_CMD"
    if [ "$ACTION" = "train" ] || [ "$ACTION" = "eval-ml" ]; then
      exec "${LIBSCRIPT_ROOT_DIR}/_lib/ml-training/deploy.sh"
    else
      exec "${LIBSCRIPT_ROOT_DIR}/_lib/ai-serving/deploy.sh"
    fi
    ;;
  gcp-gpu-vm|gpu-vm|gpu)
    export APP_DIR="$MANIFEST_DIR"
    export WORKLOAD_CMD="$EXEC_CMD"
    exec "${LIBSCRIPT_ROOT_DIR}/payloads/ai/gcp-gpu-vm/deploy.sh"
    ;;
  gke-xpk|xpk)
    export TRAIN_SCRIPT="$EXEC_CMD"
    export WORKLOAD_CMD="$EXEC_CMD"
    if [ "$ACTION" = "train" ] || [ "$ACTION" = "eval-ml" ]; then
      exec "${LIBSCRIPT_ROOT_DIR}/payloads/ai/gke-xpk-training/deploy.sh"
    else
      exec "${LIBSCRIPT_ROOT_DIR}/payloads/ai/gke-xpk-inference/deploy.sh"
    fi
    ;;
  *)
    log_error "Unknown ML target: $ML_TARGET"
    exit 1
    ;;
esac
