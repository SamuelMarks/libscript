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

if [ ! -d "${JUPYTER_NOTEBOOK_VENV}" ]; then
  SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_lib/_toolchain/python/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"

  "${PRIV}" mkdir -p "${JUPYTER_NOTEBOOK_VENV}"
  "${PRIV}" chown -R "${USER}":"${GROUP:-$USER}" "${JUPYTER_NOTEBOOK_VENV}"
  uv venv --python "${PYTHON_VERSION}" "${JUPYTER_NOTEBOOK_VENV}"
  "${JUPYTER_NOTEBOOK_VENV}"'/bin/python' -m ensurepip
  "${JUPYTER_NOTEBOOK_VENV}"'/bin/python' -m pip install -U pip
  "${JUPYTER_NOTEBOOK_VENV}"'/bin/python' -m pip install -U setuptools wheel
  "${JUPYTER_NOTEBOOK_VENV}"'/bin/python' -m pip install -U jupyter notebook
fi

"${PRIV}" mkdir -p "${JUPYTER_NOTEBOOK_DIR}"
"${PRIV}" chown -R "${JUPYTER_NOTEBOOK_SERVICE_USER}":"${JUPYTER_NOTEBOOK_SERVICE_GROUP}" "${JUPYTER_NOTEBOOK_DIR}" "${JUPYTER_NOTEBOOK_VENV}"

if [ -d '/etc/systemd/system' ]; then
  if [ ! -d '/home/'"${JUPYTER_NOTEBOOK_SERVICE_USER}"'/' ]; then
    adduser "${JUPYTER_NOTEBOOK_SERVICE_USER}" --home '/home/'"${JUPYTER_NOTEBOOK_SERVICE_USER}"'/' --gecos ''
  fi
  "${PRIV}" chown -R "${JUPYTER_NOTEBOOK_SERVICE_USER}":"${JUPYTER_NOTEBOOK_SERVICE_USER}" "${JUPYTER_NOTEBOOK_VENV}"

  service_name='jupyter_notebook'"${JUPYTER_NOTEBOOK_IP}"'_'"${JUPYTER_NOTEBOOK_PORT}"
  service='/etc/systemd/system/'"${service_name}"'.service'
  tmp="${TMPDIR:-/tmp}"'/'"${service_name}"
  envsubst < "${SCRIPT_ROOT_DIR}"'/app/third_party/jupyter/conf/systemd/jupyter_notebook.service' > "${tmp}"
  "${PRIV}" mv "${tmp}" "${service}"
  "${PRIV}" chmod 0644 "${service}"
  "${PRIV}" systemctl stop "${service_name}" || true
  "${PRIV}" systemctl daemon-reload
  "${PRIV}" systemctl start "${service_name}"
elif [ -d '/Library/LaunchDaemons' ]; then
  >&2 echo 'TODO: macOS service'
  exit 3
else
  "${JUPYTER_NOTEBOOK_VENV}"'/bin/jupyter' notebook \
    --NotebookApp.notebook_dir="${JUPYTER_NOTEBOOK_DIR}" \
    --NotebookApp.ip="${JUPYTER_NOTEBOOK_IP}" \
    --NotebookApp.port="${JUPYTER_NOTEBOOK_PORT}" \
    --Session.username="${JUPYTER_NOTEBOOK_USERNAME}" \
    --NotebookApp.password="${JUPYTER_NOTEBOOK_PASSWORD}" \
    --NotebookApp.password_required=True \
    --NotebookApp.allow_remote_access=True \
    --NotebookApp.iopub_data_rate_limit=2147483647 \
    --no-browser \
    --NotebookApp.open_browser=False &
fi
