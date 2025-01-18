#!/bin/sh

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
export SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD=1
export SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST='/tmp/serve-actix-diesel-auth-scaffold'

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
export WWWROOT_example_com_COMMAND_FOLDER='_lib/_toolchain/nodejs'

