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

verbose="${verbose:-0}"
all_deps="${all_deps:-0}"

output_folder=${output_folder:-${SCRIPT_ROOT_DIR}/tmp}
false_env_file="${output_folder}"'/false_env.sh'
true_env_file="${output_folder}"'/env.sh'
install_file="${output_folder}"'/install_gen.sh'
install_parallel_file="${output_folder}"'/install_parallel_gen.sh'
docker_scratch_file="${output_folder}"'/docker.tmp'
toolchain_scratch_file="${output_folder}"'/toolchain.tmp'
storage_scratch_file="${output_folder}"'/storage.tmp'
server_scratch_file="${output_folder}"'/database.tmp'
wwwroot_scratch_file="${output_folder}"'/wwwroot.tmp'
base="${BASE:-alpine:latest debian:bookworm-slim}"

[ -d "${output_folder}" ] || mkdir -p "${output_folder}"
prelude="$(cat -- "${SCRIPT_ROOT_DIR}"'/prelude.sh'; printf 'a')"
prelude="${prelude%a}"
if [ ! -f "${install_file}" ]; then printf '%s\n\n' "${prelude}" > "${install_file}" ; fi
# shellcheck disable=SC2016
if [ ! -f "${install_parallel_file}" ]; then printf '%s\nDIR=$(CDPATH='"''"' cd -- "$(dirname -- "${this_file}")" && pwd)\n\n' "${prelude}"  > "${install_parallel_file}" ; fi
if [ ! -f "${true_env_file}" ]; then printf '#!/bin/sh\n\n' > "${true_env_file}" ; fi
if [ ! -f "${false_env_file}" ]; then printf '#!/bin/sh\n' > "${false_env_file}" ; fi
printf '' | tee "${docker_scratch_file}" "${toolchain_scratch_file}" \
                "${storage_scratch_file}" "${server_scratch_file}" \
                "${wwwroot_scratch_file}"

header_tpl='#############################\n#\t\t%s\t#\n#############################\n\n'

# shellcheck disable=SC2016
run_tpl='SCRIPT_NAME="${DIR}"'"'"'/%s'"'"'\nexport SCRIPT_NAME\n# shellcheck disable=SC1090\n. "${SCRIPT_NAME}"'

toolchains_len=0
toolchains_header_req=0
toolchains_header_opt=0
databases_len=0
databases_header_req=0
databases_header_opt=0
servers_len=0
servers_header_req=0
wwwroot_len=0
wwwroot_header_req=0

# Extra check in case a different `SCRIPT_ROOT_DIR` is found in the JSON
if ! command -v jq >/dev/null 2>&1; then
  SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_lib/_toolchain/jq/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
fi

path2key() {
  case "${1}" in
    '_lib/_toolchain') export res='toolchain' ;;
    '_lib/_storage') export res='storage' ;;
    'app/third_party') export res='third_party' ;;
    **) export res="${1}" ;;
  esac
}

key2path() {
  case "${1}" in
    'toolchain') export res='_lib/_toolchain' ;;
    'storage') export res='_lib/_storage' ;;
    'third_party') export res='app/third_party' ;;
    **) export res="${1}" ;;
  esac
}

scratch2key() {
  case "${1}" in
    "${toolchain_scratch_file}") export res='toolchain' ;;
    "${server_scratch_file}") export res='server' ;;
    "${wwwroot_scratch_file}") export res='wwwroot' ;;
    'storage'|**) export res='storage' ;;
  esac
}

key2scratch() {
  case "${1}" in
    'toolchain') export res="${toolchain_scratch_file}" ;;
    'server') export res="${server_scratch_file}" ;;
    'wwwroot') export res="${wwwroot_scratch_file}" ;;
    'storage'|**) export res="${storage_scratch_file}" ;;
  esac
}

