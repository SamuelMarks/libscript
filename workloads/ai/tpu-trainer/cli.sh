#!/bin/sh
# ## Overview
# CLI router for multi-worker Cloud TPU training jobs delegating to `workloads/schedulers/tpu_vm.sh`.
#
# ## Usage
# ./workloads/ai/tpu-trainer/cli.sh <submit|status|logs|stop|destroy|install|test> [payload.json]

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

ACT="${1:-status}"
shift 2>/dev/null || true
case "$ACT" in
  --help|-h) printf '%s\n' 'Usage: cli.sh <submit|status|logs|stop|destroy|test> [payload.json]'; exit 0 ;;
  install) exit 0 ;;
  test) exec "${SCRIPT_DIR}/test.sh" "$@" ;;
  deploy) ACT='submit' ;;
  teardown) ACT='destroy' ;;
esac
PF="${1:-${LIBSCRIPT_ROOT_DIR}/workloads/payloads/ai/gcp-tpu-vm/payload.json}"
[ $# -gt 0 ] && shift
exec "${LIBSCRIPT_ROOT_DIR}/workloads/schedulers/tpu_vm.sh" "$ACT" "$PF" "$@"
