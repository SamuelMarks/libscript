#!/bin/sh
# ## Overview
# Utilities for managing Python virtual environments, resolving Python versions, and ensuring ownership/symlink integrity.
#
# ## Usage
# Source this file (`. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/python_env.sh"`) to use `libscript_python_venv`, `libscript_python_resolve`, and `libscript_python_ensure_venv_owner`.

set -feu
_pe_caller_this="${THIS_FILE:-}"; _pe_caller_dir="${SCRIPT_DIR:-}"
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    [ -n "$_pe_caller_this" ] && THIS_FILE="$_pe_caller_this"
    [ -n "$_pe_caller_dir" ] && SCRIPT_DIR="$_pe_caller_dir"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

# ## libscript_resolve_user_home
# Resolves the home directory for a given system username across Linux, BSD, and macOS.
libscript_resolve_user_home() {
  _ruh_user="${1:-}"
  if [ -z "$_ruh_user" ] || [ "$_ruh_user" = "root" ]; then
    printf '%s\n' "${REMOTE_HOME:-/root}"
    return 0
  fi
  if [ -n "${REMOTE_HOME:-}" ] && [ -d "${REMOTE_HOME}" ]; then
    printf '%s\n' "${REMOTE_HOME}"
    return 0
  fi
  if command -v getent >/dev/null 2>&1; then
    _ruh_ent=$(getent passwd "$_ruh_user" 2>/dev/null | awk -F: '{print $6}' || true)
    if [ -n "$_ruh_ent" ]; then
      printf '%s\n' "$_ruh_ent"
      return 0
    fi
  fi
  if [ -f /etc/passwd ]; then
    _ruh_pw=$(awk -F: -v u="$_ruh_user" '$1 == u {print $6}' /etc/passwd 2>/dev/null || true)
    if [ -n "$_ruh_pw" ]; then
      printf '%s\n' "$_ruh_pw"
      return 0
    fi
  fi
  if [ "$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]')" = "darwin" ] && [ -d "/Users/${_ruh_user}" ]; then
    printf '%s\n' "/Users/${_ruh_user}"
    return 0
  fi
  printf '%s\n' "/home/${_ruh_user}"
}

# ## libscript_python_resolve
# Resolves the path to the Python executable for a given version.
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
        log_error 'pyenv is not installed or not in PATH.'
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
          if ! type libscript_get_version_dir >/dev/null 2>&1; then
            SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/versioning.sh"
            export SCRIPT_NAME
            # shellcheck disable=SC1090,SC1091
            . "${SCRIPT_NAME}"
            unset SCRIPT_NAME || true
          fi
          _py_dir=$(libscript_get_version_dir "python" "${_version}")
          if [ ! -d "${_py_dir}" ]; then
            log_info "Python version ${_version} not found locally. Installing via libscript..."
            "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install python "${_version}" >&2 || return 1
          fi
          
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
libscript_python_venv() {
  if [ "$#" -lt 1 ]; then
    log_error 'Usage: libscript_python_venv <target_dir> [python_version]'
    return 1
  fi

  _target_dir="$1"
  _python_version="${2:-}"
  _backend="${LIBSCRIPT_PYTHON_VENV_BACKEND:-venv}"
  
  log_info "Creating Python virtual environment at '${_target_dir}' using backend '${_backend}'..."
  
  case "${_backend}" in
    uv)
      if [ -n "${_python_version}" ]; then
        uv venv --seed --python "${_python_version}" -- "${_target_dir}" || return 1
      else
        uv venv --seed -- "${_target_dir}" || return 1
      fi
      ;;
    venv)
      if [ -n "${_python_version}" ]; then
         _python_exe=$(libscript_python_resolve "${_python_version}") || return 1
      else
         _python_exe=$(libscript_python_resolve) || return 1
      fi
      _venv_args=""
      if [ "${LIBSCRIPT_OFFLINE:-0}" = "1" ] || [ "${PIP_NO_INDEX:-0}" = "1" ]; then
        _venv_args='--without-pip'
      fi
      if ! "${_python_exe}" -m venv ${_venv_args} "${_target_dir}"; then
        if [ -z "${_venv_args}" ]; then
          "${_python_exe}" -m venv --without-pip "${_target_dir}" || return 1
        else
          return 1
        fi
      fi
      if [ ! -f "${_target_dir}/bin/pip" ] && [ ! -f "${_target_dir}/Scripts/pip.exe" ]; then
        _wheels_dir="${PIP_FIND_LINKS:-${PIP_WHEEL_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache}/wheels}}"
        if [ -d "${_wheels_dir}" ]; then
          _py_bin="${_target_dir}/bin/python"
          [ -f "${_target_dir}/Scripts/python.exe" ] && _py_bin="${_target_dir}/Scripts/python.exe"
          "$_py_bin" -m pip install --no-index --find-links "${_wheels_dir}" pip setuptools wheel 2>/dev/null || true
        fi
      fi
      ;;
    *)
      log_error "Unsupported Python venv backend: ${_backend}"
      return 1
      ;;
  esac
}

