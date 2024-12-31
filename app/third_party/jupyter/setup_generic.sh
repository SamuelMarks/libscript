#!/bin/sh

if [ -n "${BASH_VERSION}" ]; then
  # shellcheck disable=SC3028 disable=SC3054
  this_file="${BASH_SOURCE[0]}"
  # shellcheck disable=SC3040
  set -xeuo pipefail
elif [ -n "${ZSH_VERSION}" ]; then
  # shellcheck disable=SC2296
  this_file="${(%):-%x}"
  # shellcheck disable=SC3040
  set -xeuo pipefail
else
  this_file="${0}"
  printf 'argv[%d] = "%s"\n' "0" "${0}";
  printf 'argv[%d] = "%s"\n' "1" "${1}";
  printf 'argv[%d] = "%s"\n' "2" "${2}";
fi

guard='H_'"$(realpath -- "${this_file}" | sed 's/[^a-zA-Z0-9_]/_/g')"

if env | grep -qF "${guard}"'=1'; then
  echo 'EXIT      jupyter/setup_generic.sh guard '"${guard}"
  return ;
else
  echo 'CONTINUE  jupyter/setup_generic.sh guard '"${guard}"
fi
export "${guard}"=1

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
SCRIPT_ROOT_DIR="${SCRIPT_ROOT_DIR:-$(d="$(CDPATH='' cd -- "$(dirname -- "$(dirname -- "$( dirname -- "${DIR}" )" )" )")"; if [ -d "$d" ]; then echo "$d"; else echo './'"$d"; fi)}"

# shellcheck disable=SC1091
. "${SCRIPT_ROOT_DIR}"'/conf.env.sh'

# shellcheck disable=SC1091
. "${DIR}"'/conf.env.sh'

if [ ! -d "${JUPYTER_NOTEBOOK_VENV}" ]; then
  # shellcheck disable=SC1091
  . "${SCRIPT_ROOT_DIR}"'/_lib/_toolchain/python/setup.sh'

  uv venv --python "${PYTHON_VERSION}" "${JUPYTER_NOTEBOOK_VENV}"
fi

get_priv

"${PRIV}" mkdir -p "${JUPYTER_NOTEBOOK_DIR}"
"${PRIV}" chown -R "${JUPYTER_NOTEBOOK_SERVICE_USER}":"${JUPYTER_NOTEBOOK_SERVICE_GROUP}" "${JUPYTER_NOTEBOOK_DIR}" "${JUPYTER_NOTEBOOK_VENV}"

if [ -d '/etc/systemd/system' ]; then
  if [ ! -d '/home/'"${JUPYTER_NOTEBOOK_SERVICE_USER}"'/' ]; then
    adduser "${JUPYTER_NOTEBOOK_SERVICE_USER}" --home '/home/'"${JUPYTER_NOTEBOOK_SERVICE_USER}"'/' --gecos ''
  fi

  service_name='jupyter_notebook'"${JUPYTER_NOTEBOOK_IP}"'_'"${JUPYTER_NOTEBOOK_PORT}"
  service='/etc/systemd/system/'"${service_name}"'.service'
  tmp="${TMPDIR:-/tmp}"'/'"${service_name}"
  envsubst < "${DIR}"'/conf/systemd/jupyter_notebook.service' > "${tmp}"
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
