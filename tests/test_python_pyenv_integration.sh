#!/bin/sh
# ## Overview
# Validates the 'pyenv' backend integration for Python virtual environments.
# 
# ## Usage
# Execute this script to verify that components can successfully resolve and use Python via 'pyenv'.

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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
export DIR="${SCRIPT_DIR}"

. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"

if ! command -v pyenv >/dev/null 2>&1; then
  log_warn "pyenv is not installed or not in PATH. Skipping pyenv integration validation."
  exit 0
fi

# Set global environment variables to force 'pyenv'
export LIBSCRIPT_PYTHON_BACKEND="pyenv"
export LIBSCRIPT_PYTHON_VENV_BACKEND="venv" # venv will use the resolved pyenv path
export LIBSCRIPT_HOME="${TMPDIR:-/tmp}/libscript_pyenv_test"
export PYENV_VERSION="3.12.13"

log_info "Testing pyenv integration..."

# Test 1: Resolve python executable via pyenv
log_info "Testing Python resolution via pyenv..."
# Source abstraction
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/python_env.sh"
py_path=$(libscript_python_resolve)
if [ -z "$py_path" ]; then
    log_error "Failed to resolve python via pyenv."
    exit 1
fi
log_info "Resolved python: $py_path"

# Test 2: Create a venv using the resolved pyenv executable
log_info "Testing venv creation using pyenv executable..."
VENV_DIR="${LIBSCRIPT_HOME}/test_venv"
libscript_python_venv "${VENV_DIR}"
if [ ! -d "${VENV_DIR}/bin" ] && [ ! -d "${VENV_DIR}/Scripts" ]; then
    log_error "Failed to create venv using pyenv."
    exit 1
fi
log_info "Successfully created venv via pyenv at ${VENV_DIR}."

log_info "Cleaning up..."
rm -rf "${LIBSCRIPT_HOME}"

log_info "pyenv integration validation complete."
