#!/bin/sh

#############################
#		Toolchain(s) [required]	#
#############################

export NODEJS_INSTALL_DIR=1
export NODEJS_VERSION='lts'

export PYTHON_INSTALL_DIR=1
export PYTHON_VERSION='3.10'

export RUST_INSTALL_DIR=1
export RUST_VERSION='nightly'

export POSTGRES_URL=1
export POSTGRES_USER="rest_user"
export POSTGRES_PASSWORD="rest_pass"
export POSTGRES_DB="rest_db"
export POSTGRES_VERSION='17'

export REDIS_URL=1
export VALKEY_VERSION='*'

#############################
#		Server(s) [required]	#
#############################

export SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD=1
export serve-actix-diesel-auth-scaffold_VERSION='*'

export JUPYTERHUB=1
export JupyterHub_VERSION='*'

#############################
#		Database(s) [optional]	#
#############################

export AMQP_URL=0
export RABBITMQ_VERSION='*'

#############################
#		      WWWROOT(s)      	#
#############################

export WWWROOT_example_com_INSTALL=1
export WWWROOT_example_com_INSTALL=1
export WWWROOT_example_com_INSTALL=0
export example_com_VERSION='0.0.1'

