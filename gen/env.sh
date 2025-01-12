#!/bin/sh

#############################
#		Toolchain(s) [required]	#
#############################

export NODEJS_INSTALL_DIR=1
export NODEJS_INSTALL_DIR_VERSION='lts'

export PYTHON_INSTALL_DIR=1
export PYTHON_INSTALL_DIR_VERSION='3.10'

export RUST_INSTALL_DIR=1
export RUST_INSTALL_DIR_VERSION='nightly'

export POSTGRES_URL=1
export POSTGRES_URL_VERSION='>17'

export REDIS_URL=1
export REDIS_URL_VERSION='*'

#############################
#		Server(s) [required]	#
#############################

export SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD=1
export SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_VERSION='*'

export JUPYTERHUB=1
export JUPYTERHUB_VERSION='*'

#############################
#		Database(s) [optional]	#
#############################

export AMQP_URL=0
export AMQP_URL_VERSION='*'

#############################
#		      WWWROOT(s)      	#
#############################

export WWWROOT_example_com_INSTALL=1
export WWWROOT_example_com_INSTALL=1
export WWWROOT_example_com_INSTALL=0
export WWWROOT_example_com_INSTALL_VERSION='0.0.1'

