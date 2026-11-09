#!/bin/sh
# ## Overview
# Manages background service lifecycle operations (start, stop, status, configure, override-env)
# and persistent VALKEY_DATA_DIR / REDIS_DATA_DIR configuration for the valkey component.
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

for _vk_lib in "_lib/_common/log.sh" "_lib/_common/priv.sh" "_lib/_common/pkg_mgr.sh" "_lib/caches/valkey/env.sh" "_lib/_common/service.sh" "_lib/_common/service_install.sh"; do
  if [ -f "${LIBSCRIPT_ROOT_DIR}/${_vk_lib}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_vk_lib}"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
done
unset SCRIPT_NAME || true

_vk_action="${1:-${ACTION:-status}}"
_vk_svc="${LIBSCRIPT_SERVICE_NAME:-valkey-server}"
_vk_sys_etc="${LIBSCRIPT_SYSTEMD_DIR:-/etc/systemd/system}"
_vk_sys_lib="${LIBSCRIPT_LIB_SYSTEMD_DIR:-/lib/systemd/system}"
for _vk_cand_svc in valkey-server valkey redis-server redis; do
  if [ -f "${_vk_sys_etc}/${_vk_cand_svc}.service" ] || [ -f "${_vk_sys_lib}/${_vk_cand_svc}.service" ]; then
    _vk_svc="$_vk_cand_svc"
    break
  fi
done

# ## configure_valkey_storage
# Configures Valkey/Redis persistent data directory (e.g. /mnt/data/valkey), updates valkey.conf/redis.conf dir and appendonly directives, and writes systemd ReadWritePaths & RequiresMountsFor overrides.
configure_valkey_storage() {
  _vk_dir="${1:-${VALKEY_DATA_DIR:-${REDIS_DATA_DIR:-}}}"
  if [ "$_vk_dir" = "valkey" ] || [ "$_vk_dir" = "valkey-server" ] || [ "$_vk_dir" = "redis" ] || [ "$_vk_dir" = "redis-server" ] || [ "$_vk_dir" = "libscript_valkey" ]; then
    _vk_dir="${VALKEY_DATA_DIR:-${REDIS_DATA_DIR:-}}"
  fi
  [ -n "$_vk_dir" ] || return 0
  export VALKEY_DATA_DIR="$_vk_dir"
  export REDIS_DATA_DIR="$_vk_dir"

  _vk_user="${SERVICE_USER:-root}"
  if id valkey >/dev/null 2>&1; then
    _vk_user='valkey'
  elif id redis >/dev/null 2>&1; then
    _vk_user='redis'
  fi

  _vk_mount_parent=$(dirname "$_vk_dir")
  if [ -d "$_vk_mount_parent" ] && [ "$_vk_mount_parent" != "/" ]; then
    chmod 0755 "$_vk_mount_parent" 2>/dev/null || priv chmod 0755 "$_vk_mount_parent" 2>/dev/null || true
  fi
  mkdir -p "$_vk_dir" 2>/dev/null || priv mkdir -p "$_vk_dir" 2>/dev/null || true
  if id "$_vk_user" >/dev/null 2>&1; then
    chown -R "${_vk_user}:${_vk_user}" "$_vk_dir" 2>/dev/null || priv chown -R "${_vk_user}:${_vk_user}" "$_vk_dir" 2>/dev/null || true
  fi
  chmod 0750 "$_vk_dir" 2>/dev/null || priv chmod 0750 "$_vk_dir" 2>/dev/null || true

  _vk_changed=0
  for _vk_conf in "${LIBSCRIPT_ETC_DIR:-/etc}/valkey/valkey.conf" "${LIBSCRIPT_ETC_DIR:-/etc}/valkey.conf" "${LIBSCRIPT_ETC_DIR:-/etc}/redis/redis.conf" "${LIBSCRIPT_ETC_DIR:-/etc}/redis.conf"; do
    [ -f "$_vk_conf" ] || continue
    _vk_tmp_conf=$(mktemp)
    if grep -Eq '^[[:space:]]*dir[[:space:]]+' "$_vk_conf" 2>/dev/null; then
      sed "s|^[[:space:]]*dir[[:space:]].*|dir ${_vk_dir}|" "$_vk_conf" > "$_vk_tmp_conf"
    else
      cat "$_vk_conf" > "$_vk_tmp_conf"
      printf '%s\n' "dir ${_vk_dir}" >> "$_vk_tmp_conf"
    fi
    if grep -Eq '^[#[:space:]]*appendonly[[:space:]]+' "$_vk_tmp_conf" 2>/dev/null; then
      sed "s|^[#[:space:]]*appendonly[[:space:]].*|appendonly yes|" "$_vk_tmp_conf" > "${_vk_tmp_conf}.2" && mv "${_vk_tmp_conf}.2" "$_vk_tmp_conf"
    else
      printf '%s\n' 'appendonly yes' >> "$_vk_tmp_conf"
    fi
    if ! cmp -s "$_vk_tmp_conf" "$_vk_conf" 2>/dev/null; then
      cp "$_vk_tmp_conf" "$_vk_conf" 2>/dev/null || priv cp "$_vk_tmp_conf" "$_vk_conf" 2>/dev/null || true
      _vk_changed=1
    fi
    rm -f "$_vk_tmp_conf"
  done

  _vk_sys_root="${LIBSCRIPT_SYSTEMD_DIR:-/etc/systemd/system}"
  if [ -d "$_vk_sys_root" ] || [ -n "${LIBSCRIPT_SYSTEMD_DIR:-}" ]; then
    for _vk_unit in valkey-server.service valkey.service redis-server.service redis.service; do
      _vk_drop_dir="${_vk_sys_root}/${_vk_unit}.d"
      _vk_drop_file="${_vk_drop_dir}/override.conf"
      mkdir -p "$_vk_drop_dir" 2>/dev/null || priv mkdir -p "$_vk_drop_dir" 2>/dev/null || true
      _vk_tmp_ov=$(mktemp)
      {
        printf '%s\n' '[Unit]'
        printf '%s\n' "RequiresMountsFor=${_vk_mount_parent}"
        printf '%s\n' '[Service]'
        printf '%s\n' "ReadWritePaths=${_vk_dir}"
        printf '%s\n' "Environment=\"VALKEY_DATA_DIR=${_vk_dir}\""
        printf '%s\n' "Environment=\"REDIS_DATA_DIR=${_vk_dir}\""
      } > "$_vk_tmp_ov"
      if [ ! -f "$_vk_drop_file" ] || ! cmp -s "$_vk_tmp_ov" "$_vk_drop_file" 2>/dev/null; then
        cp "$_vk_tmp_ov" "$_vk_drop_file" 2>/dev/null || priv cp "$_vk_tmp_ov" "$_vk_drop_file" 2>/dev/null || true
        _vk_changed=1
      fi
      rm -f "$_vk_tmp_ov"
    done
    if [ "$_vk_changed" -eq 1 ] && [ "${LIBSCRIPT_MOCK_SYSTEMD:-0}" != "1" ] && [ "${LIBSCRIPT_DRY_RUN:-0}" != "1" ]; then
      libscript_service daemon-reload "$_vk_svc" >/dev/null 2>&1 || true
      for _vk_rsvc in valkey-server valkey redis-server redis; do
        if libscript_service is-active "$_vk_rsvc" >/dev/null 2>&1 || [ -f "${_vk_sys_lib}/${_vk_rsvc}.service" ] || [ -f "${_vk_sys_root}/${_vk_rsvc}.service" ]; then
          libscript_service restart "$_vk_rsvc" >/dev/null 2>&1 || true
          break
        fi
      done
    fi
  fi
  return 0
}

case "$_vk_action" in
  configure|override-env)
    _vk_arg_dir=""
    if [ -n "${2:-}" ] && [ "${2:-}" != "valkey" ] && [ "${2:-}" != "valkey-server" ] && [ "${2:-}" != "redis" ] && [ "${2:-}" != "redis-server" ]; then
      _vk_arg_dir="$2"
    elif [ -n "${3:-}" ]; then
      _vk_arg_dir="$3"
    fi
    configure_valkey_storage "$_vk_arg_dir"
    exit 0
    ;;
  start|restart|up|install-service)
    if [ -n "${VALKEY_DATA_DIR:-${REDIS_DATA_DIR:-}}" ]; then
      configure_valkey_storage "${VALKEY_DATA_DIR:-${REDIS_DATA_DIR:-}}"
    fi
    libscript_service "$_vk_action" "$_vk_svc" 2>/dev/null || exit 0
    exit 0
    ;;
  stop|status|down|uninstall-service)
    libscript_service "$_vk_action" "$_vk_svc" 2>/dev/null || exit 0
    exit 0
    ;;
esac

exit 0
