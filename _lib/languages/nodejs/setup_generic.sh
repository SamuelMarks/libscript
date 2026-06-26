#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
if [ -z "${LIBSCRIPT_ROOT_DIR:-}" ]; then
  _tmp_dir="$SCRIPT_DIR"
  while [ "$_tmp_dir" != "/" ] && [ ! -f "$_tmp_dir/libscript.sh" ]; do
    _tmp_dir="$(dirname "$_tmp_dir")"
  done
  LIBSCRIPT_ROOT_DIR="$_tmp_dir"
fi
DIR="${SCRIPT_DIR}"

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/env.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

NODEJS_VERSION_LTS='22'
# latest lts ^

NODEJS_VERSION="${NODEJS_VERSION:-lts}"
if [ "${NODEJS_VERSION}" = 'lts' ]; then
  NODEJS_VERSION="${NODEJS_VERSION_LTS}"
fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

NODEJS_INSTALL_METHOD="${NODEJS_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-source}}"

if [ "${NODEJS_INSTALL_METHOD}" = 'system' ]; then
  libscript_depends 'nodejs'
else
  export MISE_HOME="${HOME}/.local/share/mise"
  export PATH="${MISE_HOME}/bin:${PATH}"
  
  if libscript_cmd_avail node ; then
    version="$(node --version)"
    case "${version}" in
      v${NODEJS_VERSION}*|${NODEJS_VERSION}*)
        return
        ;;
    esac
  fi

  libscript_depends 'curl'
  if ! [ -f "${MISE_HOME}/bin/mise" ] ; then
    curl https://mise.run | bash
  fi
  
  # Trim 'v' if present for mise compatibility
  clean_version=$(echo "$NODEJS_VERSION" | sed 's/^v//')
  mise use --global node@"${clean_version}"
fi