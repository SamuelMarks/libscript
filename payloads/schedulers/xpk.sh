#!/bin/sh
# ## Overview
# Tier 4 XPK Gang Scheduler translating AI/ML `payload.json` into Google Cloud XPK TPU slice
# workload commands with idempotent deduplication, TFRC zero-cost blocking, and live/staged modes.
#
# ## Usage
# ./payloads/schedulers/xpk.sh <compile|submit|status|logs|stop|destroy> <payload.json_or_id> [--dry-run] [--live]

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

_xpk_this="${THIS_FILE}"; _xpk_dir="${SCRIPT_DIR}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/ml-training/_common/tfrc_guard.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true
THIS_FILE="${_xpk_this}"; SCRIPT_DIR="${_xpk_dir}"

ACTION="${1:-compile}"
TARGET="${2:-}"
shift 2 2>/dev/null || shift $#

DRY_RUN="${LIBSCRIPT_DRY_RUN:-0}"
LIVE_EXEC="${LIBSCRIPT_SCHEDULER_LIVE:-0}"
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --live) LIVE_EXEC=1; shift ;;
    *) shift ;;
  esac
done

if [ "$ACTION" != "compile" ] && libscript_tfrc_is_enabled; then
  ML_TARGET='gke-xpk'
  export ML_TARGET
  libscript_tfrc_require_config "${PWD}"
  libscript_tfrc_enforce_zero_cost_env
fi

STATE_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript-state}/schedulers/xpk"
mkdir -p "$STATE_DIR"

# ## compile_xpk_command
# Translates a payload.json file into an XPK gang-scheduled TPU workload command specification.
compile_xpk_command() {
  _pf="$1"
  jq -r --arg cl "${XPK_CLUSTER_NAME:-libscript-tpu-cluster}" --arg zn "${GCP_ZONE:-us-central2-b}" --arg prj "${GCP_PROJECT_ID:-}" '
    . as $p
    | ($p.resources.tpu_topology // "v5litepod-16") as $tpu
    | ($p.scaling.replicas // 1) as $slices
    | ($p.artifact.source // "gcr.io/cloud-tpu-images/jax-ai-image:latest") as $img
    | (($p.artifact.command // ["/bin/sh", "-c", "python3 train.py"]) | join(" ")) as $cmd
    | {
        scheduler: "xpk",
        workload: $p.name,
        cluster: $cl,
        project: $prj,
        zone: $zn,
        tpu_type: $tpu,
        num_slices: $slices,
        docker_image: $img,
        xpk_cli_invocation: "xpk workload create --cluster \($cl) --workload \($p.name) --tpu-type \($tpu) --num-slices \($slices) --docker-image \($img) --command \"\($cmd)\""
      }
  ' "$_pf"
}

WID=$(basename -- "$TARGET" .json)
[ -f "$TARGET" ] && WID=$(jq -r '.name' "$TARGET")
CLUSTER="${XPK_CLUSTER_NAME:-libscript-tpu-cluster}"
ZONE="${GCP_ZONE:-${TPU_ZONE:-us-central2-b}}"
SFILE="${STATE_DIR}/${WID}.json"

case "$ACTION" in
  compile)
    compile_xpk_command "$TARGET"
    ;;
  submit)
    if [ "$DRY_RUN" != "1" ] && { [ "$LIVE_EXEC" = "1" ] || [ -n "${XPK_CLUSTER_NAME:-}" ]; } && [ -n "${GCP_PROJECT_ID:-}" ] && command -v xpk >/dev/null 2>&1; then
      _existing=$(xpk workload list --cluster "$CLUSTER" --project "$GCP_PROJECT_ID" --zone "$ZONE" 2>/dev/null | grep -F "$WID" || true)
      if [ -z "$_existing" ]; then
        _tpu=$(jq -r '.resources.tpu_topology // "v4-8"' "$TARGET" 2>/dev/null || printf 'v4-8')
        _slices=$(jq -r '.scaling.replicas // 1' "$TARGET" 2>/dev/null || printf '1')
        _img="${DOCKER_IMAGE:-$(jq -r '.artifact.source // "ubuntu:24.04"' "$TARGET" 2>/dev/null)}"
        _cmd="${TRAIN_SCRIPT:-${WORKLOAD_CMD:-$(jq -r '(.artifact.command // ["python3","train.py"]) | join(" ")' "$TARGET" 2>/dev/null)}}"
        _tier_flag=''
        [ "${TPU_SCHEDULING_TYPE:-}" = "spot" ] && _tier_flag='--spot'
        # shellcheck disable=SC2086
        xpk workload create --cluster "$CLUSTER" --workload "$WID" --tpu-type "$_tpu" --num-slices "$_slices" \
          --docker-image "$_img" --command "$_cmd" --project "$GCP_PROJECT_ID" --zone "$ZONE" $_tier_flag >&2
      fi
      _mode='live'
    else
      _mode='staged'
    fi
    jq -n --arg wid "$WID" --arg cl "$CLUSTER" --arg m "$_mode" '{scheduler:"xpk",action:"submit",workload:$wid,cluster:$cl,mode:$m,state:"RUNNING",status:"ok"}' | tee "$SFILE"
    ;;
  status)
    if [ "$DRY_RUN" != "1" ] && [ "$LIVE_EXEC" = "1" ] && [ -n "${GCP_PROJECT_ID:-}" ] && command -v xpk >/dev/null 2>&1; then
      xpk workload list --cluster "$CLUSTER" --project "$GCP_PROJECT_ID" --zone "$ZONE" >&2 || true
    fi
    if [ -f "$SFILE" ]; then
      jq '.action = "status"' "$SFILE"
    else
      jq -n --arg wid "$WID" --arg cl "$CLUSTER" '{scheduler:"xpk",action:"status",workload:$wid,cluster:$cl,state:"UNKNOWN",status:"ok"}'
    fi
    ;;
  logs)
    _k8s_logs=''
    if [ "$DRY_RUN" != "1" ] && [ "$LIVE_EXEC" = "1" ] && command -v kubectl >/dev/null 2>&1; then
      _k8s_logs=$(kubectl logs -l "jobset.sigs.k8s.io/jobset-name=${WID}" --tail=50 2>/dev/null || true)
    fi
    jq -n --arg wid "$WID" --arg logs "$_k8s_logs" '{scheduler:"xpk",action:"logs",workload:$wid,logs:$logs,status:"ok"}'
    ;;
  stop|destroy)
    if [ "$DRY_RUN" != "1" ] && { [ "$LIVE_EXEC" = "1" ] || [ -n "${XPK_CLUSTER_NAME:-}" ]; } && [ -n "${GCP_PROJECT_ID:-}" ] && command -v xpk >/dev/null 2>&1; then
      xpk workload delete --cluster "$CLUSTER" --workload "$WID" --project "$GCP_PROJECT_ID" --zone "$ZONE" >&2 || true
    fi
    [ "$ACTION" = "destroy" ] && rm -f "$SFILE"
    jq -n --arg wid "$WID" --arg act "$ACTION" '{scheduler:"xpk",action:$act,workload:$wid,status:"ok"}'
    ;;
  *)
    exit 1
    ;;
esac
