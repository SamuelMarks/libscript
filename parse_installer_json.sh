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

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$( CDPATH='' cd -- "$( dirname -- "$( readlink -nf -- "${this_file}" )")" && pwd)}"
export LIBSCRIPT_ROOT_DIR

STACK="${STACK:-:}${this_file}"':'
export STACK

verbose="${verbose:-0}"
all_deps="${all_deps:-0}"
NL='
'

output_folder="${output_folder:-${LIBSCRIPT_ROOT_DIR}/tmp}"
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
third_party_scratch_file="${output_folder}"'/third_party.tmp'
_lib_folder="${output_folder}"'/_lib'
app_folder="${output_folder}"'/app'
global_docker_exports=''

base="${BASE:-alpine:latest debian:bookworm-slim}"

[ -d "${output_folder}"'/dockerfiles' ] || mkdir -p -- "${output_folder}"'/dockerfiles'
prelude="$(cat -- "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh'; printf 'a')"
prelude="${prelude%a}"
if [ ! -f "${install_file}" ]; then printf '%s\n\n' "${prelude}" > "${install_file}" ; fi
# shellcheck disable=SC2016
if [ ! -f "${install_parallel_file}" ]; then printf '%s\nDIR=$(CDPATH='"''"' cd -- "$(dirname -- "${this_file}")" && pwd)\n\n' "${prelude}"  > "${install_parallel_file}" ; fi
if [ ! -f "${true_env_file}" ]; then
  # shellcheck disable=SC2016
  printf '#!/bin/sh\n\n%s\n%s\n\n%s\n%s\n\n' \
    'export LANG="${LANG:-C.UTF-8}"' \
    'export LC_ALL="${LC_ALL:-C.UTF-8}"' \
    'LIBSCRIPT_BUILD_DIR="${LIBSCRIPT_BUILD_DIR:-${TMPDIR:-/tmp}/libscript_build}"' \
    'LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"' > "${true_env_file}"
fi
if [ ! -f "${false_env_file}" ]; then printf '#!/bin/sh\n' > "${false_env_file}" ; fi
if [ ! -e "${_lib_folder}" ]; then cp -r -- "${LIBSCRIPT_ROOT_DIR}"'/_lib' "${_lib_folder}" ; fi
if [ ! -e "${app_folder}" ]; then cp -r -- "${LIBSCRIPT_ROOT_DIR}"'/app' "${app_folder}" ; fi

cp -- "${LIBSCRIPT_ROOT_DIR}"'/prelude.sh' "${output_folder}"'/'

chmod +x "${false_env_file}" "${true_env_file}" \
  "${install_file}" "${install_parallel_file}" \
  "${output_folder}"'/prelude.sh'

# shellcheck disable=SC2016
run_tpl='SCRIPT_NAME="${DIR}"'"'"'/%s'"'"'\nexport SCRIPT_NAME\n# shellcheck disable=SC1090\n. "${SCRIPT_NAME}"'
prelude_cmd='SET "LIBSCRIPT_ROOT_DIR=%~dp0"
SET "LIBSCRIPT_ROOT_DIR=%LIBSCRIPT_ROOT_DIR:~0,-1%"
SET "LIBSCRIPT_DATA_DIR=%LIBSCRIPT_DATA_DIR:~0,-1%"

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
if [ ! -f "${true_env_cmd_file}" ]; then printf '%s\n\n' 'SET "LIBSCRIPT_DATA_DIR=%LIBSCRIPT_DATA_DIR:~0,-1%"' > "${true_env_cmd_file}"; fi

touch -- "${docker_scratch_file}" "${toolchain_scratch_file}" \
         "${storage_scratch_file}" "${server_scratch_file}" \
         "${third_party_scratch_file}" "${false_env_cmd_file}"

toolchains_len=0
toolchains_header_req=0
toolchains_header_opt=0
databases_len=0
databases_header_req=0
databases_header_opt=0
servers_len=0
servers_header_req=0

