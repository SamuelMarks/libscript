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
DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(D="${DIR}"; while [ ! -f "${D}/ROOT" ] && [ "${D}" != "/" ]; do D="$(dirname -- "${D}")"; done; [ "${D}" = "/" ] && D="${DIR}"; printf '%s' "${D}")}"

for LIB in _lib/_common/os_info.sh ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

for LIB in _lib/_common/pkg_mgr.sh ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

if [ "${TARGET_OS}" = "windows" ] || [ "${TARGET_OS}" = "mingw" ] || [ "${TARGET_OS}" = "cygwin" ]; then
    >&2 printf "Valkey is not available on Windows natively. Exiting gracefully...\n"
    log_info "skipping valkey source build"
fi

if libscript_depends 'valkey'; then
    >&2 printf "Valkey installed via package manager.\n"
elif libscript_depends 'valkey-server'; then
    >&2 printf "Valkey-server installed via package manager.\n"
elif libscript_depends 'redis'; then
    >&2 printf "Redis installed via package manager as fallback.\n"
elif libscript_depends 'redis-server'; then
    >&2 printf "Redis-server installed via package manager as fallback.\n"
else
    libscript_depends 'git' 'c_compiler' 'make' || {
        >&2 printf "Required build tools for Valkey are missing. Exiting...\n"
        log_info "skipping valkey source build"
    }
    >&2 printf "Building valkey from source is not implemented. Exiting...\n"
    log_info "skipping valkey source build"
fi
# Simplified for generic systems
# Could pull from git and build...

case "1" in
  "$( [ -n "${VALKEY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ] && echo 1 )")
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "unix:${VALKEY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 ; then
    true
  fi
    ;;
  "$( [ -n "${VALKEY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ] && echo 1 )")
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${VALKEY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
    ;;
  "$( [ -n "${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ] && echo 1 )")
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
    ;;
esac
