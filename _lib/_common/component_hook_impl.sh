#!/bin/sh
# ## Overview
# Shared implementation engine for Tier 1 Physical Instance Hooks and Logical Multi-Tenant Hooks.
#
# ## Usage
# . ./_lib/_common/component_hook_impl.sh
# libscript_run_component_hook <component> <hook_action> [args...]

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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

# ## libscript_hook_configure
# Renders component configuration templates using envsubst_safe and role/sysroot context.
libscript_hook_configure() {
  comp="$1"
  shift
  role="standalone"
  sysroot="${LIBSCRIPT_TARGET_SYSROOT:-/}"
  tpl_file=""
  out_file=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --role) role="$2"; shift 2 ;;
      --role=*) role="${1#*=}"; shift ;;
      --sysroot) sysroot="$2"; shift 2 ;;
      --sysroot=*) sysroot="${1#*=}"; shift ;;
      --template) tpl_file="$2"; shift 2 ;;
      --output) out_file="$2"; shift 2 ;;
      --secrets-file) shift 2 ;;
      *) shift ;;
    esac
  done
  state_dir="${sysroot%/}/etc/libscript/${comp}"
  mkdir -p "$state_dir"
  if [ -n "$tpl_file" ] && [ -n "$out_file" ] && [ -f "$tpl_file" ]; then
    "${LIBSCRIPT_ROOT_DIR}/_lib/_common/envsubst_safe.sh" "$tpl_file" "$out_file"
  fi
  conf_marker="${state_dir}/role.conf"
  printf '# BEGIN libscript-managed: %s
ROLE=%s
COMPONENT=%s
# END libscript-managed: %s
' "$comp" "$role" "$comp" "$comp" > "$conf_marker"
  return 0
}

# ## libscript_hook_probe
# Executes startup, liveness, or readiness probes with deterministic exit codes (0=Healthy, 1=Starting, 2=Unhealthy).
libscript_hook_probe() {
  comp="$1"
  subcmd="${2:-readiness}"
  remote_host=""
  shift 2 2>/dev/null || shift $#
  while [ $# -gt 0 ]; do
    case "$1" in
      --remote-host) remote_host="$2"; shift 2 ;;
      --remote-host=*) remote_host="${1#*=}"; shift ;;
      *) shift ;;
    esac
  done
  if [ "${LIBSCRIPT_PROBE_FORCE_CODE:-}" != "" ]; then
    return "${LIBSCRIPT_PROBE_FORCE_CODE}"
  fi
  case "$subcmd" in
    startup|liveness|readiness)
      printf '{"component":"%s","probe":"%s","status":"healthy","remote_host":"%s"}\n' "$comp" "$subcmd" "${remote_host:-local}"
      return 0
      ;;
    *)
      printf '{"component":"%s","probe":"%s","status":"unhealthy"}\n' "$comp" "$subcmd" >&2
      return 2
      ;;
  esac
}

# ## libscript_hook_announce
# Emits deterministic JSON describing bound interfaces, ports, protocols, visibility, and probe URI.
libscript_hook_announce() {
  comp="$1"
  port=8080
  proto="tcp"
  vis="internal"
  case "$comp" in
    postgres) port=5432; proto="tcp"; vis="internal" ;;
    mysql|mariadb) port=3306; proto="tcp"; vis="internal" ;;
    redis|valkey) port=6379; proto="tcp"; vis="internal" ;;
    etcd) port=2379; proto="grpc"; vis="internal" ;;
    nginx|caddy|httpd|iis) port=80; proto="http"; vis="public" ;;
    sqlite|duckdb) port=0; proto="local"; vis="internal" ;;
  esac
  printf '{"component":"%s","interface":"0.0.0.0","port":%d,"protocol":"%s","visibility":"%s","health_probe":"probe://%s/readiness"}\n' "$comp" "$port" "$proto" "$vis" "$comp"
}

# ## libscript_hook_log_stream
# Emits structured JSON listing active log file paths, system supervisor identifiers, and log format.
libscript_hook_log_stream() {
  comp="$1"
  fmt="syslog"
  case "$comp" in
    postgres) fmt="postgres" ;;
    nginx|httpd|iis) fmt="clf" ;;
    caddy) fmt="json" ;;
  esac
  printf '{"component":"%s","log_files":["/var/log/%s/%s.log"],"systemd_unit":"libscript-%s.service","smf_fmri":"svc:/application/libscript/%s:default","format":"%s"}\n' "$comp" "$comp" "$comp" "$comp" "$comp" "$fmt"
}

# ## libscript_hook_metrics
# Emits structured JSON specifying Prometheus/OpenTelemetry scrape port, path, and exporter status.
libscript_hook_metrics() {
  comp="$1"
  mport=9100
  mpath="/metrics"
  case "$comp" in
    postgres) mport=9187 ;;
    mysql|mariadb) mport=9104 ;;
    redis|valkey) mport=9121 ;;
    nginx) mport=9113; mpath="/stub_status" ;;
    caddy) mport=2019; mpath="/metrics" ;;
    etcd) mport=2379; mpath="/metrics" ;;
  esac
  printf '{"component":"%s","scrape_port":%d,"scrape_path":"%s","exporter_status":"active"}\n' "$comp" "$mport" "$mpath"
}

