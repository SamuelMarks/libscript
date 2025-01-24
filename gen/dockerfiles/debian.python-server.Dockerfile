FROM debian:bookworm-slim

ENV LIBSCRIPT_ROOT_DIR='/scripts'
ENV LIBSCRIPT_BUILD_DIR='/libscript_build'
ENV LIBSCRIPT_DATA_DIR='/libscript_data'


COPY . /scripts
WORKDIR /scripts

########################
# Server(s) [optional] #
########################
ARG PYTHON_SERVER=1

ARG python_server_COMMANDS_BEFORE='git_get https://github.com/digitalocean/sample-python "${PYTHON_SERVER_DEST}" \
uv venv --python 3.12 venv-3-12 \
venv-3-12/bin/python -m ensurepip \
venv-3-12/bin/python -m pip install -r requirements.txt'
ARG python_server_COMMAND_FOLDER='_lib/_server/python'
ARG PYTHON_SERVER_DEST='/tmp/python-server'

RUN <<-EOF

if [ "${PYTHON_SERVER:-1}" -eq 1 ]; then
  if [ ! -z "${PYTHON_SERVER_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${PYTHON_SERVER_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p "${DEST}"
    cd "${DEST}"
  fi
  if [ ! -z "${PYTHON_SERVER_VARS+x}" ]; then
    export VARS="${PYTHON_SERVER_VARS}"
  fi
  if [ ! -z "${python_server_COMMANDS_BEFORE+x}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'/setup_before_python-server.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${python_server_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${python_server_COMMAND_FOLDER:-app/third_party/python-server}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then
    . "${SCRIPT_NAME}";
  else
    >&2 printf 'Not found, SCRIPT_NAME of %s\n' "${SCRIPT_NAME}"
  fi
  if [ ! -z "${PYTHON_SERVER_DEST+x}" ]; then cd "${previous_wd}"; fi
fi

EOF


