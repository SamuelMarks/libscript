#!/bin/sh
# ## Overview
# Idempotently synchronizes LibScript and the `gemma-4-sql` workspace repository to all workers of a Cloud TPU VM slice.
# ## Usage
# ./experiments/gemma-4-sql/sync.sh [--repo-dir=<dir>] [--dry-run]

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

REPO_DIR="${GEMMA_4_SQL_REPO_DIR:-$(pwd)}"
DRY_RUN_FLAG="${GEMMA_4_SQL_DRY_RUN:-0}"
while [ $# -gt 0 ]; do
  case "$1" in
    --repo-dir=*) REPO_DIR="${1#*=}"; shift ;;
    --repo-dir) REPO_DIR="$2"; shift 2 ;;
    --dry-run) DRY_RUN_FLAG='1'; shift ;;
    *) shift ;;
  esac
done

# ## run_sync_tpu
# Synchronizes libscript and workspace repositories to all workers on TPU_NAME.
run_sync_tpu() {
  REPO_DIR=$(cd -- "${REPO_DIR}" && pwd)
  if [ "${DRY_RUN_FLAG}" = '1' ] || [ -z "${TPU_NAME:-}" ]; then
    printf '[SYNC] Verified workspace %s (TPU_NAME=%s).\n' "${REPO_DIR}" "${TPU_NAME:-local}"
    return 0
  fi
  _cli="${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/gcp-tpu-vm/cli.sh"
  "${_cli}" sync-repo "${TPU_NAME}" "${LIBSCRIPT_ROOT_DIR}" 'libscript' --all-workers
  "${_cli}" sync-repo "${TPU_NAME}" "${REPO_DIR}" 'workspace' --all-workers
}

run_sync_tpu
