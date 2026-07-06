#!/bin/sh
# ## Overview
# Main CLI entry point for cloud orchestration (deploy, teardown, backup, restore).
#
# ## Usage
# Handles dispatching commands like `deploy_cloud` and handles pushing/pulling/locking infrastructure state.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
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
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"

PACKAGE_NAME="core"

SKIP_STATE=0
for arg in "$@"; do
    case "$arg" in
        diff|list-managed|status|--help|-h)
            SKIP_STATE=1
            ;;
    esac
done

if [ "$SKIP_STATE" -eq 0 ]; then
    if [ -f "$SCRIPT_DIR/state_backend.sh" ]; then
        "$SCRIPT_DIR/state_backend.sh" pull_state
        "$SCRIPT_DIR/state_backend.sh" lock_state
        # Using a subshell function to ensure the trap runs even if exec is called later
        cleanup_state() {
            "$SCRIPT_DIR/state_backend.sh" push_state || true
            "$SCRIPT_DIR/state_backend.sh" unlock_state || true
        }
        trap cleanup_state EXIT INT TERM
    fi
fi

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/component_core.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
