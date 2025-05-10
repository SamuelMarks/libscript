FROM alpine:latest

ENV LC_ALL=C.UTF-8 LANG=C.UTF-8

ENV LIBSCRIPT_ROOT_DIR='/scripts'
ENV LIBSCRIPT_BUILD_DIR='/libscript_build'
ENV LIBSCRIPT_DATA_DIR='/libscript_data'


COPY . /scripts
WORKDIR /scripts

##########################
# Database(s) [required] #
##########################
ARG POSTGRES_URL=1

ARG POSTGRES_USER='rest_user'
ARG POSTGRES_PASSWORD='rest_pass'
ARG POSTGRES_HOST='localhost'
ARG POSTGRES_DB='rest_db'
ARG POSTGRES_PASSWORD_FILE
ARG POSTGRES_VERSION=17

RUN <<-EOF

if [ "${POSTGRES_URL:-1}" -eq 1 ]; then
  if [ "${POSTGRES_DEST-}" ]; then
    previous_wd="$(pwd)"
    DEST="${POSTGRES_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"
    cd -- "${DEST}"
  fi
  if [ "${POSTGRES_VARS-}" ]; then
    export VARS="${POSTGRES_VARS}"
  fi
  if [ "${POSTGRES_COMMANDS_BEFORE-}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'/setup_before_postgres.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${POSTGRES_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${POSTGRES_COMMAND_FOLDER:-_lib/_storage/postgres}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then
    . "${SCRIPT_NAME}";
  else
    >&2 printf 'Not found, SCRIPT_NAME of %s\n' "${SCRIPT_NAME}"
  fi
  if [ "${POSTGRES_DEST-}" ]; then cd -- "${previous_wd}"; fi
fi

EOF



ARG REDIS_URL=1
ARG VALKEY_VERSION='*'

RUN <<-EOF

if [ "${REDIS_URL:-1}" -eq 1 ]; then
  if [ "${VALKEY_DEST-}" ]; then
    previous_wd="$(pwd)"
    DEST="${VALKEY_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"
    cd -- "${DEST}"
  fi
  if [ "${VALKEY_VARS-}" ]; then
    export VARS="${VALKEY_VARS}"
  fi
  if [ "${VALKEY_COMMANDS_BEFORE-}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'/setup_before_valkey.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${VALKEY_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${VALKEY_COMMAND_FOLDER:-_lib/_storage/valkey}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then
    . "${SCRIPT_NAME}";
  else
    >&2 printf 'Not found, SCRIPT_NAME of %s\n' "${SCRIPT_NAME}"
  fi
  if [ "${VALKEY_DEST-}" ]; then cd -- "${previous_wd}"; fi
fi

EOF


ARG AMQP_URL=0
ARG RABBITMQ_VERSION='*'

RUN <<-EOF

if [ "${AMQP_URL:-0}" -eq 1 ]; then
  if [ "${RABBITMQ_DEST-}" ]; then
    previous_wd="$(pwd)"
    DEST="${RABBITMQ_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"
    cd -- "${DEST}"
  fi
  if [ "${RABBITMQ_VARS-}" ]; then
    export VARS="${RABBITMQ_VARS}"
  fi
  if [ "${RABBITMQ_COMMANDS_BEFORE-}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'/setup_before_rabbitmq.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${RABBITMQ_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${RABBITMQ_COMMAND_FOLDER:-_lib/_storage/rabbitmq}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then
    . "${SCRIPT_NAME}";
  else
    >&2 printf 'Not found, SCRIPT_NAME of %s\n' "${SCRIPT_NAME}"
  fi
  if [ "${RABBITMQ_DEST-}" ]; then cd -- "${previous_wd}"; fi
fi

EOF


