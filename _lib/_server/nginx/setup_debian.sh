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

run_before=0
STACK="${STACK:-:}"
case "${STACK}" in
  *':'"${this_file}"':'*)
    # printf '[STOP]     processing "%s"\n' "${this_file}"
    run_before=1 ;;
  *)
    printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
STACK="${STACK}${this_file}"':'
export STACK

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/priv.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_os/_apt/apt.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

if [ "${run_before}" -eq 0 ]; then
  apt_depends curl gnupg2 ca-certificates lsb-release debian-archive-keyring
  [ -f '/usr/share/keyrings/nginx-archive-keyring.gpg' ] || \
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
      | "${PRIV}" tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
  [ -f '/etc/apt/sources.list.d/nginx.list' ] || \
    printf 'deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
    http://nginx.org/packages/debian %s nginx\n' "$(lsb_release -cs)" \
      | "${PRIV}" tee /etc/apt/sources.list.d/nginx.list
  [ -f '/etc/apt/preferences.d/99nginx' ] || \
    printf 'Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n' \
      | "${PRIV}" tee /etc/apt/preferences.d/99nginx && \
    "${PRIV}" apt update -qq

  apt_depends nginx
fi

rtrim() {
  trimmed="${1}"
  while :
  do
    case "$trimmed" in
      *[[:space:]] )
          trimmed=${trimmed%?}
          ;;
      * )
          break
          ;;
    esac
  done
  printf '%s' "$trimmed"
}

merge_location_into_nginx_server() {
  conf_existing="${1}"
  location_conf="${2}"

  if [ -z "${conf_existing}" ]; then
    >&2 printf 'Error: conf_existing is empty.\n'
    return 1
  fi

  if [ -z "${location_conf}" ]; then
    >&2 printf 'Error: location_conf is empty.\n'
    return 1
  fi

  if printf '%s' "${conf_existing}" | grep -qF "${location_conf}"; then
    return
  fi
  >&2 printf 'merge_location_into_nginx_server::conf_existing "%s"\n' "${conf_existing}"
  >&2 printf 'merge_location_into_nginx_server::location_conf "%s"\n\n' "${location_conf}"

  rtrimmed_conf=$(rtrim "${conf_existing}")
  printf '%s%s\n}\n' "${rtrimmed_conf%}" "${location_conf}"
  printf 'WHY DOES THIS TEXT NEVER APPEAR\n'
}

if [ ! -z "${VARS+x}" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/environ.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"

  TMP_FILE=$(mktemp -t 'libscript_XXX_tmp')
  ENV_SCRIPT_FILE=$(mktemp -t 'libscript_XXX_env')
  chmod +x "${ENV_SCRIPT_FILE}"
  object2key_val "${VARS}" 'export ' "'" > "${ENV_SCRIPT_FILE}"

  # shellcheck disable=SC1090
  SERVER_NAME="$(. "${ENV_SCRIPT_FILE}"; printf '%s' "${SERVER_NAME}")"

  LOCATION_CONF_FILE=$(mktemp -t 'libscript_'"${SERVER_NAME}"'_XXX_location_conf')

  env -i PATH="${PATH}" \
         ENV_SCRIPT_FILE="${ENV_SCRIPT_FILE}" \
         LIBSCRIPT_BUILD_DIR="${LIBSCRIPT_BUILD_DIR}" \
         LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR}" \
         LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR}" \
         "${DIR}"'/create_location_block.sh' > "${LOCATION_CONF_FILE}"
  location_conf="$(cat -- "${LOCATION_CONF_FILE}"; printf 'a')"
  location_conf="${location_conf%a}"

  # TODO: each location in separate 'fragment'; then merge them into one `server {}`
  # TODO: final thing joins them all to avoid race condition; rather than this next line:

  # TODO: lock file if not implementing "final thing" lifecycle

  site_conf_install_location='/etc/nginx/conf.d/'"${SERVER_NAME}"'.conf'
  if [ -f "${site_conf_install_location}" ]; then
    conf_existing="$(cat -- "${site_conf_install_location}"; printf 'a')"
    conf_existing="${conf_existing%a}"
    if [ ${#conf_existing} -eq 0 ]; then
      >&2 printf 'Existing conf unexpectedly empty at: "%s"\n' "${site_conf_install_location}"
      exit 5
    fi

    out="$(merge_location_into_nginx_server "${conf_existing}" "${location_conf}")"
    merge_location_into_nginx_server "${conf_existing}" "${location_conf}"
    merge_location_into_nginx_server "${conf_existing}" "${location_conf}" > "${TMP_FILE}"
    if [ ${#out} -eq 0 ]; then
      >&2 printf 'merge_location_into_nginx_server result unexpectedly empty\n'
      #exit 5
    fi
    printf '[merge_location_into_nginx_server out] "%s"\n' "${out}"
    printf '%s' "${out}" | sudo dd of="${site_conf_install_location}"
    "${PRIV}" cp "${TMP_FILE}" "${site_conf_install_location}"
    # | "${PRIV}" tee "${site_conf_install_location}" >/dev/null
    printf '#------------AFTER MERGE---------------------#\n'
    cat "${site_conf_install_location}"
  else
    env -i PATH="${PATH}" \
           ENV_SCRIPT_FILE="${ENV_SCRIPT_FILE}" \
           LIBSCRIPT_BUILD_DIR="${LIBSCRIPT_BUILD_DIR}" \
           LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR}" \
           LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR}" \
           LOCATIONS="${location_conf}" \
           "${DIR}"'/create_server_block.sh' | "${PRIV}" dd of="${site_conf_install_location}"
    printf '#############NO MERGE#######################\n'
    cat "${site_conf_install_location}"
    #printf '\n\nsleeping for 10 seconds\n'
    #sleep 10s
  fi

  rm -f "${ENV_SCRIPT_FILE}" "${LOCATION_CONF_FILE}" "${TMP_FILE}"
  unset ENV_SCRIPT_FILE
  unset LOCATION_CONF_FILE
  unset TMP_FILE
fi
