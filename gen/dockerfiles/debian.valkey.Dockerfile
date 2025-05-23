FROM debian:bookworm-slim

ENV LC_ALL=C.UTF-8 LANG=C.UTF-8

ENV LIBSCRIPT_ROOT_DIR='/scripts'
ENV LIBSCRIPT_BUILD_DIR='/libscript_build'
ENV LIBSCRIPT_DATA_DIR='/libscript_data'


COPY . /scripts
WORKDIR /scripts


ARG REDIS_URL=1
ARG VALKEY_VERSION='*'

RUN <<-EOF

if [ "${REDIS_URL:-1}" -eq 1 ]; then
  if [ "${VALKEY_DEST-}" ]; then
    previous_wd="$(pwd)"
    DEST="${VALKEY_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"
    cd -- "${DEST}"
  fi
  if [ "${VALKEY_VARS-}" ]; then
    export VARS="${VALKEY_VARS}"
  fi
  if [ "${VALKEY_COMMANDS_BEFORE-}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'/setup_before_valkey.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${VALKEY_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${VALKEY_COMMAND_FOLDER:-_lib/_storage/valkey}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then
    . "${SCRIPT_NAME}";
  else
    >&2 printf 'Not found, SCRIPT_NAME of %s\n' "${SCRIPT_NAME}"
  fi
  if [ "${VALKEY_DEST-}" ]; then cd -- "${previous_wd}"; fi
fi

EOF


