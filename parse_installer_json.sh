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

verbose="${verbose:-0}"
all_deps="${all_deps:-0}"

output_folder=${output_folder:-${SCRIPT_ROOT_DIR}/tmp}
false_env_file="${output_folder}"'/false_env.sh'
true_env_file="${output_folder}"'/env.sh'
install_file="${output_folder}"'/install_gen.sh'
[ -d "${output_folder}" ] || mkdir -p "${output_folder}"
prelude="$(cat "${SCRIPT_ROOT_DIR}"'/prelude.sh')"
[ ! -f "${install_file}" ] && printf '%s\n\n' "${prelude}" > "${install_file}"
[ ! -f "${true_env_file}" ] && printf '#!/bin/sh\n\n' > "${true_env_file}"
[ ! -f "${false_env_file}" ] && printf '#!/bin/sh\n\n' > "${false_env_file}"

header_tpl='#############################\n#\t\t%s\t#\n#############################\n\n'
wwwroot_header_req=0
databases_header_req=0
databases_header_opt=0
toolchains_header_req=0
toolchains_header_opt=0

# Extra check in case a different `SCRIPT_ROOT_DIR` is found in the JSON
if ! command -v jq >/dev/null 2>&1; then
  SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_lib/_toolchain/jq/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
fi

update_generated_files() {
  name="${1}"
  version="${2}"
  env="${3}"
  location="${4}"
  dep_group_name="${5}"

  {
    # shellcheck disable=SC2016
    if [ "${dep_group_name}" = 'Required' ] || [ "${all_deps}" -ge 1 ]; then
      printf 'export %s="${%s:-1}"\n' "${env}" "${env}"
    else
      printf 'export %s=0\n' "${env}"
    fi
    printf 'export %s_VERSION='"'"'%s'"'"'\n\n' "${name}" "${version}"
  } >> "${true_env_file}"
  printf 'export %s=0\n' "${env}" >> "${false_env_file}"
  # shellcheck disable=SC2016
  {
    printf 'if [ "${%s:-0}" -eq 1 ]; then\n' "${env}"
    name_lower="$(echo "${name}" | tr '[:upper:]' '[:lower:]')"
    printf '  SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'"'"'/%s/%s/setup.sh'"'"'\n' "${location}" "${name_lower}"
    printf '  export SCRIPT_NAME\n'
    printf '  # shellcheck disable=SC1090\n'
    printf '  . "${SCRIPT_NAME}"\n'
    printf 'fi\n\n'
  } >> "${install_file}"
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

    printf 'export %s="${%s:-1}"\n' "${env}" "${env}" >> "${true_env_file}"
    printf 'export %s=0\n' "${env}" >> "${false_env_file}"

    if [ "${verbose}" -ge 3 ]; then
      printf 'wwwroot Item:\n'
      printf '  Name: %s\n' "${name}"
    fi
    # clean_name="$(printf '%s' "${name}" | tr -c '^[:alpha:]+_+[:alnum:]' '_')"
    {
      if [ "${wwwroot_header_req}" -lt 1 ]; then
          wwwroot_header_req=1
          # shellcheck disable=SC2059
          printf "${header_tpl}" '      WWWROOT(s)      '
      fi
      printf 'if [ "${%s:-0}" -eq 1 ]; then\n' "${env}"
      printf '  WWWROOT_NAME='"'"'%s'"'"'\n' "${name}"
      printf '  WWWROOT_VENDOR='"'"'%s'"'"'\n' "${vendor}"
      printf '  WWWROOT_PATH='"'"'%s'"'"'\n' "${path:-/}"
      printf '  WWWROOT_LISTEN='"'"'%s'"'"'\n' "${listen:-80}"
    } >> "${install_file}"
    [ "${verbose}" -ge 3 ] && [ -n "${path}" ] && printf '  Path: %s\n' "${path}"
    if [ -n "${https_provider}" ]; then
      printf '  WWWROOT_HTTPS_PROVIDER='"'"'%s'"'"'\n' "${https_provider}" >> "${install_file}"
      [ "${verbose}" -ge 3 ] && printf '  HTTPS Provider: %s\n' "${https_provider}"
    fi
    {
      printf '  if [ "${WWWROOT_VENDOR:-nginx}" = '"'"'nginx'"'"' ]; then\n'

      printf '    SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'"'"'/_server/nginx/setup.sh'"'"'\n'
      printf '    export SCRIPT_NAME\n'
      printf '    # shellcheck disable=SC1090\n'
      printf '    . "${SCRIPT_NAME}"\n'

      printf '  fi\n'
      printf 'fi\n\n'
    } >> "${install_file}"

    parse_wwwroot_builders "${www_json}"
}

