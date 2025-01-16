FROM debian:bookworm-slim

ENV SCRIPT_ROOT_DIR='/scripts'

COPY . /scripts
WORKDIR /scripts

ARG SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD=1
ARG serve-actix-diesel-auth-scaffold_VERSION='*'

RUN <<-EOF

if [ "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD:-0}" -eq 1 ]; then
  SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/app/third_party/serve-actix-diesel-auth-scaffold/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
fi

EOF


