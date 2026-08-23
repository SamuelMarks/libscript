#!/bin/sh
# ## Overview
# This module provides utilities for managing Python virtual environments
# and resolving Python executable versions. It abstracts the underlying
# toolchain (`venv`, `uv`, `pyenv`, etc.) behind common functions.
#
# ## Usage
# Source this file to use `libscript_python_venv` and `libscript_python_resolve`.
#
# ```sh
# . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/python_env.sh"
#
# # Resolve a Python executable
# PYTHON_EXE=$(libscript_python_resolve "3.11")
#
# # Create a virtual environment
# libscript_python_venv "/path/to/venv" "3.11"
# ```

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

. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"

# ## libscript_python_resolve
# Resolves the path to the Python executable for a given version.
#
# **Environment Variables:**
# - `LIBSCRIPT_PYTHON_BACKEND`: The backend to use (`uv`, `pyenv`, `native`). Defaults to `native`.
#
# **Arguments:**
# 1. `_version` (string, optional): The requested Python version (e.g., `3.11`).
#
# **Returns:**
# Prints the path to the executable and returns 0 on success, or non-zero on failure.
libscript_python_resolve() {
  _version="${1:-}"
  _backend="${LIBSCRIPT_PYTHON_BACKEND:-native}"
  
  case "${_backend}" in
    uv)
      if [ -n "${_version}" ]; then
        uv python find "${_version}" || return 1
      else
        uv python find || return 1
      fi
      ;;
    pyenv)
      if command -v pyenv >/dev/null 2>&1; then
        if [ -n "${_version}" ]; then
          PYENV_VERSION="${_version}" pyenv which python || return 1
        else
          pyenv which python || return 1
        fi
      else
        log_error "pyenv is not installed or not in PATH."
        return 1
      fi
      ;;
    native)
      if [ -n "${_version}" ]; then
        if command -v "python${_version}" >/dev/null 2>&1; then
          command -v "python${_version}"
        elif command -v "python$(printf '%s' "${_version}" | cut -d. -f1)" >/dev/null 2>&1; then
          command -v "python$(printf '%s' "${_version}" | cut -d. -f1)"
        else
          # Fallback to libscript_native installation check
          # Source versioning if needed
          if ! type libscript_get_version_dir >/dev/null 2>&1; then
            . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/versioning.sh"
          fi
          _py_dir=$(libscript_get_version_dir "python" "${_version}")
          if [ ! -d "${_py_dir}" ]; then
            log_info "Python version ${_version} not found locally. Installing via libscript..."
            "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install python "${_version}" >&2 || return 1
          fi
          
          # Try to find the binary in the newly installed/resolved directory
          if [ -x "${_py_dir}/bin/python${_version}" ]; then
            printf '%s\n' "${_py_dir}/bin/python${_version}"
          elif [ -x "${_py_dir}/bin/python$(printf '%s' "${_version}" | cut -d. -f1)" ]; then
            printf '%s\n' "${_py_dir}/bin/python$(printf '%s' "${_version}" | cut -d. -f1)"
          elif [ -x "${_py_dir}/bin/python3" ]; then
            printf '%s\n' "${_py_dir}/bin/python3"
          elif [ -x "${_py_dir}/bin/python" ]; then
            printf '%s\n' "${_py_dir}/bin/python"
          elif command -v python3 >/dev/null 2>&1; then
             command -v python3
          else
             command -v python || return 1
          fi
        fi
      else
        if command -v python3 >/dev/null 2>&1; then
          command -v python3
        else
          command -v python || return 1
        fi
      fi
      ;;
    *)
      log_error "Unsupported Python resolve backend: ${_backend}"
      return 1
      ;;
  esac
}

# ## libscript_python_venv
# Creates a Python virtual environment at the specified directory.
#
# **Environment Variables:**
# - `LIBSCRIPT_PYTHON_VENV_BACKEND`: The backend to use (`uv`, `venv`). Defaults to `venv`.
#
# **Arguments:**
# 1. `_target_dir` (string): The path where the virtual environment will be created.
# 2. `_python_version` (string, optional): The specific Python version to use.
#
# **Returns:**
# 0 on success, non-zero on failure.
libscript_python_venv() {
  if [ "$#" -lt 1 ]; then
    log_error "Usage: libscript_python_venv <target_dir> [python_version]"
    return 1
  fi

  _target_dir="$1"
  _python_version="${2:-}"
  _backend="${LIBSCRIPT_PYTHON_VENV_BACKEND:-venv}"
  
  log_info "Creating Python virtual environment at '${_target_dir}' using backend '${_backend}'..."
  
  case "${_backend}" in
    uv)
      if [ -n "${_python_version}" ]; then
        uv venv --python "${_python_version}" -- "${_target_dir}" || return 1
      else
        uv venv -- "${_target_dir}" || return 1
      fi
      ;;
    venv)
      # Try to resolve a specific python executable if a version is requested,
      # otherwise fallback to default `python3` or `python`
      if [ -n "${_python_version}" ]; then
         _python_exe=$(libscript_python_resolve "${_python_version}") || return 1
      else
         _python_exe=$(libscript_python_resolve) || return 1
      fi
      "${_python_exe}" -m venv "${_target_dir}" || return 1
      ;;
    *)
      log_error "Unsupported Python venv backend: ${_backend}"
      return 1
      ;;
  esac
}
