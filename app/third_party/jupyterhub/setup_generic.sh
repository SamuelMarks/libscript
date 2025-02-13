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
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

for lib in 'env.sh' '_lib/_common/priv.sh' '_lib/_common/envsubst_safe.sh' \
           '_lib/_toolchain/python/setup.sh' 'app/third_party/jupyterhub/env.sh' \
           '_lib/_toolchain/nodejs/setup.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

if [ ! -d "${JUPYTERHUB_VENV}" ]; then
  "${PRIV}" mkdir -p -- "${JUPYTERHUB_VENV}"
  "${PRIV}" chown -R -- "${USER}":"${GROUP:-${USER}}" "${JUPYTERHUB_VENV}"
  uv venv --python "${PYTHON_VERSION}" -- "${JUPYTERHUB_VENV}"
  "${JUPYTERHUB_VENV}"'/bin/python' -m ensurepip
  "${JUPYTERHUB_VENV}"'/bin/python' -m pip install -U pip
  "${JUPYTERHUB_VENV}"'/bin/python' -m pip install -U setuptools wheel
  "${JUPYTERHUB_VENV}"'/bin/python' -m pip install -U "jupyverse[auth,jupyterlab]" fps-jupyterlab fps-auth jupyter-collaboration oauthenticator jupyterhub-nativeauthenticator
  # "${JUPYTERHUB_VENV}"'/bin/python' -m pip install -U jupyter notebook pyright python-language-server python-lsp-server
fi
if ! cmd_avail configurable-http-proxy; then
  npm install -g configurable-http-proxy
fi
if [ ! -d "${JUPYTERHUB_NOTEBOOK_DIR}" ]; then
  "${PRIV}" mkdir -p -- "${JUPYTERHUB_NOTEBOOK_DIR}"
  "${PRIV}" chown -R -- "${JUPYTERHUB_SERVICE_USER}":"${JUPYTERHUB_SERVICE_GROUP}" "${JUPYTERHUB_NOTEBOOK_DIR}" "${JUPYTERHUB_VENV}"
fi

if [ -d '/etc/systemd/system' ]; then
  ENV=''
  if [ ! -z "${VARS+x}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/environ.sh'
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"

    object2key_val "${VARS}" 'export ' "'" >> "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh'
    chmod +x "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh'
    ENV="$(cut -c8- "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh' | awk '{arr[i++]=$0} END {while (i>0) print arr[--i] }' | tr -d "'" | awk -F= '!seen[$1]++' | xargs printf 'Environment="%s"\n')"
  fi

  if [ ! -d '/home/'"${JUPYTERHUB_SERVICE_USER}"'/' ]; then
    adduser "${JUPYTERHUB_SERVICE_USER}" --home '/home/'"${JUPYTERHUB_SERVICE_USER}"'/' --gecos ''
  fi
  "${PRIV}" chown -R -- "${JUPYTERHUB_SERVICE_USER}":"${JUPYTERHUB_SERVICE_USER}" "${JUPYTERHUB_VENV}"

  service_name='jupyterhub_'"${JUPYTERHUB_IP}"'_'"${JUPYTERHUB_PORT}"
  service='/etc/systemd/system/'"${service_name}"'.service'
  tmp00="$(mktemp -t "${service_name}"'.XXX.systemd.service')"
  envsubst_safe < "${LIBSCRIPT_ROOT_DIR}"'/app/third_party/jupyterhub/conf/systemd/jupyverse.service' > "${tmp00}"
  if [ -f "${service}" ]; then "${PRIV}" rm -f -- "${service}"; fi
  "${PRIV}" install -m 0644 -- "${tmp00}" "${service}"
  "${PRIV}" systemctl daemon-reload
  "${PRIV}" systemctl reload-or-restart -- "${service_name}"
  rm "${tmp00}"
elif [ -d '/Library/LaunchDaemons' ]; then
  >&2 printf 'TODO: macOS service\n'
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
