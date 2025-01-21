FROM debian:bookworm-slim

ENV LIBSCRIPT_ROOT_DIR='/scripts'


COPY . /scripts
WORKDIR /scripts


ARG REDIS_URL=1
ARG VALKEY_VERSION='*'

RUN <<-EOF

if [ "${REDIS_URL:-1}" -eq 1 ]; then
  if [ ! -z "${VALKEY_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${VALKEY_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p "${DEST}"
    cd "${DEST}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${VALKEY_COMMAND_FOLDER:-_lib/_storage}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then . "${SCRIPT_NAME}"; fi
  if [ ! -z "${VALKEY_COMMANDS+x}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"'/setup_valkey.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${VALKEY_COMMANDS}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  if [ ! -z "${VALKEY_DEST+x}" ]; then cd "${previous_wd}"; fi
fi

EOF


