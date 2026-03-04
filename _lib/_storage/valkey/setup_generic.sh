#!/bin/sh
set -feu
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
else
  this_file="${0}"
fi
DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/os_info.sh'
export SCRIPT_NAME
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
. "${SCRIPT_NAME}"

if [ "${TARGET_OS}" = "windows" ] || [ "${TARGET_OS}" = "mingw" ] || [ "${TARGET_OS}" = "cygwin" ]; then
    >&2 printf "Valkey is not available on Windows natively. Exiting gracefully...\n"
    echo "skipping valkey source build"
fi

if depends 'valkey'; then
    >&2 printf "Valkey installed via package manager.\n"
else
    depends 'git' 'c_compiler' 'make' || {
        >&2 printf "Required build tools for Valkey are missing. Exiting...\n"
        echo "skipping valkey source build"
    }
    >&2 printf "Building valkey from source is not implemented. Exiting...\n"
    echo "skipping valkey source build"
fi
# Simplified for generic systems
# Could pull from git and build...

if [ -n "${VALKEY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
  "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "unix:${VALKEY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 || true
elif [ -n "${VALKEY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${VALKEY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 || true
elif [ -n "${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 || true
fi
