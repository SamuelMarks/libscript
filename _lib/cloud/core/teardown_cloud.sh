#!/bin/sh
# ## Overview
# Teardown orchestrator for cloud infrastructure and remote applications.
#
# ## Usage
# Run `teardown_cloud.sh <provider> <node> <rg> <loc> [options]` to cleanly remove applications or VMs/VPCs.

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
_TEARDOWN_SCRIPT_DIR="$SCRIPT_DIR"
_TEARDOWN_THIS_FILE="$THIS_FILE"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true
SCRIPT_DIR="$_TEARDOWN_SCRIPT_DIR"
THIS_FILE="$_TEARDOWN_THIS_FILE"

IS_TPU=0
export SHARED_STORAGE=0
RETAIN_IP=0
RETAIN_DATA=0
KEEP_INFRA=0
PURGE_DATA="${PURGE_DATA:-0}"
ONLY_TARGET="${ONLY_TARGET:-all}"
DRY_RUN_MODE=0
if [ "${DRY_RUN:-false}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
  DRY_RUN_MODE=1
  export DRY_RUN='true'
fi

PROVIDER="${CLOUD_PROVIDER:-${PROVIDER:-}}"
NODE="${NODE_NAME:-}"
RG="${RG_NAME:-}"
LOC="${LOCATION:-eastus}"
ADMIN_USER="${ADMIN_USER:-azureuser}"
APP_SPECS=""

_p1="" _p2="" _p3="" _p4="" _p5="" _p6=""

while [ $# -gt 0 ]; do
  case "$1" in
    --tpu|--accelerator) IS_TPU=1; shift ;;
    --shared-storage) export SHARED_STORAGE=1; shift ;;
    --retain-ip) RETAIN_IP=1; shift ;;
    --retain-data) RETAIN_DATA=1; shift ;;
    --keep-infra|--remove-app) KEEP_INFRA=1; shift ;;
    --purge-data) PURGE_DATA=1; shift ;;
    --dry-run|-n) DRY_RUN_MODE=1; export DRY_RUN="true"; shift ;;
    --only=*) ONLY_TARGET="${1#*=}"; shift ;;
    --only) ONLY_TARGET="${2:-all}"; shift 2 ;;
    --provider=*) PROVIDER="${1#*=}"; shift ;;
    --provider) PROVIDER="${2:-}"; shift 2 ;;
    --node=*) NODE="${1#*=}"; shift ;;
    --node) NODE="${2:-}"; shift 2 ;;
    --rg=*|--resource-group=*) RG="${1#*=}"; shift ;;
    --rg|--resource-group) RG="${2:-}"; shift 2 ;;
    --location=*) LOC="${1#*=}"; shift ;;
    --location) LOC="${2:-}"; shift 2 ;;
    --admin-user=*|--admin-username=*) ADMIN_USER="${1#*=}"; shift ;;
    --admin-user|--admin-username) ADMIN_USER="${2:-}"; shift 2 ;;
    --app=*) APP_SPECS="${APP_SPECS}${1#*=}|"; KEEP_INFRA=1; shift ;;
    --app) APP_SPECS="${APP_SPECS}${2:-}|"; KEEP_INFRA=1; shift 2 ;;
    *)
      if [ -z "$_p1" ]; then _p1="$1"
      elif [ -z "$_p2" ]; then _p2="$1"
      elif [ -z "$_p3" ]; then _p3="$1"
      elif [ -z "$_p4" ]; then _p4="$1"
      elif [ -z "$_p5" ]; then _p5="$1"
      elif [ -z "$_p6" ]; then _p6="$1"
      fi
      shift
      ;;
  esac
done

[ -z "$PROVIDER" ] && PROVIDER="$_p1"
[ -z "$NODE" ] && NODE="$_p2"
[ -z "$RG" ] && RG="$_p3"
[ -n "$_p4" ] && LOC="$_p4"
REPO_PATH="${_p5:-.}"
REMOTE_DEST="${_p6:-~/$NODE}"

if [ -z "$PROVIDER" ] || [ -z "$NODE" ] || [ -z "$RG" ]; then
  log_info 'Usage: teardown_cloud.sh [options] <provider> <node_name> <rg_or_vpc_or_project> [region_or_zone] [local_repo_path] [remote_dest]'
  exit 1
fi

export AZURE_LOCATION="$LOC"
export LOCATION="$LOC"
export ADMIN_USER

CLI="$SCRIPT_DIR/../../cloud-providers/$PROVIDER/cli.sh"
if [ ! -f "$CLI" ]; then
  printf '%s\n' "Provider $PROVIDER not supported." >&2
  exit 1
fi

CTX="$RG"
if [ "$PROVIDER" = "aws" ] || [ "$PROVIDER" = "gcp" ]; then CTX="$LOC"; fi

