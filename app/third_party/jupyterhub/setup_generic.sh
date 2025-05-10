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
  priv  mkdir -p -- "${JUPYTERHUB_VENV}"
  priv  chown -R -- "${USER}":"${GROUP:-${USER}}" "${JUPYTERHUB_VENV}"
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
  priv  mkdir -p -- "${JUPYTERHUB_NOTEBOOK_DIR}"
  priv  chown -R -- "${JUPYTERHUB_SERVICE_USER}":"${JUPYTERHUB_SERVICE_GROUP}" "${JUPYTERHUB_NOTEBOOK_DIR}" "${JUPYTERHUB_VENV}"
fi

if [ -d '/etc/systemd/system' ]; then
  ENV=''
  if [ "${VARS-}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/environ.sh'
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"

    object2key_val "${VARS}" 'export ' "'" >> "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh'
    chmod +x "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh'
    ENV="$(cut -c8- "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh' | awk -- '{arr[i++]=$0} END {while (i>0) print arr[--i] }' | tr -d "'" | awk -F= '!seen[$1]++' | xargs printf 'Environment="%s"\n')"
  fi

  if [ ! -d '/home/'"${JUPYTERHUB_SERVICE_USER}"'/' ]; then
    adduser "${JUPYTERHUB_SERVICE_USER}" --home '/home/'"${JUPYTERHUB_SERVICE_USER}"'/' --gecos ''
  fi
  priv  chown -R -- "${JUPYTERHUB_SERVICE_USER}":"${JUPYTERHUB_SERVICE_USER}" "${JUPYTERHUB_VENV}"

  service_name='jupyterhub_'"${JUPYTERHUB_IP}"'_'"${JUPYTERHUB_PORT}"
  service='/etc/systemd/system/'"${service_name}"'.service'
  tmp00="$(mktemp -t "${service_name}"'.XXX.systemd.service')"
  trap 'rm -f -- "${tmp00}"' EXIT HUP INT QUIT TERM
  envsubst_safe < "${LIBSCRIPT_ROOT_DIR}"'/app/third_party/jupyterhub/conf/systemd/jupyverse.service' > "${tmp00}"
  if [ -f "${service}" ]; then priv  rm -f -- "${service}"; fi
  priv  install -m 0644 -- "${tmp00}" "${service}"
  priv  systemctl daemon-reload
  priv  systemctl reload-or-restart -- "${service_name}"
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
