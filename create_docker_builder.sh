#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0 [OPTIONS]"
  echo "See script source or documentation for more details."
  exit 0
fi
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"

elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${0}"

else
  THIS_FILE="${0}"
fi

set +f

DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)

PREFIX="${DOCKER_IMAGE_PREFIX:-deploysh-}"
SUFFIX="${DOCKER_IMAGE_SUFFIX:--latest}"
DOCKER_BUILDER='docker_builder.sh'
DOCKER_BUILDER_CMD='docker_builder.cmd'
DOCKER_BUILDER_PARALLEL='docker_builder_parallel.sh'
HEADER_TPL='###################\n#\t\t%s\t#\n###################\n\n'
HEADER_CMD_TPL=':: ###################\n:: #\t%s #\n:: ###################\n\n'

VERBOSE=0
INPUT_DIRECTORY=
HELP=0

while getopts 'p:s:i:vh' opt; do
    case ${opt} in
      'p')  PREFIX="${OPTARG}" ;;
      's')  SUFFIX="${OPTARG}" ;;
      'i')  INPUT_DIRECTORY="${OPTARG}" ;;
      'v')  # shellcheck disable=SC2003
            VERBOSE=$(expr "${VERBOSE}" + 1) ;;
      'h')  HELP=1 ;;
      *) ;;
    esac
done
export verbose

shift "$((OPTIND - 1))"
REMAINING="$*"

help() {
    # shellcheck disable=SC2016
    >&2 printf 'Create Docker image builder scripts.\n
\t-p prefix ($DOCKER_IMAGE_PREFIX, default: "deploysh")
\t-s suffix ($DOCKER_IMAGE_SUFFIX, default: "-latest")
\t-i input directory (`cd`s if provided, defaults to current working directory; adds scripts here also)
\t-v verbosity (can be specified multiple times)
\t-h show help text\n\n'
}

if [ "${HELP}" -ge 1 ]; then
  # shellcheck disable=SC2016
  help
  exit 2
fi

if [ -n "${REMAINING}" ]; then
  >&2 printf '[W] Extra arguments provided: %s\n' "${REMAINING}"
fi

previous_wd="$(pwd)"
if [ "${INPUT_DIRECTORY-}" ]; then
  cd -- "${INPUT_DIRECTORY}"
fi

awk 'NR==1,/^fi$/' "${DIR}"'/prelude.sh' | tee -a "${DOCKER_BUILDER}" "${DOCKER_BUILDER_PARALLEL}" >/dev/null
chmod +x "${DOCKER_BUILDER}" "${DOCKER_BUILDER_PARALLEL}"

collect_when_pattern() {
  pattern="$1"
    result=''

    # Expand the pattern into positional parameters
    # shellcheck disable=SC2086
    set -- $pattern

    for f in "$@"; do
      # Check if the file exists and is a regular file
      if [ -f "$f" ]; then
        result="${result} $f"
      fi
    done

    # Output the result, trimming leading whitespace
    printf '%s\n' "${result}" | sed 's/^ *//'
}

SERVER_DFS="$(collect_when_pattern 'dockerfiles/*.server.Dockerfile')"
STORAGE_DFS="$(collect_when_pattern 'dockerfiles/*.storage.Dockerfile')"
THIRD_PARTY_DFS="$(collect_when_pattern 'dockerfiles/*.third_party.Dockerfile')"
TOOLCHAIN_DFS="$(collect_when_pattern 'dockerfiles/*.toolchain.Dockerfile')"
WWWROOT_DFS="$(collect_when_pattern 'dockerfiles/*.wwwroot.Dockerfile')"

