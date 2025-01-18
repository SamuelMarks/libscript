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
false_env_cmd_file="${output_folder}"'/false_env.cmd'
true_env_file="${output_folder}"'/env.sh'
true_env_cmd_file="${output_folder}"'/env.cmd'
install_file="${output_folder}"'/install_gen.sh'
install_cmd_file="${output_folder}"'/install_gen.cmd'
install_parallel_file="${output_folder}"'/install_parallel_gen.sh'
docker_scratch_file="${output_folder}"'/docker.tmp'
toolchain_scratch_file="${output_folder}"'/toolchain.tmp'
storage_scratch_file="${output_folder}"'/storage.tmp'
server_scratch_file="${output_folder}"'/database.tmp'
wwwroot_scratch_file="${output_folder}"'/wwwroot.tmp'
third_party_scratch_file="${output_folder}"'/third_party.tmp'
_lib_folder="${output_folder}"'/_lib'
app_folder="${output_folder}"'/app'

base="${BASE:-alpine:latest debian:bookworm-slim}"

[ -d "${output_folder}"'/dockerfiles' ] || mkdir -p "${output_folder}"'/dockerfiles'
prelude="$(cat -- "${SCRIPT_ROOT_DIR}"'/prelude.sh'; printf 'a')"
prelude="${prelude%a}"
if [ ! -f "${install_file}" ]; then printf '%s\n\n' "${prelude}" > "${install_file}" ; fi
# shellcheck disable=SC2016
if [ ! -f "${install_parallel_file}" ]; then printf '%s\nDIR=$(CDPATH='"''"' cd -- "$(dirname -- "${this_file}")" && pwd)\n\n' "${prelude}"  > "${install_parallel_file}" ; fi
if [ ! -f "${true_env_file}" ]; then printf '#!/bin/sh\n\n' > "${true_env_file}" ; fi
if [ ! -f "${false_env_file}" ]; then printf '#!/bin/sh\n' > "${false_env_file}" ; fi
if [ ! -e "${_lib_folder}" ]; then cp -r "${SCRIPT_ROOT_DIR}"'/_lib' "${_lib_folder}" ; fi
if [ ! -e "${app_folder}" ]; then cp -r "${SCRIPT_ROOT_DIR}"'/app' "${app_folder}" ; fi

chmod +x "${false_env_file}" "${true_env_file}" \
  "${install_file}" "${install_parallel_file}"

print_header() {
  name="${1}"
  prefix="${2:-}"
  i=${#name}
  # shellcheck disable=SC2003
  i="$(expr "${i}" + 2)"
  leading='#'
  for _ in $(seq "${i}" 0); do
    leading="${leading}"'#'
  done
  printf '%s%s\n%s# %s #\n%s%s\n' "${prefix}" "${leading}" "${prefix}" "${name}" "${prefix}" "${leading}"
}

# shellcheck disable=SC2016
run_tpl='SCRIPT_NAME="${DIR}"'"'"'/%s'"'"'\nexport SCRIPT_NAME\n# shellcheck disable=SC1090\n. "${SCRIPT_NAME}"'
prelude_cmd='SET "SCRIPT_ROOT_DIR=%~dp0"
SET "SCRIPT_ROOT_DIR=%SCRIPT_ROOT_DIR:~0,-1%"

:: Initialize STACK variable
IF NOT DEFINED STACK (
   SET "STACK=;%~nx0;"
) ELSE (
   SET "STACK=%STACK%%~nx0;"
)

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

SET "searchVal=;%this_file%;"
IF NOT x!str1:%searchVal%=!"=="x%str1% (
 ECHO [STOP]     processing "%this_file%"
 SET ERRORLEVEL=0
 GOTO end
) ELSE (
 ECHO [CONTINUE] processing "%this_file%"
)'
end_prelude_cmd='ENDLOCAL

:end
@%COMSPEC% /C exit %ERRORLEVEL% >nul'

if [ ! -f "${install_cmd_file}" ]; then printf '%s\n\n' "${prelude_cmd}" > "${install_cmd_file}"; fi

touch "${docker_scratch_file}" "${toolchain_scratch_file}" \
      "${storage_scratch_file}" "${server_scratch_file}" \
      "${wwwroot_scratch_file}" "${third_party_scratch_file}" \
      "${true_env_cmd_file}" "${false_env_cmd_file}"

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
    '_lib/_server') res='server' ;;
    '_lib/_storage') res='storage' ;;
    'app/third_party') res='third_party' ;;
    '_lib/_toolchain') res='toolchain' ;;
    *) res="${1}" ;;
  esac
  export res
}

