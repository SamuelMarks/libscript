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

SCRIPT_ROOT_DIR="${SCRIPT_ROOT_DIR:-$( CDPATH='' cd -- "$( dirname -- "$( readlink -nf -- "${this_file}" )")" && pwd)}"
export SCRIPT_ROOT_DIR

STACK="${STACK:-:}${this_file}"':'
export STACK

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
  export SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD=1
export SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST='/tmp/serve-actix-diesel-auth-scaffold'
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

##############
# WWWROOT(s) #
##############
wait

(
  export WWWROOT_example_com_INSTALL=0
export WWWROOT_example_com_COMMAND_FOLDER='_lib/_toolchain/nodejs'
SCRIPT_NAME="${DIR}"'/install_gen.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}" ) &