add_missing_line_continuation() {
  in_run_block=0
  starts_with_run=0
  if_count=0
  while_count=0
  for_count=0
  printf '' > "${2}"
  # TODO: Read a word [token] at a time not a line at a time, so `if foo; fi` style can be handled
  while read -r line; do
    case "${line}" in
      'RUN '*)
        in_run_block=1 ;
        starts_with_run=1 ;;
      'if '*)
        # shellcheck disable=SC2003
        if_count="$(expr "${if_count}" + 1)" ;;
      'while '*|*' while')
        # shellcheck disable=SC2003
        while_count="$(expr "${while_count}" + 1)" ;;
      'for '*|*' for')
        # shellcheck disable=SC2003
        for_count="$(expr "${for_count}" + 1)" ;;
      *'\;'|'\done'|'\fi'|'\if') starts_with_run=0 ;;
      'fi'|*' fi'|'fi '*)
        # shellcheck disable=SC2003
        if_count="$(expr "${if_count}" - 1)"
        if [ "${if_count}" -eq 0 ] && [ "${while_count}" -eq 0 ] && [ "${for_count}" -eq 0 ] ; then
          in_run_block=0
        fi
        starts_with_run=0 ;;
      *' done'|'done'|'done '*)
        # shellcheck disable=SC2003
        done_count="$(expr "${done_count}" - 1)"
        if [ "${if_count}" -eq 0 ] && [ "${while_count}" -eq 0 ] && [ "${for_count}" -eq 0 ] ; then
          in_run_block=0
        fi
        starts_with_run=0
        ;;
      *';'|'[:space:]')
        if [ "${if_count}" -eq 0 ] && [ "${while_count}" -eq 0 ] && [ "${for_count}" -eq 0 ] ; then
          in_run_block=0
        fi
        starts_with_run=0 ;;
      **) starts_with_run=0 ;;
    esac
    {
      if [ "${starts_with_run}" -eq 1 ]; then
        printf '%s %s\n' "${line}" '\'
      elif [ "${in_run_block}" -eq 1 ]; then
        # shellcheck disable=SC1003
        printf '  %s %s\n' "${line}" '\'
      else
        printf '%s\n' "${line}"
      fi
    } >> "${2}"
  done<"${1}"
}

update_generated_files() {
  name="${1}"
  version="${2}"
  env="${3}"
  location="${4}"
  dep_group_name="${5}"

  path2key "${location}"
  key2scratch "${res}"
  scratch_file="${res}"

  {
    # shellcheck disable=SC2016
    printf '(\n  ' >> "${install_parallel_file}"
    if [ "${dep_group_name}" = 'Required' ] || [ "${all_deps}" -ge 1 ]; then
      # shellcheck disable=SC2016
      printf 'ARG %s=1\n' "${env}" "${env}" | tee -a "${docker_scratch_file}" "${scratch_file}" >/dev/null
      # shellcheck disable=SC2016
      printf 'export %s="${%s:-1}"\n' "${env}" "${env}"
    else
      # shellcheck disable=SC2016
      printf 'ARG %s=0\n' "${env}" | tee -a "${docker_scratch_file}" "${scratch_file}" >/dev/null
      printf 'export %s=0\n' "${env}"
    fi
    printf 'ARG %s_VERSION='"'"'%s'"'"'\n\n' "${name}" "${version}" | tee -a "${docker_scratch_file}" "${scratch_file}" >/dev/null
    printf 'export %s_VERSION='"'"'%s'"'"'\n\n' "${name}" "${version}"
  } | tee -a "${install_parallel_file}" "${true_env_file}" >/dev/null
  # shellcheck disable=SC2059
  printf "${run_tpl}"' ) &\n\n' 'install_gen.sh' >> "${install_parallel_file}"
  printf 'export %s=0\n' "${env}" >> "${false_env_file}"

  printf 'RUN ' >> "${scratch_file}"
  # shellcheck disable=SC2016
  {
    printf 'if [ "${%s:-0}" -eq 1 ]; then\n' "${env}"
    name_lower="$(printf '%s' "${name}" | tr '[:upper:]' '[:lower:]')"
    printf '  SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'"'"'/%s/%s/setup.sh'"'"'\n' "${location}" "${name_lower}"
    printf '  export SCRIPT_NAME\n'
    printf '  # shellcheck disable=SC1090\n'
    printf '  . "${SCRIPT_NAME}"\n'
    printf 'fi\n\n'
  } | tee -a "${scratch_file}" "${install_file}" >/dev/null
}

