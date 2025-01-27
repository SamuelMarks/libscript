FROM alpine:latest

ENV LIBSCRIPT_ROOT_DIR='/scripts'
ENV LIBSCRIPT_BUILD_DIR='/libscript_build'
ENV LIBSCRIPT_DATA_DIR='/libscript_data'


COPY . /scripts
WORKDIR /scripts

########################
# Server(s) [optional] #
########################
ARG NGINX_CONFIG_BUILDER__CRAWL=1

ARG nginx_config_builder__crawl_COMMAND_FOLDER='_lib/_server/nginx'
ARG NGINX_CONFIG_BUILDER__CRAWL_VARS='{"SERVER_NAME":"example.com","LOCATION_EXPR":"/v1/crawl","HTTPS_ALWAYS":1,"HTTPS_VENDOR":"letsencrypt","PROXY_PASS":"http://localhost:3002"}'

RUN <<-EOF

if [ "${NGINX_CONFIG_BUILDER__CRAWL:-1}" -eq 1 ]; then
  if [ ! -z "${NGINX_CONFIG_BUILDER__CRAWL_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${NGINX_CONFIG_BUILDER__CRAWL_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"
    cd -- "${DEST}"
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
  if [ ! -z "${NGINX_CONFIG_BUILDER__CRAWL_DEST+x}" ]; then cd -- "${previous_wd}"; fi
fi

EOF


