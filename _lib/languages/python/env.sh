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
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
_EB_CALLER_THIS="${THIS_FILE}"
_EB_CALLER_DIR="${SCRIPT_DIR}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_base.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

_py_base="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/python"
if [ -z "${PYTHON_VERSION:-}" ] || [ "${PYTHON_VERSION:-}" = "latest" ]; then
  if [ -d "${_py_base}/default" ]; then
    PYTHON_VERSION="default"
  elif [ -d "${_py_base}/latest" ]; then
    PYTHON_VERSION="latest"
  elif [ -d "${_py_base}/3.12" ]; then
    PYTHON_VERSION="3.12"
  else
    _py_detected=""
    for _py_dir in "${_py_base}"/3.*; do
      if [ -d "$_py_dir" ]; then
        _py_detected=$(basename "$_py_dir")
      fi
    done
    if [ -n "$_py_detected" ]; then
      PYTHON_VERSION="$_py_detected"
    else
      PYTHON_VERSION="${PYTHON_VERSION:-3.12}"
    fi
  fi
fi
export PYTHON_VERSION

if [ "${PYTHON_VERSION:-}" ]; then
  export PYTHONHOME="${_py_base}/${PYTHON_VERSION}"
  PYTHON_MINOR_VERSION=$(printf '%s
' "${PYTHON_VERSION}" | cut -d. -f1,2)
  export PYTHON_MINOR_VERSION
  _py_site="${PYTHONHOME}/lib/python${PYTHON_MINOR_VERSION}/site-packages"
  case ":${PYTHONPATH:-}:" in
    *":${_py_site}:"*) ;;
    *) export PYTHONPATH="${_py_site}${PYTHONPATH:+:${PYTHONPATH}}" ;;
  esac
  for _py_cand in "${PYTHONHOME}/bin" "${_py_base}/default/bin"; do
    if [ -d "$_py_cand" ] || [ "$_py_cand" = "${PYTHONHOME}/bin" ]; then
      case ":${PATH:-}:" in
        *":${_py_cand}:"*) ;;
        *) PATH="${_py_cand}${PATH:+:${PATH}}" ;;
      esac
    fi
  done
  export PATH
  if [ ! -d "${PYTHONHOME}" ]; then
    unset PYTHONHOME
  fi
fi
if [ "${PYTHON_VENV:-}" ]; then
  case ":${PATH:-}:" in
    *":${PYTHON_VENV}/bin:"*) ;;
    *) export PATH="${PYTHON_VENV}/bin${PATH:+:${PATH}}" ;;
  esac
  export VIRTUAL_ENV="${PYTHON_VENV}"
  unset PYTHONHOME
fi