# parse the "name" field
parse_name() {
    name="$(jq -r '.name' "${JSON_FILE}")"
    rc="$?"
    export name
    return "${rc}"
}

# parse the "description" field
parse_description() {
    description="$(jq -r '.description // empty' "${JSON_FILE}")"
    rc="$?"
    export description
    return "${rc}"
}

# parse the "version" field
parse_version() {
    version="$(jq -r '.version // empty' "${JSON_FILE}")"
    rc="$?"
    export version
    return "${rc}"
}

# parse the "url" field
parse_url() {
    url="$(jq -r '.url // empty' "${JSON_FILE}")"
    rc="$?"
    export url
    return "${rc}"
}

# parse the "license" field
parse_license() {
    license="$(jq -r '.license // empty' "${JSON_FILE}")"
    rc="$?"
    export license
    return "${rc}"
}

parse_scripts_root() {
    scripts_root="$(jq -r '.scripts_root' "${JSON_FILE}")"
    rc="$?"
    export scripts_root
    if [ -d "${scripts_root}" ]; then
      SCRIPT_ROOT_DIR="${scripts_root}"
      export SCRIPT_ROOT_DIR
    fi
    if [ "${verbose}" -ge 3 ]; then
      printf 'Scripts Root: %s\n' "${scripts_root}"
    fi
    return "${rc}"
}

parse_wwwroot() {
    jq -c '.wwwroot[]?' "${JSON_FILE}" | while read -r www_item; do
        parse_wwwroot_item "${www_item}"
    done
}

parse_wwwroot_item() {
    www_json="${1}"
    name=$(printf '%s' "${www_json}" | jq -r '.name')
    path=$(printf '%s' "${www_json}" | jq -r '.path // empty')
    env=$(printf '%s' "${www_json}" | jq -r '.env')
    listen=$(printf '%s' "${www_json}" | jq -r '.listen // empty')
    https_provider=$(printf '%s' "${www_json}" | jq -r '.https.provider // empty')
    vendor='nginx' # only supported one now

    if [ "${wwwroot_header_req}" -lt 1 ]; then
        wwwroot_header_req=1
        printf '\n' >> "${false_env_file}"
        # shellcheck disable=SC2059
        printf "${header_tpl}" '      WWWROOT(s)      ' | tee -a "${install_file}" "${install_parallel_file}" "${true_env_file}" "${false_env_file}" >/dev/null
    fi
    # shellcheck disable=SC2003
    wwwroot_len=$(expr "${wwwroot_len}" + 1)

    # shellcheck disable=SC2016
    printf '( \n' >> "${install_parallel_file}"
    printf 'export %s="${%s:-1}"\n' "${env}" "${env}" | tee -a "${install_parallel_file}" "${true_env_file}" >/dev/null
    printf 'export %s=0\n' "${env}" >> "${false_env_file}"

    if [ "${verbose}" -ge 3 ]; then
      printf 'wwwroot Item:\n'
      printf '  Name: %s\n' "${name}"
    fi
    # clean_name="$(printf '%s' "${name}" | tr -c '^[:alpha:]+_+[:alnum:]' '_')"
    printf 'RUN ' >> "${wwwroot_scratch_file}"
    {
      # shellcheck disable=SC2016
      printf 'if [ "${%s:-0}" -eq 1 ]; then\n' "${env}"
      printf '  WWWROOT_NAME='"'"'%s'"'"'\n' "${name}"
      printf '  WWWROOT_VENDOR='"'"'%s'"'"'\n' "${vendor}"
      printf '  WWWROOT_PATH='"'"'%s'"'"'\n' "${path:-/}"
      printf '  WWWROOT_LISTEN='"'"'%s'"'"'\n' "${listen:-80}"
    } | tee -a "${install_file}" "${wwwroot_scratch_file}" >/dev/null
    if [ "${verbose}" -ge 3 ] && [ -n "${path}" ]; then printf '  Path: %s\n' "${path}"; fi
    if [ -n "${https_provider}" ]; then
      printf '  WWWROOT_HTTPS_PROVIDER='"'"'%s'"'"'\n' "${https_provider}" >> "${install_file}"
      if [ "${verbose}" -ge 3 ]; then printf '  HTTPS Provider: %s\n' "${https_provider}"; fi
    fi
    {
      # shellcheck disable=SC2016
      printf '  if [ "${WWWROOT_VENDOR:-nginx}" = '"'"'nginx'"'"' ]; then\n'

      # shellcheck disable=SC2016
      printf '    SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'"'"'/_server/nginx/setup.sh'"'"'\n'
      printf '    export SCRIPT_NAME\n'
      printf '    # shellcheck disable=SC1090\n'
      # shellcheck disable=SC2016
      printf '    . "${SCRIPT_NAME}"\n'

      printf '  fi\n'
      printf 'fi\n\n'
    } | tee -a "${install_file}" "${wwwroot_scratch_file}" >/dev/null
    # shellcheck disable=SC2059
    printf "${run_tpl}"' ) &\n\n' 'install_gen.sh' >> "${install_parallel_file}"

    parse_wwwroot_builders "${www_json}"
}

