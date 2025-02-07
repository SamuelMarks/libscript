#!/bin/sh

# shellcheck disable=SC2236
if [ ! -z "${SCRIPT_NAME+x}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ ! -z "${BASH_VERSION+x}" ]; then
  # shellcheck disable=SC3028 disable=SC3054
  this_file="${BASH_SOURCE[0]}"
  # shellcheck disable=SC3040
  set -o pipefail
elif [ ! -z "${ZSH_VERSION+x}" ]; then
  # shellcheck disable=SC2296
  this_file="${(%):-%x}"
  # shellcheck disable=SC3040
  set -o pipefail
else
  this_file="${0}"
fi
set -feu

STACK="${STACK:-:}"
case "${STACK}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    return ;;
  *)
    printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
STACK="${STACK}${this_file}"':'
export STACK

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

depends 'curl'
if [ ! -f "${HOME}"'/.local/bin/uv' ]; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
# shellcheck disable=SC1091
. "${HOME}"'/.local/bin/env'
# uv python install "${PYTHON_VERSION}"
if [ -z "${VENV+x}" ] && [ ! -z "${PYTHON_VENV+x}" ]; then
  export VENV="${PYTHON_VENV}"
fi
if [ ! -z "${VENV+x}" ] && [ ! -f "${VENV}"'/bin/python' ]; then
  uv venv --python "${PYTHON_VERSION}" "${VENV}"
  "${VENV}"'/bin/python' -m ensurepip
  "${VENV}"'/bin/python' -m pip install -U pip
  "${VENV}"'/bin/python' -m pip install -U setuptools wheel
  # For safety only install package and its deps inside a venv
  if [ -f 'requirements.txt' ]; then
    "${VENV}"'/bin/python' -m pip install -r 'requirements.txt'
  fi
  if [ -f 'setup.py' ] || [ -f 'setup.cfg' ] || [ -f 'pyproject.toml' ]; then
    "${VENV}"'/bin/python' -m pip install -e .
  fi
fi
