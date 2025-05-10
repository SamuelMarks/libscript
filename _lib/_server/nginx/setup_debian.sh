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

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'

run_before=0
STACK="${STACK:-:}"
case "${STACK}" in
  *':'"${this_file}"':'*)
    # printf '[STOP]     processing "%s"\n' "${this_file}"
    run_before=1 ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

for lib in 'env.sh' '_lib/_common/priv.sh' '_lib/_common/pkg_mgr.sh' \
           '_lib/_server/nginx/merge_location_into_server.sh' \
           '_lib/_common/environ.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

if [ "${run_before}" -eq 0 ]; then
  depends curl gnupg2 ca-certificates lsb-release debian-archive-keyring
  [ -f '/usr/share/keyrings/nginx-archive-keyring.gpg' ] || \
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
      | priv  tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
  [ -f '/etc/apt/sources.list.d/nginx.list' ] || \
    printf 'deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
    http://nginx.org/packages/debian %s nginx\n' "$(lsb_release -cs)" \
      | priv  tee /etc/apt/sources.list.d/nginx.list
  [ -f '/etc/apt/preferences.d/99nginx' ] || \
    printf 'Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n' \
      | priv  tee /etc/apt/preferences.d/99nginx && \
    priv  apt update -qq

  depends nginx
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

remove_last() {
  c="${1}"
  s="${2}"

  if [ -z "${c}" ]; then
    # If 'c' is empty, return 's' unchanged
    printf '%s' "${s}"
    return
  fi

  case "$s" in
    *"$c"*) ;;
    *)
      printf '%s' "$s"
      return
      ;;
  esac

  prefix="${s%"${c}"*}"
  suffix="${s##*"${c}"}"

  printf '%s%s' "${prefix}" "${suffix}"
}

merge_location_into_nginx_server() {
  conf_existing="${1}"
  location_conf="${2}"

  if [ -z "${conf_existing}" ] || [ "${#conf_existing}" -eq 0 ]; then
    >&2 printf 'Error: conf_existing is empty.\n'
    return 1
  fi

  if [ -z "${location_conf}" ] || [ "${#location_conf}" -eq 0 ]; then
    >&2 printf 'Error: location_conf is empty.\n'
    return 1
  fi

  case "${conf_existing}" in
    *"${location_conf}"*) return ;;
  esac

  rtrimmed=$(rtrim "${conf_existing}")
  rtrimmed_one_lbrace_off_conf=$(remove_last '}' "${rtrimmed}")
  printf '%s\n\n%s}\n\n' "${rtrimmed_one_lbrace_off_conf}" "${location_conf}"
}

if [ ! -z "${VARS+x}" ]; then
  ENV_SCRIPT_FILE=$(mktemp -t 'libscript_XXX_env')
  trap 'rm -f -- "${ENV_SCRIPT_FILE}"' EXIT HUP INT QUIT TERM
  chmod +x "${ENV_SCRIPT_FILE}"
  object2key_val "${VARS}" 'export ' "'" > "${ENV_SCRIPT_FILE}"

  # shellcheck disable=SC1090
  SERVER_NAME="$(. "${ENV_SCRIPT_FILE}"; printf '%s' "${SERVER_NAME}")"

  LOCATION_CONF_FILE=$(mktemp -t 'libscript_'"${SERVER_NAME}"'_XXX_location_conf')
  trap 'rm -f -- "${LOCATION_CONF_FILE}"' EXIT HUP INT QUIT TERM

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
    if ! merge_location_into_server "${conf_existing}" "${location_conf}" "${SERVER_NAME}" | priv  dd of="${site_conf_install_location}" status='none'; then
      >&2 printf 'merge_location_into_nginx_server failed.\n'
      exit 1
    fi
  else
    env -i PATH="${PATH}" \
           ENV_SCRIPT_FILE="${ENV_SCRIPT_FILE}" \
           LIBSCRIPT_BUILD_DIR="${LIBSCRIPT_BUILD_DIR}" \
           LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR}" \
           LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR}" \
           LOCATIONS="${location_conf}" \
           "${DIR}"'/create_server_block.sh' | priv  dd of="${site_conf_install_location}" status='none'
  fi

  unset ENV_SCRIPT_FILE
  unset LOCATION_CONF_FILE
fi
