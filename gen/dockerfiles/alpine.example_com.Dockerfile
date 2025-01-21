FROM alpine:latest

ENV LIBSCRIPT_ROOT_DIR='/scripts'


COPY . /scripts
WORKDIR /scripts

##############
# WWWROOT(s) #
##############
ARG WWWROOT_example_com_INSTALL=0

ARG example_com='./my_symlinked_wwwroot'
ARG WWWROOT_example_com_COMMAND_FOLDER='_lib/_toolchain/nodejs'
ARG WWWROOT_example_com_COMMANDS='npm i -g @angular/cli && \
npm i && \
ng build --configuration production'

RUN <<-EOF

if [ "${WWWROOT_example_com_INSTALL:-0}" -eq 1 ]; then
  if [ ! -z "${EXAMPLE_COM_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${EXAMPLE_COM_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p "${DEST}"
    cd "${DEST}"
  fi
  export WWWROOT_NAME="${WWWROOT_example_com_NAME:-example.com}"
  export WWWROOT_VENDOR="${WWWROOT_example_com_VENDOR:-nginx}"
  export WWWROOT_PATH="${WWWROOT_example_com_PATH:-./my_symlinked_wwwroot}"
  export WWWROOT_LISTEN="${80:-WWWROOT_example_com_LISTEN}"
  export WWWROOT_HTTPS_PROVIDER="${WWWROOT_example_com_HTTPS_PROVIDER:-letsencrypt}"
  export WWWROOT_COMMAND_FOLDER="${WWWROOT_example_com_COMMAND_FOLDER:-}"
  export WWWROOT_COMMANDS="${WWWROOT_example_com_COMMANDS:-}"
  if [ "${WWWROOT_VENDOR:-nginx}" = 'nginx' ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${WWWROOT_COMMAND_FOLDER:-_server/nginx}"'/setup.sh'
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    if [ -f "${SCRIPT_NAME}" ]; then . "${SCRIPT_NAME}"; fi
    if [ ! -z "${WWWROOT_COMMANDS+x}" ]; then
      SCRIPT_NAME="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"'/setup_example_com.sh'
      export SCRIPT_NAME
      install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
      printf '%s' "${WWWROOT_COMMANDS}" >> "${SCRIPT_NAME}"
      # shellcheck disable=SC1090
      . "${SCRIPT_NAME}"
    fi
  fi
fi
EOF


