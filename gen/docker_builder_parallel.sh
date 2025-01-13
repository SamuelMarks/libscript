#!/bin/sh

# shellcheck disable=SC2236
if [ ! -z "${BASH_VERSION+x}" ]; then
  # shellcheck disable=SC3040
  set -o pipefail
elif [ ! -z "${ZSH_VERSION+x}" ]; then
  # shellcheck disable=SC3040
  set -o pipefail
fi
set -feu

###################
#		Toolchain(s)	#
###################

docker build --file "alpine.toolchain.Dockerfile" --progress plain --no-cache --tag "deploysh-toolchain":"alpine-latest" . &
docker build --file "debian.toolchain.Dockerfile" --progress plain --no-cache --tag "deploysh-toolchain":"debian-latest" . &
wait

###################
#		Servers	#
###################

docker build --file "alpine.server.Dockerfile" --progress plain --no-cache --tag "deploysh-server":"alpine-latest" . &
docker build --file "debian.server.Dockerfile" --progress plain --no-cache --tag "deploysh-server":"debian-latest" . &
wait

###################
#		Storage	#
###################

docker build --file "alpine.storage.Dockerfile" --progress plain --no-cache --tag "deploysh-storage":"alpine-latest" . &
docker build --file "debian.storage.Dockerfile" --progress plain --no-cache --tag "deploysh-storage":"debian-latest" . &
wait

###################
#		Third party	#
###################

docker build --file "alpine.third_party.Dockerfile" --progress plain --no-cache --tag "deploysh-third_party":"alpine-latest" . &
docker build --file "debian.third_party.Dockerfile" --progress plain --no-cache --tag "deploysh-third_party":"debian-latest" . &
wait

###################
#		WWWROOT(s)	#
###################

docker build --file "alpine.wwwroot.Dockerfile" --progress plain --no-cache --tag "deploysh-wwwroot":"alpine-latest" . &
docker build --file "debian.wwwroot.Dockerfile" --progress plain --no-cache --tag "deploysh-wwwroot":"debian-latest" . &
wait

###################
#		rest	#
###################

docker build --file "alpine.Dockerfile" --progress plain --no-cache --tag "deploysh-":"alpine-latest" . &
docker build --file "alpine.example_com.Dockerfile" --progress plain --no-cache --tag "deploysh-example_com":"alpine-latest" . &
docker build --file "alpine.jupyterhub.Dockerfile" --progress plain --no-cache --tag "deploysh-jupyterhub":"alpine-latest" . &
docker build --file "alpine.nodejs.Dockerfile" --progress plain --no-cache --tag "deploysh-nodejs":"alpine-latest" . &
docker build --file "alpine.postgres.Dockerfile" --progress plain --no-cache --tag "deploysh-postgres":"alpine-latest" . &
docker build --file "alpine.python.Dockerfile" --progress plain --no-cache --tag "deploysh-python":"alpine-latest" . &
docker build --file "alpine.rabbitmq.Dockerfile" --progress plain --no-cache --tag "deploysh-rabbitmq":"alpine-latest" . &
docker build --file "alpine.rust.Dockerfile" --progress plain --no-cache --tag "deploysh-rust":"alpine-latest" . &
docker build --file "alpine.serve-actix-diesel-auth-scaffold.Dockerfile" --progress plain --no-cache --tag "deploysh-serve-actix-diesel-auth-scaffold":"alpine-latest" . &
docker build --file "alpine.valkey.Dockerfile" --progress plain --no-cache --tag "deploysh-valkey":"alpine-latest" . &
docker build --file "debian.Dockerfile" --progress plain --no-cache --tag "deploysh-":"debian-latest" . &
docker build --file "debian.example_com.Dockerfile" --progress plain --no-cache --tag "deploysh-example_com":"debian-latest" . &
docker build --file "debian.jupyterhub.Dockerfile" --progress plain --no-cache --tag "deploysh-jupyterhub":"debian-latest" . &
docker build --file "debian.nodejs.Dockerfile" --progress plain --no-cache --tag "deploysh-nodejs":"debian-latest" . &
docker build --file "debian.postgres.Dockerfile" --progress plain --no-cache --tag "deploysh-postgres":"debian-latest" . &
docker build --file "debian.python.Dockerfile" --progress plain --no-cache --tag "deploysh-python":"debian-latest" . &
docker build --file "debian.rabbitmq.Dockerfile" --progress plain --no-cache --tag "deploysh-rabbitmq":"debian-latest" . &
docker build --file "debian.rust.Dockerfile" --progress plain --no-cache --tag "deploysh-rust":"debian-latest" . &
docker build --file "debian.serve-actix-diesel-auth-scaffold.Dockerfile" --progress plain --no-cache --tag "deploysh-serve-actix-diesel-auth-scaffold":"debian-latest" . &
docker build --file "debian.valkey.Dockerfile" --progress plain --no-cache --tag "deploysh-valkey":"debian-latest" . &
wait