# Extra check in case a different `LIBSCRIPT_ROOT_DIR` is found in the JSON
if ! command -v jq >/dev/null 2>&1; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_toolchain/jq/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
fi

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

  quote="'"
  case "${language}" in
    'cmd')
      prefix='SET'
      quote='"'
      # shellcheck disable=SC1003
      var_value="$(printf '%s' "${var_value}" | tr '/' '\\')"
      ;;
    'docker')
      prefix='ARG'
      # var_value="$(printf '%s' "${var_value}" | tr "${NL}" '/n')"
      ;;
    'sh') prefix='export' ;;
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
  obj="$1"
  prefix="${2:-}"
  sq="'"
  q="${3:-$sq}"
  null_setter=''
  join_arr_on="${NL}"
  if [ "${prefix}" = 'SET ' ]; then
    null_setter='=';
    join_arr_on=' ';
  fi

  printf '%s' "$obj" | jq --arg null_setter "${null_setter}" \
                          --arg join_arr_on "${join_arr_on}" \
                          --arg lbrace '{' --arg prefix "${prefix}" \
                          --arg q "${q}" --arg sq "${sq}" --arg dq '"' -r '
    # Build the pattern dynamically using $sq and $dq
    ("^(" + "\\\\{" + "|" + $dq + "\\\\{" + "|" + $sq + "\\\\{" + ")") as $pattern_start |
    ("(" + "\\\\}" + "|" + "\\\\}" + $dq + "|" + "\\\\}" + $sq + ")$") as $pattern_end |
    ($pattern_start + ".*" + $pattern_end) as $full_pattern |

    def custom_format(value):
      if value == null then
        $null_setter+""
      elif value | type == "number" then
        "=\(value)"
      elif value | type == "string" then
        if value | any(.; test($full_pattern)) then
          "=" + $q + value + $q
        elif value | any(.; test("^[0-9]+$", $sq, $dq)) then
          "=" + value
        else
          "=" + $q + value + $q
        end
      elif value | type == "array" then
        "=" + $q + (value | join($join_arr_on)) + $q
      elif value | type == "object" then
        "=" + $q + "\(value)" + $q
      else
        "=\(value)"
      end;
    to_entries[] | $prefix+"\(.key)\(custom_format(.value))"
  '
}

add_missing_line_continuation() {
  in_single_quote=0
  in_double_quote=0

  if [ -f "${1}" ]; then
    src="$(cat -- "${1}"; printf 'a')"
    src="${src%a}"
  else
    src="${1}"
  fi
  src_len=${#src}

  eaten=0
  tmp="${src}"
  prev_ch=''
  line=''

  while [ -n "${tmp}" ]; do
    rest="${tmp#?}"
    ch="${tmp%"$rest"}"
    # shellcheck disable=SC2003
    eaten="$(expr "${eaten}" + 1)"
    if [ "${ch}" = "${NL}" ]; then
      continues=$(dc -e "${in_single_quote}"' '"${in_double_quote}"' 0d[+z1<a]dsaxp')
      if [ "${continues}" -ge 1 ]; then
        # shellcheck disable=SC1003
        suffix=' \'
      else
        suffix=''
      fi
      printf '%s%s\n' "${line}" "${suffix}"
      line=''
      ch=''

    elif  # shellcheck disable=SC1003
     [ "${prev_ch}" != '\' ]; then
      case "${ch}" in
        "'")
          if [ "${in_single_quote}" -eq 0 ]; then
            in_single_quote=1
          else
            in_single_quote=0
          fi
          ;;
        '"')
          if [ "${in_double_quote}" -eq 0 ]; then
            in_double_quote=1
          else
            in_double_quote=0
          fi
          ;;
      esac
    fi
    line="${line}${ch}"
    tmp="${rest}"
    prev_ch="${ch}"
  done
  if [ -n "${line}" ]; then
    printf '%s' "${line}"
    line=''
  fi
  if [ "${eaten}" -ne "${src_len}" ]; then
    >&2 printf 'Did not parse all of src: %d != %d\n' "${eaten}" "${src_len}"
    exit 4
  fi
}