# ## libscript_python_ensure_venv_owner
# Verifies that a project directory's .venv does not symlink into /root when run by a non-root user,
# recreating and syncing the virtual environment under the target user's home directory if needed.
libscript_python_ensure_venv_owner() {
  _venv_dir="${1:-}"
  _venv_ver="${2:-${PYTHON_VERSION:-3.12}}"
  _venv_user="${3:-${SERVICE_USER:-${REMOTE_USER:-${SUDO_USER:-}}}}"
  _venv_home="${4:-}"

  [ -n "$_venv_dir" ] && [ -d "$_venv_dir" ] || return 0
  if [ ! -f "${_venv_dir}/pyproject.toml" ] && [ ! -f "${_venv_dir}/requirements.txt" ] && [ ! -d "${_venv_dir}/.venv" ]; then
    return 0
  fi

  if [ -z "$_venv_ver" ] || [ "$_venv_ver" = "null" ] || [ "$_venv_ver" = "latest" ] || [ "$_venv_ver" = "default" ]; then
    _venv_ver='3.12'
  fi
  if [ -z "$_venv_home" ]; then
    _venv_home=$(libscript_resolve_user_home "$_venv_user")
  fi

  if [ -L "${_venv_dir}/.venv/bin/python" ] || [ -L "${_venv_dir}/.venv/bin/python3" ]; then
    _venv_lnk=$(readlink -f "${_venv_dir}/.venv/bin/python3" 2>/dev/null || readlink "${_venv_dir}/.venv/bin/python3" 2>/dev/null || true)
    case "$_venv_lnk" in
      /root/*)
        if [ -n "$_venv_user" ] && [ "$_venv_user" != "root" ]; then
          log_info "Recreating '${_venv_dir}/.venv' for user '$_venv_user' (previously linked into /root)..."
          rm -rf "${_venv_dir}/.venv"
        fi
        ;;
    esac
  fi

  if [ ! -x "${_venv_dir}/.venv/bin/python" ]; then
    if command -v uv >/dev/null 2>&1; then
      HOME="$_venv_home" UV_PYTHON_INSTALL_DIR="${_venv_home}/.local/share/uv/python" UV_CACHE_DIR="${_venv_home}/.cache/uv" LIBSCRIPT_PYTHON_VENV_BACKEND=uv libscript_python_venv "${_venv_dir}/.venv" "$_venv_ver" 2>/dev/null || true
      (cd "$_venv_dir" && HOME="$_venv_home" UV_PYTHON_INSTALL_DIR="${_venv_home}/.local/share/uv/python" UV_CACHE_DIR="${_venv_home}/.cache/uv" PATH="${PATH}:${_venv_home}/.local/bin:/root/.local/bin" uv sync --python "$_venv_ver" 2>/dev/null || HOME="$_venv_home" uv sync 2>/dev/null || true)
    else
      libscript_python_venv "${_venv_dir}/.venv" "$_venv_ver" 2>/dev/null || true
    fi
  fi

  if [ -n "$_venv_user" ] && id "$_venv_user" >/dev/null 2>&1 && [ -d "${_venv_dir}/.venv" ]; then
    _venv_grp="${SERVICE_GROUP:-${REMOTE_GROUP:-$_venv_user}}"
    chown -R "${_venv_user}:${_venv_grp}" "${_venv_dir}/.venv" "${_venv_home}/.local" "${_venv_home}/.cache" 2>/dev/null || sudo -n chown -R "${_venv_user}:${_venv_grp}" "${_venv_dir}/.venv" "${_venv_home}/.local" "${_venv_home}/.cache" 2>/dev/null || true
  fi
}

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_pe_caller_dir:-}" ] && SCRIPT_DIR="$_pe_caller_dir"
[ -n "${_pe_caller_this:-}" ] && THIS_FILE="$_pe_caller_this"
unset _pe_caller_this _pe_caller_dir || true
