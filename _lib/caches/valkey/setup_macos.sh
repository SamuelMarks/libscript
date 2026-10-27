#!/bin/sh
# ## Overview
# Provides specialized installation logic for Valkey on macOS systems.
# It relies on Homebrew (`brew install valkey`) and registers the service via `brew services`,
# followed by standard `netctl` port/socket registrations.
# 
# ## Usage
# Typically called automatically by `setup.sh` when running on macOS.


set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
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
export DIR="${SCRIPT_DIR}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mgr.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"

SCRIPT_NAME="${DIR}/env.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"

if [ ! -f '/opt/homebrew/bin/valkey-server' ] && [ ! -f '/usr/local/bin/valkey-server' ] && ! command -v valkey-server >/dev/null 2>&1; then
  libscript_depends_via brew 'valkey' || true
fi
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
libscript_service start valkey || true

if [ -n "${VALKEY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" --listen "unix:${VALKEY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${VALKEY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" --listen "${VALKEY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" --listen "${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
fi
