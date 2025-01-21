FROM debian:bookworm-slim

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
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/app/third_party/sadas/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
fi

EOF


