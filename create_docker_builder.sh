#!/bin/sh

# shellcheck disable=SC2236
if [ ! -z "${BASH_VERSION+x}" ]; then
  # shellcheck disable=SC3040
  set -o pipefail
elif [ ! -z "${ZSH_VERSION+x}" ]; then
  # shellcheck disable=SC3040
  set -o pipefail
fi
set -eu
set +f # in case anyone else set this; we use glob here!!

prefix="${DOCKER_IMAGE_PREFIX:-deploysh-}"
suffix="${DOCKER_IMAGE_SUFFIX:--latest}"
docker_builder='docker_builder.sh'
docker_builder_cmd='docker_builder.cmd'
docker_builder_parallel='docker_builder_parallel.sh'
header_tpl='###################\n#\t\t%s\t#\n###################\n\n'
header_cmd_tpl=':: ###################\n:: #\t%s #\n:: ###################\n\n'

verbose=0
input_directory=''
help=0

while getopts 'p:s:i:vh' opt; do
    case ${opt} in
      'p')  prefix="${OPTARG}" ;;
      's')  suffix="${OPTARG}" ;;
      'i')  input_directory="${OPTARG}" ;;
      'v')  # shellcheck disable=SC2003
            verbose=$(expr "${verbose}" + 1) ;;
      'h')  help=1 ;;
      *) ;;
    esac
done
export verbose

shift "$((OPTIND - 1))"
remaining="$*"

help() {
    # shellcheck disable=SC2016
    >&2 printf 'Create Docker image builder scripts.\n
\t-p prefix ($DOCKER_IMAGE_PREFIX, default: "deploysh")
\t-s suffix ($DOCKER_IMAGE_SUFFIX, default: "-latest")
\t-i input directory (`cd`s if provided, defaults to current working directory; adds scripts here also)
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

# shellcheck disable=SC2016
printf '#!/bin/sh

# shellcheck disable=SC2236
if [ ! -z "${BASH_VERSION+x}" ]; then
  # shellcheck disable=SC3040
  set -o pipefail
elif [ ! -z "${ZSH_VERSION+x}" ]; then
  # shellcheck disable=SC3040
  set -o pipefail
fi
set -feu\n\n' | tee "${docker_builder}" "${docker_builder_parallel}" >/dev/null
chmod +x "${docker_builder}" "${docker_builder_parallel}"

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
    echo "$result" | sed 's/^ *//'
}

server_dfs="$(collect_when_pattern 'dockerfiles/*.server.Dockerfile')"
storage_dfs="$(collect_when_pattern 'dockerfiles/*.storage.Dockerfile')"
third_party_dfs="$(collect_when_pattern 'dockerfiles/*.third_party.Dockerfile')"
toolchain_dfs="$(collect_when_pattern 'dockerfiles/*.toolchain.Dockerfile')"
wwwroot_dfs="$(collect_when_pattern 'dockerfiles/*.wwwroot.Dockerfile')"

processed=' '"${server_dfs}"' '"${storage_dfs}"' '"${third_party_dfs}"' '"${toolchain_dfs}"' '"${wwwroot_dfs}"' '
remaining=''
for dockerfile in dockerfiles/*Dockerfile; do
  case "${processed}" in
    *[[:space:]]"${dockerfile}"[[:space:]]*|'*Dockerfile') ;;
    *)
      if [ ! "${dockerfile}" = '*Dockerfile' ]; then remaining="${remaining}${dockerfile}"' ' ; fi
      ;;
  esac
done

if [ "${verbose}" -ge 3 ]; then
  printf 'server_dfs = %s\n' "${server_dfs}"
  printf 'storage_dfs = %s\n' "${storage_dfs}"
  printf 'third_party_dfs = %s\n' "${third_party_dfs}"
  printf 'toolchain_dfs = %s\n' "${toolchain_dfs}"
  printf 'wwwroot_dfs = %s\n' "${wwwroot_dfs}"
  printf 'remaining = %s\n' "${remaining}"
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
    build_args_="${build_args}"
    if [ "${q}" = '"' ]; then
      build_args_="${build_args_dq}";
      # shellcheck disable=SC1003
      dockerfile="$(printf '%s' "${dockerfile}" | tr '/' '\\')"
    fi
    printf 'docker build --file '"${q}"'%s'"${q}"' %s --tag '"${q}"'%s%s'"${q}"':'"${q}"'%s%s'"${q}"' .%s' "${dockerfile}" "${build_args_}" "${prefix}" "${name}" "${tag}" "${suffix}" "${end}"
}

section2name() {
  case "${1}" in
    "${server_dfs}") res='Servers' ;;
    "${storage_dfs}") res='Storage' ;;
    "${third_party_dfs}") res='Third party' ;;
    "${toolchain_dfs}") res='Toolchain(s)' ;;
    "${wwwroot_dfs}") res='WWWROOT(s)' ;;
    "${remaining}"|*) res='rest' ;;
  esac
  export res;
}

DOCKER_BUILD_ARGS=${DOCKER_BUILD_ARGS:---progress=\'plain\' --no-cache}
build_args="$(printf '%s' "${DOCKER_BUILD_ARGS}")"
build_args_dq="$(printf '%s' "${DOCKER_BUILD_ARGS}" | tr "'" '"')"

for section in "${toolchain_dfs}" "${server_dfs}" "${storage_dfs}" "${third_party_dfs}" "${wwwroot_dfs}" "${remaining}"; do
  section2name "${section}"
  # shellcheck disable=SC2059
  printf "${header_tpl}" "${res}" | tee -a "${docker_builder}" "${docker_builder_parallel}" >/dev/null
  # shellcheck disable=SC2059
  printf "${header_cmd_tpl}" "${res}" >> "${docker_builder_cmd}"
  for dockerfile in ${section}; do
    process_one_dockerfile "${dockerfile}" ' &
' "'" >> "${docker_builder_parallel}"
    process_one_dockerfile "${dockerfile}" '
' "'" >> "${docker_builder}"
    process_one_dockerfile "${dockerfile}" '
' '"' >> "${docker_builder_cmd}"
  done
  printf 'wait\n\n' >> "${docker_builder_parallel}"
  printf '\n' | tee -a "${docker_builder}" "${docker_builder_cmd}" >/dev/null
done

if [ ! -z "${input_directory+x}" ]; then
  cd "${previous_wd}"
fi
