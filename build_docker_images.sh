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

prefix="${DOCKER_IMAGE_PREFIX:-deploysh}"
suffix="${DOCKER_IMAGE_SUFFIX:--latest}"


verbose=0
input_directory=''
help=0

while getopts 'p:s:i:v:h:' opt; do
    case ${opt} in
      (p)   prefix="${OPTARG}" ;;
      (s)   suffix="${OPTARG}" ;;
      (i)   input_directory="${OPTARG}" ;;
      (v)   # shellcheck disable=SC2003
            verbose=$(expr "${verbose}" + 1) ;;
      (h)   if test "${OPTARG}" = "$(eval echo '$'$((OPTIND - 1)))"; then
              OPTIND=$((OPTIND - 1));
            fi
            help=1 ;;
      (*) ;;
    esac
done
export verbose

shift "$((OPTIND - 1))"
remaining="$*"

help() {
    # shellcheck disable=SC2016
    >&2 printf 'Build Docker images.\n
\t-p prefix ($DOCKER_IMAGE_PREFIX, default: "deploysh")
\t-s suffix ($DOCKER_IMAGE_SUFFIX, default: "-latest")
\t-i input directory (`cd`s if provided, defaults to current working directory)
\t-v verbosity (can be specified multiple times)
\t-h show help text\n\n'
}

if [ "${help}" -ge 1 ]; then
  # shellcheck disable=SC2016
  help
  exit 2
fi

if [ -n "${remaining}" ]; then
  >&2 printf '[W] Extra arguments provided: %s\n' "${remaining}"
fi

previous_wd="$(pwd)"
if [ ! -z "${input_directory+x}" ]; then
  cd "${input_directory}"
fi
printf 'input_directory = %s\n' "${input_directory}"
cwd=$(pwd)
printf 'cwd = %s\n' "${cwd}"

server_dfs="$(ls -- *.server.Dockerfile)"
storage_dfs="$(echo -- *.storage.Dockerfile)"
third_party_dfs="$(echo -- *.third_party.Dockerfile)"
toolchain_dfs="$(echo -- *.toolchain.Dockerfile)"
wwwroot_dfs="$(echo -- *.wwwroot.Dockerfile)"
verbose=0

processed=' '"${server_dfs}"' '"${storage_dfs}"' '"${third_party_dfs}"' '"${toolchain_dfs}"' '"${wwwroot_dfs}"' '
remaining=''
for dockerfile in *Dockerfile; do
  case "${processed}" in
    *[[:space:]]"${dockerfile}"[[:space:]]*) ;;
    *)
      remaining="${remaining}${dockerfile}"' '
      printf 'dockerfile = %s\n' "${dockerfile}" ;;
  esac
done
verbose=3

printf 'verbose = %d\n' "${verbose}"
if [ "${verbose}" -ge 3 ]; then
  printf 'server_dfs = %s\n' "${server_dfs}"
  printf 'storage_dfs = %s\n' "${storage_dfs}"
  printf 'third_party_dfs = %s\n' "${third_party_dfs}"
  printf 'toolchain_dfs = %s\n' "${toolchain_dfs}"
  printf 'wwwroot_dfs = %s\n' "${wwwroot_dfs}"
  printf 'remaining = %s\n' "${remaining}"
fi

DOCKER_BUILD_ARGS=${DOCKER_BUILD_ARGS:---progress plain --no-cache}
dockerfiles=' '"${server_dfs}"' '"${storage_dfs}"' '"${third_party_dfs}"' '"${toolchain_dfs}"' '"${wwwroot_dfs}"' '"${remaining}"
for dockerfile in ${dockerfiles}; do
  IFS=. read -r tag name _ <<EOF
${dockerfile}
EOF
  if [ "${name}" = 'Dockerfile' ]; then
    name=''
  elif [ "${tag}" = 'Dockerfile' ]; then
    name=''
    tag=''
  fi
  # shellcheck disable=SC2086
  docker build --file "${dockerfile}" ${DOCKER_BUILD_ARGS} --tag "${prefix}${name}":"${tag}${suffix}" .
done

if [ ! -z "${input_directory+x}" ]; then
  cd "${previous_wd}"
fi
