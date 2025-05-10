#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE+x}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION+x}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi
###################
#		Toolchain(s)	#
###################

docker build --file 'dockerfiles/alpine.toolchain.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-toolchain':'dockerfiles/alpine-latest' .
docker build --file 'dockerfiles/debian.toolchain.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-toolchain':'dockerfiles/debian-latest' .

###################
#		Servers	#
###################


###################
#		Storage	#
###################

docker build --file 'dockerfiles/alpine.storage.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-storage':'dockerfiles/alpine-latest' .
docker build --file 'dockerfiles/debian.storage.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-storage':'dockerfiles/debian-latest' .

###################
#		Third party	#
###################

docker build --file 'dockerfiles/alpine.third_party.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-third_party':'dockerfiles/alpine-latest' .
docker build --file 'dockerfiles/debian.third_party.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-third_party':'dockerfiles/debian-latest' .

###################
#		Servers	#
###################


###################
#		rest	#
###################

docker build --file 'dockerfiles/alpine.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-':'dockerfiles/alpine-latest' .
docker build --file 'dockerfiles/alpine.build-static-files0.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-build-static-files0':'dockerfiles/alpine-latest' .
docker build --file 'dockerfiles/alpine.jupyterhub.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-jupyterhub':'dockerfiles/alpine-latest' .
docker build --file 'dockerfiles/alpine.nginx-config-builder__crawl.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-nginx-config-builder__crawl':'dockerfiles/alpine-latest' .
docker build --file 'dockerfiles/alpine.nginx-config-builder__data.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-nginx-config-builder__data':'dockerfiles/alpine-latest' .
docker build --file 'dockerfiles/alpine.nginx-config-builder__docs.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-nginx-config-builder__docs':'dockerfiles/alpine-latest' .
docker build --file 'dockerfiles/alpine.nginx-config-builder__frontend.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-nginx-config-builder__frontend':'dockerfiles/alpine-latest' .
docker build --file 'dockerfiles/alpine.nginx-config-builder__swap.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-nginx-config-builder__swap':'dockerfiles/alpine-latest' .
docker build --file 'dockerfiles/alpine.nodejs-http-server.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-nodejs-http-server':'dockerfiles/alpine-latest' .
docker build --file 'dockerfiles/alpine.nodejs.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-nodejs':'dockerfiles/alpine-latest' .
docker build --file 'dockerfiles/alpine.postgres.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-postgres':'dockerfiles/alpine-latest' .
docker build --file 'dockerfiles/alpine.python-server.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-python-server':'dockerfiles/alpine-latest' .
docker build --file 'dockerfiles/alpine.python.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-python':'dockerfiles/alpine-latest' .
docker build --file 'dockerfiles/alpine.rabbitmq.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-rabbitmq':'dockerfiles/alpine-latest' .
docker build --file 'dockerfiles/alpine.rust.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-rust':'dockerfiles/alpine-latest' .
docker build --file 'dockerfiles/alpine.sadas.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-sadas':'dockerfiles/alpine-latest' .
docker build --file 'dockerfiles/alpine.valkey.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-valkey':'dockerfiles/alpine-latest' .
docker build --file 'dockerfiles/debian.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-':'dockerfiles/debian-latest' .
docker build --file 'dockerfiles/debian.build-static-files0.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-build-static-files0':'dockerfiles/debian-latest' .
docker build --file 'dockerfiles/debian.jupyterhub.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-jupyterhub':'dockerfiles/debian-latest' .
docker build --file 'dockerfiles/debian.nginx-config-builder__crawl.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-nginx-config-builder__crawl':'dockerfiles/debian-latest' .
docker build --file 'dockerfiles/debian.nginx-config-builder__data.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-nginx-config-builder__data':'dockerfiles/debian-latest' .
docker build --file 'dockerfiles/debian.nginx-config-builder__docs.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-nginx-config-builder__docs':'dockerfiles/debian-latest' .
docker build --file 'dockerfiles/debian.nginx-config-builder__frontend.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-nginx-config-builder__frontend':'dockerfiles/debian-latest' .
docker build --file 'dockerfiles/debian.nginx-config-builder__swap.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-nginx-config-builder__swap':'dockerfiles/debian-latest' .
docker build --file 'dockerfiles/debian.nodejs-http-server.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-nodejs-http-server':'dockerfiles/debian-latest' .
docker build --file 'dockerfiles/debian.nodejs.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-nodejs':'dockerfiles/debian-latest' .
docker build --file 'dockerfiles/debian.postgres.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-postgres':'dockerfiles/debian-latest' .
docker build --file 'dockerfiles/debian.python-server.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-python-server':'dockerfiles/debian-latest' .
docker build --file 'dockerfiles/debian.python.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-python':'dockerfiles/debian-latest' .
docker build --file 'dockerfiles/debian.rabbitmq.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-rabbitmq':'dockerfiles/debian-latest' .
docker build --file 'dockerfiles/debian.rust.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-rust':'dockerfiles/debian-latest' .
docker build --file 'dockerfiles/debian.sadas.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-sadas':'dockerfiles/debian-latest' .
docker build --file 'dockerfiles/debian.valkey.Dockerfile' --progress='plain' --no-cache --tag 'deploysh-valkey':'dockerfiles/debian-latest' .

