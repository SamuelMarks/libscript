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

STACK="${STACK:-:}"
case "${STACK}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    return ;;
  *)
    printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
STACK="${STACK}${this_file}"':'
export STACK

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
export DIR

SCRIPT_ROOT_DIR="${SCRIPT_ROOT_DIR:-$(d="$(CDPATH='' cd -- "$(dirname -- "$(dirname -- "$( dirname -- "${DIR}" )" )" )")"; if [ -d "$d" ]; then echo "$d"; else echo './'"$d"; fi)}"

SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/conf.env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_lib/_common/common.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_lib/_common/os_info.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

# TODO: latest version dance function and wrap this up
DOWNLOAD_DIR=${DOWNLOAD_DIR:-${SCRIPT_ROOT_DIR}/Downloads}
version='v1.38.1'
if ! [ -f "${DOWNLOAD_DIR}"'/bin/fnm' ] ; then
  ensure_available curl unzip
  os="$(echo "${TARGET_OS}" | tr '[:upper:]' '[:lower:]')"
  case "${os}" in
    'macos'*) ;;
    *) os='linux' ;;
  esac
  archive='fnm-'"${os}"'.zip'
  mkdir -p "${DOWNLOAD_DIR}"'/bin'
  previous_wd="$(pwd)"
  cd "${DOWNLOAD_DIR}"
  # https://github.com/Schniz/fnm/releases/download/v1.38.1/fnm-linux.zip
  # https://github.com/Schniz/fnm/releases/download/v1.38.1/fnm-debian.zip
  echo 'https://github.com/Schniz/fnm/releases/download/'${version}'/'"${archive}"
  curl -OL 'https://github.com/Schniz/fnm/releases/download/'${version}'/'"${archive}"
  unzip "${archive}"
  mv fnm "${DOWNLOAD_DIR}"'/bin/'
  cd "${previous_wd}"
fi
"${DOWNLOAD_DIR}"'/bin/fnm' install '22.12.0'
# ${NODEJS_VERSION}