# parse "builder" array within a "wwwroot" item
parse_wwwroot_builders() {
    www_json="${1}"
    printf '%s' "${www_json}" | jq -c '.builder[]?' | while read -r builder_item; do
        parse_builder_item "${builder_item}"
    done
}

# parse a builder item
parse_builder_item() {
    builder_json="${1}"
    shell=$(printf '%s' "${builder_json}" | jq -r '.shell // "*"' )
    [ "${verbose}" -ge 3 ] && printf '  Builder:\n'
    [ "${verbose}" -ge 3 ] && printf '    Shell: %s\n' "${shell}"

    [ "${verbose}" -ge 3 ] && printf '    Commands:\n'
    printf '%s' "${builder_json}" | jq -r '.commands[]' | while read -r cmd; do
        [ "${verbose}" -ge 3 ] && printf '      %s\n' "${cmd}"
    done

    outputs=$(printf '%s' "${builder_json}" | jq -c '.output[]?')
    if [ -n "${outputs}" ]; then
        [ "${verbose}" -ge 3 ] && printf '    Outputs:\n'
        printf '%s' "${builder_json}" | jq -r '.output[]' | while read -r out; do
            [ "${verbose}" -ge 3 ] && printf '      %s\n' "${out}"
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
    [ "${verbose}" -ge 3 ] && printf '%s Dependencies:\n' "${dep_group_name}"

    parse_databases "${dep_group_query}"'.databases' "${dep_group_name}"
    parse_toolchains "${dep_group_query}"'.toolchains' "${dep_group_name}"
    parse_servers "${dep_group_query}"'.servers' "${dep_group_name}"
}

# parse "databases" array
parse_databases() {
    db_query="${1}"
    dep_group_name="${2}"
    jq -c "${db_query}"'[]?' "${JSON_FILE}" | while read -r db_item; do
        parse_database_item "${db_item}" "${dep_group_name}"
    done
}

# parse a single database item
parse_database_item() {
    db_json="${1}"
    dep_group_name="${2}"
    name=$(printf '%s' "${db_json}" | jq -r '.name')
    version=$(printf '%s' "${db_json}" | jq -r '.version')
    env=$(printf '%s' "${db_json}" | jq -r '.env')
    target_env=$(printf '%s' "${db_json}" | jq -c '.target_env[]?')

    [ "${verbose}" -ge 3 ] && printf '  Database:\n'
    [ "${verbose}" -ge 3 ] && printf '    Name: %s\n' "${name}"
    [ "${verbose}" -ge 3 ] && printf '    Version: %s\n' "${version}"
    [ "${verbose}" -ge 3 ] && printf '    Env: %s\n' "${env}"

    if [ "${dep_group_name}" = "Required" ] && [ "${databases_header_req}" -lt 1 ]; then
        databases_header_req=1
        # shellcheck disable=SC2059
        printf "${header_tpl}" 'Database(s) [required]' >> "${install_file}"
    elif [ "${databases_header_opt}" -lt 1 ]; then
        databases_header_opt=1
        # shellcheck disable=SC2059
        printf "${header_tpl}" 'Database(s) [optional]' >> "${install_file}"
    fi
    update_generated_files "${name}" "${version}" "${env}" '_lib/_storage' "${dep_group_name}"

    if [ -n "${target_env}" ]; then
        [ "${verbose}" -ge 3 ] && printf '    Target Env:\n'
        printf '%s' "${db_json}" | jq -r '.target_env[]' | while read -r env_var; do
            [ "${verbose}" -ge 3 ] && printf '      %s\n' "${env_var}"
        done
    fi
}

