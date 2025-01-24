FROM alpine:latest

ENV LIBSCRIPT_ROOT_DIR='/scripts'
ENV LIBSCRIPT_BUILD_DIR='/libscript_build'
ENV LIBSCRIPT_DATA_DIR='/libscript_data'


COPY . /scripts
WORKDIR /scripts

########################
# Server(s) [optional] #
########################
ARG BUILD_STATIC_FILES0=1

ARG build_static_files0_COMMANDS_BEFORE='git_get https://github.com/SamuelMarks/ng-material-scaffold "${BUILD_STATIC_FILES0_DEST}" && \
hash=$(git rev-list HEAD -1) \
hash_f=dist/ng-material-scaffold/browser/"${hash}" \
if [ ! -f "${hash_f}" ]; then \
  npm i -g npm && npm i -g @angular/cli && \
  npm i && \
  ng build --configuration production && \
  touch "${hash_f}" \
  install -d -D "${BUILD_STATIC_FILES0_DEST}"/dist/ng-material-scaffold/browser "${LIBSCRIPT_BUILD_DIR}"/ng-material-scaffold \
fi'
ARG build_static_files0_COMMAND_FOLDER='_lib/_common/_noop'
ARG BUILD_STATIC_FILES0_DEST='/tmp/ng-material-scaffold'

RUN <<-EOF

if [ "${BUILD_STATIC_FILES0:-1}" -eq 1 ]; then
  if [ ! -z "${BUILD_STATIC_FILES0_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${BUILD_STATIC_FILES0_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p "${DEST}"
    cd "${DEST}"
  fi
  if [ ! -z "${BUILD_STATIC_FILES0_VARS+x}" ]; then
    export VARS="${BUILD_STATIC_FILES0_VARS}"
  fi
  if [ ! -z "${build_static_files0_COMMANDS_BEFORE+x}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'/setup_before_build-static-files0.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${build_static_files0_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${build_static_files0_COMMAND_FOLDER:-app/third_party/build-static-files0}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then
    . "${SCRIPT_NAME}";
  else
    >&2 printf 'Not found, SCRIPT_NAME of %s\n' "${SCRIPT_NAME}"
  fi
  if [ ! -z "${BUILD_STATIC_FILES0_DEST+x}" ]; then cd "${previous_wd}"; fi
fi

EOF


