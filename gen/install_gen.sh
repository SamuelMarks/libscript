#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE+x}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION+x}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'

STACK="${STACK:-:}${this_file}"':'
export STACK

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$( CDPATH='' cd -- "$( dirname -- "$( readlink -nf -- "${this_file}" )")" && pwd)}"
export LIBSCRIPT_ROOT_DIR

LIBSCRIPT_BUILD_DIR="${LIBSCRIPT_BUILD_DIR:-${TMPDIR:-/tmp}/libscript_build}"
export LIBSCRIPT_BUILD_DIR

LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"
export LIBSCRIPT_DATA_DIR

PATH="${HOME}"'/.cargo/bin:'"${HOME}"'/.local/share/fnm/aliases/default/bin:'"${LIBSCRIPT_DATA_DIR}"'/bin:'"${PATH}"
export PATH

[ -d "${LIBSCRIPT_BUILD_DIR}" ] || mkdir -p -- "${LIBSCRIPT_BUILD_DIR}"
[ -d "${LIBSCRIPT_DATA_DIR}" ] || mkdir -p -- "${LIBSCRIPT_DATA_DIR}"


###########################
# Toolchain(s) [required] #
###########################
if [ "${NODEJS_INSTALL_DIR:-1}" -eq 1 ]; then
  if [ "${NODEJS_DEST-}" ]; then
    previous_wd="$(pwd)"
    DEST="${NODEJS_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"
    cd -- "${DEST}"
  fi
  if [ "${NODEJS_VARS-}" ]; then
    export VARS="${NODEJS_VARS}"
  fi
  if [ "${NODEJS_COMMANDS_BEFORE-}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'/setup_before_nodejs.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${NODEJS_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${NODEJS_COMMAND_FOLDER:-_lib/_toolchain/nodejs}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then
    . "${SCRIPT_NAME}";
  else
    >&2 printf 'Not found, SCRIPT_NAME of %s\n' "${SCRIPT_NAME}"
  fi
  if [ "${NODEJS_DEST-}" ]; then cd -- "${previous_wd}"; fi
fi

if [ "${PYTHON_INSTALL_DIR:-1}" -eq 1 ]; then
  if [ "${PYTHON_DEST-}" ]; then
    previous_wd="$(pwd)"
    DEST="${PYTHON_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"
    cd -- "${DEST}"
  fi
  if [ "${PYTHON_VARS-}" ]; then
    export VARS="${PYTHON_VARS}"
  fi
  if [ "${PYTHON_COMMANDS_BEFORE-}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'/setup_before_python.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${PYTHON_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${PYTHON_COMMAND_FOLDER:-_lib/_toolchain/python}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then
    . "${SCRIPT_NAME}";
  else
    >&2 printf 'Not found, SCRIPT_NAME of %s\n' "${SCRIPT_NAME}"
  fi
  if [ "${PYTHON_DEST-}" ]; then cd -- "${previous_wd}"; fi
fi

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

##########################
# Database(s) [required] #
##########################
if [ "${POSTGRES_URL:-1}" -eq 1 ]; then
  if [ "${POSTGRES_DEST-}" ]; then
    previous_wd="$(pwd)"
    DEST="${POSTGRES_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"
    cd -- "${DEST}"
  fi
  if [ "${POSTGRES_VARS-}" ]; then
    export VARS="${POSTGRES_VARS}"
  fi
  if [ "${POSTGRES_COMMANDS_BEFORE-}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'/setup_before_postgres.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${POSTGRES_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${POSTGRES_COMMAND_FOLDER:-_lib/_storage/postgres}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then
    . "${SCRIPT_NAME}";
  else
    >&2 printf 'Not found, SCRIPT_NAME of %s\n' "${SCRIPT_NAME}"
  fi
  if [ "${POSTGRES_DEST-}" ]; then cd -- "${previous_wd}"; fi
fi

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

########################
# Server(s) [required] #
########################
if [ "${SADAS:-1}" -eq 1 ]; then
  if [ "${SADAS_DEST-}" ]; then
    previous_wd="$(pwd)"
    DEST="${SADAS_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"
    cd -- "${DEST}"
  fi
  if [ "${SADAS_VARS-}" ]; then
    export VARS="${SADAS_VARS}"
  fi
  if [ "${SADAS_COMMANDS_BEFORE-}" ]; then
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
  if [ "${SADAS_DEST-}" ]; then cd -- "${previous_wd}"; fi
fi

########################
# Server(s) [optional] #
########################
if [ "${NODEJS_HTTP_SERVER:-1}" -eq 1 ]; then
  if [ "${NODEJS_HTTP_SERVER_DEST-}" ]; then
    previous_wd="$(pwd)"
    DEST="${NODEJS_HTTP_SERVER_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"
    cd -- "${DEST}"
  fi
  if [ "${NODEJS_HTTP_SERVER_VARS-}" ]; then
    export VARS="${NODEJS_HTTP_SERVER_VARS}"
  fi
  if [ "${nodejs_http_server_COMMANDS_BEFORE-}" ]; then
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
  if [ "${NODEJS_HTTP_SERVER_DEST-}" ]; then cd -- "${previous_wd}"; fi
fi

########################
# Server(s) [optional] #
########################
if [ "${PYTHON_SERVER:-1}" -eq 1 ]; then
  if [ "${PYTHON_SERVER_DEST-}" ]; then
    previous_wd="$(pwd)"
    DEST="${PYTHON_SERVER_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"
    cd -- "${DEST}"
  fi
  if [ "${PYTHON_SERVER_VARS-}" ]; then
    export VARS="${PYTHON_SERVER_VARS}"
  fi
  if [ "${python_server_COMMANDS_BEFORE-}" ]; then
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
  if [ "${PYTHON_SERVER_DEST-}" ]; then cd -- "${previous_wd}"; fi
fi

########################
# Server(s) [optional] #
########################
if [ "${BUILD_STATIC_FILES0:-1}" -eq 1 ]; then
  if [ "${BUILD_STATIC_FILES0_DEST-}" ]; then
    previous_wd="$(pwd)"
    DEST="${BUILD_STATIC_FILES0_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"
    cd -- "${DEST}"
  fi
  if [ "${BUILD_STATIC_FILES0_VARS-}" ]; then
    export VARS="${BUILD_STATIC_FILES0_VARS}"
  fi
  if [ "${build_static_files0_COMMANDS_BEFORE-}" ]; then
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
  if [ "${BUILD_STATIC_FILES0_DEST-}" ]; then cd -- "${previous_wd}"; fi
fi

########################
# Server(s) [optional] #
########################
if [ "${NGINX_CONFIG_BUILDER__FRONTEND:-1}" -eq 1 ]; then
  if [ "${NGINX_CONFIG_BUILDER__FRONTEND_DEST-}" ]; then
    previous_wd="$(pwd)"
    DEST="${NGINX_CONFIG_BUILDER__FRONTEND_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"
    cd -- "${DEST}"
  fi
  if [ "${NGINX_CONFIG_BUILDER__FRONTEND_VARS-}" ]; then
    export VARS="${NGINX_CONFIG_BUILDER__FRONTEND_VARS}"
  fi
  if [ "${nginx_config_builder__frontend_COMMANDS_BEFORE-}" ]; then
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
  if [ "${NGINX_CONFIG_BUILDER__FRONTEND_DEST-}" ]; then cd -- "${previous_wd}"; fi
fi

########################
# Server(s) [optional] #
########################
if [ "${NGINX_CONFIG_BUILDER__DOCS:-1}" -eq 1 ]; then
  if [ "${NGINX_CONFIG_BUILDER__DOCS_DEST-}" ]; then
    previous_wd="$(pwd)"
    DEST="${NGINX_CONFIG_BUILDER__DOCS_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"
    cd -- "${DEST}"
  fi
  if [ "${NGINX_CONFIG_BUILDER__DOCS_VARS-}" ]; then
    export VARS="${NGINX_CONFIG_BUILDER__DOCS_VARS}"
  fi
  if [ "${nginx_config_builder__docs_COMMANDS_BEFORE-}" ]; then
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
  if [ "${NGINX_CONFIG_BUILDER__DOCS_DEST-}" ]; then cd -- "${previous_wd}"; fi
fi

########################
# Server(s) [optional] #
########################
if [ "${NGINX_CONFIG_BUILDER__CRAWL:-1}" -eq 1 ]; then
  if [ "${NGINX_CONFIG_BUILDER__CRAWL_DEST-}" ]; then
    previous_wd="$(pwd)"
    DEST="${NGINX_CONFIG_BUILDER__CRAWL_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"
    cd -- "${DEST}"
  fi
  if [ "${NGINX_CONFIG_BUILDER__CRAWL_VARS-}" ]; then
    export VARS="${NGINX_CONFIG_BUILDER__CRAWL_VARS}"
  fi
  if [ "${nginx_config_builder__crawl_COMMANDS_BEFORE-}" ]; then
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
  if [ "${NGINX_CONFIG_BUILDER__CRAWL_DEST-}" ]; then cd -- "${previous_wd}"; fi
fi

########################
# Server(s) [optional] #
########################
if [ "${NGINX_CONFIG_BUILDER__SWAP:-1}" -eq 1 ]; then
  if [ "${NGINX_CONFIG_BUILDER__SWAP_DEST-}" ]; then
    previous_wd="$(pwd)"
    DEST="${NGINX_CONFIG_BUILDER__SWAP_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"
    cd -- "${DEST}"
  fi
  if [ "${NGINX_CONFIG_BUILDER__SWAP_VARS-}" ]; then
    export VARS="${NGINX_CONFIG_BUILDER__SWAP_VARS}"
  fi
  if [ "${nginx_config_builder__swap_COMMANDS_BEFORE-}" ]; then
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
  if [ "${NGINX_CONFIG_BUILDER__SWAP_DEST-}" ]; then cd -- "${previous_wd}"; fi
fi

########################
# Server(s) [optional] #
########################
if [ "${NGINX_CONFIG_BUILDER__DATA:-1}" -eq 1 ]; then
  if [ "${NGINX_CONFIG_BUILDER__DATA_DEST-}" ]; then
    previous_wd="$(pwd)"
    DEST="${NGINX_CONFIG_BUILDER__DATA_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"
    cd -- "${DEST}"
  fi
  if [ "${NGINX_CONFIG_BUILDER__DATA_VARS-}" ]; then
    export VARS="${NGINX_CONFIG_BUILDER__DATA_VARS}"
  fi
  if [ "${nginx_config_builder__data_COMMANDS_BEFORE-}" ]; then
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
  if [ "${NGINX_CONFIG_BUILDER__DATA_DEST-}" ]; then cd -- "${previous_wd}"; fi
fi

##########################
# Database(s) [optional] #
##########################
if [ "${AMQP_URL:-0}" -eq 1 ]; then
  if [ "${RABBITMQ_DEST-}" ]; then
    previous_wd="$(pwd)"
    DEST="${RABBITMQ_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"
    cd -- "${DEST}"
  fi
  if [ "${RABBITMQ_VARS-}" ]; then
    export VARS="${RABBITMQ_VARS}"
  fi
  if [ "${RABBITMQ_COMMANDS_BEFORE-}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'/setup_before_rabbitmq.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${RABBITMQ_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${RABBITMQ_COMMAND_FOLDER:-_lib/_storage/rabbitmq}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then
    . "${SCRIPT_NAME}";
  else
    >&2 printf 'Not found, SCRIPT_NAME of %s\n' "${SCRIPT_NAME}"
  fi
  if [ "${RABBITMQ_DEST-}" ]; then cd -- "${previous_wd}"; fi
fi

########################
# Server(s) [required] #
########################
if [ "${JUPYTERHUB:-0}" -eq 1 ]; then
  if [ "${JUPYTERHUB_DEST-}" ]; then
    previous_wd="$(pwd)"
    DEST="${JUPYTERHUB_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"
    cd -- "${DEST}"
  fi
  if [ "${JUPYTERHUB_VARS-}" ]; then
    export VARS="${JUPYTERHUB_VARS}"
  fi
  if [ "${JupyterHub_COMMANDS_BEFORE-}" ]; then
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
  if [ "${JUPYTERHUB_DEST-}" ]; then cd -- "${previous_wd}"; fi
fi