key2path() {
  case "${1}" in
    'server') res='_lib/_server' ;;
    'storage') res='_lib/_storage' ;;
    'third_party') res='app/third_party' ;;
    'toolchain') res='_lib/_toolchain' ;;
    *) res="${1}" ;;
  esac
  export res
}

scratch2key() {
  case "${1}" in
    "${server_scratch_file}") res='server' ;;
    "${storage_scratch_file}") res='storage' ;;
    "${third_party_scratch_file}") res='third_party' ;;
    "${toolchain_scratch_file}") res='toolchain' ;;
    "${wwwroot_scratch_file}") res='wwwroot' ;;
    *) res="${1}" ;;
  esac
  export res
}

key2scratch() {
  case "${1}" in
    'server') res="${server_scratch_file}" ;;
    'storage') res="${storage_scratch_file}" ;;
    'third_party') res="${third_party_scratch_file}" ;;
    'toolchain') res="${toolchain_scratch_file}" ;;
    'wwwroot') res="${wwwroot_scratch_file}" ;;
  esac
  export res
}

lang_set() {
  language="${1}"
  var_name="${2}"
  var_value="${3}"

  is_digit=1
  case "${var_value}" in
      ''|*[![:digit:]]*) is_digit=0 ;;
  esac

  case "${language}" in
    'cmd')
      prefix='SET'
      quote='"'
      # shellcheck disable=SC1003
      var_value="$(printf '%s' "${var_value}" | tr '/' '\\')"
      ;;
    'docker')
      prefix='ARG'
      quote="'"
      ;;
    'sh')
      prefix='export'
      quote="'"
      ;;
    *)
      >&2 printf 'Unsupported language: %s\n' "${language}"
      exit 5
      ;;
  esac
  if [ "${is_digit}" -eq 1 ]; then quote=''; fi

  case "${language}" in
    'cmd')
      printf '%s %s=%s%s%s\n' "${prefix}" "${var_name}" "${quote}" "${var_value}" "${quote}"
      ;;
    'docker')
      printf '%s %s=%s%s%s\n' "${prefix}" "${var_name}" "${quote}" "${var_value}" "${quote}"
      ;;
    'sh')
      printf '%s %s=%s%s%s\n' "${prefix}" "${var_name}" "${quote}" "${var_value}" "${quote}"
      ;;
  esac
}

object2key_val() {
  obj="${1}"
  prefix="${2:-}"
  q="${3:-\'}"
  s=''
  if [ "${q}" = '"' ]; then s='=';  fi
  printf '%s' "${obj}" | jq --arg q "${q}" -rc '. | to_entries[] | "'"${prefix}"'"+ .key + if .value == null then "'"${s}"'" else "="+$q+.value+$q end'
}

