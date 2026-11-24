#!/bin/sh
# ## Overview
# Provisions a TFRC-guarded Cloud TPU VM slice, arms the auto-TTL dead-man switch, and bootstraps remote tools for `gemma-4-sql`.
# ## Usage
# ./experiments/gemma-4-sql/provision.sh [--tfrc-config=<path>] [--repo-dir=<dir>] [--dry-run]

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

_pv_this="${THIS_FILE}"; _pv_dir="${SCRIPT_DIR}"
for _lib in engine/common/log.sh engine/common/tfrc_guard.sh workloads/ai/_common/tpu_matrix.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_lib}"; export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _lib || true
THIS_FILE="${_pv_this}"; SCRIPT_DIR="${_pv_dir}"

REPO_DIR="${GEMMA_4_SQL_REPO_DIR:-$(pwd)}"
DRY_RUN_FLAG="${GEMMA_4_SQL_DRY_RUN:-0}"
while [ $# -gt 0 ]; do
  case "$1" in
    --tfrc-config=*) TFRC_CONFIG="${1#*=}"; TFRC_STRICT='1'; export TFRC_CONFIG TFRC_STRICT; shift ;;
    --tfrc-config) TFRC_CONFIG="$2"; TFRC_STRICT='1'; export TFRC_CONFIG TFRC_STRICT; shift 2 ;;
    --repo-dir=*) REPO_DIR="${1#*=}"; shift ;;
    --repo-dir) REPO_DIR="$2"; shift 2 ;;
    --dry-run) DRY_RUN_FLAG='1'; shift ;;
    *) shift ;;
  esac
done

# ## run_provision_tpu
# Validates TFRC config and creates/bootstraps the Cloud TPU VM slice idempotently.
run_provision_tpu() {
  REPO_DIR=$(cd -- "${REPO_DIR}" && pwd)
  if libscript_tfrc_is_enabled; then
    libscript_tfrc_require_config "${REPO_DIR}"
    libscript_tfrc_enforce_zero_cost_env
    GCP_PROJECT_ID="${GCP_PROJECT_ID:-$(jq -r '.gcp_project_id' "${TFRC_CONFIG}")}"
    TPU_ZONE="${TPU_ZONE:-$(jq -r '.grants[0].zone' "${TFRC_CONFIG}")}"
    TPU_ACCELERATOR_TYPE="${TPU_ACCELERATOR_TYPE:-$(jq -r '.grants[0].accelerator_types[0]' "${TFRC_CONFIG}")}"
    TPU_SCHEDULING_TYPE="${TPU_SCHEDULING_TYPE:-$(jq -r '.grants[0].scheduling_tiers[0]' "${TFRC_CONFIG}")}"
    export GCP_PROJECT_ID TPU_ZONE TPU_ACCELERATOR_TYPE TPU_SCHEDULING_TYPE
  fi
  TPU_NAME="${TPU_NAME:-gemma-tfrc-node}"
  export TPU_NAME
  if [ "${DRY_RUN_FLAG}" = '1' ]; then
    log_info "[DRY-RUN] Validated gemma-4-sql TPU provisioning plan for ${TPU_NAME} (${TPU_ACCELERATOR_TYPE:-v4-8})."
    return 0
  fi
  libscript_tpu_ensure_host_tools '1'
  _cli="${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh"
  "${_cli}" create "${TPU_NAME}"
  "${_cli}" wait-ready "${TPU_NAME}"
  "${_cli}" arm-ttl "${TPU_NAME}" --minutes "${TFRC_MAX_TTL_MINUTES:-180}"
  libscript_tpu_bootstrap_remote "${TPU_NAME}" "${REPO_DIR}"
}

run_provision_tpu
