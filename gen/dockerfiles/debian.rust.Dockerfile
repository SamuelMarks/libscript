FROM debian:bookworm-slim

ENV LC_ALL=C.UTF-8 LANG=C.UTF-8

ENV LIBSCRIPT_ROOT_DIR='/scripts'
ENV LIBSCRIPT_BUILD_DIR='/libscript_build'
ENV LIBSCRIPT_DATA_DIR='/libscript_data'


COPY . /scripts
WORKDIR /scripts

###########################
# Toolchain(s) [required] #
###########################
ARG RUST_INSTALL_DIR=1
ARG RUST_VERSION='nightly'

RUN <<-EOF

if [ "${RUST_INSTALL_DIR:-1}" -eq 1 ]; then
  if [ "${RUST_DEST-}" ]; then
    previous_wd="$(pwd)"
    DEST="${RUST_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"
    cd -- "${DEST}"
  fi
  if [ "${RUST_VARS-}" ]; then
    export VARS="${RUST_VARS}"
  fi
  if [ "${RUST_COMMANDS_BEFORE-}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'/setup_before_rust.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${RUST_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${RUST_COMMAND_FOLDER:-_lib/_toolchain/rust}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then
    . "${SCRIPT_NAME}";
  else
    >&2 printf 'Not found, SCRIPT_NAME of %s\n' "${SCRIPT_NAME}"
  fi
  if [ "${RUST_DEST-}" ]; then cd -- "${previous_wd}"; fi
fi

EOF


