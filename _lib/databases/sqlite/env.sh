#!/bin/sh
# ## Overview
# Environment initialization for SQLite.
# Resolves the active SQLite installation prefix (including compiler-namespaced
# source builds) and exports PATH, CPATH, and LIBRARY_PATH.
#
# ## Usage
# . ./_lib/databases/sqlite/env.sh

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
_EB_CALLER_THIS="${THIS_FILE}"
_EB_CALLER_DIR="${SCRIPT_DIR}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_base.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true
export LIBSCRIPT_ROOT_DIR

SQLITE_VERSION="${SQLITE_VERSION:-default}"
_tc="${SQLITE_BUILD_TOOLCHAIN:-${SQLITE_COMPILER:-${LIBSCRIPT_BUILD_TOOLCHAIN:-default}}}"
_sqlite_base="${LIBSCRIPT_HOME:-$HOME/.libscript}/sqlite"

if [ "${_tc}" != "default" ] && [ -d "${_sqlite_base}/default-${_tc}/bin" ]; then
  _sqlite_prefix="${_sqlite_base}/default-${_tc}"
elif [ -d "${_sqlite_base}/${SQLITE_VERSION}/bin" ]; then
  _sqlite_prefix="${_sqlite_base}/${SQLITE_VERSION}"
elif [ -d "${_sqlite_base}/default/bin" ]; then
  _sqlite_prefix="${_sqlite_base}/default"
else
  _sqlite_prefix="${_sqlite_base}/${SQLITE_VERSION}"
fi

export SQLITE_PREFIX="${_sqlite_prefix}"
libscript_path_prepend "${_sqlite_prefix}/bin"
if [ -d "${_sqlite_prefix}/include" ]; then
  case ":${CPATH:-}:" in
    *":${_sqlite_prefix}/include:"*) ;;
    *) export CPATH="${_sqlite_prefix}/include${CPATH:+:${CPATH}}" ;;
  esac
fi
if [ -d "${_sqlite_prefix}/lib" ]; then
  case ":${LIBRARY_PATH:-}:" in
    *":${_sqlite_prefix}/lib:"*) ;;
    *) export LIBRARY_PATH="${_sqlite_prefix}/lib${LIBRARY_PATH:+:${LIBRARY_PATH}}" ;;
  esac
fi
