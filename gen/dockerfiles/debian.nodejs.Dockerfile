FROM debian:bookworm-slim

ENV LIBSCRIPT_ROOT_DIR='/scripts'


COPY . /scripts
WORKDIR /scripts

###########################
# Toolchain(s) [required] #
###########################
ARG NODEJS_INSTALL_DIR=1
ARG NODEJS_VERSION='lts'

RUN <<-EOF

if [ "${NODEJS_INSTALL_DIR:-1}" -eq 1 ]; then
  if [ ! -z "${NODEJS_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${NODEJS_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p "${DEST}"
    cd "${DEST}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${NODEJS_COMMAND_FOLDER:-_lib/_toolchain}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then . "${SCRIPT_NAME}"; fi
  if [ ! -z "${NODEJS_COMMANDS+x}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"'/setup_nodejs.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${NODEJS_COMMANDS}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  if [ ! -z "${NODEJS_DEST+x}" ]; then cd "${previous_wd}"; fi
fi

EOF


