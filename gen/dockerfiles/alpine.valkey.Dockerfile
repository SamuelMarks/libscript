FROM alpine:latest

ENV SCRIPT_ROOT_DIR='/scripts'


COPY . /scripts
WORKDIR /scripts

ARG REDIS_URL=1
ARG VALKEY_VERSION='*'

RUN <<-EOF

if [ "${REDIS_URL:-1}" -eq 1 ]; then
  SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_lib/_storage/valkey/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
fi

EOF


