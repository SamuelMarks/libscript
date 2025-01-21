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
uv venv --python 3.12 venv-3-12
venv-3-12/bin/python -m ensurepip
venv-3-12/bin/python -m pip install -r requirements.txt'
export python_server_COMMAND_FOLDER='_lib/_server/python'
export PYTHON_SERVER_DEST='/tmp/python-server'

##########################
# Database(s) [optional] #
##########################
export AMQP_URL=0
export RABBITMQ_VERSION='*'

########################
# Server(s) [required] #
########################
export JUPYTERHUB=0

##############
# WWWROOT(s) #
##############
export WWWROOT_example_com_INSTALL=0
export example_com='./my_symlinked_wwwroot'
export WWWROOT_example_com_COMMAND_FOLDER='_lib/_toolchain/nodejs'
export WWWROOT_example_com_COMMANDS_BEFORE='npm i -g @angular/cli &&
npm i &&
ng build --configuration production'