update_generated_files() {
  name="${1}"
  name_lower="$(printf '%s' "${name}" | tr '[:upper:]' '[:lower:]')"
  name_clean="$(printf '%s' "${name}" | tr -c '^[:alpha:]+_+[:alnum:]' '_')"
  name_lower_clean="$(printf '%s' "${name_lower}" | tr '[:upper:]' '[:lower:]')"
  name_upper_clean="$(printf '%s' "${name_clean}" | tr '[:lower:]' '[:upper:]')"
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
  trap 'rm -f -- "${scratch}"' EXIT HUP INT QUIT TERM
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
      lang_set 'cmd' "${env_clean}" '0' >> "${false_env_cmd_file}"
      lang_set 'docker' "${env_clean}" '1' | tee -a "${docker_scratch_file}" "${scratch_file}" "${scratch}" >/dev/null
      lang_set 'sh' "${env_clean}" '1'
      lang_set 'sh' "${env_clean}" '0' >> "${false_env_file}"
    else
      printf 'IF NOT DEFINED "%s" ( SET %s=0 )\n' "${env_clean}" "${env_clean}" >> "${install_cmd_file}"
      lang_set 'cmd' "${env_clean}" '0' | tee -a "${true_env_cmd_file}" "${false_env_cmd_file}" >/dev/null
      lang_set 'docker' "${env_clean}" '0' | tee -a "${docker_scratch_file}" "${scratch_file}" "${scratch}" >/dev/null
      lang_set 'sh' "${env_clean}" '0' | tee -a "${false_env_file}"
    fi
    if [ -n "${extra_env_vars_as_json}" ] && [ ! "${extra_env_vars_as_json}" = 'null' ] ; then
      {
        printf '\n'
        out="$(object2key_val "${extra_env_vars_as_json}" 'ARG ' "'")"
        add_missing_line_continuation "${out}"
        #>&2 printf '[out]\n%s\n[/out]' "${out}"
        #printf '%s' "${out}"
        printf '\n'
      } | tee -a "${docker_scratch_file}" "${scratch_file}" "${scratch}" >/dev/null
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

  printf '\n' | tee -a "${install_parallel_file}" "${true_env_file}" "${true_env_cmd_file}" \
                       "${docker_scratch_file}" "${scratch_file}" "${scratch}" \
                       "${false_env_cmd_file}" "${false_env_file}" >/dev/null

  printf 'RUN <<-EOF\n\n' | tee -a "${scratch_file}" "${scratch}" >/dev/null
  # shellcheck disable=SC2016
  {
    printf 'if [ "${%s:-%d}" -eq 1 ]; then\n' "${env_clean}" "${required}" | tee -a "${scratch_file}" "${scratch}" "${install_file}" >/dev/null
    printf '  if [ ! -z "${%s_DEST+x}" ]; then\n' "${name_upper_clean}"
    printf '    previous_wd="$(pwd)"\n'
    printf '    DEST="${%s_DEST}"\n' "${name_upper_clean}"
    printf '    export DEST\n'
    printf '    [ -d "${DEST}" ] || mkdir -p -- "${DEST}"\n'
    printf '    cd -- "${DEST}"\n'
    printf '  fi\n'
    printf '  if [ ! -z "${%s_VARS+x}" ]; then\n' "${name_upper_clean}"
    printf '    export VARS="${%s_VARS}"\n' "${name_upper_clean}"
    printf '  fi\n'
    if [ -n "${alt_if_body}" ]; then
      printf '%s\n' "${alt_if_body}"
    else
      # shellcheck disable=SC2016
      printf '  if [ ! -z "${%s_COMMANDS_BEFORE+x}" ]; then\n' "${name_clean}"
      # shellcheck disable=SC2016
      printf '    SCRIPT_NAME="${LIBSCRIPT_DATA_DIR}"'"'"'/setup_before_%s.sh'"'"'\n' "${name_lower_clean}"
      printf '    export SCRIPT_NAME\n'
      # shellcheck disable=SC2016
      printf '    install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'"'"'/prelude.sh'"'"' "${SCRIPT_NAME}"\n'

      # shellcheck disable=SC2016
      printf '    printf '"'"'%%s'"'"' "${%s_COMMANDS_BEFORE}" >> "${SCRIPT_NAME}"\n' "${name_clean}"
      printf '    # shellcheck disable=SC1090\n'
      # shellcheck disable=SC2016
      printf '    . "${SCRIPT_NAME}"\n'
      printf '  fi\n'

      printf '  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'"'"'/'"'"'"%s"'"'"'/setup.sh'"'"'\n' '${'"${name_clean}"'_COMMAND_FOLDER:-'"${location}/${name_lower}"'}'
      printf '  export SCRIPT_NAME\n'
      printf '  # shellcheck disable=SC1090\n'
      # shellcheck disable=SC2016
      printf '  if [ -f "${SCRIPT_NAME}" ]; then\n'
      # shellcheck disable=SC2016
      printf '    . "${SCRIPT_NAME}";\n'
      printf '  else\n'
      # shellcheck disable=SC2016
      printf '    >&2 printf '"'"'Not found, SCRIPT_NAME of %%s\\n'"'"' "${SCRIPT_NAME}"\n'
      printf '  fi\n'

      printf '  if [ ! -z "${%s_DEST+x}" ]; then cd -- "${previous_wd}"; fi\n' "${name_upper_clean}"
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
  SET "SCRIPT_NAME=%%LIBSCRIPT_ROOT_DIR%%'
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
  [ -d "${output_folder}"'/dockerfiles' ] || mkdir -- "${output_folder}"'/dockerfiles'
  for image in ${base}; do
    image_no_tag="$(printf '%s' "${image}" | cut -d ':' -f1)"
    name_file="${output_folder}"'/dockerfiles/'"${image_no_tag}"'.'"${name_lower}"'.Dockerfile'

    if [ -n "${scratch_contents}" ]; then
      # shellcheck disable=SC2016
      env -i BODY="${global_docker_exports}${scratch_contents}" image="${image}" SCRIPT_NAME='${SCRIPT_NAME}' \
        "$(which envsubst)" < "${LIBSCRIPT_ROOT_DIR}"'/Dockerfile.no_body.tpl' > "${name_file}"
    fi
  done
}

# parse the "name" field
parse_name() {
    name="$(jq -r '.name' "${1}")"
    rc="$?"
    export name
    return "${rc}"
}

# parse the "description" field
parse_description() {
    description="$(jq -r '.description // empty' "${1}")"
    rc="$?"
    export description
    return "${rc}"
}

# parse the "version" field
parse_version() {
    version="$(jq -r '.version // empty' "${1}")"
    rc="$?"
    export version
    return "${rc}"
}

# parse the "url" field
parse_url() {
    url="$(jq -r '.url // empty' "${1}")"
    rc="$?"
    export url
    return "${rc}"
}

# parse the "license" field
parse_license() {
    license="$(jq -r '.license // empty' "${1}")"
    rc="$?"
    export license
    return "${rc}"
}

parse_scripts_root() {
  json_file="${1}"
  scripts_root="$(jq -r '.scripts_root' "${json_file}")"
  rc="$?"
  export scripts_root
  if [ -d "${scripts_root}" ]; then
    LIBSCRIPT_ROOT_DIR="${scripts_root}"
    export LIBSCRIPT_ROOT_DIR
  fi
  if [ "${verbose}" -ge 3 ]; then
    printf 'Scripts Root: %s\n' "${scripts_root}"
  fi
  return "${rc}"
}

parse_build_root() {
  json_file="${1}"
  build_root="$(jq -r '.build_root' "${json_file}")"
  rc="$?"
  export build_root
  LIBSCRIPT_BUILD_DIR="${build_root}"
  export LIBSCRIPT_BUILD_DIR
  if [ "${verbose}" -ge 3 ]; then
    printf 'Build Root: %s\n' "${build_root}"
  fi
  return "${rc}"
}

parse_global_vars() {
  json_file="${1}"
  global_vars="$(jq -r '.global_vars // empty' "${json_file}")"
  rc="$?"
  export global_vars
  if [ -n "${global_vars}" ]; then
    if ! grep -Fvq -- 'Env (explicit)' "${true_env_file}"; then
      print_header 'Env (explicit)' ':: ' >> "${true_env_file}"
    fi
    {
      object2key_val "${global_vars}" 'export ' "'"
      printf '\n'
    } >> "${true_env_file}"

    if ! grep -Fvq -- 'Env (explicit)' "${true_env_file}"; then
      print_header 'Env (explicit)' ':: ' >> "${true_env_cmd_file}"
    fi
    {
      object2key_val "${global_vars}" 'SET ' '"'
      printf '\n'
    } >> "${true_env_cmd_file}"

    global_docker_exports="$(object2key_val "${global_vars}" 'ARG ' "'")${NL}"
    export global_docker_exports
  fi

  if [ "${verbose}" -ge 3 ]; then
    printf 'Global Vars: %s\n' "${global_vars}"
  fi
  return "${rc}"
}

# parse a builder item
parse_builder_item() {
    builder_json="${1}"
    name="${2}"
    prefix="${3:-}"
    shell=$(printf '%s' "${builder_json}" | jq -r '.shell // "*"' )
    command_folder=$(printf '%s' "${builder_json}" | jq -r '.command_folder // empty' )
    if [ "${verbose}" -ge 3 ]; then
      >&2 printf '  Builder:\n'
      >&2 printf '    Shell: %s\n' "${shell}"

      >&2 printf '    Commands before:\n'
    fi

    commands_before="$(printf '%s' "${builder_json}" | jq -r '.commands_before[]?')"
    if [ -n "${commands_before}" ]; then
      printf '%s' "${commands_before}" | while read -r cmd; do
        if [ "${verbose}" -ge 3 ]; then
          >&2 printf '      %s\n' "${cmd}"
        fi
        # >&2 printf '"%s"\n' "${cmd}"
      done
      # Expose to callee by `printf`ing
      commands_before_js="$(printf '%s' "${builder_json}" | jq '.commands_before')"
      printf '{"%s%s_COMMANDS_BEFORE": %s}\n' "${prefix}" "${name}" "${commands_before_js}"
    fi

    if [ -n "${command_folder}" ]; then
      if [ "${verbose}" -ge 3 ]; then
        >&2 printf '      Command_folder: %s\n' "${command_folder}"
      fi
      # Expose to callee by `printf`ing
      printf '{"%s%s_COMMAND_FOLDER": "%s"}\n' "${prefix}" "${name}" "${command_folder}"
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
  json_file="${1}"
  parse_dependency_group "${json_file}" '.dependencies.required' 'Required'
  parse_dependency_group "${json_file}" '.dependencies.optional' 'Optional'
}

# parse a dependency group (required|optional)
parse_dependency_group() {
  json_file="${1}"
  dep_group_query="${2}"
  dep_group_name="${3}"
  if [ "${verbose}" -ge 3 ]; then printf '%s Dependencies:\n' "${dep_group_name}"; fi

  parse_toolchains "${json_file}" "${dep_group_query}"'.toolchains' "${dep_group_name}"
  parse_databases "${json_file}" "${dep_group_query}"'.databases' "${dep_group_name}"
  parse_servers "${json_file}" "${dep_group_query}"'.servers' "${dep_group_name}"
}

# parse "toolchains" array
parse_toolchains() {
  json_file="${1}"
  tc_query="${2}"
  dep_group_name="${3}"
  jq -c "${tc_query}"'[]?' "${json_file}" |
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
  json_file="${1}"
  db_query="${2}"
  dep_group_name="${3}"
  jq -c "${db_query}"'[]?' "${json_file}" | {
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
  vars=$(printf '%s' "${db_json}" | jq -c '.vars?')
  extra_before_str=''

  if [ "${verbose}" -ge 3 ]; then
    printf '  Database:\n'
    printf '    Name: %s\n' "${name}"
    printf '    Version: %s\n' "${version}"
    printf '    Env: %s\n' "${env}"
    printf '    Vars: %s\n' "${vars}"
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

  update_generated_files "${name}" "${version}" "${env}" '_lib/_storage' "${dep_group_name}" "${extra_before_str}" '' '' "${vars}"
  if [ -n "${target_env}" ]; then
    if [ "${verbose}" -ge 3 ]; then printf '    Target Env:\n'; fi

    printf '%s' "${db_json}" | jq -r '.target_env[]' | while read -r env_var; do
      if [ "${verbose}" -ge 3 ]; then printf '      %s\n' "${env_var}"; fi
    done
  fi
}

# parse "servers" array
parse_servers() {
  json_file="${1}"
  server_query="${2}"
  dep_group_name="${3}"
  jq -c "${server_query}"'[]?' "${json_file}" | while read -r server_item; do
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
  vars=$(printf '%s' "${server_json}" | jq -r '.vars // empty')

  extra_env_vars_as_json=''
  name_clean="$(printf '%s' "${name}" | tr -c '^[:alpha:]+_+[:alnum:]' '_')"
  name_upper_clean="$(printf '%s' "${name_clean}" | tr '[:lower:]' '[:upper:]')"

  if [ ! -n "${name}" ]; then
    >&2 printf 'no name for server\n'
    exit 4
  fi
  extra_env_vars_as_json="$(parse_server_builders "${server_json}" "${name_clean}" | jq -n 'reduce inputs as $in (null; . + $in)')"

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
      extra_env_vars_as_json="$(printf '%s %s' "${extra_env_vars_as_json}" "${js}" | jq -n 'reduce inputs as $in (null; . + $in)')"

      if [ "${verbose}" -ge 3 ] ; then
        printf '    Dest: %s\n' "${dest}"
      fi
    fi
    if [ -n "${vars}" ]; then
      js="$(printf '{"%s_VARS": %s}' "${name_upper_clean}" "${vars}")"
      extra_env_vars_as_json="$(printf '%s %s' "${extra_env_vars_as_json}" "${js}" | jq -n 'reduce inputs as $in (null; . + $in)')"

      if [ "${verbose}" -ge 3 ] ; then
        printf '    Vars: %s\n' "${vars}"
      fi
    fi
    update_generated_files "${name}" "${version}" "${name_upper}" 'app/third_party' "${dep_group_name}" "${extra_before_str}" '' '' "${extra_env_vars_as_json}"
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
  optional=$(jq -r '.log_server.optional // empty' "${1}")
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
  json_file="${1}"
  missing_fields=""

  # Required fields at the root level
  required_root_fields='["name", "scripts_root", "dependencies"]'

  for field in $(printf '%s' "${required_root_fields}" | jq -r '.[]'); do
    value=$(jq -r ".${field} // empty" "${json_file}")
    if [ -z "${value}" ]; then
        missing_fields="${missing_fields} ${field}"
    fi
  done

  if [ -n "${missing_fields}" ]; then
    >&2 printf 'Error: Missing required field(s): %s\n' "${missing_fields}"
    exit 1
  fi
}

test_assert_eq() {
  expect="${1}"
  actual="${2}"
  name="${3:-test}"
  if [ "${expect}" = "${actual}" ]; then
    printf '[%s] passed\n' "${name}";
  else
    >&2 printf '[%s] failed "%s" != "%s"\n' "${name}" "${mock0}" "${res}";
    exit 4
  fi
}

test_add_missing_line_continuation() {
  # Test cases
  mock0='foo'
  mock1='bar can'
  mock2='foo="bar
can"'
  mock3='foo=bar
can"'
  # shellcheck disable=SC2016
  mock4='if [ "$x" -eq 1 ]
then
echo "x is 1"
fi'
  # shellcheck disable=SC2016
  mock5='for i in 1 2 3
do
echo $i
done'
  mock6="ARG SADAS_COMMANDS='git_get https://github.com/SamuelMarks/serve-actix-diesel-auth-scaffold
git_get https://github.com/SamuelMarks/serve-actix-diesel-auth-scaffold'"

  # Test 0
  res="$(add_missing_line_continuation "${mock0}")"
  test_assert_eq "${mock0}" "${res}" 'test0'

  # Test 1
  res="$(add_missing_line_continuation "${mock1}")"
  test_assert_eq "${mock1}" "${res}" 'test1'

  # Test 2
  res="$(add_missing_line_continuation "${mock2}")"
  expect='foo="bar \
can"'
  test_assert_eq "${expect}" "${res}" 'test2'

  # Test 3
  res="$(add_missing_line_continuation "${mock3}")"
  expect="${mock3}"
  #test_assert_eq "${expect}" "${res}" 'test3'

  # Test 4 (Handling 'if' statement)
  res="$(add_missing_line_continuation "${mock4}")"
  # shellcheck disable=SC2016
  expect='if [ "$x" -eq 1 ] \
then \
echo "x is 1" \
fi'
  test_assert_eq "${expect}" "${res}" 'test4'

  # Test 5 (Handling 'for' loop)
  res="$(add_missing_line_continuation "${mock5}")"
  # shellcheck disable=SC2016
  expect='for i in 1 2 3 \
do \
echo $i \
done'
  test_assert_eq "${expect}" "${res}" 'test5'

  # Test 6 (Multiline single-quoted string)
  res="$(add_missing_line_continuation "${mock6}")"
  expect="ARG SADAS_COMMANDS='git_get https://github.com/SamuelMarks/serve-actix-diesel-auth-scaffold \
git_get https://github.com/SamuelMarks/serve-actix-diesel-auth-scaffold'"
  test_assert_eq "${expect}" "${res}" 'test6'
}

# Main function
parse_json() {
  # test_add_missing_line_continuation

  json_file="${1}"

  check_required_fields "${json_file}"

  parse_name "${json_file}"
  parse_description "${json_file}" || true
  parse_version "${json_file}" || true
  parse_url "${json_file}" || true
  parse_license "${json_file}" || true

  if [ "${verbose}" -ge 3 ]; then
    printf 'Name: %s\n' "${name}"
    if [ -n "${description}" ]; then printf 'Description: %s\n' "${description}" ; fi
    if [ -n "${version}" ]; then printf 'Version: %s\n' "${version}" ; fi
    if [ -n "${url}" ]; then printf 'URL: %s\n' "${url}" ; fi
    if [ -n "${license}" ]; then printf 'License: %s\n' "${license}" ; fi
  fi

  parse_scripts_root "${json_file}"
  case "${scripts_root}" in
    *'$'*|''|'null') ;;
    *)
      printf 'export LIBSCRIPT_ROOT_DIR='"'"'%s'"'"'\n\n' "${scripts_root}" >> "${true_env_file}"
      ;;
  esac
  parse_build_root "${json_file}"
  case "${build_root}" in
    '$'*|''|'null') ;;
    *)
      printf 'export LIBSCRIPT_BUILD_DIR='"'"'%s'"'"'\n\n' "${build_root}" >> "${true_env_file}"
      ;;
  esac

  tmp0="$(mktemp)"
  awk -- '
    /^#!\/bin\/sh/ {
      if (shebang++) next
    }
    /^export LIBSCRIPT_ROOT_DIR=/ {
      if (export_root++) next
    }
    /^LIBSCRIPT_ROOT_DIR=/ {
      if (root++) next
    }
    /^export LIBSCRIPT_BUILD_DIR=/ {
      if (export_build++) next
    }
    /^LIBSCRIPT_BUILD_DIR=/ {
      if (build++) next
    }
    { print }
  ' "${true_env_file}" > "${tmp0}" && mv "${tmp0}" "${true_env_file}"
  chmod +x "${true_env_file}"

  parse_global_vars "${json_file}"

  parse_dependencies "${json_file}"
  parse_log_server "${json_file}"

  docker_s="$(cat -- "${docker_scratch_file}"; printf 'a')"
  docker_s="${docker_s%a}"

  [ -d "${output_folder}"'/dockerfiles' ] || mkdir -- "${output_folder}"'/dockerfiles'
  for image in ${base}; do
    image_no_tag="$(printf '%s' "${image}" | cut -d ':' -f1)"
    dockerfile="${output_folder}"'/dockerfiles/'"${image_no_tag}"'.Dockerfile'
    for section in "${toolchain_scratch_file}" "${storage_scratch_file}" \
                   "${server_scratch_file}" "${third_party_scratch_file}"; do
      docker_sec="$(cat -- "${section}"; printf 'a')"
      docker_sec="${docker_sec%a}"
      scratch2key "${section}"
      dockerfile_by_section="${output_folder}"'/dockerfiles/'"${image_no_tag}"'.'"${res}"'.Dockerfile'
      if [ ! -f "${dockerfile_by_section}" ] && [ -f "${section}" ]; then
         sec_contents="$(cat -- "${section}"; printf 'a')"
         sec_contents="${sec_contents%a}"
         if [ -n "${sec_contents}" ]; then
           # shellcheck disable=SC2016
           env -i BODY="${global_docker_exports}${sec_contents}" image="${image}" SCRIPT_NAME='${SCRIPT_NAME}' \
             "$(which envsubst)" < "${LIBSCRIPT_ROOT_DIR}"'/Dockerfile.no_body.tpl' > "${dockerfile_by_section}"
         fi
      fi
    done

    if [ ! -f "${dockerfile}" ] && [ -n "${docker_s}" ]; then
      # shellcheck disable=SC2016
      env -i ENV="${global_docker_exports}${docker_s}" image="${image}" SCRIPT_NAME='${SCRIPT_NAME}' \
        "$(which envsubst)" < "${LIBSCRIPT_ROOT_DIR}"'/Dockerfile.tpl' > "${dockerfile}"
    fi
  done

  printf '%s\n\n' "${end_prelude_cmd}" >> "${install_cmd_file}"

  rm -- "${docker_scratch_file}" "${toolchain_scratch_file}" "${storage_scratch_file}" \
        "${server_scratch_file}" "${third_party_scratch_file}"
}
