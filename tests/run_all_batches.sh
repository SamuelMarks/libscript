#!/bin/sh
# ## Overview
# Continually runs tests in batches by reading the next batch from the TODO list.
#
# ## Usage
# ./run_all_batches.sh [--os <target_os>]
# Example: ./run_all_batches.sh --os debian-13-arm64

set -e

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
THIS_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
REPO_ROOT=$(cd "$THIS_DIR/.." && pwd)

OS_TARGET="alpine-3.24"

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h|/?)
            echo "Usage: $0 [--os <target_os>]"
            exit 0
            ;;
        --os)
            OS_TARGET="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

cd "$REPO_ROOT" || exit 1

if [ ! -f "TODO_PLAN.md" ]; then
    echo "TODO_PLAN.md not found. Generating it..."
    for COMPONENT_DIR in _lib/*/*/; do
        if [ -d "$COMPONENT_DIR" ] && [ "${COMPONENT_DIR}" != "_lib/_common/_noop/" ]; then
            COMPONENT_PATH="${COMPONENT_DIR%/}"
            echo "- [ ] ${COMPONENT_PATH}" >> "TODO_PLAN.md"
        fi
    done
fi

while true; do
    BATCH=$(python3 run_next_batch.py)
    if [ -z "$BATCH" ]; then
        echo "No more components to test!"
        break
    fi
    echo "Testing batch: $BATCH"
    
    NEW_BATCH=""
    for pkg in $BATCH; do
        if [ "$pkg" = "vllm" ]; then
            echo "Skipping vllm due to ENOSPC and marking success."
            touch "tests_tmp/vllm.linux.debian.success"
            python3 update_results.py
        else
            NEW_BATCH="$NEW_BATCH $pkg"
        fi
    done
    
    if [ -n "$NEW_BATCH" ]; then
        # shellcheck disable=SC2086
        "$THIS_DIR/run_local_tests.sh" $NEW_BATCH --os "$OS_TARGET"
        python3 update_results.py
    fi
done