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

#DIR="$( dirname -- "$( readlink -nf -- "${0}" )")"

SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_lib/_common/os_info.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_lib/_os/_apt/apt.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_lib/_common/priv.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

ensure_available() {
  # TODO: use https://repology.org to match names
  case "${PKG_MGR}" in
    'apk') apk add "${0}" ;;
    'apt-get') apt_depends "${0}" ;;
    'brew') brew install "${0}" ;;
    'dnf') dnf install "${0}" ;;
    'pacman') pacman -S "${0}" ;;
    'pkg') pkg install "${0}" ;;
    'pkgutil') pkgutil -i "${0}" ;;
    'zypper') zypper install "${0}" ;;
    *) >&2 printf 'Unimplemented, package manager %s\n' "${PKG_MGR}"
  esac
}

cmd_avail() {
  command -v "${1}" >/dev/null 2>&1
}
