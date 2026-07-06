#!/bin/sh
# ## Overview
# Environment initialization for Python.
#
# ## Usage
# Sets up `PYTHON_VERSION` and `PYTHON_VENV` and prepends them to PATH.

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
PYTHON_VERSION="${PYTHON_VERSION:-3.11.9}"
export PYTHONHOME="${LIBSCRIPT_HOME:-$HOME/.libscript}/python/${PYTHON_VERSION}"
PYTHON_MINOR_VERSION="$(printf '%s\n' "$PYTHON_VERSION" | cut -d. -f1,2)"
export PYTHONPATH="${PYTHONHOME}/lib/python${PYTHON_MINOR_VERSION}/site-packages:${PYTHONPATH:-}"
export PATH="${PYTHONHOME}/bin:${PATH}"
if [ "${PYTHON_VENV:-}" ]; then
  export PATH="${PYTHON_VENV}/bin:${PATH}"
  export VIRTUAL_ENV="${PYTHON_VENV}"
  unset PYTHONHOME
fi