FROM debian:bookworm-slim

ENV SCRIPT_ROOT_DIR='/scripts'

COPY . /scripts
WORKDIR /scripts

ARG POSTGRES_URL=1
ARG POSTGRES_USER='rest_user'
ARG POSTGRES_PASSWORD='rest_pass'
ARG POSTGRES_DB='rest_db'
ARG POSTGRES_PASSWORD_FILE
ARG POSTGRES_VERSION='17'

RUN <<-EOF

if [ "${POSTGRES_URL:-0}" -eq 1 ]; then
  SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_lib/_storage/postgres/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
fi

EOF


