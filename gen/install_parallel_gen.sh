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

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)

###########################
# Toolchain(s) [required] #
###########################
SCRIPT_NAME="${DIR}"'/false_env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

(
  export NODEJS_INSTALL_DIR=1
export NODEJS_VERSION='lts'
SCRIPT_NAME="${DIR}"'/install_gen.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}" ) &

(
  export PYTHON_INSTALL_DIR=1
export PYTHON_VERSION='3.10'
SCRIPT_NAME="${DIR}"'/install_gen.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}" ) &

(
  export RUST_INSTALL_DIR=1
export RUST_VERSION='nightly'
SCRIPT_NAME="${DIR}"'/install_gen.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}" ) &

wait

##########################
# Database(s) [required] #
##########################
SCRIPT_NAME="${DIR}"'/false_env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

(
  export POSTGRES_URL=1
export POSTGRES_USER='rest_user'
export POSTGRES_PASSWORD='rest_pass'
export POSTGRES_DB='rest_db'
export POSTGRES_PASSWORD_FILE
export POSTGRES_VERSION=17
SCRIPT_NAME="${DIR}"'/install_gen.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}" ) &

(
  export REDIS_URL=1
export VALKEY_VERSION='*'
SCRIPT_NAME="${DIR}"'/install_gen.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}" ) &

wait

########################
# Server(s) [required] #
########################
SCRIPT_NAME="${DIR}"'/false_env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

(
  export SADAS=1
export SADAS_COMMANDS_BEFORE='git_get https://github.com/SamuelMarks/serve-actix-diesel-auth-scaffold "${SADAS_DEST}"'
export SADAS_COMMAND_FOLDER='_lib/_server/rust'
export SADAS_DEST='/tmp/serve-actix-diesel-auth-scaffold'
SCRIPT_NAME="${DIR}"'/install_gen.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}" ) &

########################
# Server(s) [optional] #
########################
(
  export NODEJS_HTTP_SERVER=1
export nodejs_http_server_COMMANDS_BEFORE='git_get https://github.com/mohammadhasanii/Node-HTTP3 "${NODEJS_HTTP_SERVER_DEST}"'
export nodejs_http_server_COMMAND_FOLDER='_lib/_server/nodejs'
export NODEJS_HTTP_SERVER_DEST='/tmp/nodejs-http-server'
SCRIPT_NAME="${DIR}"'/install_gen.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}" ) &

########################
# Server(s) [optional] #
########################
(
  export PYTHON_SERVER=1
export python_server_COMMANDS_BEFORE='git_get https://github.com/digitalocean/sample-python "${PYTHON_SERVER_DEST}"
uv venv --python 3.12 venv-3-12
venv-3-12/bin/python -m ensurepip
venv-3-12/bin/python -m pip install -r requirements.txt'
export python_server_COMMAND_FOLDER='_lib/_server/python'
export PYTHON_SERVER_DEST='/tmp/python-server'
SCRIPT_NAME="${DIR}"'/install_gen.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}" ) &

########################
# Server(s) [optional] #
########################
(
  export BUILD_STATIC_FILES0=1
export build_static_files0_COMMANDS_BEFORE='git_get https://github.com/SamuelMarks/ng-material-scaffold "${BUILD_STATIC_FILES0_DEST}" &&
npm i -g npm && npm i -g @angular/cli &&
npm i &&
ng build --configuration production &&
echo install -d -D "${BUILD_STATIC_FILES0_DEST}"/dist/ng-material-scaffold/browser "${LIBSCRIPT_BUILD_DIR}"/ng-material-scaffold &&
install -d -D "${BUILD_STATIC_FILES0_DEST}"/dist/ng-material-scaffold/browser "${LIBSCRIPT_BUILD_DIR}"/ng-material-scaffold &&
echo GOT HERE &&
echo GOT FURTHER FURTHER HERE'
export build_static_files0_COMMAND_FOLDER='_lib/_common/_noop'
export BUILD_STATIC_FILES0_DEST='/tmp/ng-material-scaffold'
SCRIPT_NAME="${DIR}"'/install_gen.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}" ) &

########################
# Server(s) [optional] #
########################
(
  export NGINX_CONFIG_BUILDER=1
export nginx_config_builder_COMMAND_FOLDER='_lib/_server/nginx'
export NGINX_CONFIG_BUILDER_VARS='{"SERVER_NAME":"example.com","WWWROOT":"\"${LIBSCRIPT_BUILD_DIR}\"/ng-material-scaffold","HTTPS_ALWAYS":1,"HTTPS_VENDOR":"letsencrypt"}'
SCRIPT_NAME="${DIR}"'/install_gen.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}" ) &

##########################
# Database(s) [optional] #
##########################
SCRIPT_NAME="${DIR}"'/false_env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

(
  export AMQP_URL=0
export RABBITMQ_VERSION='*'
SCRIPT_NAME="${DIR}"'/install_gen.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}" ) &

wait

########################
# Server(s) [required] #
########################
SCRIPT_NAME="${DIR}"'/false_env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

(
  export JUPYTERHUB=0
SCRIPT_NAME="${DIR}"'/install_gen.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}" ) &

