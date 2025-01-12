FROM debian:bookworm-slim

ENV SCRIPT_ROOT_DIR='/scripts'

COPY . /scripts
WORKDIR /scripts

ARG POSTGRES_URL=1
ARG POSTGRES_URL_VERSION='>17'

RUN <<-EOF

if [ "${POSTGRES_URL:-0}" -eq 1 ]; then
  SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_lib/_storage/postgres/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
fi

EOF


ARG REDIS_URL=1
ARG REDIS_URL_VERSION='*'

RUN <<-EOF

if [ "${REDIS_URL:-0}" -eq 1 ]; then
  SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_lib/_storage/valkey/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
fi

EOF


ARG AMQP_URL=0
ARG AMQP_URL_VERSION='*'

RUN <<-EOF

if [ "${AMQP_URL:-0}" -eq 1 ]; then
  SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_lib/_storage/rabbitmq/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
fi

EOF


