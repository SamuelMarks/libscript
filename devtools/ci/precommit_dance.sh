#!/bin/sh
# ## Overview
# Runs the pre-commit hook dance in CI to ensure code quality.
#
# ## Usage
# Execute this script without arguments.

set -e

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  printf '%s\n' "Usage: $(basename "$0")"
  printf '%s\n' "Runs the pre-commit hook dance in CI to ensure code quality."
  exit 0
fi

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

cd "${SCRIPT_DIR}/../.." || exit 1

printf '%s\n' ">>> RUNNING PRE-COMMIT DANCE <<<"

# Stage all files so the pre-commit hook thinks they are staged
git add -A

# Run the pre-commit script
.githooks/pre-commit.sh

# Check if anything changed
if ! git diff --cached --exit-code; then
  printf '%s\n' "Error: The pre-commit hook modified files. Please run the pre-commit hook locally and commit the changes."
  exit 1
fi

printf '%s\n' "Pre-commit dance completed successfully."