PROCESSED=' '"${SERVER_DFS}"' '"${STORAGE_DFS}"' '"${THIRD_PARTY_DFS}"' '"${TOOLCHAIN_DFS}"' '"${WWWROOT_DFS}"' '
REMAINING=''
for dockerfile in dockerfiles/*Dockerfile; do
  case "${PROCESSED}" in
    *[[:space:]]"${dockerfile}"[[:space:]]*|'*Dockerfile') ;;
    *)
      if [ ! "${dockerfile}" = '*Dockerfile' ]; then REMAINING="${REMAINING}${dockerfile}"' ' ; fi
      ;;
  esac
done

if [ "${VERBOSE}" -ge 3 ]; then
  printf 'server_dfs = %s\n' "${SERVER_DFS}"
  printf 'storage_dfs = %s\n' "${STORAGE_DFS}"
  printf 'third_party_dfs = %s\n' "${THIRD_PARTY_DFS}"
  printf 'toolchain_dfs = %s\n' "${TOOLCHAIN_DFS}"
  printf 'wwwroot_dfs = %s\n' "${WWWROOT_DFS}"
  printf 'remaining = %s\n' "${REMAINING}"
fi
NL='
'
process_one_dockerfile() {
  dockerfile="${1}";
  end="${2:-${NL}}"
  q="${3:-\'}"
IFS=. read -r tag name _ <<EOF
  ${dockerfile}
EOF
    tag=$(printf '%s' "${tag}" | tr -d '[:space:]')
    if [ "${name}" = 'Dockerfile' ]; then
      name=''
    elif [ "${tag}" = 'Dockerfile' ]; then
      name=''
      tag=''
    fi
    build_args_="${BUILD_ARGS}"
    if [ "${q}" = '"' ]; then
      build_args_="${BUILD_ARGS_DQ}";
      # shellcheck disable=SC1003
      dockerfile="$(printf '%s' "${dockerfile}" | tr '/' '\\')"
    fi
    printf 'docker build --file '"${q}"'%s'"${q}"' %s --tag '"${q}"'%s%s'"${q}"':'"${q}"'%s%s'"${q}"' .%s' "${dockerfile}" "${build_args_}" "${PREFIX}" "${name}" "${tag}" "${SUFFIX}" "${end}"
}

section2name() {
  case "${1}" in
    "${SERVER_DFS}") res='Servers' ;;
    "${STORAGE_DFS}") res='Storage' ;;
    "${THIRD_PARTY_DFS}") res='Third party' ;;
    "${TOOLCHAIN_DFS}") res='Toolchain(s)' ;;
    "${WWWROOT_DFS}") res='WWWROOT(s)' ;;
    "${REMAINING}"|*) res='rest' ;;
  esac
  export res;
}

DOCKER_BUILD_ARGS=${DOCKER_BUILD_ARGS:---progress=\'plain\' --no-cache}
BUILD_ARGS="$(printf '%s' "${DOCKER_BUILD_ARGS}")"
BUILD_ARGS_DQ="$(printf '%s' "${DOCKER_BUILD_ARGS}" | tr "'" '"')"

for section in "${TOOLCHAIN_DFS}" "${SERVER_DFS}" "${STORAGE_DFS}" "${THIRD_PARTY_DFS}" "${WWWROOT_DFS}" "${REMAINING}"; do
  section2name "${section}"
  # shellcheck disable=SC2059
  printf "${HEADER_TPL}" "${res}" | tee -a "${DOCKER_BUILDER}" "${DOCKER_BUILDER_PARALLEL}" >/dev/null
  # shellcheck disable=SC2059
  printf "${HEADER_CMD_TPL}" "${res}" >> "${DOCKER_BUILDER_CMD}"
  for dockerfile in ${section}; do
    process_one_dockerfile "${dockerfile}" ' &
' "'" >> "${DOCKER_BUILDER_PARALLEL}"
    process_one_dockerfile "${dockerfile}" '
' "'" >> "${DOCKER_BUILDER}"
    process_one_dockerfile "${dockerfile}" '
' '"' >> "${DOCKER_BUILDER_CMD}"
  done
  printf 'wait\n\n' >> "${DOCKER_BUILDER_PARALLEL}"
  printf '\n' | tee -a "${DOCKER_BUILDER}" "${DOCKER_BUILDER_CMD}" >/dev/null
done

if [ "${INPUT_DIRECTORY-}" ]; then
  cd -- "${previous_wd}"
fi
