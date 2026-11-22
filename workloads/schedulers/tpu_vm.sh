#!/bin/sh
# ## Overview
# Tier 4 Cloud TPU VM Slice Scheduler coordinating tree-hashed `--all-workers` repo sync,
# `/dev/shm` uv virtualenvs, TFRC zero-cost guardrails, and multi-host lockstep execution.
#
# ## Usage
# ./workloads/schedulers/tpu_vm.sh <compile|submit|status|logs|stop|destroy> <payload.json_or_id> [--dry-run] [--live]

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

_tpu_saved_this="${THIS_FILE}"; _tpu_saved_dir="${SCRIPT_DIR}"
for _lib in "engine/common/tfrc_guard.sh" "workloads/ai/_common/tpu_matrix.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
  THIS_FILE="${_tpu_saved_this}"; SCRIPT_DIR="${_tpu_saved_dir}"
done
unset _tpu_saved_this _tpu_saved_dir || true

ACTION="${1:-compile}"
TARGET="${2:-}"
shift 2 2>/dev/null || shift $#

DRY_RUN="${LIBSCRIPT_DRY_RUN:-0}"
LIVE_EXEC="${LIBSCRIPT_SCHEDULER_LIVE:-0}"
BACKEND="${TPU_BACKEND:-jax_native}"

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --live) LIVE_EXEC=1; shift ;;
    --backend=*) BACKEND="${1#*=}"; shift ;;
    *) shift ;;
  esac
done

if libscript_tfrc_is_enabled; then
  libscript_tfrc_require_config "${PWD}"
  libscript_tfrc_enforce_zero_cost_env
fi

STATE_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript-state}/schedulers/tpu_vm"
mkdir -p "$STATE_DIR"

WID=$(basename -- "$TARGET" .json)
[ -f "$TARGET" ] && WID=$(jq -r '.name // "tpu-workload"' "$TARGET")
TPU_NODE="${TPU_NAME:-${WID}-tpu}"
TPU_SKU="${TPU_ACCELERATOR_TYPE:-v4-8}"
[ -f "$TARGET" ] && TPU_SKU=$(jq -r '.resources.tpu_topology // empty' "$TARGET")
[ -n "$TPU_SKU" ] || TPU_SKU="${TPU_ACCELERATOR_TYPE:-v4-8}"
CMD_STR="${WORKLOAD_CMD:-${ML_SCRIPT:-python train.py}}"
if [ -f "$TARGET" ]; then
  _p_cmd=$(jq -r '(.artifact.command // []) | join(" ")' "$TARGET")
  [ -n "$_p_cmd" ] && [ -z "${WORKLOAD_CMD:-}" ] && CMD_STR="$_p_cmd"
fi

# ## compile_tpu_vm_spec
# Emits the compiled multi-worker Cloud TPU VM execution plan JSON.
compile_tpu_vm_spec() {
  jq -n \
    --arg wid "$WID" \
    --arg node "$TPU_NODE" \
    --arg sku "$TPU_SKU" \
    --arg backend "$BACKEND" \
    --arg cmd "$CMD_STR" \
    --arg xla_cache "${JAX_COMPILATION_CACHE_DIR:-}" \
    '{
      scheduler: "tpu_vm",
      workload_id: $wid,
      tpu_name: $node,
      accelerator_type: $sku,
      backend: $backend,
      shm_venv_root: "/dev/shm/libscript-tpu",
      sync_mode: "tree-hash-all-workers",
      command: $cmd,
      xla_compilation_cache: $xla_cache
    }'
}

TPU_CLI="${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh"
SFILE="${STATE_DIR}/${WID}.json"

case "$ACTION" in
  compile)
    compile_tpu_vm_spec
    ;;
  submit)
    if [ "$DRY_RUN" != "1" ] && { [ "$LIVE_EXEC" = "1" ] || [ -n "${GCP_PROJECT_ID:-}" ]; } && [ -n "${TPU_ZONE:-}" ]; then
      STACK='' "$TPU_CLI" create "$TPU_NODE" >&2
      STACK='' "$TPU_CLI" wait-ready "$TPU_NODE" >&2
      libscript_tpu_bootstrap_remote "$TPU_NODE" "${APP_DIR:-${REPO_DIR:-}}" >&2
      libscript_tpu_run_lockstep "$TPU_NODE" "$BACKEND" "$CMD_STR" "${STATE_DIR}/${WID}_logs" >&2
      _mode='live'
    else
      _mode='staged'
    fi
    jq -n --arg wid "$WID" --arg node "$TPU_NODE" --arg mode "$_mode" --arg st "RUNNING" \
      '{scheduler:"tpu_vm",action:"submit",workload:$wid,tpu_name:$node,mode:$mode,state:$st,status:"ok"}' | tee "$SFILE"
    ;;
  status)
    if [ "$DRY_RUN" != "1" ] && [ "$LIVE_EXEC" = "1" ] && [ -n "${GCP_PROJECT_ID:-}" ] && [ -n "${TPU_ZONE:-}" ]; then
      STACK='' "$TPU_CLI" status "$TPU_NODE" >&2 || true
    fi
    if [ -f "$SFILE" ]; then
      jq '.action = "status"' "$SFILE"
    else
      jq -n --arg wid "$WID" --arg node "$TPU_NODE" '{scheduler:"tpu_vm",action:"status",workload:$wid,tpu_name:$node,state:"UNKNOWN",status:"ok"}'
    fi
    ;;
  logs)
    _log_txt=''
    if [ -f "${STATE_DIR}/${WID}_logs/worker_0.log" ]; then
      _log_txt=$(tail -n 50 "${STATE_DIR}/${WID}_logs/worker_0.log")
    elif [ -f "${STATE_DIR}/${WID}_logs/workers_all.log" ]; then
      _log_txt=$(tail -n 50 "${STATE_DIR}/${WID}_logs/workers_all.log")
    fi
    jq -n --arg wid "$WID" --arg logs "$_log_txt" '{scheduler:"tpu_vm",action:"logs",workload:$wid,logs:$logs,status:"ok"}'
    ;;
  stop)
    if [ "$DRY_RUN" != "1" ] && { [ "$LIVE_EXEC" = "1" ] || [ -n "${GCP_PROJECT_ID:-}" ]; } && [ -n "${TPU_ZONE:-}" ]; then
      STACK='' "$TPU_CLI" release-locks "$TPU_NODE" >&2 || true
    fi
    jq -n --arg wid "$WID" --arg node "$TPU_NODE" '{scheduler:"tpu_vm",action:"stop",workload:$wid,tpu_name:$node,state:"STOPPED",status:"ok"}' | tee "$SFILE"
    ;;
  destroy)
    if [ "$DRY_RUN" != "1" ] && { [ "$LIVE_EXEC" = "1" ] || [ -n "${GCP_PROJECT_ID:-}" ]; } && [ -n "${TPU_ZONE:-}" ]; then
      STACK='' "$TPU_CLI" delete "$TPU_NODE" >&2 || true
    fi
    rm -f "$SFILE"
    jq -n --arg wid "$WID" --arg node "$TPU_NODE" '{scheduler:"tpu_vm",action:"destroy",workload:$wid,tpu_name:$node,state:"DESTROYED",status:"ok"}'
    ;;
  *)
    printf '[ERROR] Unsupported tpu_vm scheduler action: %s\n' "$ACTION" >&2
    exit 1
    ;;
esac
