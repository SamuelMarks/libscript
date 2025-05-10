#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE+x}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION+x}" ]; then
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

export BUILD_DIR="${BUILD_DIR:-./build}"

export RUST_INSTALL="${RUST_INSTALL:-1}"
export RUST_VERSION="${RUST_VERSION:-nightly}"

export NODEJS_INSTALL="${NODEJS_INSTALL:-1}"
export NODEJS_VERSION="${NODEJS_VERSION:-lts}"

export PYTHON_INSTALL="${PYTHON_INSTALL:-1}"
export PYTHON_VERSION="${PYTHON_VERSION:-3.10}"

export PYTHON_VENV="${PYTHON_VENV:-/opt/venvs/venv-${PYTHON_VERSION}}"

export POSTGRES_URL="${POSTGRES_URL:-1}"
export POSTGRES_USER="${POSTGRES_USER:-rest_user}"
export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-rest_pass}"
export POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
export POSTGRES_DB="${POSTGRES_DB:-rest_db}"
export POSTGRES_PASSWORD_FILE
export POSTGRES_VERSION="${POSTGRES_VERSION:-17}"

export VALKEY_INSTALL="${VALKEY_INSTALL:-1}"
export VALKEY_VERSION="${VALKEY_VERSION:-unstable}"
export VALKEY_DAEMON="${VALKEY_DAEMON:-1}"

export NGINX_INSTALL="${NGINX_INSTALL:-1}"
export NGINX_VERSION="${NGINX_VERSION:-mainline}"
export NGINX_DAEMOM="${NGINX_DAEMOM:-1}"

export CELERY_INSTALL="${CELERY_INSTALL:-1}"
export CELERY_DAEMOM="${CELERY_DAEMOM:-1}"
export CELERY_VENV="${CELERY_VENV:-${PYTHON_VENV}}"

export WWWROOT_INSTALL="${WWWROOT_INSTALL:-1}"

export JUPYTERHUB_INSTALL="${JUPYTERHUB_INSTALL:-1}"
export JUPYTERHUB_NOTEBOOK_DIR="${JUPYTERHUB_NOTEBOOK_DIR:-/opt/notebooks}"
export JUPYTERHUB_IP="${JUPYTERHUB_IP:-127.0.0.1}"
# Don't actually use the plaintext password this represents in production!
# shellcheck disable=SC2016
default_password='-argon2:$argon2id$v=19$m=10240,t=10,p=8$HeC4C022haY1PxTUcAPk+A$ULz24zkP3jNHvScVul9t/OAOjhdgTNJYfPUvMWSOGcg'
export JUPYTERHUB_PASSWORD="${JUPYTERHUB_PASSWORD:-${default_password}}"
export JUPYTERHUB_PORT="${JUPYTERHUB_PORT:-8888}"
export JUPYTERHUB_SERVICE_GROUP="${JUPYTERHUB_SERVICE_GROUP:-jupyter}"
export JUPYTERHUB_SERVICE_USER="${JUPYTERHUB_SERVICE_USER:-jupyter}"
export JUPYTERHUB_USERNAME="${JUPYTERHUB_USERNAME:-jupyter}"
export JUPYTERHUB_VENV="${JUPYTERHUB_VENV:-/opt/venvs/jupyter-${PYTHON_VERSION}}"