# parse "builder" array within a "wwwroot" item
parse_wwwroot_builders() {
    www_json="${1}"
    printf '%s' "${www_json}" | jq -c '.builder[]?' | {
      while read -r builder_item; do
        parse_builder_item "${builder_item}"
      done
      if [ "${wwwroot_len}" -ge 1 ]; then
        printf 'wait\n\n' >> "${install_parallel_file}"
      fi
    }
}

# parse a builder item
parse_builder_item() {
    builder_json="${1}"
    shell=$(printf '%s' "${builder_json}" | jq -r '.shell // "*"' )
    if [ "${verbose}" -ge 3 ]; then
      printf '  Builder:\n'
      printf '    Shell: %s\n' "${shell}"

      printf '    Commands:\n'
    fi
    printf '%s' "${builder_json}" | jq -r '.commands[]' | while read -r cmd; do
        if [ "${verbose}" -ge 3 ]; then
          printf '      %s\n' "${cmd}"
        fi
    done

    outputs=$(printf '%s' "${builder_json}" | jq -c '.output[]?')
    if [ -n "${outputs}" ]; then
        if [ "${verbose}" -ge 3 ]; then printf '    Outputs:\n'; fi
        printf '%s' "${builder_json}" | jq -r '.output[]' | while read -r out; do
            if [ "${verbose}" -ge 3 ]; then printf '      %s\n' "${out}"; fi
        done
    fi
}

# parse "dependencies" field
parse_dependencies() {
    parse_dependency_group '.dependencies.required' 'Required'
    parse_dependency_group '.dependencies.optional' 'Optional'
}

# parse a dependency group (required|optional)
parse_dependency_group() {
    dep_group_query="${1}"
    dep_group_name="${2}"
    if [ "${verbose}" -ge 3 ]; then printf '%s Dependencies:\n' "${dep_group_name}"; fi

    parse_toolchains "${dep_group_query}"'.toolchains' "${dep_group_name}"
    parse_databases "${dep_group_query}"'.databases' "${dep_group_name}"
    parse_servers "${dep_group_query}"'.servers' "${dep_group_name}"
}