update_generated_files() {
  name="${1}"
  name_lower="$(printf '%s' "${name}" | tr '[:upper:]' '[:lower:]')"
  name_upper_clean="$(printf '%s' "${name}" | tr '[:lower:]' '[:upper:]' | tr -c '^[:alpha:]+_+[:alnum:]' '_')"
  version="${2:-}"
  env="${3}"
  env_clean="$(printf '%s' "${env}" | tr -c '^[:alpha:]+_+[:alnum:]' '_')"
  location="${4}"
  dep_group_name="${5}"
  extra_before_str="${6:-}"
  alt_if_body="${7:-}"
  alt_if_body_cmd="${8:-}"
  extra_env_vars_as_json="${9:-}"

  path2key "${location}"
  key2scratch "${res}"
  scratch_file="${res}"

  scratch="$(mktemp)"
  required=0
  if [ "${dep_group_name}" = 'Required' ] || [ "${all_deps}" -eq 1 ]; then
    required=1
  fi

  {
    # shellcheck disable=SC2016
    printf '(\n  ' >> "${install_parallel_file}"
    for f in "${docker_scratch_file}" "${scratch_file}" "${scratch}"; do
      if ! grep -Fvq -- "${extra_before_str}" "${f}"; then
        printf '%s\n' "${extra_before_str}" >> "${f}"
      fi
    done

    if [ "${required}" -eq 1 ]; then
      printf 'IF NOT DEFINED %s ( SET %s=1 )\n' "${env_clean}" "${env_clean}" >> "${install_cmd_file}"
      lang_set 'cmd' "${env_clean}" '1' >> "${true_env_cmd_file}"
      lang_set 'docker' "${env_clean}" '1' | tee -a "${docker_scratch_file}" "${scratch_file}" "${scratch}" >/dev/null
      lang_set 'sh' "${env_clean}" '1'
      export default_val=1
    else
      printf 'IF NOT DEFINED "%s" ( SET %s=0 )\n' "${env_clean}" "${env_clean}" >> "${install_cmd_file}"
      lang_set 'cmd' "${env_clean}" '0' >> "${false_env_cmd_file}"
      lang_set 'docker' "${env_clean}" '0' | tee -a "${docker_scratch_file}" "${scratch_file}" "${scratch}" >/dev/null
      lang_set 'sh' "${env_clean}" '0'
      export default_val=0
    fi
    if [ -n "${extra_env_vars_as_json}" ] && [ ! "${extra_env_vars_as_json}" = 'null' ] ; then
      object2key_val "${extra_env_vars_as_json}" 'ARG ' "'" | tee -a "${docker_scratch_file}" "${scratch_file}" "${scratch}" >/dev/null
      object2key_val "${extra_env_vars_as_json}" 'export ' "'" # TODO: Use default value here on `install_parallel_file`
      object2key_val "${extra_env_vars_as_json}" 'SET ' '"' >> "${true_env_cmd_file}"
    fi
    if [ -n "${version}" ]; then
      lang_set 'cmd' "${name_upper_clean}"'_VERSION' "${version}" >> "${true_env_cmd_file}"
      lang_set 'docker' "${name_upper_clean}"'_VERSION' "${version}" | tee -a "${docker_scratch_file}" "${scratch_file}" "${scratch}" >/dev/null
      lang_set 'sh' "${name_upper_clean}"'_VERSION' "${version}"
    fi
  } | tee -a "${install_parallel_file}" "${true_env_file}" >/dev/null
  # shellcheck disable=SC2059
  printf "${run_tpl}"' ) &\n' 'install_gen.sh' >> "${install_parallel_file}"
  lang_set 'cmd' "${env_clean}" '0' >> "${false_env_cmd_file}"
  lang_set 'sh' "${env_clean}" '0' >> "${false_env_file}"

  printf '\n' | tee -a "${install_parallel_file}" "${true_env_file}" "${true_env_cmd_file}" \
                       "${docker_scratch_file}" "${scratch_file}" "${scratch}" \
                       "${false_env_cmd_file}" "${false_env_file}" >/dev/null

  printf 'RUN <<-EOF\n\n' | tee -a "${scratch_file}" "${scratch}" >/dev/null
  # shellcheck disable=SC2016
  {
    printf 'if [ "${%s:-%d}" -eq 1 ]; then\n' "${env_clean}" "${required}" | tee -a "${scratch_file}" "${scratch}" "${install_file}" >/dev/null
    if [ -n "${alt_if_body}" ]; then
      printf '%s\n' "${alt_if_body}"
    else
      printf '  SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'"'"'/%s/%s/setup.sh'"'"'\n' "${location}" "${name_lower}"
      printf '  export SCRIPT_NAME\n'
      printf '  # shellcheck disable=SC1090\n'
      printf '  . "${SCRIPT_NAME}"\n'
      printf 'fi\n\n'
   fi
  } | tee -a "${scratch_file}" "${scratch}" "${install_file}" >/dev/null
  printf 'EOF\n\n\n' | tee -a "${scratch_file}" "${scratch}" >/dev/null

  {
    # shellcheck disable=SC1003
    location_win=$(printf '%s' "${location}" | tr '/' '\\')
    printf 'IF "%%'
    printf '%s%%%s' "${env_clean}" '"==1 ('
    if [ -n "${alt_if_body_cmd}" ]; then
      printf '\n%s\n' "${alt_if_body_cmd}"
    fi
    # shellcheck disable=SC2183
    printf '
  SET "SCRIPT_NAME=%%SCRIPT_ROOT_DIR%%'
    printf '\%s\%s\setup.cmd"' "${location_win}" "${name_lower}"
  # shellcheck disable=SC2183
  printf '\n  IF NOT EXIST "%%SCRIPT_NAME%%" (
    >&2 ECHO File not found "%%SCRIPT_NAME%%"
    SET ERRORLEVEL=2
    GOTO end
  )
  CALL "%%SCRIPT_NAME%%"
)\n\n'
  } >> "${install_cmd_file}"

  scratch_contents="$(cat -- "${scratch}"; printf 'a')"
  scratch_contents="${scratch_contents%a}"
  [ -d "${output_folder}"'/dockerfiles' ] || mkdir "${output_folder}"'/dockerfiles'
  for image in ${base}; do
    image_no_tag="$(printf '%s' "${image}" | cut -d ':' -f1)"
    name_file="${output_folder}"'/dockerfiles/'"${image_no_tag}"'.'"${name_lower}"'.Dockerfile'

    if [ -n "${scratch_contents}" ]; then
      # shellcheck disable=SC2016
      env -i BODY="${scratch_contents}" image="${image}" SCRIPT_NAME='${SCRIPT_NAME}' \
        "$(which envsubst)" < "${SCRIPT_ROOT_DIR}"'/Dockerfile.no_body.tpl' > "${name_file}"
    fi
  done
  rm -f "${scratch}"
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
    name_clean="$(printf '%s' "${name}" | tr -c '^[:alpha:]+_+[:alnum:]' '_')"
    name_upper_clean="$(printf '%s' "${name_clean}" | tr '[:lower:]' '[:upper:]')"
    version=$(printf '%s' "${www_json}" | jq -r '.version // empty')
    path=$(printf '%s' "${www_json}" | jq -r '.path // empty')
    env=$(printf '%s' "${www_json}" | jq -r '.env')
    listen=$(printf '%s' "${www_json}" | jq -r '.listen // empty')
    https_provider=$(printf '%s' "${www_json}" | jq -r '.https.provider // empty')
    vendor='nginx' # only supported one now

    if [ "${wwwroot_header_req}" -eq 0 ]; then
        wwwroot_header_req=1
        printf '\n' >> "${false_env_file}"
        extra_before_str=$(print_header 'WWWROOT(s)' | tee -a "${install_file}" "${install_parallel_file}" "${true_env_file}" "${false_env_file}")
        print_header 'WWWROOT(s)' ':: ' | tee -a "${install_cmd_file}" "${true_env_cmd_file}" "${false_env_cmd_file}" >/dev/null
    fi
    # shellcheck disable=SC2003
    wwwroot_len=$(expr "${wwwroot_len}" + 1)


    lang_set 'cmd' "${env}" '1' >> "${false_env_cmd_file}"

    if [ "${verbose}" -ge 3 ]; then
      printf 'wwwroot Item:\n'
      printf '  Name: %s\n' "${name}"
    fi

    if [ "${verbose}" -ge 3 ] && [ -n "${path}" ]; then printf '  Path: %s\n' "${path}"; fi
    extra=''
    if [ -n "${https_provider}" ]; then
      # shellcheck disable=SC2016
      extra=$(printf '  export WWWROOT_HTTPS_PROVIDER="${WWWROOT_'"${name_clean}"'_HTTPS_PROVIDER:-'"%s"'}"\n\n' "${https_provider}")
      if [ "${verbose}" -ge 3 ]; then printf '  HTTPS Provider: %s\n' "${https_provider}"; fi
    fi
    {
      lang_set 'docker' 'WWWROOT_'"${name_clean}"'_NAME' "${name}"
      lang_set 'docker' 'WWWROOT_'"${name_clean}"'_VENDOR' "${vendor}"
      lang_set 'docker' 'WWWROOT_'"${name_clean}"'_PATH' "${path:-/}"
      lang_set 'docker' 'WWWROOT_'"${name_clean}"'_LISTEN' "${listen:-80}"
    } | tee -a "${wwwroot_scratch_file}" "${docker_scratch_file}" >/dev/null
    alt_if_body=$(
      # shellcheck disable=SC2016
      printf '  export WWWROOT_NAME="${%s:-'"%s"'}"\n' 'WWWROOT_'"${name_clean}"'_NAME' "${name}"
      # shellcheck disable=SC2016
      printf '  export WWWROOT_VENDOR="${%s:-'"%s"'}"\n' 'WWWROOT_'"${name_clean}"'_VENDOR' "${vendor}"
      # shellcheck disable=SC2016
      printf '  export WWWROOT_PATH="${%s:-'"%s"'}"\n' 'WWWROOT_'"${name_clean}"'_PATH' "${path:-/}"
      # shellcheck disable=SC2016
      printf '  export WWWROOT_LISTEN="${%s:-'"%s"'}"\n' "${listen:-80}" 'WWWROOT_'"${name_clean}"'_LISTEN'
      if [ -n "${extra}" ]; then printf '%s\n' "${extra}"; fi

      # shellcheck disable=SC2016
      printf '  export WWWROOT_COMMAND_FOLDER="${%s:-}"\n' 'WWWROOT_'"${name_clean}"'_COMMAND_FOLDER'

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
    )
    alt_if_body_cmd=$(
      printf '  IF NOT DEFINED WWWROOT_NAME ( SET WWWROOT_NAME="%s" )\n' "${name}"
      printf '  IF NOT DEFINED WWWROOT_VENDOR ( SET WWWROOT_VENDOR="%s" )\n' "${vendor}"
      printf '  IF NOT DEFINED WWWROOT_PATH ( SET WWWROOT_PATH="%s" )\n' "${path:-/}"
      printf '  IF NOT DEFINED WWWROOT_LISTEN ( SET WWWROOT_LISTEN="%s" )\n' "${listen:-80}"
    )
    extra_env_vars_as_json="$(parse_wwwroot_builders "${www_json}" "${name_clean}")"
    update_generated_files "${name_upper_clean}" "${version}" "${env}" 'wwwroot' "${dep_group_name}" "${extra_before_str}" "${alt_if_body}" "${alt_if_body_cmd}" "${extra_env_vars_as_json}"
}

