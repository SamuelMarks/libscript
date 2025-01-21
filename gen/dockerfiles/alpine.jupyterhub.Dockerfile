FROM alpine:latest

ENV LIBSCRIPT_ROOT_DIR='/scripts'


COPY . /scripts
WORKDIR /scripts

########################
# Server(s) [required] #
########################
ARG JUPYTERHUB=0

RUN <<-EOF

if [ "${JUPYTERHUB:-0}" -eq 1 ]; then
  if [ ! -z "${JUPYTERHUB_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${JUPYTERHUB_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p "${DEST}"
    cd "${DEST}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${JUPYTERHUB_COMMAND_FOLDER:-app/third_party}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then . "${SCRIPT_NAME}"; fi
  if [ ! -z "${JUPYTERHUB_COMMANDS+x}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"'/setup_jupyterhub.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${JUPYTERHUB_COMMANDS}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  if [ ! -z "${JUPYTERHUB_DEST+x}" ]; then cd "${previous_wd}"; fi
fi

EOF


