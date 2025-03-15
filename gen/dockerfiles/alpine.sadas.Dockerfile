FROM alpine:latest

ENV LC_ALL=C.UTF-8 LANG=C.UTF-8

ENV LIBSCRIPT_ROOT_DIR='/scripts'
ENV LIBSCRIPT_BUILD_DIR='/libscript_build'
ENV LIBSCRIPT_DATA_DIR='/libscript_data'


COPY . /scripts
WORKDIR /scripts

########################
# Server(s) [required] #
########################
ARG SADAS=1

ARG SADAS_COMMANDS_BEFORE='git_get https://github.com/SamuelMarks/serve-actix-diesel-auth-scaffold "${SADAS_DEST}"'
ARG SADAS_COMMAND_FOLDER='_lib/_server/rust'
ARG SADAS_DEST='/tmp/serve-actix-diesel-auth-scaffold'

RUN <<-EOF

if [ "${SADAS:-1}" -eq 1 ]; then
  if [ ! -z "${SADAS_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${SADAS_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"
    cd -- "${DEST}"
  fi
  if [ ! -z "${SADAS_VARS+x}" ]; then
    export VARS="${SADAS_VARS}"
  fi
  if [ ! -z "${SADAS_COMMANDS_BEFORE+x}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'/setup_before_sadas.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${SADAS_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${SADAS_COMMAND_FOLDER:-app/third_party/sadas}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then
    . "${SCRIPT_NAME}";
  else
    >&2 printf 'Not found, SCRIPT_NAME of %s\n' "${SCRIPT_NAME}"
  fi
  if [ ! -z "${SADAS_DEST+x}" ]; then cd -- "${previous_wd}"; fi
fi

EOF


