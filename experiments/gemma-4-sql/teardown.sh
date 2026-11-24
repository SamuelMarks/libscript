#!/bin/sh
# ## Overview
# Deletes the Cloud TPU VM + Queued Resource and executes a post-flight TFRC orphan audit enforcing USD 0.00 zero surviving resources.
# ## Usage
# ./experiments/gemma-4-sql/teardown.sh [--tfrc-config=<path>] [--dry-run]

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

_td_this="${THIS_FILE}"; _td_dir="${SCRIPT_DIR}"
for _lib in engine/common/log.sh engine/common/tfrc_guard.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_lib}"; export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _lib || true
THIS_FILE="${_td_this}"; SCRIPT_DIR="${_td_dir}"

DRY_RUN_FLAG="${GEMMA_4_SQL_DRY_RUN:-0}"
while [ $# -gt 0 ]; do
  case "$1" in
    --tfrc-config=*) TFRC_CONFIG="${1#*=}"; TFRC_STRICT='1'; export TFRC_CONFIG TFRC_STRICT; shift ;;
    --tfrc-config) TFRC_CONFIG="$2"; TFRC_STRICT='1'; export TFRC_CONFIG TFRC_STRICT; shift 2 ;;
    --dry-run) DRY_RUN_FLAG='1'; shift ;;
    *) shift ;;
  esac
done

# ## run_teardown_tpu
# Deletes TPU_NAME and verifies zero surviving TFRC billable resources.
run_teardown_tpu() {
  if [ "${DRY_RUN_FLAG}" = '1' ] || [ -z "${TPU_NAME:-}" ]; then
    log_info "[TEARDOWN] No active remote TPU VM slice to tear down (TPU_NAME=${TPU_NAME:-none})."
    return 0
  fi
  "${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh" delete "${TPU_NAME}"
  if libscript_tfrc_is_enabled && [ -n "${TPU_ZONE:-}" ]; then
    libscript_tfrc_postflight_audit "${GCP_PROJECT_ID:-}" "${TPU_ZONE}" "${TPU_NAME}"
  fi
}

run_teardown_tpu