# parse "builder" array within a "wwwroot" item
parse_wwwroot_builders() {
    www_json="${1}"
    name="${2}"
    printf '%s' "${www_json}" | jq -c '.builder[]?' | {
      while read -r builder_item; do
        parse_builder_item "${builder_item}" "${name}"
      done
      if [ "${wwwroot_len}" -ge 1 ]; then
        printf 'wait\n\n' >> "${install_parallel_file}"
      fi
    }
}

# parse a builder item
parse_builder_item() {
    builder_json="${1}"
    name="${2}"
    shell=$(printf '%s' "${builder_json}" | jq -r '.shell // "*"' )
    command_folder=$(printf '%s' "${builder_json}" | jq -r '.command_folder // empty' )
    if [ "${verbose}" -ge 3 ]; then
      >&2 printf '  Builder:\n'
      >&2 printf '    Shell: %s\n' "${shell}"

      >&2 printf '    Commands:\n'
    fi

    commands="$(printf '%s' "${builder_json}" | jq -r '.commands[]?')"
    if [ -n "${commands}" ]; then
      printf '%s' "${commands}" | while read -r cmd; do
        if [ "${verbose}" -ge 3 ]; then
          printf '      %s\n' "${cmd}"
        fi
      done
    fi

    if [ -n "${command_folder}" ]; then
      if [ "${verbose}" -ge 3 ]; then
        >&2 printf '      Command_folder: %s\n' "${command_folder}"
      fi
      # Expose to callee by `printf`ing
      printf '{"WWWROOT_%s_COMMAND_FOLDER": "%s"}\n' "${name}" "${command_folder}"
    fi

    outputs=$(printf '%s' "${builder_json}" | jq -c '.output[]?')
    if [ -n "${outputs}" ]; then
        if [ "${verbose}" -ge 3 ]; then >&2 printf '    Outputs:\n'; fi
        printf '%s' "${builder_json}" | jq -r '.output[]' | while read -r out; do
            if [ "${verbose}" -ge 3 ]; then >&2 printf '      %s\n' "${out}"; fi
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
        if [ "${toolchains_header_req}" -eq 0 ]; then
          toolchains_header_req=1
          printf '\n' >> "${false_env_file}"
          extra_before_str=$(print_header 'Toolchain(s) [required]' | tee -a "${install_file}" "${install_parallel_file}" "${true_env_file}" "${false_env_file}")
          print_header 'Toolchain(s) [required]' ':: ' | tee -a "${install_cmd_file}" "${true_env_cmd_file}" "${false_env_cmd_file}" >/dev/null
          # shellcheck disable=SC2059
          printf "${run_tpl}"'\n\n' 'false_env.sh' >> "${install_parallel_file}"
        fi
    elif [ "${toolchains_header_opt}" -eq 0 ]; then
        toolchains_header_opt=1
        printf '\n' >> "${false_env_file}"
        extra_before_str=$(print_header 'Toolchain(s) [optional]' | tee -a "${install_file}" "${install_parallel_file}" "${true_env_file}" "${false_env_file}")
        print_header 'Toolchain(s) [optional]' ':: ' | tee -a "${install_cmd_file}" "${true_env_cmd_file}" "${false_env_cmd_file}" >/dev/null
        # shellcheck disable=SC2059
        if [ "${all_deps}" -eq 0 ]; then printf "${run_tpl}"'\n\n' 'false_env.sh' >> "${install_parallel_file}" ; fi
    fi
    # shellcheck disable=SC2003
    toolchains_len=$(expr "${toolchains_len}" + 1)
    update_generated_files "${name}" "${version}" "${env}" '_lib/_toolchain' "${dep_group_name}" "${extra_before_str}" '' '' ''
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
    secrets=$(printf '%s' "${db_json}" | jq -c '.secrets?')
    extra_before_str=''

    if [ "${verbose}" -ge 3 ]; then
      printf '  Database:\n'
      printf '    Name: %s\n' "${name}"
      printf '    Version: %s\n' "${version}"
      printf '    Env: %s\n' "${env}"
      printf '    Secrets: %s\n' "${secrets}"
    fi

    if [ "${dep_group_name}" = "Required" ] ; then
        if [ "${databases_header_req}" -eq 0 ]; then
          databases_header_req=1
          extra_before_str=$(print_header 'Database(s) [required]' |  tee -a "${install_file}" "${install_parallel_file}" "${true_env_file}" "${false_env_file}")
          print_header 'Database(s) [required]' ':: ' | tee -a "${install_cmd_file}" "${true_env_cmd_file}" "${false_env_cmd_file}" >/dev/null

          # shellcheck disable=SC2059
          printf "${run_tpl}"'\n\n' 'false_env.sh' >> "${install_parallel_file}"
        fi
    elif [ "${databases_header_opt}" -eq 0 ]; then
        databases_header_opt=1
        printf '\n' >> "${false_env_file}"
        extra_before_str=$(print_header 'Database(s) [optional]' | tee -a "${install_file}" "${install_parallel_file}" "${true_env_file}" "${false_env_file}")
        print_header 'Database(s) [optional]' ':: ' | tee -a "${install_cmd_file}" "${true_env_cmd_file}" "${false_env_cmd_file}" >/dev/null
        # shellcheck disable=SC2059
        if [ "${all_deps}" -eq 0 ]; then printf "${run_tpl}"'\n\n' 'false_env.sh' >> "${install_parallel_file}" ; fi
    fi

    # shellcheck disable=SC2003
    databases_len=$(expr "${databases_len}" + 1)

    update_generated_files "${name}" "${version}" "${env}" '_lib/_storage' "${dep_group_name}" "${extra_before_str}" '' '' "${secrets}"
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
    version=$(printf '%s' "${server_json}" | jq -r '.version // empty')
    location=$(printf '%s' "${server_json}" | jq -r '.location // empty')
    dest=$(printf '%s' "${server_json}" | jq -r '.dest // empty')
    extra_env_vars_as_json=''
    name_clean="$(printf '%s' "${name}" | tr -c '^[:alpha:]+_+[:alnum:]' '_')"
    name_upper_clean="$(printf '%s' "${name_clean}" | tr '[:lower:]' '[:upper:]')"

    if [ ! -n "${name}" ]; then
      >&2 printf 'no name for server\n'
      exit 4
    fi

    extra_env_vars_as_json="$(parse_server_builders "${server_json}" "${name_clean}")"

    if [ "${verbose}" -ge 3 ]; then printf '  Server:\n'; fi
    if [ -n "${name}" ]; then
      if [ "${servers_header_req}" -eq 0 ]; then
        servers_header_req=1
        extra_before_str=$(print_header 'Server(s) [required]' | tee -a "${install_file}" "${install_parallel_file}" "${true_env_file}" "${false_env_file}")
        print_header 'Server(s) [required]' ':: ' | tee -a "${install_cmd_file}" "${true_env_cmd_file}" "${false_env_cmd_file}" >/dev/null

        # shellcheck disable=SC2059
        printf "${run_tpl}"'\n\n' 'false_env.sh' >> "${install_parallel_file}"
      else
        extra_before_str=$(print_header 'Server(s) [optional]' | tee -a "${install_file}" "${install_parallel_file}" "${true_env_file}" "${false_env_file}")
        print_header 'Server(s) [optional]' ':: ' | tee -a "${install_cmd_file}" "${true_env_cmd_file}" "${false_env_cmd_file}" >/dev/null
      fi
      if [ "${verbose}" -ge 3 ]; then printf '    Name: %s\n' "${name}"; fi
      name_upper="$(printf '%s' "${name}" | tr '[:lower:]' '[:upper:]')"
      name_upper_clean="$(printf '%s' "${name_upper}" | tr -c '^[:alpha:]+_+[:alnum:]' '_')"
      if [ -n "${dest}" ]; then
        js="$(printf '{"%s_DEST": "%s"}' "${name_upper_clean}" "${dest}")"
        if [ -n "${extra_env_vars_as_json}" ]; then
          extra_env_vars_as_json="$(printf '%s %s' "${extra_env_vars_as_json}" "${js}" | jq -s add)"
        else
          extra_env_vars_as_json="${js}"
        fi
      fi
      update_generated_files "${name}" "${version}" "${name_upper}" 'app/third_party' "${dep_group_name}" "${extra_before_str}" '' '' "${extra_env_vars_as_json}"
    fi
    if [ -n "${dest}" ] && [ "${verbose}" -ge 3 ] ; then
      printf '    Dest: %s\n' "${dest}"
    fi
    if [ "${verbose}" -ge 3 ] && [ -n "${location}" ]; then
      printf '    Location: %s\n' "${location}";
    fi

    parse_daemon "${server_json}"
}

