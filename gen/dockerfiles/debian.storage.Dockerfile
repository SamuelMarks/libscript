FROM debian:bookworm-slim

ENV LIBSCRIPT_ROOT_DIR='/scripts'


COPY . /scripts
WORKDIR /scripts

##########################
# Database(s) [required] #
##########################
ARG POSTGRES_URL=1

ARG POSTGRES_USER='rest_user'
ARG POSTGRES_PASSWORD='rest_pass'
ARG POSTGRES_DB='rest_db'
ARG POSTGRES_PASSWORD_FILE
ARG POSTGRES_VERSION=17

RUN <<-EOF

if [ "${POSTGRES_URL:-1}" -eq 1 ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${POSTGRES_COMMAND_FOLDER:-_lib/_storage}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then . "${SCRIPT_NAME}"; fi
  if [ -n "${POSTGRES_COMMANDS}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"'/setup_postgres.sh'
    export SCRIPT_NAME
    cp "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${POSTGRES_COMMANDS}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
fi

EOF



ARG REDIS_URL=1
ARG VALKEY_VERSION='*'

RUN <<-EOF

if [ "${REDIS_URL:-1}" -eq 1 ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${VALKEY_COMMAND_FOLDER:-_lib/_storage}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then . "${SCRIPT_NAME}"; fi
  if [ -n "${VALKEY_COMMANDS}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"'/setup_valkey.sh'
    export SCRIPT_NAME
    cp "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${VALKEY_COMMANDS}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
fi

EOF


ARG AMQP_URL=0
ARG RABBITMQ_VERSION='*'

RUN <<-EOF

if [ "${AMQP_URL:-0}" -eq 1 ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${RABBITMQ_COMMAND_FOLDER:-_lib/_storage}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then . "${SCRIPT_NAME}"; fi
  if [ -n "${RABBITMQ_COMMANDS}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"'/setup_rabbitmq.sh'
    export SCRIPT_NAME
    cp "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${RABBITMQ_COMMANDS}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
fi

EOF


