FROM debian:bookworm-slim

ENV LC_ALL=C.UTF-8 LANG=C.UTF-8

ENV LIBSCRIPT_ROOT_DIR='/scripts'
ENV LIBSCRIPT_BUILD_DIR='/libscript_build'
ENV LIBSCRIPT_DATA_DIR='/libscript_data'


COPY . /scripts
WORKDIR /scripts

########################
# Server(s) [optional] #
########################
ARG NODEJS_HTTP_SERVER=1

ARG nodejs_http_server_COMMANDS_BEFORE='git_get https://github.com/mohammadhasanii/Node-HTTP3 "${NODEJS_HTTP_SERVER_DEST}"'
ARG nodejs_http_server_COMMAND_FOLDER='_lib/_server/nodejs'
ARG NODEJS_HTTP_SERVER_DEST='/tmp/nodejs-http-server'

RUN <<-EOF

if [ "${NODEJS_HTTP_SERVER:-1}" -eq 1 ]; then
  if [ "${NODEJS_HTTP_SERVER_DEST-}" ]; then
    previous_wd="$(pwd)"
    DEST="${NODEJS_HTTP_SERVER_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"
    cd -- "${DEST}"
  fi
  if [ "${NODEJS_HTTP_SERVER_VARS-}" ]; then
    export VARS="${NODEJS_HTTP_SERVER_VARS}"
  fi
  if [ "${nodejs_http_server_COMMANDS_BEFORE-}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'/setup_before_nodejs-http-server.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${nodejs_http_server_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${nodejs_http_server_COMMAND_FOLDER:-app/third_party/nodejs-http-server}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then
    . "${SCRIPT_NAME}";
  else
    >&2 printf 'Not found, SCRIPT_NAME of %s\n' "${SCRIPT_NAME}"
  fi
  if [ "${NODEJS_HTTP_SERVER_DEST-}" ]; then cd -- "${previous_wd}"; fi
fi

EOF


