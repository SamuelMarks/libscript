#!/bin/sh
# ## Overview
# Updates the Supported Components table in README.md with test results.
#
# ## Usage
# ./update_results.sh

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
REPO_ROOT=$(cd "${THIS_DIR}/.." && pwd)

if command -v python3 >/dev/null 2>&1; then
    python3 "${THIS_DIR}/update_results.py" "${REPO_ROOT}"
elif command -v python >/dev/null 2>&1; then
    python "${THIS_DIR}/update_results.py" "${REPO_ROOT}"
else
    printf '%s\n' "Error: python3 or python is required to run this script." >&2
    exit 1
fi
