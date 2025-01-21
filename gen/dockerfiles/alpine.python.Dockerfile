FROM alpine:latest

ENV LIBSCRIPT_ROOT_DIR='/scripts'


COPY . /scripts
WORKDIR /scripts

###########################
# Toolchain(s) [required] #
###########################
ARG PYTHON_INSTALL_DIR=1
ARG PYTHON_VERSION='3.10'

RUN <<-EOF

if [ "${PYTHON_INSTALL_DIR:-1}" -eq 1 ]; then
  if [ ! -z "${PYTHON_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${PYTHON_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p "${DEST}"
    cd "${DEST}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${PYTHON_COMMAND_FOLDER:-_lib/_toolchain}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then . "${SCRIPT_NAME}"; fi
  if [ ! -z "${PYTHON_COMMANDS+x}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"'/setup_python.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${PYTHON_COMMANDS}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  if [ ! -z "${PYTHON_DEST+x}" ]; then cd "${previous_wd}"; fi
fi

EOF


