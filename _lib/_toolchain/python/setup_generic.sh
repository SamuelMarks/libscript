#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'

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
if [ "${VENV-}" ] && [ "${PYTHON_VENV-}" ]; then
  export VENV="${PYTHON_VENV}"
fi
if [ "${VENV-}" ] && [ ! -f "${VENV}"'/bin/python' ]; then
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
