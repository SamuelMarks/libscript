#!/bin/sh
# ## Overview
# Backend orchestrator for the deploy-remote command. Handles checksum state, sync, and DB setup.
# 
# ## Usage
# Internally invoked via cli/commands/cloud/deploy-remote.sh.

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
_dr_saved_this="$THIS_FILE"
_dr_saved_dir="$SCRIPT_DIR"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true
THIS_FILE="$_dr_saved_this"
SCRIPT_DIR="$_dr_saved_dir"
unset _dr_saved_this _dr_saved_dir || true

# Delegate to deploy_cloud.sh when --provider is specified
for _dr_arg in "$@"; do
  case "$_dr_arg" in
    --provider|--provider=*)
      exec "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/deploy_cloud.sh" "$@"
      ;;
  esac
done

if [ $# -lt 1 ]; then
  log_error 'Usage: deploy_remote.sh <user@host> [--app <path>@<domain>]... [--shared-db <engine>]'
  exit 1
fi

TARGET_HOST="$1"
shift

# Arrays via delimited strings for POSIX compliance
APPS_PATHS=""
APPS_DOMAINS=""
SHARED_DB=""
FORCE_REINSTALL="${FORCE_REINSTALL:-0}"
FORCE_REBUILD="${FORCE_REBUILD:-0}"
DRY_RUN_MODE="${DRY_RUN_MODE:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --app)
      if [ -z "${2:-}" ]; then
        log_error '--app requires an argument format: <path>@<domain>'
        exit 1
      fi
      raw_app="$2"
      app_path="${raw_app%%@*}"
      app_domain="${raw_app#*@}"
      APPS_PATHS="${APPS_PATHS}${app_path}|"
      APPS_DOMAINS="${APPS_DOMAINS}${app_domain}|"
      shift 2
      ;;
    --shared-db)
      if [ -z "${2:-}" ]; then
        log_error '--shared-db requires an engine (e.g. postgres)'
        exit 1
      fi
      SHARED_DB="$2"
      shift 2
      ;;
    --force-reinstall)
      FORCE_REINSTALL=1
      shift
      ;;
    --force-rebuild)
      FORCE_REBUILD=1
      shift
      ;;
    --dry-run|-n)
      DRY_RUN_MODE=1
      shift
      ;;
    --skip-infra|--skip-prepare|--skip-verify)
      shift
      ;;
    *)
      log_error "Unknown argument: $1"
      exit 1
      ;;
  esac
done

