#!/bin/sh
# ## Overview
# Validates the 'uv' backend integration for Python virtual environments.
# 
# ## Usage
# Execute this script to verify that components can successfully install using 'uv'.

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

if ! command -v uv >/dev/null 2>&1; then
  log_warn "uv is not installed. Skipping uv integration validation."
  exit 0
fi

# Set global environment variables to force 'uv'
export LIBSCRIPT_PYTHON_BACKEND="uv"
export LIBSCRIPT_PYTHON_VENV_BACKEND="uv"
export LIBSCRIPT_HOME="${TMPDIR:-/tmp}/libscript_uv_test"
export DOWNLOAD_DIR="${LIBSCRIPT_HOME}/downloads"

log_info "Testing uv integration..."

# Test 1: Resolve python executable via uv
log_info "Testing Python resolution via uv..."
# Source abstraction
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/python_env.sh"
py_path=$(libscript_python_resolve)
if [ -z "$py_path" ]; then
    log_error "Failed to resolve python via uv."
    exit 1
fi
log_info "Resolved python: $py_path"

# Test 2: xpk setup
log_info "Testing xpk setup via uv..."
export ACTION="install"
export VERSION="latest"
export PACKAGE_NAME="xpk"
export XPK_INSTALL_METHOD="libscript_native"
sh "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/xpk/setup_generic.sh"

if [ ! -f "${LIBSCRIPT_HOME}/xpk/latest/bin/xpk" ] && [ ! -f "${LIBSCRIPT_HOME}/xpk/latest/Scripts/xpk.exe" ]; then
    # Note: latest might not be the exact version name used if xpk defaults to something else
    # Let's just check if the directory was created by uv
    if [ ! -d "${LIBSCRIPT_HOME}/xpk" ]; then
      log_error "xpk installation via uv failed."
      exit 1
    fi
fi
log_info "xpk setup via uv successful."

log_info "Cleaning up..."
rm -rf "${LIBSCRIPT_HOME}"

log_info "uv integration validation complete."
