#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145



set -feu
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE}"

elif [ "${ZSH_VERSION-}" ]; then
  this_file="${0}"

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

export PYTHON_VERSION="${PYTHON_VERSION:-3.10}"

export JUPYTERHUB_NOTEBOOK_DIR="${JUPYTERHUB_NOTEBOOK_DIR:-/opt/notebooks}"
export JUPYTERHUB_IP="${JUPYTERHUB_IP:-127.0.0.1}"
default_password='-argon2:$argon2id$v=19$m=10240,t=10,p=8$HeC4C022haY1PxTUcAPk+A$ULz24zkP3jNHvScVul9t/OAOjhdgTNJYfPUvMWSOGcg'
export JUPYTERHUB_PASSWORD="${JUPYTERHUB_PASSWORD:-${default_password}}"
export JUPYTERHUB_PORT="${JUPYTERHUB_PORT:-8888}"
export JUPYTERHUB_SERVICE_GROUP="${JUPYTERHUB_SERVICE_GROUP:-jupyter}"
export JUPYTERHUB_SERVICE_USER="${JUPYTERHUB_SERVICE_USER:-jupyter}"
export JUPYTERHUB_USERNAME="${JUPYTERHUB_USERNAME:-jupyter}"
export JUPYTERHUB_VENV="${JUPYTERHUB_VENV:-/opt/venvs/jupyter-${PYTHON_VERSION}}"