# ## calculate_checksum
# Computes a deterministic digest of an application repository including git HEAD, dirty diff, untracked files, and env files.
calculate_checksum() {
  local_path="$1"
  if [ -d "$local_path/.git" ] && command -v git >/dev/null 2>&1; then
    _dr_git=$(git -C "$local_path" rev-parse HEAD 2>/dev/null || printf 'nogit')
    _dr_dirty=$(
      {
        git -C "$local_path" status --porcelain 2>/dev/null || true
        git -C "$local_path" diff HEAD 2>/dev/null || true
        git -C "$local_path" ls-files --others --exclude-standard 2>/dev/null | while IFS= read -r _uf; do
          [ -n "$_uf" ] && [ -f "${local_path}/${_uf}" ] && cksum "${local_path}/${_uf}" 2>/dev/null || true
        done
        cat "${local_path}/libscript.json" "${local_path}/.env" "${local_path}/.env.secrets" 2>/dev/null || true
      } | cksum 2>/dev/null | awk '{print $1"_"$2}' || printf '0'
    )
    printf '%s_%s\n' "$_dr_git" "$_dr_dirty"
  else
    find "$local_path" -type f -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/target/*" -not -path "*/.venv/*" -not -path "*/venv/*" -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/.angular/*" -not -path "*/.vite/*" -not -path "*/__pycache__/*" -exec cksum {} + 2>/dev/null | sort | cksum | awk '{print $1"_"$2}'
  fi
}

# ## provision_shared_db
# Performs the provision_shared_db operation and updates component state.
provision_shared_db() {
  if [ -n "$SHARED_DB" ]; then
    log_info "Provisioning shared DB ($SHARED_DB) on $TARGET_HOST (if missing)..."
    if [ "$SHARED_DB" = "postgres" ]; then
      # shellcheck disable=SC2029
      ssh "$TARGET_HOST" "if [ -f \$HOME/libscript/_lib/databases/postgres/env.sh ]; then STACK='' SCRIPT_NAME=\$HOME/libscript/_lib/databases/postgres/env.sh . \$HOME/libscript/_lib/databases/postgres/env.sh >/dev/null 2>&1 || true; fi; command -v psql >/dev/null 2>&1 || \$HOME/libscript/libscript.sh install $SHARED_DB latest; if [ -f \$HOME/libscript/_lib/databases/postgres/env.sh ]; then STACK='' SCRIPT_NAME=\$HOME/libscript/_lib/databases/postgres/env.sh . \$HOME/libscript/_lib/databases/postgres/env.sh >/dev/null 2>&1 || true; fi; pg_isready >/dev/null 2>&1 || \$HOME/libscript/libscript.sh start $SHARED_DB"
    else
      # shellcheck disable=SC2029
      ssh "$TARGET_HOST" "\$HOME/libscript/libscript.sh install $SHARED_DB latest && \$HOME/libscript/libscript.sh start $SHARED_DB"
    fi
  fi
}

# ## setup_app_db
# Performs the setup_app_db operation and updates component state.
setup_app_db() {
  app_name="$1"
  needs_db="$2"
  # shellcheck disable=SC2029
  ssh "$TARGET_HOST" "cd \"\$HOME/apps/$app_name\" && if [ -f libscript.json ]; then if [ -f \$HOME/libscript/_lib/_common/env_printer.sh ]; then STACK='' SCRIPT_NAME=\$HOME/libscript/_lib/_common/env_printer.sh . \$HOME/libscript/_lib/_common/env_printer.sh && libscript_hydrate_manifest_env libscript.json || true; fi; REMOTE_HOME=\$HOME LIBSCRIPT_HOME=\$HOME/.libscript LIBSCRIPT_ROOT_DIR=\$HOME/libscript \$HOME/libscript/_lib/databases/provision_db.sh libscript.json; fi"
  if [ "$needs_db" -eq 1 ] && [ "$SHARED_DB" = "postgres" ]; then
    safe_db_name=$(printf "%s" "$app_name" | tr '-' '_')
    log_info "Ensuring DB $safe_db_name exists on $TARGET_HOST..."
    # shellcheck disable=SC2029
    ssh "$TARGET_HOST" "if [ -f \$HOME/libscript/_lib/databases/postgres/env.sh ]; then STACK='' SCRIPT_NAME=\$HOME/libscript/_lib/databases/postgres/env.sh . \$HOME/libscript/_lib/databases/postgres/env.sh >/dev/null 2>&1 || true; fi; \$HOME/libscript/_lib/databases/provision_schema.sh --engine postgres --host 127.0.0.1 --port 5432 --admin-user postgres --schema $safe_db_name --user postgres --password postgres >/dev/null 2>&1 || createdb $safe_db_name 2>/dev/null || true"
    # shellcheck disable=SC2029
    ssh "$TARGET_HOST" "touch \$HOME/apps/$app_name/.env && grep -v '^DATABASE_URL=' \$HOME/apps/$app_name/.env > \$HOME/apps/$app_name/.env.tmp 2>/dev/null || true; printf 'DATABASE_URL=postgres://localhost:5432/%s\n' '$safe_db_name' >> \$HOME/apps/$app_name/.env.tmp && mv \$HOME/apps/$app_name/.env.tmp \$HOME/apps/$app_name/.env"
  fi
}

# ## execute_lifecycle_hooks
# Performs the execute_lifecycle_hooks operation and updates component state.
execute_lifecycle_hooks() {
  remote_dir="$1"
  app_name="$2"
  _dr_flags=""
  [ "$FORCE_REINSTALL" -eq 1 ] && _dr_flags="${_dr_flags} --force-reinstall"
  [ "$FORCE_REBUILD" -eq 1 ] && _dr_flags="${_dr_flags} --force-rebuild"
  log_info "Executing lifecycle hooks for $app_name..."
  # shellcheck disable=SC2029
  ssh "$TARGET_HOST" "cd \"$remote_dir\" && if [ -f libscript.json ]; then REMOTE_HOME=\$HOME LIBSCRIPT_HOME=\$HOME/.libscript LIBSCRIPT_ROOT_DIR=\$HOME/libscript \$HOME/libscript/libscript.sh install-deps libscript.json${_dr_flags} && REMOTE_HOME=\$HOME LIBSCRIPT_HOME=\$HOME/.libscript LIBSCRIPT_ROOT_DIR=\$HOME/libscript \$HOME/libscript/libscript.sh start libscript.json; fi"
}

# ## configure_routing
# Performs the configure_routing operation and updates component state.
configure_routing() {
  app_name="$1"
  domain="$2"
  remote_dir="$3"
  app_path="$4"
  log_info "Configuring routing for $app_name -> $domain..."
  
  is_static=0
  if [ ! -f "$app_path/libscript.json" ]; then
    if [ -f "$app_path/index.html" ]; then
      is_static=1
    else
      log_info "Warning: No libscript.json or index.html found in $app_path. Assuming static routing."
      is_static=1
    fi
  fi
  
  if [ "$is_static" -eq 1 ]; then
    # shellcheck disable=SC2029
    ssh "$TARGET_HOST" "\$HOME/libscript/_lib/networking/netctl/cli.sh --domain \"$domain\" --listen 80 --static / \"\$HOME/$remote_dir\" --emit nginx"
  elif [ -f "$app_path/libscript.json" ] && jq -e '.ingress != null' "$app_path/libscript.json" >/dev/null 2>&1; then
    # shellcheck disable=SC2029
    ssh "$TARGET_HOST" "cd \"\$HOME/$remote_dir\" && \$HOME/libscript/_lib/networking/netctl/cli.sh apply libscript.json --reload"
  else
    remote_port=3000
    if [ -f "$app_path/libscript.json" ]; then
      parsed_port=$(jq -r '.port // empty' < "$app_path/libscript.json" 2>/dev/null || true)
      if [ -n "$parsed_port" ] && [ "$parsed_port" != "null" ]; then remote_port="$parsed_port"; fi
    fi
    # shellcheck disable=SC2029
    ssh "$TARGET_HOST" "\$HOME/libscript/_lib/networking/netctl/cli.sh --domain \"$domain\" --listen 80 --proxy / \"http://127.0.0.1:${remote_port}\" --emit nginx"
  fi
}


provision_shared_db

# Use standard IFS trick for delimited parsing
OIFS="$IFS"
IFS="|"

# Process apps using arrays
# POSIX hack: set positional parameters to iterate
# shellcheck disable=SC2086
# ## print_remote_deployment_report
# Outputs an ASCII summary table of deployed applications, DNS domains, and healthcheck results.
print_remote_deployment_report() {
  printf '%s\n' '+----------------------------------------------------------------------------------------------------+'
  printf '| %-98s |\n' "LIBSCRIPT REMOTE DEPLOYMENT REPORT (Host: $TARGET_HOST)"
  printf '%s\n' '+----------------------------+--------------------------------+-------------------+------------------+'
  printf '| %-26s | %-30s | %-17s | %-16s |\n' 'Application' 'DNS / Public Endpoint' 'Sync Status' 'Healthcheck'
  printf '%s\n' '+----------------------------+--------------------------------+-------------------+------------------+'
  if [ -n "$REPORT_ROWS" ]; then
    printf '%s\n' "$REPORT_ROWS" | while IFS='|' read -r _r_app _r_url _r_sync _r_hc; do
      [ -n "$_r_app" ] || continue
      printf '| %-26s | %-30s | %-17s | %-16s |\n' "$_r_app" "$_r_url" "$_r_sync" "$_r_hc"
    done
  fi
  printf '%s\n' '+----------------------------+--------------------------------+-------------------+------------------+'
}

set -- $APPS_PATHS
path_idx=1
HEALTH_APPS=""
REPORT_ROWS=""

for app_path in "$@"; do
  if [ -z "$app_path" ]; then continue; fi
  
  # Extract domain matching the path index
  domain_idx=1
  app_domain=""
  for d in $APPS_DOMAINS; do
    if [ "$domain_idx" -eq "$path_idx" ]; then
      app_domain="$d"
      break
    fi
    domain_idx=$((domain_idx + 1))
  done
  
  app_name=$(basename "$app_path")
  local_sum=$(calculate_checksum "$app_path")
  remote_state_file="\$HOME/.libscript/deploy_state_$app_name"

  # shellcheck disable=SC2029
  remote_sum=$(ssh "$TARGET_HOST" "cat $remote_state_file 2>/dev/null" || true)

  _sync_state='SYNCED'
  if [ "$FORCE_REINSTALL" -eq 0 ] && [ "$FORCE_REBUILD" -eq 0 ] && [ "$local_sum" = "$remote_sum" ]; then
    log_info "[SKIPPED] $app_name -> https://$app_domain is live and up-to-date."
    _sync_state='UP-TO-DATE'
  else
    log_info "[SYNCING] $app_name -> https://$app_domain (local: $local_sum, remote: ${remote_sum:-none})"
    # shellcheck disable=SC2029
    ssh "$TARGET_HOST" "mkdir -p \$HOME/apps/$app_name"

    if command -v rsync >/dev/null 2>&1; then
      rsync -avz --delete --filter="P .env" --filter="P .env.secrets" --filter="P .env.libscript" --filter="P data" --exclude=".git" --exclude="node_modules" --exclude="target" --exclude=".venv" --exclude="venv" --exclude=".angular" --exclude=".vite" --exclude=".next" --exclude=".nuxt" --exclude=".turbo" --exclude=".parcel-cache" --exclude=".cache" --exclude=".tox" --exclude=".nox" --exclude=".terraform" --exclude=".mypy_cache" --exclude=".pytest_cache" --exclude=".ruff_cache" --exclude="__pycache__" --exclude="*.pyc" --exclude="*.pyo" --exclude=".DS_Store" --exclude="dist" --exclude="build" --exclude="webroot" --exclude=".libscript_build.sha256" --exclude=".libscript_src_hash" --exclude=".env.libscript" --exclude=".gradle" --exclude=".kotlin" --exclude="htmlcov" --exclude="coverage" --exclude=".coverage" --exclude="coverage.*" --exclude="combined-coverage.*" --exclude="test-results" --exclude="playwright-report" --exclude="documentation" --exclude="e2e_test.db" --exclude="logs" --exclude="*.duckdb" --exclude="*.duckdb.wal" "$app_path/" "$TARGET_HOST:apps/$app_name/"
    elif command -v tar >/dev/null 2>&1 && [ -d "$app_path" ]; then
      # shellcheck disable=SC2029
      tar -czf - -C "$app_path" --exclude=".git" --exclude="node_modules" --exclude="target" --exclude=".venv" --exclude="venv" --exclude=".angular" --exclude=".vite" --exclude=".next" --exclude=".nuxt" --exclude=".turbo" --exclude=".parcel-cache" --exclude=".cache" --exclude=".tox" --exclude=".nox" --exclude=".terraform" --exclude=".mypy_cache" --exclude=".pytest_cache" --exclude=".ruff_cache" --exclude="__pycache__" --exclude="*.pyc" --exclude="*.pyo" --exclude=".DS_Store" --exclude="dist" --exclude="build" --exclude="webroot" --exclude=".libscript_build.sha256" --exclude=".libscript_src_hash" --exclude=".env.libscript" --exclude=".gradle" --exclude=".kotlin" --exclude="htmlcov" --exclude="coverage" --exclude=".coverage" --exclude="test-results" --exclude="playwright-report" --exclude="documentation" --exclude="e2e_test.db" --exclude="logs" --exclude="*.duckdb" --exclude="*.duckdb.wal" . | ssh "$TARGET_HOST" "mkdir -p \$HOME/apps/$app_name && find \$HOME/apps/$app_name -mindepth 1 \( -name .git -o -name node_modules -o -name .venv -o -name venv -o -name dist -o -name build -o -name .angular -o -name .vite -o -name webroot -o -name logs -o -name data -o -name '.env*' -o -name '*.duckdb*' -o -name '.libscript_*' \) -prune -o -type f -exec rm -f {} + 2>/dev/null || true; tar -xzf - -C \$HOME/apps/$app_name && find \$HOME/apps/$app_name -depth -type d -empty -exec rmdir {} + 2>/dev/null || true"
    else
      scp -r "$app_path/"* "$TARGET_HOST:apps/$app_name/"
    fi

    # Save new state
    # shellcheck disable=SC2029
    ssh "$TARGET_HOST" "mkdir -p \$HOME/.libscript && echo \"$local_sum\" > $remote_state_file"
    
    # Check if this app needs the shared DB based on libscript.json dependencies
    needs_db=0
    if [ -f "$app_path/libscript.json" ] && [ -n "$SHARED_DB" ]; then
      if command -v jq >/dev/null 2>&1; then
        has_db=$(jq -r ".dependencies[\"$SHARED_DB\"] // empty" "$app_path/libscript.json")
        if [ -n "$has_db" ]; then needs_db=1; fi
      else
        if grep -q "\"$SHARED_DB\"" "$app_path/libscript.json"; then needs_db=1; fi
      fi
    fi
    
    setup_app_db "$app_name" "$needs_db"
    
    execute_lifecycle_hooks "apps/$app_name" "$app_name"
    configure_routing "$app_name" "$app_domain" "apps/$app_name" "$app_path"
  fi
  
  _hc_state='STATIC'
  if [ -f "$app_path/libscript.json" ]; then
    HEALTH_APPS="$HEALTH_APPS $app_name"
    # shellcheck disable=SC2029
    if ssh "$TARGET_HOST" "cd \$HOME/apps/$app_name && LIBSCRIPT_ROOT_DIR=\$HOME/libscript \$HOME/libscript/libscript.sh health libscript.json"; then
      _hc_state='PASS (200 OK)'
    else
      _hc_state='FAIL'
    fi
  fi
  REPORT_ROWS="${REPORT_ROWS}${app_name}|https://${app_domain}|${_sync_state}|${_hc_state}
"
  
  path_idx=$((path_idx + 1))
done

IFS="$OIFS"

print_remote_deployment_report
log_info 'Deployment remote complete.'
