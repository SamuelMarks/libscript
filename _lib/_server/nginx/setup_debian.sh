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
export DIR

SCRIPT_ROOT_DIR="${SCRIPT_ROOT_DIR:-$(d="$(CDPATH='' cd -- "$(dirname -- "$(dirname -- "$( dirname -- "${DIR}" )" )" )")"; if [ -d "${d}" ]; then echo "${d}"; else echo './'"${d}"; fi)}"

SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_lib/_common/priv.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_lib/_os/_apt/apt.sh'
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
