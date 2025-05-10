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

for lib in '_lib/_common/priv.sh' '_lib/_common/os_info.sh' '_lib/_common/pkg_mgr.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

if ! cmd_avail wait4x; then
  if [ ! -f /usr/local/bin/wait4x ]; then
    DOWNLOAD_DIR=${DOWNLOAD_DIR:-${LIBSCRIPT_DATA_DIR}/Downloads}
    [ -d "${DOWNLOAD_DIR}" ] || mkdir -p -- "${DOWNLOAD_DIR}"
    previous_wd="$(pwd)"
    cd -- "${DOWNLOAD_DIR}"
    name='wait4x-'"${UNAME_LOWER}"'-'"${ARCH_ALT}"
    archive="${name}"'.tar.gz'
    curl -#LO 'https://github.com/atkrad/wait4x/releases/latest/download/'"${archive}"
    tar --one-top-level -xvf "${archive}"
    priv install .'/'"${name}"'/wait4x' '/usr/local/bin/wait4x'
    # rm -- wait4x-linux-amd64.tar.gz
    cd -- "${previous_wd}"
  fi
fi
