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

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

NODEJS_VERSION_LTS='v22.13.1'
# latest lts ^

if [ "${NODEJS_VERSION}" = 'lts' ]; then
  NODEJS_VERSION="${NODEJS_VERSION_LTS}"
fi

for lib in '_lib/_common/pkg_mgr.sh' '_lib/_common/os_info.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

if cmd_avail node ; then
  version="$(node --version)"
  if [ "${version}" = "${NODEJS_VERSION}" ]; then
    return
  fi
fi

# TODO: latest version dance function and wrap this up
LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"
DOWNLOAD_DIR=${DOWNLOAD_DIR:-${LIBSCRIPT_DATA_DIR}/Downloads}
version='v1.38.1'
if ! [ -f "${DOWNLOAD_DIR}"'/bin/fnm' ] ; then
  depends 'curl' 'unzip'
  os="$(printf '%s' "${TARGET_OS}" | tr '[:upper:]' '[:lower:]')"
  case "${os}" in
    'macos'*) ;;
    *) os='linux' ;;
  esac
  archive='fnm-'"${os}"'.zip'
  mkdir -p -- "${DOWNLOAD_DIR}"'/bin'
  previous_wd="$(pwd)"
  cd -- "${DOWNLOAD_DIR}"
  # https://github.com/Schniz/fnm/releases/download/v1.38.1/fnm-linux.zip
  # https://github.com/Schniz/fnm/releases/download/v1.38.1/fnm-debian.zip
  printf 'https://github.com/Schniz/fnm/releases/download/%s/%s\n' "${version}" "${archive}"
  curl -OL 'https://github.com/Schniz/fnm/releases/download/'${version}'/'"${archive}"
  unzip "${archive}"
  mv fnm "${DOWNLOAD_DIR}"'/bin/'
  cd -- "${previous_wd}"
fi
"${DOWNLOAD_DIR}"'/bin/fnm' install "${NODEJS_VERSION}"
export PATH="${HOME}"'/.local/share/fnm/aliases/default/bin:'"${PATH}"
