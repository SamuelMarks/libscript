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

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
SCRIPT_ROOT_DIR="${SCRIPT_ROOT_DIR:-$(d="$(CDPATH='' cd -- "$(dirname -- "$(dirname -- "$( dirname -- "${DIR}" )" )" )")"; if [ -d "$d" ]; then echo "$d"; else echo './'"$d"; fi)}"

SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/conf.env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${DIR}"'/conf.env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_lib/_common/priv.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

if [ ! -d "${JUPYTERHUB_VENV}" ]; then
  SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_lib/_toolchain/python/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"

  "${PRIV}" mkdir -p "${JUPYTERHUB_VENV}"
  "${PRIV}" chown -R "${USER}":"${GROUP:-$USER}" "${JUPYTERHUB_VENV}"
  uv venv --python "${PYTHON_VERSION}" "${JUPYTERHUB_VENV}"
  "${JUPYTERHUB_VENV}"'/bin/python' -m ensurepip
  "${JUPYTERHUB_VENV}"'/bin/python' -m pip install -U pip
  "${JUPYTERHUB_VENV}"'/bin/python' -m pip install -U setuptools wheel
  "${JUPYTERHUB_VENV}"'/bin/python' -m pip install -U jupyverse[auth,jupyterlab] fps-jupyterlab fps-auth jupyter-collaboration oauthenticator jupyterhub-nativeauthenticator
  # "${JUPYTERHUB_VENV}"'/bin/python' -m pip install -U jupyter notebook pyright python-language-server python-lsp-server
fi

if ! cmd_avail npm ; then
  SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_lib/_toolchain/nodejs/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
fi
npm install -g configurable-http-proxy
"${PRIV}" mkdir -p "${JUPYTERHUB_NOTEBOOK_DIR}"
"${PRIV}" chown -R "${JUPYTERHUB_SERVICE_USER}":"${JUPYTERHUB_SERVICE_GROUP}" "${JUPYTERHUB_NOTEBOOK_DIR}" "${JUPYTERHUB_VENV}"

if [ -d '/etc/systemd/system' ]; then
  if [ ! -d '/home/'"${JUPYTERHUB_SERVICE_USER}"'/' ]; then
    adduser "${JUPYTERHUB_SERVICE_USER}" --home '/home/'"${JUPYTERHUB_SERVICE_USER}"'/' --gecos ''
  fi
  "${PRIV}" chown -R "${JUPYTERHUB_SERVICE_USER}":"${JUPYTERHUB_SERVICE_USER}" "${JUPYTERHUB_VENV}"

  service_name='jupyterhub_'"${JUPYTERHUB_IP}"'_'"${JUPYTERHUB_PORT}"
  service='/etc/systemd/system/'"${service_name}"'.service'
  tmp="${TMPDIR:-/tmp}"'/'"${service_name}"
  envsubst < "${SCRIPT_ROOT_DIR}"'/app/third_party/jupyter/conf/systemd/jupyverse.service' > "${tmp}"
  "${PRIV}" mv "${tmp}" "${service}"
  "${PRIV}" chmod 0644 "${service}"
  "${PRIV}" systemctl stop "${service_name}" || true
  "${PRIV}" systemctl daemon-reload
  "${PRIV}" systemctl start "${service_name}"
elif [ -d '/Library/LaunchDaemons' ]; then
  >&2 echo 'TODO: macOS service'
  exit 3
else
  "${JUPYTERHUB_VENV}"'/bin/jupyter' notebook \
    --NotebookApp.notebook_dir="${JUPYTERHUB_NOTEBOOK_DIR}" \
    --NotebookApp.ip="${JUPYTERHUB_IP}" \
    --NotebookApp.port="${JUPYTERHUB_PORT}" \
    --Session.username="${JUPYTERHUB_USERNAME}" \
    --NotebookApp.password="${JUPYTERHUB_PASSWORD}" \
    --NotebookApp.password_required=True \
    --NotebookApp.allow_remote_access=True \
    --NotebookApp.iopub_data_rate_limit=2147483647 \
    --no-browser \
    --NotebookApp.open_browser=False &
fi
