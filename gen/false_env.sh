#!/bin/sh

###########################
# Toolchain(s) [required] #
###########################
export NODEJS_INSTALL_DIR=0

export PYTHON_INSTALL_DIR=0

export RUST_INSTALL_DIR=0

##########################
# Database(s) [required] #
##########################
export POSTGRES_URL=0

export REDIS_URL=0

########################
# Server(s) [required] #
########################
export SADAS=0

########################
# Server(s) [optional] #
########################
export NODEJS_HTTP_SERVER=0

########################
# Server(s) [optional] #
########################
export PYTHON_SERVER=0

########################
# Server(s) [optional] #
########################
export BUILD_STATIC_FILES0=0

########################
# Server(s) [optional] #
########################
export NGINX_CONFIG_BUILDER__FRONTEND=0

########################
# Server(s) [optional] #
########################
export NGINX_CONFIG_BUILDER__DOCS=0

########################
# Server(s) [optional] #
########################
export NGINX_CONFIG_BUILDER__CRAWL=0

########################
# Server(s) [optional] #
########################
export NGINX_CONFIG_BUILDER__SWAP=0

########################
# Server(s) [optional] #
########################
export NGINX_CONFIG_BUILDER__DATA=0


##########################
# Database(s) [optional] #
##########################
export AMQP_URL=0

########################
# Server(s) [required] #
########################
export JUPYTERHUB=0

