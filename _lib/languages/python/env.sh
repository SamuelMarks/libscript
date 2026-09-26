#!/bin/sh
# ## Overview
# Environment initialization for Python.
#
# ## Usage
# Sets up `PYTHON_VERSION` and `PYTHON_VENV` and prepends them to PATH.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
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
_SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
PYTHON_VERSION="${PYTHON_VERSION:-3.11.9}"
_PY_HOME="${LIBSCRIPT_HOME:-$HOME/.libscript}/python/${PYTHON_VERSION}"
if [ -d "$_PY_HOME" ]; then
  export PYTHONHOME="$_PY_HOME"
  PYTHON_MINOR_VERSION="$(printf '%s\n' "$PYTHON_VERSION" | cut -d. -f1,2)"
  export PYTHONPATH="${PYTHONHOME}/lib/python${PYTHON_MINOR_VERSION}/site-packages:${PYTHONPATH:-}"
  export PATH="${PYTHONHOME}/bin:${PATH}"
fi
if [ "${PYTHON_VENV:-}" ]; then
  export PATH="${PYTHON_VENV}/bin:${PATH}"
  export VIRTUAL_ENV="${PYTHON_VENV}"
  unset PYTHONHOME
fi
