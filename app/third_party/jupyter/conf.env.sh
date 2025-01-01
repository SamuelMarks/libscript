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
    printf '[STOP]     processing "%s" found in "%s"\n' "${this_file}" "${STACK}"
    return ;;
  *)
    printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
STACK="${STACK}${this_file}"':'
export STACK

export PYTHON_VERSION="${PYTHON_VERSION:-3.10}"

export JUPYTER_NOTEBOOK_DIR="${JUPYTER_NOTEBOOK_DIR:-/opt/notebooks}"
export JUPYTER_NOTEBOOK_IP="${JUPYTER_NOTEBOOK_IP:-127.0.0.1}"
export JUPYTER_NOTEBOOK_PASSWORD="${JUPYTER_NOTEBOOK_PASSWORD:-argon2:$argon2id$v=19$m=10240,t=10,p=8$HeC4C022haY1PxTUcAPk+A$ULz24zkP3jNHvScVul9t/OAOjhdgTNJYfPUvMWSOGcg}"
export JUPYTER_NOTEBOOK_PORT="${JUPYTER_NOTEBOOK_PORT:-8888}"
export JUPYTER_NOTEBOOK_SERVICE_GROUP="${JUPYTER_NOTEBOOK_SERVICE_GROUP:-jupyter}"
export JUPYTER_NOTEBOOK_SERVICE_USER="${JUPYTER_NOTEBOOK_SERVICE_USER:-jupyter}"
export JUPYTER_NOTEBOOK_USERNAME="${JUPYTER_NOTEBOOK_USERNAME:-jupyter}"
export JUPYTER_NOTEBOOK_VENV="${JUPYTER_NOTEBOOK_VENV:-/opt/venvs/jupyter-${PYTHON_VERSION}}"