# parse "toolchains" array
parse_toolchains() {
    tc_query="${1}"
    dep_group_name="${2}"
    jq -c "${tc_query}"'[]?' "${JSON_FILE}" |
    {
        while read -r tc_item; do
          parse_toolchain_item "${tc_item}" "${dep_group_name}"
        done
        if [ "${toolchains_len}" -ge 1 ]; then
          printf 'wait\n\n' >> "${install_parallel_file}"
        fi
    }
}

# parse a single toolchain item
parse_toolchain_item() {
    tc_json="${1}"
    name=$(printf '%s' "${tc_json}" | jq -r '.name')
    version=$(printf '%s' "${tc_json}" | jq -r '.version')
    env=$(printf '%s' "${tc_json}" | jq -r '.env')
    dep_group_name="${2}"

    if [ "${verbose}" -ge 3 ]; then
      printf '  Toolchain:\n'
      printf '    Name: %s\n' "${name}"
      printf '    Version: %s\n' "${version}"
      printf '    Env: %s\n' "${env}"
    fi

    if [ "${dep_group_name}" = "Required" ] ; then
        if [ "${toolchains_header_req}" -lt 1 ]; then
          toolchains_header_req=1
          printf '\n' >> "${false_env_file}"
          # shellcheck disable=SC2059
          printf "${header_tpl}" 'Toolchain(s) [required]' | tee -a "${install_file}" "${install_parallel_file}" "${true_env_file}" "${false_env_file}" >/dev/null
          # shellcheck disable=SC2059
          printf "${run_tpl}"'\n\n' 'false_env.sh' >> "${install_parallel_file}"
        fi
    elif [ "${toolchains_header_opt}" -lt 1 ]; then
        toolchains_header_opt=1
        printf '\n' >> "${false_env_file}"
        # shellcheck disable=SC2059
        printf "${header_tpl}" 'Toolchain(s) [optional]' | tee -a "${install_file}" "${install_parallel_file}" "${true_env_file}" "${false_env_file}" >/dev/null
        # shellcheck disable=SC2059
        if [ "${all_deps}" -ge 0 ]; then printf "${run_tpl}"'\n\n' 'false_env.sh' >> "${install_parallel_file}" ; fi
    fi
    # shellcheck disable=SC2003
    toolchains_len=$(expr "${toolchains_len}" + 1)
    update_generated_files "${name}" "${version}" "${env}" '_lib/_toolchain' "${dep_group_name}"
}

# parse "databases" array
parse_databases() {
    db_query="${1}"
    dep_group_name="${2}"
    jq -c "${db_query}"'[]?' "${JSON_FILE}" | {
      while read -r db_item; do
        parse_database_item "${db_item}" "${dep_group_name}"
      done
      if [ "${databases_len}" -ge 1 ]; then
        printf 'wait\n\n' >> "${install_parallel_file}"
      fi
    }
}