# parse "toolchains" array
parse_toolchains() {
    tc_query="${1}"
    dep_group_name="${2}"
    jq -c "${tc_query}"'[]?' "${JSON_FILE}" | while read -r tc_item; do
        parse_toolchain_item "${tc_item}" "${dep_group_name}"
    done
}

# parse a single toolchain item
parse_toolchain_item() {
    tc_json="${1}"
    name=$(printf '%s' "${tc_json}" | jq -r '.name')
    version=$(printf '%s' "${tc_json}" | jq -r '.version')
    env=$(printf '%s' "${tc_json}" | jq -r '.env')
    dep_group_name="${2}"

    [ "${verbose}" -ge 3 ] && printf '  Toolchain:\n'
    [ "${verbose}" -ge 3 ] && printf '    Name: %s\n' "${name}"
    [ "${verbose}" -ge 3 ] && printf '    Version: %s\n' "${version}"
    [ "${verbose}" -ge 3 ] && printf '    Env: %s\n' "${env}"

    if [ "${dep_group_name}" = "Required" ] && [ "${toolchains_header_req}" -lt 1 ]; then
        toolchains_header_req=1
        # shellcheck disable=SC2059
        printf "${header_tpl}" 'Toolchain(s) [required]' >> "${install_file}"
    elif [ "${toolchains_header_opt}" -lt 1 ]; then
        toolchains_header_opt=1
        # shellcheck disable=SC2059
        printf "${header_tpl}" 'Toolchain(s) [optional]' >> "${install_file}"
    fi
    update_generated_files "${name}" "${version}" "${env}" '_lib/_toolchain' "${dep_group_name}"
}

# parse "servers" array
parse_servers() {
    server_query="${1}"
    dep_group_name="${2}"
    jq -c "${server_query}"'[]?' "${JSON_FILE}" | while read -r server_item; do
        parse_server_item "${server_item}" "${dep_group_name}"
    done
}

# parse a single server item
parse_server_item() {
    server_json="${1}"
    dep_group_name="${2}"
    name=$(printf '%s' "${server_json}" | jq -r '.name // empty')
    location=$(printf '%s' "${server_json}" | jq -r '.location // empty')

    [ "${verbose}" -ge 3 ] && printf '  Server:\n'
    [ "${verbose}" -ge 3 ] && [ -n "${name}" ] && printf '    Name: %s\n' "${name}"
    [ "${verbose}" -ge 3 ] && [ -n "${location}" ] && printf '    Location: %s\n' "${location}"

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
        [ "${verbose}" -ge 3 ] && printf '    Daemon:\n'
        [ "${verbose}" -ge 3 ] && printf '      OS Native: %s\n' "${os_native}"

        env_vars=$(printf '%s' "${daemon_json}" | jq -c '.env[]?')
        if [ -n "${env_vars}" ]; then
            [ "${verbose}" -ge 3 ] && printf '      Env Vars:\n'
            printf '%s' "${daemon_json}" | jq -r '.env[]' | while read -r env_var; do
                [ "${verbose}" -ge 3 ] && printf '        %s\n' "${env_var}"
            done
        fi
    fi
}

# parse "log_server" field
parse_log_server() {
    optional=$(jq -r '.log_server.optional // empty' "${JSON_FILE}")
    if [ -n "${optional}" ]; then
        [ "${verbose}" -ge 3 ] && printf 'Log Server:\n'
        [ "${verbose}" -ge 3 ] && printf '  Optional: %s\n' "${optional}"
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
      [ -n "${description}" ] && printf 'Description: %s\n' "${description}"
      [ -n "${version}" ] && printf 'Version: %s\n' "${version}"
      [ -n "${url}" ] && printf 'URL: %s\n' "${url}"
      [ -n "${license}" ] && printf 'License: %s\n' "${license}"
    fi

    parse_scripts_root

    parse_wwwroot
    parse_dependencies
    parse_log_server
}
