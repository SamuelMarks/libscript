#!/bin/sh

# shellcheck disable=SC2236
if [ ! -z "${SCRIPT_NAME+x}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ ! -z "${BASH_VERSION+x}" ]; then
  # shellcheck disable=SC3028 disable=SC3054
  this_file="${BASH_SOURCE[0]}"
  # shellcheck disable=SC3040
  set -o pipefail
elif [ ! -z "${ZSH_VERSION+x}" ]; then
  # shellcheck disable=SC2296
  this_file="${(%):-%x}"
  # shellcheck disable=SC3040
  set -o pipefail
else
  this_file="${0}"
fi
set -feu

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$( CDPATH='' cd -- "$( dirname -- "$( readlink -nf -- "${this_file}" )")" && pwd)}"
export LIBSCRIPT_ROOT_DIR

STACK="${STACK:-:}${this_file}"':'
export STACK

LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"
export LIBSCRIPT_DATA_DIR


###########################
# Toolchain(s) [required] #
###########################
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

if [ "${RUST_INSTALL_DIR:-1}" -eq 1 ]; then
  if [ ! -z "${RUST_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${RUST_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p "${DEST}"
    cd "${DEST}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${RUST_COMMAND_FOLDER:-_lib/_toolchain}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then . "${SCRIPT_NAME}"; fi
  if [ ! -z "${RUST_COMMANDS+x}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"'/setup_rust.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${RUST_COMMANDS}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  if [ ! -z "${RUST_DEST+x}" ]; then cd "${previous_wd}"; fi
fi

##########################
# Database(s) [required] #
##########################
if [ "${POSTGRES_URL:-1}" -eq 1 ]; then
  if [ ! -z "${POSTGRES_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${POSTGRES_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p "${DEST}"
    cd "${DEST}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${POSTGRES_COMMAND_FOLDER:-_lib/_storage}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then . "${SCRIPT_NAME}"; fi
  if [ ! -z "${POSTGRES_COMMANDS+x}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"'/setup_postgres.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${POSTGRES_COMMANDS}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  if [ ! -z "${POSTGRES_DEST+x}" ]; then cd "${previous_wd}"; fi
fi

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

########################
# Server(s) [required] #
########################
if [ "${SADAS:-1}" -eq 1 ]; then
  if [ ! -z "${SADAS_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${SADAS_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p "${DEST}"
    cd "${DEST}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${SADAS_COMMAND_FOLDER:-app/third_party}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then . "${SCRIPT_NAME}"; fi
  if [ ! -z "${SADAS_COMMANDS+x}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"'/setup_sadas.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${SADAS_COMMANDS}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  if [ ! -z "${SADAS_DEST+x}" ]; then cd "${previous_wd}"; fi
fi

##########################
# Database(s) [optional] #
##########################
if [ "${AMQP_URL:-0}" -eq 1 ]; then
  if [ ! -z "${RABBITMQ_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${RABBITMQ_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p "${DEST}"
    cd "${DEST}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${RABBITMQ_COMMAND_FOLDER:-_lib/_storage}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then . "${SCRIPT_NAME}"; fi
  if [ ! -z "${RABBITMQ_COMMANDS+x}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"'/setup_rabbitmq.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${RABBITMQ_COMMANDS}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  if [ ! -z "${RABBITMQ_DEST+x}" ]; then cd "${previous_wd}"; fi
fi

########################
# Server(s) [required] #
########################
if [ "${JUPYTERHUB:-0}" -eq 1 ]; then
  if [ ! -z "${JUPYTERHUB_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${JUPYTERHUB_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p "${DEST}"
    cd "${DEST}"
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${JUPYTERHUB_COMMAND_FOLDER:-app/third_party}"'/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  if [ -f "${SCRIPT_NAME}" ]; then . "${SCRIPT_NAME}"; fi
  if [ ! -z "${JUPYTERHUB_COMMANDS+x}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"'/setup_jupyterhub.sh'
    export SCRIPT_NAME
    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
    printf '%s' "${JUPYTERHUB_COMMANDS}" >> "${SCRIPT_NAME}"
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
  if [ ! -z "${JUPYTERHUB_DEST+x}" ]; then cd "${previous_wd}"; fi
fi

##############
# WWWROOT(s) #
##############
if [ "${WWWROOT_example_com_INSTALL:-0}" -eq 1 ]; then
  if [ ! -z "${EXAMPLE_COM_DEST+x}" ]; then
    previous_wd="$(pwd)"
    DEST="${EXAMPLE_COM_DEST}"
    export DEST
    [ -d "${DEST}" ] || mkdir -p "${DEST}"
    cd "${DEST}"
  fi
  export WWWROOT_NAME="${WWWROOT_example_com_NAME:-example.com}"
  export WWWROOT_VENDOR="${WWWROOT_example_com_VENDOR:-nginx}"
  export WWWROOT_PATH="${WWWROOT_example_com_PATH:-./my_symlinked_wwwroot}"
  export WWWROOT_LISTEN="${80:-WWWROOT_example_com_LISTEN}"
  export WWWROOT_HTTPS_PROVIDER="${WWWROOT_example_com_HTTPS_PROVIDER:-letsencrypt}"
  export WWWROOT_COMMAND_FOLDER="${WWWROOT_example_com_COMMAND_FOLDER:-}"
  export WWWROOT_COMMANDS="${WWWROOT_example_com_COMMANDS:-}"
  if [ "${WWWROOT_VENDOR:-nginx}" = 'nginx' ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${WWWROOT_COMMAND_FOLDER:-_server/nginx}"'/setup.sh'
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    if [ -f "${SCRIPT_NAME}" ]; then . "${SCRIPT_NAME}"; fi
    if [ ! -z "${WWWROOT_COMMANDS+x}" ]; then
      SCRIPT_NAME="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"'/setup_example_com.sh'
      export SCRIPT_NAME
      install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${SCRIPT_NAME}"
      printf '%s' "${WWWROOT_COMMANDS}" >> "${SCRIPT_NAME}"
      # shellcheck disable=SC1090
      . "${SCRIPT_NAME}"
    fi
  fi
fi
