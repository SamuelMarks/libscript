#!/bin/sh
# ## Overview
# Reads TODO_PLAN.md and returns the next batch of up to 5 uncompleted tasks.
#
# ## Usage
# ./run_next_batch.sh

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

THIS_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
REPO_ROOT=$(cd "$THIS_DIR/.." && pwd)

TODO_FILE="$REPO_ROOT/TODO_PLAN.md"

if [ ! -f "$TODO_FILE" ]; then
    exit 0
fi

# Find up to 5 uncompleted items
grep "^- \[ \] " "$TODO_FILE" | head -n 5 | sed 's/^- \[ \] //' | tr '\n' ' '
echo ""