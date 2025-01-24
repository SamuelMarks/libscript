#!/bin/sh

LIBSCRIPT_BUILD_DIR="${LIBSCRIPT_BUILD_DIR:-${TMPDIR:-/tmp}/libscript_build}"
export LIBSCRIPT_DATA_DIR

#!/bin/sh

LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"
export LIBSCRIPT_DATA_DIR

###########################
# Toolchain(s) [required] #
###########################
export NODEJS_INSTALL_DIR=1
export NODEJS_VERSION='lts'

export PYTHON_INSTALL_DIR=1
export PYTHON_VERSION='3.10'

export RUST_INSTALL_DIR=1
export RUST_VERSION='nightly'

##########################
# Database(s) [required] #
##########################
export POSTGRES_URL=1
export POSTGRES_USER='rest_user'
export POSTGRES_PASSWORD='rest_pass'
export POSTGRES_DB='rest_db'
export POSTGRES_PASSWORD_FILE
export POSTGRES_VERSION=17

export REDIS_URL=1
export VALKEY_VERSION='*'

########################
# Server(s) [required] #
########################
export SADAS=1
export SADAS_COMMANDS_BEFORE='git_get https://github.com/SamuelMarks/serve-actix-diesel-auth-scaffold "${SADAS_DEST}"'
export SADAS_COMMAND_FOLDER='_lib/_server/rust'
export SADAS_DEST='/tmp/serve-actix-diesel-auth-scaffold'

########################
# Server(s) [optional] #
########################
export NODEJS_HTTP_SERVER=1
export nodejs_http_server_COMMANDS_BEFORE='git_get https://github.com/mohammadhasanii/Node-HTTP3 "${NODEJS_HTTP_SERVER_DEST}"'
export nodejs_http_server_COMMAND_FOLDER='_lib/_server/nodejs'
export NODEJS_HTTP_SERVER_DEST='/tmp/nodejs-http-server'

########################
# Server(s) [optional] #
########################
export PYTHON_SERVER=1
export python_server_COMMANDS_BEFORE='git_get https://github.com/digitalocean/sample-python "${PYTHON_SERVER_DEST}"
if [ ! -f "venv-3-12/bin/python" ]; then
  uv venv --python 3.12 venv-3-12
  venv-3-12/bin/python -m ensurepip
  venv-3-12/bin/python -m pip install -r requirements.txt
fi'
export python_server_COMMAND_FOLDER='_lib/_server/python'
export PYTHON_SERVER_DEST='/tmp/python-server'

########################
# Server(s) [optional] #
########################
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

########################
# Server(s) [optional] #
########################
export NGINX_CONFIG_BUILDER=1
export nginx_config_builder_COMMAND_FOLDER='_lib/_server/nginx'
export NGINX_CONFIG_BUILDER_VARS='{"SERVER_NAME":"example.com","WWWROOT":"\"${LIBSCRIPT_BUILD_DIR}\"/ng-material-scaffold","HTTPS_ALWAYS":1,"HTTPS_VENDOR":"letsencrypt"}'

##########################
# Database(s) [optional] #
##########################
export AMQP_URL=0
export RABBITMQ_VERSION='*'

########################
# Server(s) [required] #
########################
export JUPYTERHUB=0