# ## matches_only_target
# Checks whether an application remote destination or manifest alias matches the --only selector.
matches_only_target() {
  _mot_dest="$1"
  _mot_repo="${2:-}"
  case "$ONLY_TARGET" in
    all|both|"") return 0 ;;
    *)
      [ "$_mot_dest" = "$ONLY_TARGET" ] && return 0
      _mot_norm_target=$(printf '%s' "$ONLY_TARGET" | tr '_-' '--')
      _mot_norm_dest=$(printf '%s' "$_mot_dest" | tr '_-' '--')
      [ "$_mot_norm_dest" = "$_mot_norm_target" ] && return 0
      for _mot_cand in "${_mot_repo}/libscript.json" "${_mot_dest}/libscript.json" "./${_mot_dest}/libscript.json"; do
        if [ -f "$_mot_cand" ] && command -v jq >/dev/null 2>&1; then
          if jq -e --arg t "$ONLY_TARGET" --arg tn "$_mot_norm_target" '([.name, .remote_dest, (.aliases // [])[]?] | map(select(. != null) | tostring)) | any(. == $t or (gsub("_"; "-") == $tn))' "$_mot_cand" >/dev/null 2>&1; then
            return 0
          fi
        fi
      done
      return 1
      ;;
  esac
}

if [ -z "$APP_SPECS" ] && [ -f "${REPO_PATH}/libscript.json" ] && command -v jq >/dev/null 2>&1 && jq -e '.applications != null and (.applications | length > 0)' "${REPO_PATH}/libscript.json" >/dev/null 2>&1; then
  _base_dir=$(cd -- "$REPO_PATH" && pwd)
  _manifest_apps=$(jq -r '.applications[] | "\(.path // .name):\(.remote_dest // .name)@\(.domain // "")"' "${REPO_PATH}/libscript.json" 2>/dev/null || true)
  while IFS= read -r _ma_line; do
    [ -n "$_ma_line" ] || continue
    _ma_p="${_ma_line%%:*}"
    _ma_rest="${_ma_line#*:}"
    case "$_ma_p" in
      /*) ;;
      *) _ma_p="${_base_dir}/${_ma_p}" ;;
    esac
    APP_SPECS="${APP_SPECS}${_ma_p}:${_ma_rest}|"
  done << EOF_TEARDOWN_APPS
$_manifest_apps
EOF_TEARDOWN_APPS
fi

if [ "$KEEP_INFRA" -eq 1 ] && [ -n "$APP_SPECS" ]; then
  log_info "Removing target '${ONLY_TARGET}' from '${NODE}' (purge_data=${PURGE_DATA})..."
  "$CLI" node sync "$NODE" "$CTX"
  _purge_flag=""
  [ "$PURGE_DATA" -eq 1 ] && _purge_flag=" --purge-data"
  OIFS="$IFS"
  IFS="|"
  # shellcheck disable=SC2086
  set -- $APP_SPECS
  IFS="$OIFS"
  for _rm_spec in "$@"; do
    [ -n "$_rm_spec" ] || continue
    _rm_no_dom="${_rm_spec%%@*}"
    case "$_rm_no_dom" in
      *:*) _rm_repo="${_rm_no_dom%%:*}"; _rm_dest="${_rm_no_dom#*:}" ;;
      *) _rm_repo="$_rm_no_dom"; _rm_dest=$(basename "$_rm_no_dom") ;;
    esac
    if ! matches_only_target "$_rm_dest" "$_rm_repo"; then
      continue
    fi
    log_info "Decommissioning '${_rm_dest}' on '${NODE}' via LibScript..."
    "$CLI" node exec "$NODE" "$CTX" "if [ -f ~/${_rm_dest}/libscript.json ]; then cd ~/${_rm_dest} && sudo LIBSCRIPT_ROOT_DIR=\"\$(cd ~/libscript && pwd)\" ~/libscript/libscript.sh down libscript.json --remove${_purge_flag} && sudo LIBSCRIPT_ROOT_DIR=\"\$(cd ~/libscript && pwd)\" ~/libscript/libscript.sh netctl remove-ingress libscript.json; fi; sudo rm -rf ~/${_rm_dest}"
  done
  log_info "Removal of '${ONLY_TARGET}' completed successfully."
  exit 0
fi

if [ "$DRY_RUN_MODE" -eq 1 ]; then
  log_info "[DRY_RUN] Simulated deprovision for $PROVIDER $NODE $RG $LOC"
  exit 0
fi

LOG_DIR="$REPO_PATH/logs"
mkdir -p "$LOG_DIR" 2>/dev/null || LOG_DIR="${TMPDIR:-/tmp}"
TIMESTAMP=$(date +%s)
LOG_FILE="$LOG_DIR/teardown-${TIMESTAMP}.log"

# ## log
# Formats and emits a timestamped log message at the specified severity level.
log() {
  printf '%s\n' "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2" | tee -a "$LOG_FILE"
}

log "INIT" "Starting $PROVIDER teardown for $NODE..."

STATE_FILE="$REPO_PATH/.deploy_state"
# ## get_state
# Performs the get_state operation and updates component state.
get_state() {
  key=$1
  if [ -f "$STATE_FILE" ]; then
    grep "^${key}=" "$STATE_FILE" | cut -d= -f2- || true
  fi
}

JSON_FILE="$REPO_PATH/libscript.json"
DOMAIN=""
DNS_RG=""
STATE_BUCKET=""
STATE_ENDPOINT=""
STATE_PATHS=""

if [ -f "$JSON_FILE" ] && command -v jq >/dev/null 2>&1; then
  DOMAIN=$(jq -r '.domain // ""' "$JSON_FILE")
  DNS_RG=$(jq -r '.infrastructure.dns.resource_group // ""' "$JSON_FILE")
  STATE_BUCKET=$(jq -r '.state.bucket // ""' "$JSON_FILE")
  STATE_ENDPOINT=$(jq -r '.state.endpoint // ""' "$JSON_FILE")
  STATE_PATHS=$(jq -r '.state.paths[]? // empty' "$JSON_FILE")
fi

# ## ensure_cli
# Ensures required CLI commands and packages are installed.
ensure_cli() {
  cmd=$1
  pkg=$2
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log "INFO" "Command '$cmd' not found. Installing '$pkg' via LibScript..."
    "$SCRIPT_DIR/../../../libscript.sh" install "$pkg" "latest" || {
      log "ERROR" "Failed to auto-install $pkg. Please install it manually."
      exit 1
    }
    export PATH="${PREFIX:-$LIBSCRIPT_ROOT_DIR/installed/$pkg}/bin:$PATH"
  fi
}

if [ "$PROVIDER" = "azure" ]; then
  ensure_cli "az" "azure-cli"
elif [ "$PROVIDER" = "aws" ]; then
  ensure_cli "aws" "awscli"
elif [ "$PROVIDER" = "gcp" ]; then
  ensure_cli "gcloud" "google-cloud-sdk"
fi

# ## run_with_auth_check
# Performs the run_with_auth_check operation and updates component state.
run_with_auth_check() {
  cmd="$1"
  shift
  exit_code=0
  output_file="$LOG_DIR/auth_check.tmp"
  "$cmd" "$@" > "$output_file" 2>&1 || exit_code=$?
  if [ "$exit_code" -eq 0 ]; then
    cat "$output_file" >> "$LOG_FILE"
    rm -f "$output_file"
    return 0
  fi
  cat "$output_file" >> "$LOG_FILE"
  rm -f "$output_file"
  return $exit_code
}

log "STOP" "Stopping remote stack..."
run_with_auth_check "$CLI" node exec "$NODE" "$CTX" "cd $REMOTE_DEST && sudo ~/libscript/libscript.sh stop" || true

if [ -n "$STATE_PATHS" ]; then
  for PATH_ITEM in $STATE_PATHS; do
    log "SYNC" "Syncing $PATH_ITEM from node to prevent data loss..."
    run_with_auth_check "$CLI" node scp-from "$NODE" "$CTX" "$REMOTE_DEST/$PATH_ITEM" "$REPO_PATH/$PATH_ITEM" || true
  done
fi

if [ -n "$DOMAIN" ] && [ "$RETAIN_IP" -eq 0 ]; then
  log "DNS" "Unmapping DNS..."
  if [ "$PROVIDER" = "azure" ]; then
    ZONE_NAME=$(printf '%s\n' "$DOMAIN" | awk -F. '{print $(NF-1)"."$NF}')
    TARGET_DNS_RG="${DNS_RG:-${ZONE_NAME}-rg}"
    run_with_auth_check "$CLI" dns unmap-node "$NODE" "$RG" "$DOMAIN" "$ZONE_NAME" "$TARGET_DNS_RG" || true
  elif [ "$PROVIDER" = "gcp" ]; then
    ZONE_NAME=$(printf '%s\n' "$DOMAIN" | awk -F. '{print $(NF-1)"-"$NF}')
    run_with_auth_check "$CLI" dns unmap-node "$NODE" "$LOC" "$DOMAIN" "$ZONE_NAME" || true
  fi
fi

log "INFRA" "Deleting Node..."
if [ "$IS_TPU" -eq 1 ] && [ "$PROVIDER" = "gcp" ]; then
  TPU_CLI="$SCRIPT_DIR/../../cloud-providers/gcp-tpu-vm/cli.sh"
  run_with_auth_check "$TPU_CLI" delete "$NODE" || true
else
  run_with_auth_check "$CLI" node delete "$NODE" "$CTX" || true
fi

log "INFRA" "Deleting Firewall..."
if [ "$PROVIDER" = "azure" ]; then
  run_with_auth_check "$CLI" firewall delete "${NODE}-nsg" "$RG" || true
elif [ "$PROVIDER" = "gcp" ]; then
  run_with_auth_check "$CLI" firewall delete "${NODE}-fw" || true
fi

log "INFRA" "Deleting Network..."
if [ "$PROVIDER" = "azure" ]; then
  run_with_auth_check "$CLI" network delete "${NODE}-vnet" "$RG" || true
elif [ "$PROVIDER" = "gcp" ]; then
  run_with_auth_check "$CLI" network delete "${NODE}-vpc" || true
fi

if [ -f "$STATE_FILE" ]; then
  log "STATE" "Cleaning up $STATE_FILE"
  rm -f "$STATE_FILE"
fi

log "DONE" "Teardown complete."