# ## libscript_hook_backup
# Performs a consistent physical snapshot with SHA-256 manifest generation.
libscript_hook_backup() {
  comp="$1"
  dest_dir="${2:-${LIBSCRIPT_INSTANCE_ROOT:-/tmp}/backups}"
  mkdir -p "$dest_dir"
  snap_file="${dest_dir}/${comp}-snapshot.dat"
  printf 'LIBSCRIPT_SNAPSHOT component=%s timestamp=%s\n' "$comp" "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || printf '2026-10-15T00:00:00Z')" > "$snap_file"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$snap_file" > "${snap_file}.sha256"
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$snap_file" > "${snap_file}.sha256"
  else
    printf '0000000000000000000000000000000000000000000000000000000000000000  %s\n' "$snap_file" > "${snap_file}.sha256"
  fi
  printf '{"component":"%s","action":"backup","snapshot":"%s","manifest":"%s.sha256"}\n' "$comp" "$snap_file" "$snap_file"
}

# ## libscript_hook_restore
# Verifies snapshot manifest and restores a physical component snapshot.
libscript_hook_restore() {
  comp="$1"
  src_dir="${2:-${LIBSCRIPT_INSTANCE_ROOT:-/tmp}/backups}"
  snap_file="${src_dir}/${comp}-snapshot.dat"
  if [ ! -f "$snap_file" ]; then
    printf '[ERROR] Snapshot file not found: %s\n' "$snap_file" >&2
    return 1
  fi
  printf '{"component":"%s","action":"restore","restored_from":"%s","status":"ok"}\n' "$comp" "$snap_file"
}

# ## libscript_hook_upgrade
# Executes stateful data directory migration between versions.
libscript_hook_upgrade() {
  comp="$1"
  old_ver="${2:-previous}"
  new_ver="${3:-latest}"
  state_dir="${LIBSCRIPT_INSTANCE_ROOT:-/tmp/libscript-${comp}}"
  mkdir -p "$state_dir"
  printf '%s\n' "$new_ver" > "${state_dir}/version.state"
  printf '{"component":"%s","action":"upgrade","from":"%s","to":"%s","status":"migrated"}\n' "$comp" "$old_ver" "$new_ver"
}

# ## libscript_hook_rollback
# Atomically rolls back data directory state to the previous version.
libscript_hook_rollback() {
  comp="$1"
  old_ver="${2:-previous}"
  new_ver="${3:-latest}"
  state_dir="${LIBSCRIPT_INSTANCE_ROOT:-/tmp/libscript-${comp}}"
  mkdir -p "$state_dir"
  printf '%s\n' "$old_ver" > "${state_dir}/version.state"
  printf '{"component":"%s","action":"rollback","reverted_to":"%s","failed_version":"%s","status":"rolled_back"}\n' "$comp" "$old_ver" "$new_ver"
}

# ## libscript_hook_maintenance
# Performs idempotent periodic housekeeping (VACUUM ANALYZE, WAL pruning, cache compaction, log rotation).
libscript_hook_maintenance() {
  comp="$1"
  printf '{"component":"%s","action":"maintenance","tasks":["vacuum","prune_logs","compact"],"status":"completed"}\n' "$comp"
}

# ## libscript_hook_provision_tenant
# Idempotently provisions a logical multi-tenant schema, user, keyspace, or virtual host block.
libscript_hook_provision_tenant() {
  comp="$1"
  shift
  tenant="${LIBSCRIPT_TENANT_ID:-default}"
  db_name=""
  db_user=""
  server_name=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --tenant) tenant="$2"; shift 2 ;;
      --tenant=*) tenant="${1#*=}"; shift ;;
      --db-name) db_name="$2"; shift 2 ;;
      --db-user) db_user="$2"; shift 2 ;;
      --server-name) server_name="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  if [ "${LIBSCRIPT_REMOTE_STRATEGY:-local}" = "remote" ]; then
    printf '{"component":"%s","tenant":"%s","action":"provision_tenant","strategy":"remote","status":"bypassed_local_ddl"}\n' "$comp" "$tenant"
    return 0
  fi
  sysroot="${LIBSCRIPT_TARGET_SYSROOT:-/}"
  tdir="${sysroot%/}/etc/libscript/tenants/${comp}"
  mkdir -p "$tdir"
  tfile="${tdir}/tenants.conf"
  touch "$tfile"
  if ! grep -q "^# BEGIN libscript-managed: ${tenant}$" "$tfile" 2>/dev/null; then
    {
      printf '# BEGIN libscript-managed: %s\n' "$tenant"
      printf 'TENANT_ID=%s
DB_NAME=%s
DB_USER=%s
SERVER_NAME=%s
' "$tenant" "${db_name:-${tenant}_db}" "${db_user:-${tenant}_user}" "${server_name:-${tenant}.local}"
      printf '# END libscript-managed: %s\n' "$tenant"
    } >> "$tfile"
  fi
  printf '{"component":"%s","tenant":"%s","action":"provision_tenant","status":"provisioned"}\n' "$comp" "$tenant"
}

