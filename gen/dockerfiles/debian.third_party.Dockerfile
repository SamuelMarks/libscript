FROM debian:bookworm-slim

ENV LIBSCRIPT_ROOT_DIR='/scripts'
ENV LIBSCRIPT_BUILD_DIR='/libscript_build'
ENV LIBSCRIPT_DATA_DIR='/libscript_data'


COPY . /scripts
WORKDIR /scripts

########################
# Server(s) [required] #
########################
ARG SADAS=1

ARG SADAS_COMMANDS_BEFORE='git_get https://github.com/SamuelMarks/serve-actix-diesel-auth-scaffold "${SADAS_DEST}"'
ARG SADAS_COMMAND_FOLDER='_lib/_server/rust'
ARG SADAS_DEST='/tmp/serve-actix-diesel-auth-scaffold'

RUN <<-EOF

if [ "${SADAS:-1}" -eq 1 ]; then
  if [ ! -z "${SADAS_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${SADAS_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p "${DEST}"
    cd "${DEST}"
  fi
  if [ ! -z "${SADAS_VARS+x}" ]; then
    export VARS="${SADAS_VARS}"
  fi
  if [ ! -z "${SADAS_COMMANDS_BEFORE+x}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'/setup_before_sadas.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${SADAS_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${SADAS_COMMAND_FOLDER:-app/third_party/sadas}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then
    . "${SCRIPT_NAME}";
  else
    >&2 printf 'Not found, SCRIPT_NAME of %s\n' "${SCRIPT_NAME}"
  fi
  if [ ! -z "${SADAS_DEST+x}" ]; then cd "${previous_wd}"; fi
fi

EOF


ARG NODEJS_HTTP_SERVER=1

ARG nodejs_http_server_COMMANDS_BEFORE='git_get https://github.com/mohammadhasanii/Node-HTTP3 "${NODEJS_HTTP_SERVER_DEST}"'
ARG nodejs_http_server_COMMAND_FOLDER='_lib/_server/nodejs'
ARG NODEJS_HTTP_SERVER_DEST='/tmp/nodejs-http-server'

RUN <<-EOF

if [ "${NODEJS_HTTP_SERVER:-1}" -eq 1 ]; then
  if [ ! -z "${NODEJS_HTTP_SERVER_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${NODEJS_HTTP_SERVER_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p "${DEST}"
    cd "${DEST}"
  fi
  if [ ! -z "${NODEJS_HTTP_SERVER_VARS+x}" ]; then
    export VARS="${NODEJS_HTTP_SERVER_VARS}"
  fi
  if [ ! -z "${nodejs_http_server_COMMANDS_BEFORE+x}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'/setup_before_nodejs-http-server.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${nodejs_http_server_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${nodejs_http_server_COMMAND_FOLDER:-app/third_party/nodejs-http-server}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then
    . "${SCRIPT_NAME}";
  else
    >&2 printf 'Not found, SCRIPT_NAME of %s\n' "${SCRIPT_NAME}"
  fi
  if [ ! -z "${NODEJS_HTTP_SERVER_DEST+x}" ]; then cd "${previous_wd}"; fi
fi

EOF


ARG PYTHON_SERVER=1

ARG python_server_COMMANDS_BEFORE='git_get https://github.com/digitalocean/sample-python "${PYTHON_SERVER_DEST}" \
if [ ! -f "venv-3-12/bin/python" ]; then \
  uv venv --python 3.12 venv-3-12 \
  venv-3-12/bin/python -m ensurepip \
  venv-3-12/bin/python -m pip install -r requirements.txt \
fi'
ARG python_server_COMMAND_FOLDER='_lib/_server/python'
ARG PYTHON_SERVER_DEST='/tmp/python-server'

RUN <<-EOF

if [ "${PYTHON_SERVER:-1}" -eq 1 ]; then
  if [ ! -z "${PYTHON_SERVER_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${PYTHON_SERVER_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p "${DEST}"
    cd "${DEST}"
  fi
  if [ ! -z "${PYTHON_SERVER_VARS+x}" ]; then
    export VARS="${PYTHON_SERVER_VARS}"
  fi
  if [ ! -z "${python_server_COMMANDS_BEFORE+x}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'/setup_before_python-server.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${python_server_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${python_server_COMMAND_FOLDER:-app/third_party/python-server}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then
    . "${SCRIPT_NAME}";
  else
    >&2 printf 'Not found, SCRIPT_NAME of %s\n' "${SCRIPT_NAME}"
  fi
  if [ ! -z "${PYTHON_SERVER_DEST+x}" ]; then cd "${previous_wd}"; fi
fi

EOF


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


ARG NGINX_CONFIG_BUILDER__FRONTEND=1

ARG nginx_config_builder__frontend_COMMAND_FOLDER='_lib/_server/nginx'
ARG NGINX_CONFIG_BUILDER__FRONTEND_VARS='{"SERVER_NAME":"example.com","WWWROOT":"\"${LIBSCRIPT_BUILD_DIR}\"/ng-material-scaffold","HTTPS_ALWAYS":1,"HTTPS_VENDOR":"letsencrypt"}'

RUN <<-EOF

if [ "${NGINX_CONFIG_BUILDER__FRONTEND:-1}" -eq 1 ]; then
  if [ ! -z "${NGINX_CONFIG_BUILDER__FRONTEND_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${NGINX_CONFIG_BUILDER__FRONTEND_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p "${DEST}"
    cd "${DEST}"
  fi
  if [ ! -z "${NGINX_CONFIG_BUILDER__FRONTEND_VARS+x}" ]; then
    export VARS="${NGINX_CONFIG_BUILDER__FRONTEND_VARS}"
  fi
  if [ ! -z "${nginx_config_builder__frontend_COMMANDS_BEFORE+x}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'/setup_before_nginx-config-builder__frontend.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${nginx_config_builder__frontend_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${nginx_config_builder__frontend_COMMAND_FOLDER:-app/third_party/nginx-config-builder__frontend}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then
    . "${SCRIPT_NAME}";
  else
    >&2 printf 'Not found, SCRIPT_NAME of %s\n' "${SCRIPT_NAME}"
  fi
  if [ ! -z "${NGINX_CONFIG_BUILDER__FRONTEND_DEST+x}" ]; then cd "${previous_wd}"; fi
fi

EOF


ARG NGINX_CONFIG_BUILDER__DOCS=1

ARG nginx_config_builder__docs_COMMAND_FOLDER='_lib/_server/nginx'
ARG NGINX_CONFIG_BUILDER__DOCS_VARS='{"SERVER_NAME":"example.com","LOCATION_EXPR":"~* /(api|redoc|rapidoc|scalar|secured)","HTTPS_ALWAYS":1,"HTTPS_VENDOR":"letsencrypt","PROXY_PASS":"http://localhost:3000"}'

RUN <<-EOF

if [ "${NGINX_CONFIG_BUILDER__DOCS:-1}" -eq 1 ]; then
  if [ ! -z "${NGINX_CONFIG_BUILDER__DOCS_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${NGINX_CONFIG_BUILDER__DOCS_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p "${DEST}"
    cd "${DEST}"
  fi
  if [ ! -z "${NGINX_CONFIG_BUILDER__DOCS_VARS+x}" ]; then
    export VARS="${NGINX_CONFIG_BUILDER__DOCS_VARS}"
  fi
  if [ ! -z "${nginx_config_builder__docs_COMMANDS_BEFORE+x}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'/setup_before_nginx-config-builder__docs.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${nginx_config_builder__docs_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${nginx_config_builder__docs_COMMAND_FOLDER:-app/third_party/nginx-config-builder__docs}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then
    . "${SCRIPT_NAME}";
  else
    >&2 printf 'Not found, SCRIPT_NAME of %s\n' "${SCRIPT_NAME}"
  fi
  if [ ! -z "${NGINX_CONFIG_BUILDER__DOCS_DEST+x}" ]; then cd "${previous_wd}"; fi
fi

EOF


ARG NGINX_CONFIG_BUILDER__CRAWL=1

ARG nginx_config_builder__crawl_COMMAND_FOLDER='_lib/_server/nginx'
ARG NGINX_CONFIG_BUILDER__CRAWL_VARS='{"SERVER_NAME":"example.com","LOCATION_EXPR":"/v1/crawl","HTTPS_ALWAYS":1,"HTTPS_VENDOR":"letsencrypt","PROXY_PASS":"http://localhost:3002"}'

RUN <<-EOF

if [ "${NGINX_CONFIG_BUILDER__CRAWL:-1}" -eq 1 ]; then
  if [ ! -z "${NGINX_CONFIG_BUILDER__CRAWL_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${NGINX_CONFIG_BUILDER__CRAWL_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p "${DEST}"
    cd "${DEST}"
  fi
  if [ ! -z "${NGINX_CONFIG_BUILDER__CRAWL_VARS+x}" ]; then
    export VARS="${NGINX_CONFIG_BUILDER__CRAWL_VARS}"
  fi
  if [ ! -z "${nginx_config_builder__crawl_COMMANDS_BEFORE+x}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'/setup_before_nginx-config-builder__crawl.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${nginx_config_builder__crawl_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${nginx_config_builder__crawl_COMMAND_FOLDER:-app/third_party/nginx-config-builder__crawl}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then
    . "${SCRIPT_NAME}";
  else
    >&2 printf 'Not found, SCRIPT_NAME of %s\n' "${SCRIPT_NAME}"
  fi
  if [ ! -z "${NGINX_CONFIG_BUILDER__CRAWL_DEST+x}" ]; then cd "${previous_wd}"; fi
fi

EOF


ARG NGINX_CONFIG_BUILDER__SWAP=1

ARG nginx_config_builder__swap_COMMAND_FOLDER='_lib/_server/nginx'
ARG NGINX_CONFIG_BUILDER__SWAP_VARS='{"SERVER_NAME":"example.com","LOCATION_EXPR":"/v1/swap","HTTPS_ALWAYS":1,"HTTPS_VENDOR":"letsencrypt","PROXY_WEBSOCKETS":1,"PROXY_PASS":"http://localhost:3003"}'

RUN <<-EOF

if [ "${NGINX_CONFIG_BUILDER__SWAP:-1}" -eq 1 ]; then
  if [ ! -z "${NGINX_CONFIG_BUILDER__SWAP_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${NGINX_CONFIG_BUILDER__SWAP_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p "${DEST}"
    cd "${DEST}"
  fi
  if [ ! -z "${NGINX_CONFIG_BUILDER__SWAP_VARS+x}" ]; then
    export VARS="${NGINX_CONFIG_BUILDER__SWAP_VARS}"
  fi
  if [ ! -z "${nginx_config_builder__swap_COMMANDS_BEFORE+x}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'/setup_before_nginx-config-builder__swap.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${nginx_config_builder__swap_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${nginx_config_builder__swap_COMMAND_FOLDER:-app/third_party/nginx-config-builder__swap}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then
    . "${SCRIPT_NAME}";
  else
    >&2 printf 'Not found, SCRIPT_NAME of %s\n' "${SCRIPT_NAME}"
  fi
  if [ ! -z "${NGINX_CONFIG_BUILDER__SWAP_DEST+x}" ]; then cd "${previous_wd}"; fi
fi

EOF


ARG NGINX_CONFIG_BUILDER__DATA=1

ARG nginx_config_builder__data_COMMAND_FOLDER='_lib/_server/nginx'
ARG NGINX_CONFIG_BUILDER__DATA_VARS='{"SERVER_NAME":"example.com","LOCATION_EXPR":"/data","HTTPS_ALWAYS":1,"HTTPS_VENDOR":"letsencrypt","WWWROOT":"/opt/repos/E4S2024","PROXY_PASS":"http://localhost:3003"}'

RUN <<-EOF

if [ "${NGINX_CONFIG_BUILDER__DATA:-1}" -eq 1 ]; then
  if [ ! -z "${NGINX_CONFIG_BUILDER__DATA_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${NGINX_CONFIG_BUILDER__DATA_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p "${DEST}"
    cd "${DEST}"
  fi
  if [ ! -z "${NGINX_CONFIG_BUILDER__DATA_VARS+x}" ]; then
    export VARS="${NGINX_CONFIG_BUILDER__DATA_VARS}"
  fi
  if [ ! -z "${nginx_config_builder__data_COMMANDS_BEFORE+x}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'/setup_before_nginx-config-builder__data.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${nginx_config_builder__data_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${nginx_config_builder__data_COMMAND_FOLDER:-app/third_party/nginx-config-builder__data}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then
    . "${SCRIPT_NAME}";
  else
    >&2 printf 'Not found, SCRIPT_NAME of %s\n' "${SCRIPT_NAME}"
  fi
  if [ ! -z "${NGINX_CONFIG_BUILDER__DATA_DEST+x}" ]; then cd "${previous_wd}"; fi
fi

EOF


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
  if [ ! -z "${JUPYTERHUB_VARS+x}" ]; then
    export VARS="${JUPYTERHUB_VARS}"
  fi
  if [ ! -z "${JupyterHub_COMMANDS_BEFORE+x}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'/setup_before_jupyterhub.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${JupyterHub_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${JupyterHub_COMMAND_FOLDER:-app/third_party/jupyterhub}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then
    . "${SCRIPT_NAME}";
  else
    >&2 printf 'Not found, SCRIPT_NAME of %s\n' "${SCRIPT_NAME}"
  fi
  if [ ! -z "${JUPYTERHUB_DEST+x}" ]; then cd "${previous_wd}"; fi
fi

EOF


