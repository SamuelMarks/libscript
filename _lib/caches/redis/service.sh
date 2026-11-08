#!/bin/sh
# ## Overview
# Manages background service lifecycle operations (start, stop, status, configure, override-env)
# and persistent REDIS_DATA_DIR / VALKEY_DATA_DIR configuration for the redis component.
#
# ## Usage
# ./service.sh [action]

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
    printf '%s\n' "[STOP]     processing \"${THIS_FILE}\"" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '%s\n' "[CONTINUE] processing \"${THIS_FILE}\"" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

for _rd_lib in "_lib/_common/log.sh" "_lib/_common/priv.sh" "_lib/_common/pkg_mgr.sh" "_lib/caches/redis/env.sh" "_lib/_common/service.sh" "_lib/_common/service_install.sh"; do
  if [ -f "${LIBSCRIPT_ROOT_DIR}/${_rd_lib}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_rd_lib}"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
done
unset SCRIPT_NAME || true

_rd_action="${1:-${ACTION:-status}}"

# ## configure_redis_storage
# Delegates Redis/Valkey persistent data directory configuration to _lib/caches/valkey/service.sh.
configure_redis_storage() {
  _crs_dir="${1:-${REDIS_DATA_DIR:-${VALKEY_DATA_DIR:-}}}"
  [ -n "$_crs_dir" ] || return 0
  if [ -x "${LIBSCRIPT_ROOT_DIR}/_lib/caches/valkey/service.sh" ]; then
    VALKEY_DATA_DIR="$_crs_dir" REDIS_DATA_DIR="$_crs_dir" "${LIBSCRIPT_ROOT_DIR}/_lib/caches/valkey/service.sh" configure "$_crs_dir"
  fi
}

case "$_rd_action" in
  configure|override-env)
    _rd_arg_dir=""
    if [ -n "${2:-}" ] && [ "${2:-}" != "redis" ] && [ "${2:-}" != "redis-server" ] && [ "${2:-}" != "valkey" ] && [ "${2:-}" != "valkey-server" ]; then
      _rd_arg_dir="$2"
    elif [ -n "${3:-}" ]; then
      _rd_arg_dir="$3"
    fi
    configure_redis_storage "$_rd_arg_dir"
    exit 0
    ;;
  start|restart|up|install-service)
    if [ -n "${REDIS_DATA_DIR:-${VALKEY_DATA_DIR:-}}" ]; then
      configure_redis_storage "${REDIS_DATA_DIR:-${VALKEY_DATA_DIR:-}}"
    fi
    libscript_service "$_rd_action" "${LIBSCRIPT_SERVICE_NAME:-redis-server}" 2>/dev/null || exit 0
    exit 0
    ;;
  stop|status|down|uninstall-service)
    libscript_service "$_rd_action" "${LIBSCRIPT_SERVICE_NAME:-redis-server}" 2>/dev/null || exit 0
    exit 0
    ;;
esac

exit 0
