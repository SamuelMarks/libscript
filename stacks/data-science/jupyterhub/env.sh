#!/bin/sh
# ## Overview
# Defines environment variables and configurations for the JupyterHub data science platform stack.
# 
# ## Usage
# Source or call this script to configure the environment for jupyterhub.


set -feu
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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export PYTHON_VERSION="${PYTHON_VERSION:-3.10}"

export JUPYTERHUB_NOTEBOOK_DIR="${JUPYTERHUB_NOTEBOOK_DIR:-/opt/notebooks}"
export JUPYTERHUB_IP="${JUPYTERHUB_IP:-127.0.0.1}"
DEFAULT_PASSWORD='-argon2:$argon2id$v=19$m=10240,t=10,p=8$HeC4C022haY1PxTUcAPk+A$ULz24zkP3jNHvScVul9t/OAOjhdgTNJYfPUvMWSOGcg'
export JUPYTERHUB_PASSWORD="${JUPYTERHUB_PASSWORD:-${DEFAULT_PASSWORD}}"
export JUPYTERHUB_PORT="${JUPYTERHUB_PORT:-8888}"
export JUPYTERHUB_SERVICE_GROUP="${JUPYTERHUB_SERVICE_GROUP:-jupyter}"
export JUPYTERHUB_SERVICE_USER="${JUPYTERHUB_SERVICE_USER:-jupyter}"
export JUPYTERHUB_USERNAME="${JUPYTERHUB_USERNAME:-jupyter}"
export JUPYTERHUB_VENV="${JUPYTERHUB_VENV:-/opt/venvs/jupyter-${PYTHON_VERSION}}"
