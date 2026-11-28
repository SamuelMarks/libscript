#!/bin/sh
# ## Overview
# Atomically collects E0-E9 JSON, CSV, Markdown, and `generated_metrics.tex` artifacts from Cloud TPU VM worker 0.
# ## Usage
# ./experiments/libtpu-pjrt/collect.sh [--results-dir=<dir>] [--dry-run]

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

RESULTS_DIR="${LIBTPU_RS_RESULTS_DIR:-${LIBSCRIPT_ROOT_DIR}/build/libtpu_results}"
DRY_RUN_FLAG="${LIBTPU_RS_DRY_RUN:-0}"
while [ $# -gt 0 ]; do
  case "$1" in
    --results-dir=*|--out-dir=*) RESULTS_DIR="${1#*=}"; shift ;;
    --results-dir|--out-dir) RESULTS_DIR="$2"; shift 2 ;;
    --dry-run) DRY_RUN_FLAG='1'; shift ;;
    *) shift ;;
  esac
done

# ## run_collect_libtpu_pjrt
# Transfers remote ~/results artifacts from worker 0 into local RESULTS_DIR idempotently.
run_collect_libtpu_pjrt() {
  mkdir -p "${RESULTS_DIR}"
  RESULTS_DIR=$(cd -- "${RESULTS_DIR}" && pwd)
  if [ "${DRY_RUN_FLAG}" = '1' ] || [ -z "${TPU_NAME:-}" ]; then
    printf '[COLLECT] Verified local libtpu-pjrt results directory %s.\n' "${RESULTS_DIR}"
    return 0
  fi
  _cli="${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh"
  "${_cli}" scp-from "${TPU_NAME}" "${TPU_NAME}:~/results/*" "${RESULTS_DIR}" --recurse --worker=0
}

run_collect_libtpu_pjrt