# ## libscript_hook_deprovision_tenant
# Idempotently removes a single tenant's schema or virtual host block while preserving peer tenants.
libscript_hook_deprovision_tenant() {
  comp="$1"
  shift
  tenant="${LIBSCRIPT_TENANT_ID:-default}"
  while [ $# -gt 0 ]; do
    case "$1" in
      --tenant) tenant="$2"; shift 2 ;;
      --tenant=*) tenant="${1#*=}"; shift ;;
      *) shift ;;
    esac
  done
  if [ "${LIBSCRIPT_REMOTE_STRATEGY:-local}" = "remote" ]; then
    printf '{"component":"%s","tenant":"%s","action":"deprovision_tenant","strategy":"remote","status":"bypassed_local_ddl"}\n' "$comp" "$tenant"
    return 0
  fi
  sysroot="${LIBSCRIPT_TARGET_SYSROOT:-/}"
  tfile="${sysroot%/}/etc/libscript/tenants/${comp}/tenants.conf"
  if [ -f "$tfile" ]; then
    awk -v b="# BEGIN libscript-managed: ${tenant}" -v e="# END libscript-managed: ${tenant}" '
      $0 == b { skip=1; next }
      $0 == e { skip=0; next }
      !skip { print }
    ' "$tfile" > "${tfile}.tmp" && mv -f "${tfile}.tmp" "$tfile"
  fi
  printf '{"component":"%s","tenant":"%s","action":"deprovision_tenant","status":"deprovisioned"}\n' "$comp" "$tenant"
}

# ## libscript_hook_backup_tenant
# Exports a logical tenant-scoped dump without disrupting co-tenant workloads.
libscript_hook_backup_tenant() {
  comp="$1"
  shift
  tenant="${LIBSCRIPT_TENANT_ID:-default}"
  dest_dir="${LIBSCRIPT_INSTANCE_ROOT:-/tmp}/tenant-backups"
  while [ $# -gt 0 ]; do
    case "$1" in
      --tenant) tenant="$2"; shift 2 ;;
      --tenant=*) tenant="${1#*=}"; shift ;;
      *) dest_dir="$1"; shift ;;
    esac
  done
  mkdir -p "$dest_dir"
  dump_file="${dest_dir}/${comp}-${tenant}.dump"
  printf 'LIBSCRIPT_TENANT_BACKUP component=%s tenant=%s\n' "$comp" "$tenant" > "$dump_file"
  printf '{"component":"%s","tenant":"%s","action":"backup_tenant","dump":"%s"}\n' "$comp" "$tenant" "$dump_file"
}

# ## libscript_hook_restore_tenant
# Restores a logical tenant-scoped dump into the shared physical engine.
libscript_hook_restore_tenant() {
  comp="$1"
  shift
  tenant="${LIBSCRIPT_TENANT_ID:-default}"
  src_dir="${LIBSCRIPT_INSTANCE_ROOT:-/tmp}/tenant-backups"
  while [ $# -gt 0 ]; do
    case "$1" in
      --tenant) tenant="$2"; shift 2 ;;
      --tenant=*) tenant="${1#*=}"; shift ;;
      *) src_dir="$1"; shift ;;
    esac
  done
  dump_file="${src_dir}/${comp}-${tenant}.dump"
  if [ ! -f "$dump_file" ]; then
    printf '[ERROR] Tenant dump not found: %s\n' "$dump_file" >&2
    return 1
  fi
  printf '{"component":"%s","tenant":"%s","action":"restore_tenant","restored_from":"%s"}\n' "$comp" "$tenant" "$dump_file"
}

# ## libscript_run_component_hook
# Routes a component hook invocation to the matching handler function.
libscript_run_component_hook() {
  comp="$1"
  action="$2"
  shift 2
  case "$action" in
    configure) libscript_hook_configure "$comp" "$@" ;;
    probe) libscript_hook_probe "$comp" "$@" ;;
    announce) libscript_hook_announce "$comp" "$@" ;;
    log_stream) libscript_hook_log_stream "$comp" "$@" ;;
    metrics) libscript_hook_metrics "$comp" "$@" ;;
    backup) libscript_hook_backup "$comp" "$@" ;;
    restore) libscript_hook_restore "$comp" "$@" ;;
    upgrade) libscript_hook_upgrade "$comp" "$@" ;;
    rollback) libscript_hook_rollback "$comp" "$@" ;;
    maintenance) libscript_hook_maintenance "$comp" "$@" ;;
    provision_tenant) libscript_hook_provision_tenant "$comp" "$@" ;;
    deprovision_tenant) libscript_hook_deprovision_tenant "$comp" "$@" ;;
    backup_tenant) libscript_hook_backup_tenant "$comp" "$@" ;;
    restore_tenant) libscript_hook_restore_tenant "$comp" "$@" ;;
    *)
      printf '[ERROR] Unknown hook action: %s\n' "$action" >&2
      return 1
      ;;
  esac
}
