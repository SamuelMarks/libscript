#!/bin/sh

#############################
#		Toolchain(s) [required]	#
#############################

export NODEJS_INSTALL_DIR="${NODEJS_INSTALL_DIR:-1}"
export NODEJS_VERSION='lts'

export PYTHON_INSTALL_DIR="${PYTHON_INSTALL_DIR:-1}"
export PYTHON_VERSION='3.10'

export RUST_INSTALL_DIR="${RUST_INSTALL_DIR:-1}"
export RUST_VERSION='nightly'

export POSTGRES_URL="${POSTGRES_URL:-1}"
export POSTGRES_VERSION='>17'

export REDIS_URL="${REDIS_URL:-1}"
export VALKEY_VERSION='*'

#############################
#		Server(s) [required]	#
#############################

export JUPYTERHUB="${JUPYTERHUB:-1}"
export JupyterHub_VERSION='*'

#############################
#		Database(s) [optional]	#
#############################

export AMQP_URL=0
export RabbitMQ_VERSION='*'

#############################
#		      WWWROOT(s)      	#
#############################

export WWWROOT_example_com_INSTALL="${WWWROOT_example_com_INSTALL:-1}"