# parse "builder" array within a server
parse_server_builders() {
    server_json="${1}"
    name="${2}"
    printf '%s' "${server_json}" | jq -c '.builder[]?' | while read -r builder_item; do
        parse_builder_item "${builder_item}" "${name}"
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

    [ -d "${output_folder}"'/dockerfiles' ] || mkdir "${output_folder}"'/dockerfiles'
    for image in ${base}; do
      image_no_tag="$(printf '%s' "${image}" | cut -d ':' -f1)"
      dockerfile="${output_folder}"'/dockerfiles/'"${image_no_tag}"'.Dockerfile'
      for section in "${toolchain_scratch_file}" "${storage_scratch_file}" \
                     "${server_scratch_file}" "${wwwroot_scratch_file}" \
                     "${third_party_scratch_file}"; do
        docker_sec="$(cat -- "${section}"; printf 'a')"
        docker_sec="${docker_sec%a}"
        scratch2key "${section}"
        dockerfile_by_section="${output_folder}"'/dockerfiles/'"${image_no_tag}"'.'"${res}"'.Dockerfile'
        if [ ! -f "${dockerfile_by_section}" ] && [ -f "${section}" ]; then
           sec_contents="$(cat -- "${section}"; printf 'a')"
           sec_contents="${sec_contents%a}"
           if [ -n "${sec_contents}" ]; then
             # shellcheck disable=SC2016
             env -i BODY="${sec_contents}" image="${image}" SCRIPT_NAME='${SCRIPT_NAME}' \
               "$(which envsubst)" < "${SCRIPT_ROOT_DIR}"'/Dockerfile.no_body.tpl' > "${dockerfile_by_section}"
           fi
        fi
      done

      if [ ! -f "${dockerfile}" ] && [ -n "${docker_s}" ]; then
        # shellcheck disable=SC2016
        env -i ENV="${docker_s}" image="${image}" SCRIPT_NAME='${SCRIPT_NAME}' \
          "$(which envsubst)" < "${SCRIPT_ROOT_DIR}"'/Dockerfile.tpl' > "${dockerfile}"
      fi
    done

    printf '%s\n\n' "${end_prelude_cmd}" >> "${install_cmd_file}"

    rm "${docker_scratch_file}" "${toolchain_scratch_file}" "${storage_scratch_file}" \
       "${server_scratch_file}" "${wwwroot_scratch_file}" "${third_party_scratch_file}"
}
