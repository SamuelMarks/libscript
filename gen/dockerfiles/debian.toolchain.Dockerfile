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
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${NODEJS_COMMAND_FOLDER:-_lib/_toolchain}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then . "${SCRIPT_NAME}"; fi
  if [ -n "${NODEJS_COMMANDS}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"'/setup_nodejs.sh'
    export SCRIPT_NAME
    cp "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${NODEJS_COMMANDS}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
fi

EOF


ARG PYTHON_INSTALL_DIR=1
ARG PYTHON_VERSION='3.10'

RUN <<-EOF

if [ "${PYTHON_INSTALL_DIR:-1}" -eq 1 ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${PYTHON_COMMAND_FOLDER:-_lib/_toolchain}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then . "${SCRIPT_NAME}"; fi
  if [ -n "${PYTHON_COMMANDS}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"'/setup_python.sh'
    export SCRIPT_NAME
    cp "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${PYTHON_COMMANDS}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
fi

EOF


ARG RUST_INSTALL_DIR=1
ARG RUST_VERSION='nightly'

RUN <<-EOF

if [ "${RUST_INSTALL_DIR:-1}" -eq 1 ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${RUST_COMMAND_FOLDER:-_lib/_toolchain}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then . "${SCRIPT_NAME}"; fi
  if [ -n "${RUST_COMMANDS}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"'/setup_rust.sh'
    export SCRIPT_NAME
    cp "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${RUST_COMMANDS}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
fi

EOF


