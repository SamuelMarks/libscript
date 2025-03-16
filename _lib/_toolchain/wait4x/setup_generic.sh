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
