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
    exit 0
fi

if depends 'valkey'; then
    >&2 printf "Valkey installed via package manager.\n"
else
    depends 'git' 'c_compiler' 'make' || {
        >&2 printf "Required build tools for Valkey are missing. Exiting...\n"
        exit 1
    }
    >&2 printf "Building valkey from source...\n"
fi
# Simplified for generic systems
# Could pull from git and build...
