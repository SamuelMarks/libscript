FROM alpine:latest

ENV LIBSCRIPT_ROOT_DIR='/scripts'


COPY . /scripts
WORKDIR /scripts

########################
# Server(s) [required] #
########################
ARG SADAS=1

ARG SADAS_COMMANDS='git_get https://github.com/SamuelMarks/serve-actix-diesel-auth-scaffold && \
git_get https://github.com/SamuelMarks/serve-actix-diesel-auth-scaffold'
ARG SADAS_COMMAND_FOLDER='_lib/_server/rust'
ARG SADAS_DEST='/tmp/serve-actix-diesel-auth-scaffold'

RUN <<-EOF

if [ "${SADAS:-1}" -eq 1 ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${SADAS_COMMAND_FOLDER:-app/third_party}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then . "${SCRIPT_NAME}"; fi
  if [ -n "${SADAS_COMMANDS}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"'/setup_sadas.sh'
    export SCRIPT_NAME
    cp "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${SADAS_COMMANDS}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
fi

EOF