# parse a single database item
parse_database_item() {
    db_json="${1}"
    dep_group_name="${2}"
    name=$(printf '%s' "${db_json}" | jq -r '.name')
    version=$(printf '%s' "${db_json}" | jq -r '.version')
    env=$(printf '%s' "${db_json}" | jq -r '.env')
    target_env=$(printf '%s' "${db_json}" | jq -c '.target_env[]?')

    if [ "${verbose}" -ge 3 ]; then
      printf '  Database:\n'
      printf '    Name: %s\n' "${name}"
      printf '    Version: %s\n' "${version}"
      printf '    Env: %s\n' "${env}"
    fi

    if [ "${dep_group_name}" = "Required" ] ; then
        if [ "${databases_header_req}" -lt 1 ]; then
          databases_header_req=1
          # shellcheck disable=SC2059
          printf "${header_tpl}" 'Database(s) [required]' | tee -a "${install_file}" "${install_parallel_file}" >/dev/null

          # shellcheck disable=SC2059
          printf "${run_tpl}"'\n\n' 'false_env.sh' >> "${install_parallel_file}"
        fi
    elif [ "${databases_header_opt}" -lt 1 ]; then
        databases_header_opt=1
        printf '\n' >> "${false_env_file}"
        # shellcheck disable=SC2059
        printf "${header_tpl}" 'Database(s) [optional]' | tee -a "${install_file}" "${install_parallel_file}" "${true_env_file}" "${false_env_file}" >/dev/null
        # shellcheck disable=SC2059
        if [ "${all_deps}" -ge 0 ]; then printf "${run_tpl}"'\n\n' 'false_env.sh' >> "${install_parallel_file}" ; fi
    fi

    # shellcheck disable=SC2003
    databases_len=$(expr "${databases_len}" + 1)

    update_generated_files "${name}" "${version}" "${env}" '_lib/_storage' "${dep_group_name}"
    if [ -n "${target_env}" ]; then
        if [ "${verbose}" -ge 3 ]; then printf '    Target Env:\n'; fi

        printf '%s' "${db_json}" | jq -r '.target_env[]' | while read -r env_var; do
            if [ "${verbose}" -ge 3 ]; then printf '      %s\n' "${env_var}"; fi
        done
    fi
}

# parse "servers" array
parse_servers() {
    server_query="${1}"
    dep_group_name="${2}"
    jq -c "${server_query}"'[]?' "${JSON_FILE}" | while read -r server_item; do
        parse_server_item "${server_item}" "${dep_group_name}"
        if [ "${servers_len}" -ge 1 ]; then
            printf 'wait\n\n' >> "${install_parallel_file}"
        fi
    done
}

# parse a single server item
parse_server_item() {
    server_json="${1}"
    dep_group_name="${2}"
    name=$(printf '%s' "${server_json}" | jq -r '.name // empty')
    location=$(printf '%s' "${server_json}" | jq -r '.location // empty')

    if [ "${verbose}" -ge 3 ]; then printf '  Server:\n'; fi
    if [ -n "${name}" ]; then
      if [ "${servers_header_req}" -lt 1 ]; then
        servers_header_req=1
        # shellcheck disable=SC2059
        printf "${header_tpl}" 'Server(s) [required]' | tee -a "${install_file}" "${install_parallel_file}" "${true_env_file}" "${false_env_file}" >/dev/null

        # shellcheck disable=SC2059
        printf "${run_tpl}"'\n\n' 'false_env.sh' >> "${install_parallel_file}"
      fi
      if [ "${verbose}" -ge 3 ]; then printf '    Name: %s\n' "${name}"; fi
      name_upper="$(printf '%s' "${name}" | tr '[:lower:]' '[:upper:]')"
      update_generated_files "${name}" '*' "${name_upper}" 'app/third_party' "${dep_group_name}"
    fi
    if [ "${verbose}" -ge 3 ] && [ -n "${location}" ]; then printf '    Location: %s\n' "${location}"; fi

    parse_server_builders "${server_json}"
    parse_daemon "${server_json}"
}

# parse "builder" array within a server
parse_server_builders() {
    server_json="${1}"
    printf '%s' "${server_json}" | jq -c '.builder[]?' | while read -r builder_item; do
        parse_builder_item "${builder_item}"
    done
}

# parse "daemon" field within a server
parse_daemon() {
    server_json="${1}"
    daemon_json=$(printf '%s' "${server_json}" | jq -c '.daemon // empty')
    if [ -n "${daemon_json}" ]; then
        os_native=$(printf '%s' "${daemon_json}" | jq -r '.os_native')
        if [ "${verbose}" -ge 3 ]; then
          printf '    Daemon:\n'
          printf '      OS Native: %s\n' "${os_native}"
        fi

        env_vars=$(printf '%s' "${daemon_json}" | jq -c '.env[]?')
        if [ -n "${env_vars}" ]; then
            if [ "${verbose}" -ge 3 ]; then printf '      Env Vars:\n'; fi
            printf '%s' "${daemon_json}" | jq -r '.env[]' | while read -r env_var; do
                if [ "${verbose}" -ge 3 ]; then printf '        %s\n' "${env_var}"; fi
            done
        fi
    fi
}

