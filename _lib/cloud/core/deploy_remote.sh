#!/bin/sh
# ## Overview
# Backend orchestrator for the deploy-remote command. Handles checksum state, sync, and DB setup.
# 
# ## Usage
# Internally invoked via cli/commands/cloud/deploy-remote.sh.

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"

if [ $# -lt 1 ]; then
  log_error "Usage: deploy_remote.sh <user@host> [--app <path>@<domain>]... [--shared-db <engine>]"
  exit 1
fi

TARGET_HOST="$1"
shift

# Arrays via delimited strings for POSIX compliance
APPS_PATHS=""
APPS_DOMAINS=""
SHARED_DB=""

while [ $# -gt 0 ]; do
  case "$1" in
    --app)
      if [ -z "${2:-}" ]; then
        log_error "--app requires an argument format: <path>@<domain>"
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
        log_error "--shared-db requires an engine (e.g. postgres)"
        exit 1
      fi
      SHARED_DB="$2"
      shift 2
      ;;
    *)
      log_error "Unknown argument: $1"
      exit 1
      ;;
  esac
done

# ## calculate_checksum
# Executes calculate_checksum functionality.
calculate_checksum() {
  local_path="$1"
  if [ -d "$local_path/.git" ] && command -v git >/dev/null 2>&1; then
    cd "$local_path" && git rev-parse HEAD
  else
    find "$local_path" -type f -not -path "*/.git/*" -not -path "*/node_modules/*" -exec sha256sum {} + | sha256sum | awk '{print $1}'
  fi
}

# ## provision_shared_db
# Executes provision_shared_db functionality.
provision_shared_db() {
  if [ -n "$SHARED_DB" ]; then
    log_info "Provisioning shared DB ($SHARED_DB) on $TARGET_HOST (if missing)..."
    if [ "$SHARED_DB" = "postgres" ]; then
      # shellcheck disable=SC2029
      ssh "$TARGET_HOST" "command -v psql >/dev/null 2>&1 || \$HOME/libscript/libscript.sh install $SHARED_DB latest; pg_isready >/dev/null 2>&1 || \$HOME/libscript/libscript.sh start $SHARED_DB"
    else
      # shellcheck disable=SC2029
      ssh "$TARGET_HOST" "\$HOME/libscript/libscript.sh install $SHARED_DB latest && \$HOME/libscript/libscript.sh start $SHARED_DB"
    fi
  fi
}

# ## setup_app_db
# Executes setup_app_db functionality.
setup_app_db() {
  app_name="$1"
  needs_db="$2"
  if [ "$needs_db" -eq 1 ] && [ "$SHARED_DB" = "postgres" ]; then
    safe_db_name=$(printf "%s" "$app_name" | tr '-' '_')
    log_info "Ensuring DB $safe_db_name exists on $TARGET_HOST..."
    # shellcheck disable=SC2029
    ssh "$TARGET_HOST" "psql -lqt | cut -d \\| -f 1 | grep -qw $safe_db_name || createdb $safe_db_name"
    # shellcheck disable=SC2029
    ssh "$TARGET_HOST" "touch \$HOME/apps/$app_name/.env && grep -qxF 'DATABASE_URL=postgres://localhost:5432/$safe_db_name' \$HOME/apps/$app_name/.env || echo 'DATABASE_URL=postgres://localhost:5432/$safe_db_name' >> \$HOME/apps/$app_name/.env"
  fi
}

# ## execute_lifecycle_hooks
# Executes execute_lifecycle_hooks functionality.
execute_lifecycle_hooks() {
  remote_dir="$1"
  app_name="$2"
  log_info "Executing lifecycle hooks for $app_name..."
  # shellcheck disable=SC2029
  ssh "$TARGET_HOST" "cd \"$remote_dir\" && if [ -f libscript.json ]; then \$HOME/libscript/libscript.sh install-deps; fi"
  # shellcheck disable=SC2029
  ssh "$TARGET_HOST" "cd \"$remote_dir\" && if [ -f libscript.json ]; then LIBSCRIPT_ROOT_DIR=\$HOME/libscript \$HOME/libscript/_lib/orchestration/run_hooks.sh libscript.json install; fi"
  # shellcheck disable=SC2029
  ssh "$TARGET_HOST" "cd \"$remote_dir\" && if [ -f libscript.json ]; then LIBSCRIPT_ROOT_DIR=\$HOME/libscript \$HOME/libscript/_lib/init-systems/daemonize.sh stop libscript.json && LIBSCRIPT_ROOT_DIR=\$HOME/libscript \$HOME/libscript/_lib/init-systems/daemonize.sh start libscript.json; fi"
}

# ## configure_routing
# Executes configure_routing functionality.
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
    ssh "$TARGET_HOST" "\$HOME/libscript/netctl/netctl.sh route add \"$app_name\" \"$domain\" --static \"\$HOME/$remote_dir\""
  else
    remote_port=3000
    if [ -f "$app_path/libscript.json" ]; then
      parsed_port=$(jq -r '.port // empty' < "$app_path/libscript.json" 2>/dev/null || true)
      if [ -n "$parsed_port" ] && [ "$parsed_port" != "null" ]; then remote_port="$parsed_port"; fi
    fi
    # shellcheck disable=SC2029
    ssh "$TARGET_HOST" "\$HOME/libscript/netctl/netctl.sh route add \"$app_name\" \"$domain\" --port \"$remote_port\""
  fi
}


provision_shared_db

# Use standard IFS trick for delimited parsing
OIFS="$IFS"
IFS="|"

# Process apps using arrays
# POSIX hack: set positional parameters to iterate
set -- "$APPS_PATHS"
path_idx=1
HEALTH_APPS=""

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

  if [ "$local_sum" = "$remote_sum" ]; then
    log_info "[SKIPPED] $app_name -> https://$app_domain is live and up-to-date."
  else
    log_info "[SYNCING] $app_name -> https://$app_domain (local: $local_sum, remote: ${remote_sum:-none})"
    # shellcheck disable=SC2029
    ssh "$TARGET_HOST" "mkdir -p \$HOME/apps/$app_name"

    if command -v rsync >/dev/null 2>&1; then
      rsync -avz --exclude=".git" --exclude="node_modules" "$app_path/" "$TARGET_HOST:apps/$app_name/"
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
  
  if [ -f "$app_path/libscript.json" ]; then
    HEALTH_APPS="$HEALTH_APPS $app_name"
  fi
  
  path_idx=$((path_idx + 1))
done

IFS="$OIFS"

if [ -n "$HEALTH_APPS" ]; then
  log_info "Running health checks for backend services:$HEALTH_APPS..."
  for app in $HEALTH_APPS; do
    # shellcheck disable=SC2029
    ssh "$TARGET_HOST" "cd \$HOME/apps/$app && LIBSCRIPT_ROOT_DIR=\$HOME/libscript \$HOME/libscript/_lib/init-systems/daemonize.sh status libscript.json" || true
  done
fi

log_info "Deployment remote complete."
