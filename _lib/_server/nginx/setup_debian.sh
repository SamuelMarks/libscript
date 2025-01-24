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

# TODO: Install to sites-available
if [ ! -z "${VARS+x}" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/environ.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"

  # shellcheck disable=SC1090
  OTHER_SCRIPT_FILE="${LIBSCRIPT_DATA_DIR}"'/libscript.other.sh'
  install -D -m 0755 "${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/envsubst_safe.sh' "${OTHER_SCRIPT_FILE}"
  {
    object2key_val "${VARS}" 'export ' ''
    cat "${DIR}"'/scratch.sh'
  } >> "${OTHER_SCRIPT_FILE}"

  SITE_CONF_FILENAME="${LIBSCRIPT_DATA_DIR}"'/SITE_CONF_FILENAME'
  env -i PATH="${PATH}" \
         SITE_CONF_FILENAME="${SITE_CONF_FILENAME}" \
         LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR}" \
         LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR}" \
         /bin/sh "${OTHER_SCRIPT_FILE}"
  cat "${OTHER_SCRIPT_FILE}"
  site_conf="$(cat -- "${SITE_CONF_FILENAME}"; printf 'a')"
  site_conf="${site_conf%a}"

  # TODO: each location in separate 'fragment'; then merge them into one `server {}`
  # TODO: final thing joins them all to avoid race condition; rather than this next line:

  "${PRIV}" cp "${site_conf}" '/etc/nginx/conf.d/'"${SERVER_NAME}"'TEST_TEST.conf'

  rm -f "${SITE_CONF_FILENAME}" "${OTHER_SCRIPT_FILE}"
  unset OTHER_SCRIPT_FILE
  unset SITE_CONF_FILENAME
fi
