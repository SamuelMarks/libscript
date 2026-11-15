#!/bin/sh
# ## Overview
# Suite-agnostic CLI router delegating `libscript experiment <verb>` to `experiments/engine.sh`.
# ## Usage
# ./cli/commands/experiment/cli.sh <list|scaffold|validate|provision|sync|run|collect|render-latex|update-readme|test|teardown> [suite-id] [args...]

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

case "${1:-list}" in
  list|scaffold|validate|provision|sync|run|collect|render-latex|update-readme|test|teardown|--help|-h)
    exec "${LIBSCRIPT_ROOT_DIR}/experiments/engine.sh" "$@"
    ;;
  *)
    exec "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/experiment_cloud.sh" "$@"
    ;;
esac
