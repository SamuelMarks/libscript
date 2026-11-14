#!/bin/sh
# ## Overview
# Manages background service lifecycle operations (start, stop, status, configure, override-env)
# and persistent POSTGRES_DATA_DIR / PGDATA configuration for the postgres component.
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

for _pg_lib in "_lib/_common/log.sh" "_lib/_common/priv.sh" "_lib/_common/pkg_mgr.sh" "_lib/databases/postgres/env.sh" "_lib/_common/service.sh" "_lib/_common/service_install.sh"; do
  if [ -f "${LIBSCRIPT_ROOT_DIR}/${_pg_lib}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_pg_lib}"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
done
unset SCRIPT_NAME || true

_pg_action="${1:-${ACTION:-status}}"
_pg_svc="${LIBSCRIPT_SERVICE_NAME:-postgresql}"

# ## configure_postgres_storage
# Configures PostgreSQL cluster data directory on persistent storage (e.g. /mnt/data/postgres), migrates or reuses existing PG_VERSION clusters, updates postgresql.conf, and writes systemd drop-in overrides.
configure_postgres_storage() {
  _pg_base_dir="${1:-${POSTGRES_DATA_DIR:-${PGDATA:-}}}"
  if [ "$_pg_base_dir" = "postgres" ] || [ "$_pg_base_dir" = "postgresql" ] || [ "$_pg_base_dir" = "libscript_postgres" ]; then
    _pg_base_dir="${POSTGRES_DATA_DIR:-${PGDATA:-}}"
  fi
  [ -n "$_pg_base_dir" ] || return 0
  export POSTGRES_DATA_DIR="$_pg_base_dir"
  export PGDATA="$_pg_base_dir"

  _pg_mount_parent=$(dirname "$_pg_base_dir")
  if [ -d "$_pg_mount_parent" ] && [ "$_pg_mount_parent" != "/" ]; then
    chmod 0755 "$_pg_mount_parent" 2>/dev/null || priv chmod 0755 "$_pg_mount_parent" 2>/dev/null || true
  fi
  mkdir -p "$_pg_base_dir" 2>/dev/null || priv mkdir -p "$_pg_base_dir" 2>/dev/null || true
  if id postgres >/dev/null 2>&1; then
    chown -R postgres:postgres "$_pg_base_dir" 2>/dev/null || priv chown -R postgres:postgres "$_pg_base_dir" 2>/dev/null || true
  fi
  chmod 0700 "$_pg_base_dir" 2>/dev/null || priv chmod 0700 "$_pg_base_dir" 2>/dev/null || true

  _pg_ver=""
  _pg_conf=""
  _pg_etc_dir="${POSTGRES_ETC_DIR:-${LIBSCRIPT_ETC_DIR:-/etc}/postgresql}"
  for _pg_cand_conf in "${_pg_etc_dir}"/*/main/postgresql.conf; do
    if [ -f "$_pg_cand_conf" ]; then
      _pg_conf="$_pg_cand_conf"
      _pg_ver=$(printf '%s\n' "$_pg_cand_conf" | awk -F'/' '{print $(NF-2)}')
    fi
  done

  _pg_cluster_dir="$_pg_base_dir"
  if [ -n "$_pg_ver" ]; then
    if [ -f "${_pg_base_dir%/}/PG_VERSION" ]; then
      _pg_cluster_dir="${_pg_base_dir%/}"
    else
      _pg_cluster_dir="${_pg_base_dir%/}/${_pg_ver}/main"
    fi
  fi

  _pg_changed=0
  if [ -n "$_pg_conf" ] && [ -f "$_pg_conf" ]; then
    _pg_cur_data=$(awk -F"'" '/^[[:space:]]*data_directory[[:space:]]*=/{print $2}' "$_pg_conf" 2>/dev/null | tail -n 1 || true)
    if [ "$_pg_cur_data" != "$_pg_cluster_dir" ]; then
      _pg_changed=1
      log_info "[POSTGRES] Configuring PostgreSQL ${_pg_ver} data_directory -> ${_pg_cluster_dir}..."
      if [ "${LIBSCRIPT_MOCK_SYSTEMD:-0}" != "1" ] && [ "${LIBSCRIPT_DRY_RUN:-0}" != "1" ]; then
        libscript_service stop "postgresql@${_pg_ver}-main" >/dev/null 2>&1 || true
        libscript_service stop postgresql >/dev/null 2>&1 || true
        if command -v pg_ctlcluster >/dev/null 2>&1; then
          pg_ctlcluster "$_pg_ver" main stop 2>/dev/null || priv pg_ctlcluster "$_pg_ver" main stop 2>/dev/null || true
        fi
      fi
      mkdir -p "$_pg_cluster_dir" 2>/dev/null || priv mkdir -p "$_pg_cluster_dir" 2>/dev/null || true
      if [ -f "${_pg_cluster_dir}/PG_VERSION" ]; then
        log_info "[POSTGRES] [REUSE] Existing persistent PostgreSQL cluster detected at ${_pg_cluster_dir}; preserving persistent data."
      else
        _pg_src_dir="${_pg_cur_data:-/var/lib/postgresql/${_pg_ver}/main}"
        if [ -d "$_pg_src_dir" ] && [ "$_pg_src_dir" != "$_pg_cluster_dir" ]; then
          log_info "[POSTGRES] [MIGRATE] Syncing initial cluster from ${_pg_src_dir} to ${_pg_cluster_dir}..."
          if command -v rsync >/dev/null 2>&1; then
            rsync -a "${_pg_src_dir%/}/" "${_pg_cluster_dir%/}/" 2>/dev/null || priv rsync -a "${_pg_src_dir%/}/" "${_pg_cluster_dir%/}/" 2>/dev/null || true
          else
            cp -a "${_pg_src_dir%/}/." "${_pg_cluster_dir%/}/" 2>/dev/null || priv cp -a "${_pg_src_dir%/}/." "${_pg_cluster_dir%/}/" 2>/dev/null || true
          fi
        fi
      fi
      if id postgres >/dev/null 2>&1; then
        chown -R postgres:postgres "$_pg_base_dir" 2>/dev/null || priv chown -R postgres:postgres "$_pg_base_dir" 2>/dev/null || true
      fi
      chmod 0700 "$_pg_base_dir" "$_pg_cluster_dir" 2>/dev/null || priv chmod 0700 "$_pg_base_dir" "$_pg_cluster_dir" 2>/dev/null || true

      _pg_tmp_conf=$(mktemp)
      if grep -q '^[#[:space:]]*data_directory[[:space:]]*=' "$_pg_conf" 2>/dev/null; then
        sed "s|^[#[:space:]]*data_directory[[:space:]]*=.*|data_directory = '${_pg_cluster_dir}'|" "$_pg_conf" > "$_pg_tmp_conf"
      else
        cat "$_pg_conf" > "$_pg_tmp_conf"
        printf '%s\n' "data_directory = '${_pg_cluster_dir}'" >> "$_pg_tmp_conf"
      fi
      cp "$_pg_tmp_conf" "$_pg_conf" 2>/dev/null || priv cp "$_pg_tmp_conf" "$_pg_conf" 2>/dev/null || true
      rm -f "$_pg_tmp_conf"
    fi
  fi

  _pg_sys_root="${LIBSCRIPT_SYSTEMD_DIR:-/etc/systemd/system}"
  if [ -d "$_pg_sys_root" ] || [ -n "${LIBSCRIPT_SYSTEMD_DIR:-}" ]; then
    _pg_units='postgresql.service'
    [ -n "$_pg_ver" ] && _pg_units="postgresql.service postgresql@${_pg_ver}-main.service"
    for _pg_u in $_pg_units; do
      _pg_drop_dir="${_pg_sys_root}/${_pg_u}.d"
      _pg_drop_file="${_pg_drop_dir}/override.conf"
      mkdir -p "$_pg_drop_dir" 2>/dev/null || priv mkdir -p "$_pg_drop_dir" 2>/dev/null || true
      _pg_tmp_ov=$(mktemp)
      {
        printf '%s\n' '[Unit]'
        printf '%s\n' "RequiresMountsFor=${_pg_mount_parent}"
        printf '%s\n' '[Service]'
        printf '%s\n' "ReadWritePaths=${_pg_base_dir}"
        printf '%s\n' "Environment=\"POSTGRES_DATA_DIR=${_pg_base_dir}\""
        printf '%s\n' "Environment=\"PGDATA=${_pg_cluster_dir}\""
      } > "$_pg_tmp_ov"
      if [ ! -f "$_pg_drop_file" ] || ! cmp -s "$_pg_tmp_ov" "$_pg_drop_file" 2>/dev/null; then
        cp "$_pg_tmp_ov" "$_pg_drop_file" 2>/dev/null || priv cp "$_pg_tmp_ov" "$_pg_drop_file" 2>/dev/null || true
        _pg_changed=1
      fi
      rm -f "$_pg_tmp_ov"
    done
    if [ "$_pg_changed" -eq 1 ] && [ "${LIBSCRIPT_MOCK_SYSTEMD:-0}" != "1" ] && [ "${LIBSCRIPT_DRY_RUN:-0}" != "1" ]; then
      libscript_service daemon-reload postgresql >/dev/null 2>&1 || true
      libscript_service restart postgresql >/dev/null 2>&1 || true
    fi
  fi

  _pg_etc="${LIBSCRIPT_ETC_DIR:-/etc}"
  if [ "${UNAME_LOWER:-}" = "freebsd" ] || [ "${LIBSCRIPT_TARGET_OS:-}" = "freebsd" ]; then
    mkdir -p "${_pg_etc}/rc.conf.d" 2>/dev/null || priv mkdir -p "${_pg_etc}/rc.conf.d" 2>/dev/null || true
    printf 'postgresql_enable="YES"\npostgresql_data="%s"\n' "$_pg_cluster_dir" > "${_pg_etc}/rc.conf.d/postgresql" 2>/dev/null || true
  elif [ "${UNAME_LOWER:-}" = "sunos" ] || [ "${LIBSCRIPT_TARGET_OS:-}" = "sunos" ]; then
    _pg_smf_dir="${LIBSCRIPT_TARGET_SYSROOT:-}/var/svc/manifest/site"
    mkdir -p "$_pg_smf_dir" 2>/dev/null || priv mkdir -p "$_pg_smf_dir" 2>/dev/null || true
    cat <<PG_SMF_EOF > "${_pg_smf_dir}/postgresql.xml" 2>/dev/null || true
<?xml version="1.0"?>
<!DOCTYPE service_bundle SYSTEM "/usr/share/lib/xml/dtd/service_bundle.dtd.1">
<service_bundle type='manifest' name='libscript:postgresql'>
  <service name='application/database/postgresql' type='service' version='1'>
    <create_default_instance enabled='true' />
    <exec_method type='method' name='start' exec='/opt/ooce/pgsql-16/bin/pg_ctl -D ${_pg_cluster_dir} start' timeout_seconds='120' />
    <exec_method type='method' name='stop' exec='/opt/ooce/pgsql-16/bin/pg_ctl -D ${_pg_cluster_dir} stop' timeout_seconds='60' />
    <property_group name='postgresql' type='application'>
      <propval name='data' type='astring' value='${_pg_cluster_dir}' />
    </property_group>
  </service>
</service_bundle>
PG_SMF_EOF
  elif [ -d "${_pg_etc}/conf.d" ]; then
    printf 'PGDATA="%s"\n' "$_pg_cluster_dir" > "${_pg_etc}/conf.d/postgresql" 2>/dev/null || true
  fi
  return 0
}

case "$_pg_action" in
  configure|override-env)
    _pg_arg_dir=""
    if [ -n "${2:-}" ] && [ "${2:-}" != "postgres" ] && [ "${2:-}" != "postgresql" ] && [ "${2:-}" != "libscript_postgres" ]; then
      _pg_arg_dir="$2"
    elif [ -n "${3:-}" ]; then
      _pg_arg_dir="$3"
    fi
    configure_postgres_storage "$_pg_arg_dir"
    exit 0
    ;;
  start|restart|up|install-service)
    if [ -n "${POSTGRES_DATA_DIR:-${PGDATA:-}}" ]; then
      configure_postgres_storage "${POSTGRES_DATA_DIR:-${PGDATA:-}}"
    fi
    libscript_service "$_pg_action" "$_pg_svc" 2>/dev/null || exit 0
    exit 0
    ;;
  stop|status|down|uninstall-service)
    libscript_service "$_pg_action" "$_pg_svc" 2>/dev/null || exit 0
    exit 0
    ;;
esac

exit 0
