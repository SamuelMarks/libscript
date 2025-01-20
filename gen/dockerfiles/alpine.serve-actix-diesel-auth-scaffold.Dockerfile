FROM alpine:latest

ENV LIBSCRIPT_ROOT_DIR='/scripts'


COPY . /scripts
WORKDIR /scripts

########################
# Server(s) [required] #
########################
ARG SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD=1
ARG SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST='/tmp/serve-actix-diesel-auth-scaffold'

RUN <<-EOF

if [ "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD:-1}" -eq 1 ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/app/third_party/serve-actix-diesel-auth-scaffold/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
fi

EOF