# parse "log_server" field
parse_log_server() {
    optional=$(jq -r '.log_server.optional // empty' "${JSON_FILE}")
    if [ -n "${optional}" ]; then
        if [ "${verbose}" -ge 3 ]; then
          printf 'Log Server:\n'
          printf '  Optional: %s\n' "${optional}"
        fi
    fi
}

# check required fields based on the schema.
# Could use a proper json-schema validator instead…
check_required_fields() {
    missing_fields=""

    # Required fields at the root level
    required_root_fields='["name", "scripts_root", "dependencies"]'

    for field in $(printf '%s' "${required_root_fields}" | jq -r '.[]'); do
        value=$(jq -r ".${field} // empty" "${JSON_FILE}")
        if [ -z "${value}" ]; then
            missing_fields="${missing_fields} ${field}"
        fi
    done

    if [ -n "${missing_fields}" ]; then
        >&2 printf 'Error: Missing required field(s): %s\n' "${missing_fields}"
        exit 1
    fi
}

# Main function
parse_json() {
    JSON_FILE="${1}"

    check_required_fields

    parse_name
    parse_description || true
    parse_version || true
    parse_url || true
    parse_license || true

    if [ "${verbose}" -ge 3 ]; then
      printf 'Name: %s\n' "${name}"
      if [ -n "${description}" ]; then printf 'Description: %s\n' "${description}" ; fi
      if [ -n "${version}" ]; then printf 'Version: %s\n' "${version}" ; fi
      if [ -n "${url}" ]; then printf 'URL: %s\n' "${url}" ; fi
      if [ -n "${license}" ]; then printf 'License: %s\n' "${license}" ; fi
    fi

    parse_scripts_root

    parse_dependencies
    parse_wwwroot
    parse_log_server

    docker_s="$(cat -- "${docker_scratch_file}"; printf 'a')"
    docker_s="${docker_s%a}"

    for image in ${base}; do
      image_no_tag="$(printf '%s' "${image}" | cut -d ':' -f1)"
      dockerfile="${output_folder}"'/'"${image_no_tag}"'.Dockerfile'
      for section in "${toolchain_scratch_file}" "${storage_scratch_file}" \
                     "${server_scratch_file}" "${wwwroot_scratch_file}"; do
        docker_sec="$(cat -- "${section}"; printf 'a')"
        docker_sec="${docker_sec%a}"
        scratch2key "${section}"
        dockerfile_by_section="${output_folder}"'/'"${image_no_tag}"'.'"${res}"'.Dockerfile'
        if [ ! -f "${dockerfile_by_section}" ]; then
          add_missing_line_continuation "${section}" "${section}"'.tmp'
          mv "${section}"'.tmp' "${section}"
          sec_contents="$(cat -- "${section}"; printf 'a')"
          sec_contents="${sec_contents%a}"
          env -i BODY="${sec_contents}" ENV="${docker_sec}" image="${image}" SCRIPT_NAME='${SCRIPT_NAME}' \
                    "$(which envsubst)" < "${SCRIPT_ROOT_DIR}"'/Dockerfile.no_body.tpl' > "${dockerfile_by_section}"
        fi
      done

      if [ ! -f "${dockerfile}" ]; then
        # shellcheck disable=SC2016
        env -i ENV="${docker_s}" image="${image}" SCRIPT_NAME='${SCRIPT_NAME}' \
          "$(which envsubst)" < "${SCRIPT_ROOT_DIR}"'/Dockerfile.tpl' > "${dockerfile}"
      fi
    done
    rm "${docker_scratch_file}" "${toolchain_scratch_file}" "${storage_scratch_file}" \
       "${server_scratch_file}" "${wwwroot_scratch_file}"
}
