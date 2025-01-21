FROM debian:bookworm-slim

ENV LIBSCRIPT_ROOT_DIR='/scripts'


COPY . /scripts
WORKDIR /scripts

##############
# WWWROOT(s) #
##############
ARG WWWROOT_example_com_INSTALL=0

ARG WWWROOT_example_com_COMMAND_FOLDER='_lib/_toolchain/nodejs'
ARG WWWROOT_example_com_COMMANDS='npm i -g @angular/cli && \
npm i && \
ng build --configuration production'

RUN <<-EOF

if [ "${WWWROOT_example_com_INSTALL:-0}" -eq 1 ]; then
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
    if [ -n "${WWWROOT_COMMANDS}" ]; then
      SCRIPT_NAME="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"'/setup_example_com.sh'
      export SCRIPT_NAME
      cp "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
      printf '%s' "${WWWROOT_COMMANDS}" >> "${SCRIPT_NAME}"
      # shellcheck disable=SC1090
      . "${SCRIPT_NAME}"
    fi
  fi
fi
EOF


