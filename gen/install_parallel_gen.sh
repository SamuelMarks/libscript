#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
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
export POSTGRES_HOST='localhost'
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
if [ ! -f "venv-3-12/bin/python" ]; then
  uv venv --python 3.12 venv-3-12
  venv-3-12/bin/python -m ensurepip
  venv-3-12/bin/python -m pip install -r requirements.txt
fi'
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
hash=$(git rev-list HEAD -1)
hash_f=dist/ng-material-scaffold/browser/"${hash}"
if [ ! -f "${hash_f}" ]; then
  npm i -g npm && npm i -g @angular/cli &&
  npm i &&
  ng build --configuration production &&
  touch "${hash_f}"
  install -d -D "${BUILD_STATIC_FILES0_DEST}"/dist/ng-material-scaffold/browser "${LIBSCRIPT_BUILD_DIR}"/ng-material-scaffold
fi'
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
  export NGINX_CONFIG_BUILDER__FRONTEND=1
export nginx_config_builder__frontend_COMMAND_FOLDER='_lib/_server/nginx'
export NGINX_CONFIG_BUILDER__FRONTEND_VARS='{"SERVER_NAME":"example.com","WWWROOT":"\"${LIBSCRIPT_BUILD_DIR}\"/ng-material-scaffold","HTTPS_ALWAYS":1,"HTTPS_VENDOR":"letsencrypt"}'
SCRIPT_NAME="${DIR}"'/install_gen.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}" ) &

########################
# Server(s) [optional] #
########################
(
  export NGINX_CONFIG_BUILDER__DOCS=1
export nginx_config_builder__docs_COMMAND_FOLDER='_lib/_server/nginx'
export NGINX_CONFIG_BUILDER__DOCS_VARS='{"SERVER_NAME":"example.com","LOCATION_EXPR":"~* /(api|redoc|rapidoc|scalar|secured)","HTTPS_ALWAYS":1,"HTTPS_VENDOR":"letsencrypt","PROXY_PASS":"http://localhost:3000"}'
SCRIPT_NAME="${DIR}"'/install_gen.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}" ) &

########################
# Server(s) [optional] #
########################
(
  export NGINX_CONFIG_BUILDER__CRAWL=1
export nginx_config_builder__crawl_COMMAND_FOLDER='_lib/_server/nginx'
export NGINX_CONFIG_BUILDER__CRAWL_VARS='{"SERVER_NAME":"example.com","LOCATION_EXPR":"/v1/crawl","HTTPS_ALWAYS":1,"HTTPS_VENDOR":"letsencrypt","PROXY_PASS":"http://localhost:3002"}'
SCRIPT_NAME="${DIR}"'/install_gen.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}" ) &

########################
# Server(s) [optional] #
########################
(
  export NGINX_CONFIG_BUILDER__SWAP=1
export nginx_config_builder__swap_COMMAND_FOLDER='_lib/_server/nginx'
export NGINX_CONFIG_BUILDER__SWAP_VARS='{"SERVER_NAME":"example.com","LOCATION_EXPR":"/v1/swap","HTTPS_ALWAYS":1,"HTTPS_VENDOR":"letsencrypt","PROXY_WEBSOCKETS":1,"PROXY_PASS":"http://localhost:3003"}'
SCRIPT_NAME="${DIR}"'/install_gen.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}" ) &

########################
# Server(s) [optional] #
########################
(
  export NGINX_CONFIG_BUILDER__DATA=1
export nginx_config_builder__data_COMMAND_FOLDER='_lib/_server/nginx'
export NGINX_CONFIG_BUILDER__DATA_VARS='{"SERVER_NAME":"example.com","LOCATION_EXPR":"/data","HTTPS_ALWAYS":1,"HTTPS_VENDOR":"letsencrypt","WWWROOT":"/opt/repos/E4S2024","PROXY_PASS":"http://localhost:3003"}'
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

