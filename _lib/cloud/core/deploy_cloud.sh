#!/bin/sh
# ## Overview
# Primary deployment orchestrator for Unix, provisioning infrastructure across AWS, Azure, or GCP,
# and deploying one or more applications onto a single or shared compute node.
#
# ## Usage
# Run `deploy_cloud.sh [options] <provider> <node> <rg> <loc> [repo] [dest]` or
# `deploy_cloud.sh --provider <p> --node <n> --rg <rg> --location <loc> [--app <repo>[:<dest>][@<domain>]]...`

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
_DEPLOY_SCRIPT_DIR="$SCRIPT_DIR"
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"
SCRIPT_DIR="$_DEPLOY_SCRIPT_DIR"

IS_TPU=0
export SHARED_STORAGE=0
SKIP_INFRA=0
SKIP_PREPARE=0
SKIP_VERIFY=0
FORCE_REINSTALL="${FORCE_REINSTALL:-0}"
FORCE_REBUILD="${FORCE_REBUILD:-0}"
ONLY_TARGET="${ONLY_TARGET:-all}"
DRY_RUN_MODE=0
if [ "${DRY_RUN:-false}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
  DRY_RUN_MODE=1
  export DRY_RUN="true"
fi

PROVIDER="${CLOUD_PROVIDER:-${PROVIDER:-}}"
NODE="${NODE_NAME:-}"
RG="${RG_NAME:-}"
LOC="${LOCATION:-}"
VM_IMAGE_OVERRIDE="${VM_IMAGE:-}"
VM_SIZE_OVERRIDE="${VM_SIZE:-}"
ADMIN_USER_OVERRIDE="${ADMIN_USER:-}"
APP_SPECS=""

_p1="" _p2="" _p3="" _p4="" _p5="" _p6=""

while [ $# -gt 0 ]; do
  case "$1" in
    --tpu|--accelerator) IS_TPU=1; shift ;;
    --shared-storage) export SHARED_STORAGE=1; shift ;;
    --skip-infra) SKIP_INFRA=1; shift ;;
    --skip-prepare) SKIP_PREPARE=1; shift ;;
    --skip-verify) SKIP_VERIFY=1; shift ;;
    --force-reinstall) FORCE_REINSTALL=1; shift ;;
    --force-rebuild) FORCE_REBUILD=1; shift ;;
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
    --vm-image=*|--os=*) VM_IMAGE_OVERRIDE="${1#*=}"; shift ;;
    --vm-image|--os) VM_IMAGE_OVERRIDE="${2:-}"; shift 2 ;;
    --size=*|--vm-size=*) VM_SIZE_OVERRIDE="${1#*=}"; shift ;;
    --size|--vm-size) VM_SIZE_OVERRIDE="${2:-}"; shift 2 ;;
    --admin-user=*|--admin-username=*) ADMIN_USER_OVERRIDE="${1#*=}"; shift ;;
    --admin-user|--admin-username) ADMIN_USER_OVERRIDE="${2:-}"; shift 2 ;;
    --app=*) APP_SPECS="${APP_SPECS}${1#*=}|"; shift ;;
    --app) APP_SPECS="${APP_SPECS}${2:-}|"; shift 2 ;;
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
[ -z "$LOC" ] && LOC="$_p4"
REPO_PATH="${_p5:-.}"
REMOTE_DEST="${_p6:-}"

if [ -z "$PROVIDER" ] || [ -z "$NODE" ] || [ -z "$RG" ] || [ -z "$LOC" ]; then
  log_info "Usage: deploy_cloud.sh [options] <provider> <node_name> <rg_or_vpc_or_project> <region_or_zone> [local_repo_path] [remote_dest]"
  exit 1
fi

export AZURE_LOCATION="$LOC"
export LOCATION="$LOC"

# ## matches_only_target
# Checks whether a given application name or remote destination matches the --only selector.
matches_only_target() {
  _mot_name="$1"
  _mot_dest="$2"
  case "$ONLY_TARGET" in
    all|both|"") return 0 ;;
    pulse|pulse_query|pulse-query|hospital_dashboard_platform|hospital-dashboard-platform)
      case "$_mot_name:$_mot_dest" in
        *hospital-dashboard-platform*|*pulse*) return 0 ;;
      esac
      return 1
      ;;
    t1d|t1d_analytics|t1d-analytics)
      case "$_mot_name:$_mot_dest" in
        *t1d*) return 0 ;;
      esac
      return 1
      ;;
    *)
      if [ "$_mot_name" = "$ONLY_TARGET" ] || [ "$_mot_dest" = "$ONLY_TARGET" ]; then
        return 0
      fi
      return 1
      ;;
  esac
}

# Build APP_SPECS from root manifest `.applications[]` or single REPO_PATH when `--app` is not passed
if [ -z "$APP_SPECS" ]; then
  if [ -f "${REPO_PATH}/libscript.json" ] && command -v jq >/dev/null 2>&1 && jq -e '.applications != null and (.applications | length > 0)' "${REPO_PATH}/libscript.json" >/dev/null 2>&1; then
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
    done << EOF_MANIFEST_APPS
$_manifest_apps
EOF_MANIFEST_APPS
  else
    _def_dest="$REMOTE_DEST"
    if [ -z "$_def_dest" ]; then
      _def_dest=$(basename "$(cd -- "$REPO_PATH" 2>/dev/null && pwd || printf '%s' "$NODE")")
    fi
    APP_SPECS="${REPO_PATH}:${_def_dest}|"
  fi
fi

# Collect manifest file paths for port & infrastructure combining
MANIFEST_FILES=""
OIFS="$IFS"
IFS="|"
# shellcheck disable=SC2086
set -- $APP_SPECS
IFS="$OIFS"
for _spec in "$@"; do
  [ -n "$_spec" ] || continue
  _sp_no_dom="${_spec%%@*}"
  _sp_path="${_sp_no_dom%%:*}"
  if [ -f "${_sp_path}/libscript.json" ]; then
    MANIFEST_FILES="${MANIFEST_FILES} ${_sp_path}/libscript.json"
  fi
done

LOG_DIR="${REPO_PATH}/logs"
mkdir -p "$LOG_DIR" 2>/dev/null || LOG_DIR="${TMPDIR:-/tmp}"
TIMESTAMP=$(date +%s)
LOG_FILE="$LOG_DIR/deploy-${TIMESTAMP}.log"

# ## log
# Formats and emits a timestamped log message at the specified severity level.
log() {
  printf '%s\n' "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2" | tee -a "$LOG_FILE"
}

log "INIT" "Starting $PROVIDER deployment for $NODE in $LOC (target: $ONLY_TARGET)..."

CLI="$SCRIPT_DIR/../../cloud-providers/$PROVIDER/cli.sh"
if [ ! -f "$CLI" ]; then
  log "ERROR" "Provider $PROVIDER not supported ($CLI missing)."
  exit 1
fi

# ## ensure_cli
# Ensures required CLI commands and packages are installed.
ensure_cli() {
  cmd=$1
  pkg=$2
  if [ "$DRY_RUN_MODE" -eq 1 ]; then
    return 0
  fi
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log "INFO" "Command '$cmd' not found. Installing '$pkg' via LibScript..."
    "$SCRIPT_DIR/../../../libscript.sh" install "$pkg" "latest" || {
      log "ERROR" "Failed to auto-install $pkg. Please install it manually."
      exit 1
    }
    export PATH="${PREFIX:-$LIBSCRIPT_ROOT_DIR/installed/$pkg}/bin:$PATH"
  fi
}

if ! command -v jq >/dev/null 2>&1; then
  ensure_cli "jq" "jq"
fi

if [ "$PROVIDER" = "azure" ]; then
  ensure_cli "az" "azure-cli"
elif [ "$PROVIDER" = "aws" ]; then
  ensure_cli "aws" "awscli"
elif [ "$PROVIDER" = "gcp" ]; then
  ensure_cli "gcloud" "google-cloud-sdk"
fi

# ## resolve_manifests_ports
# Extracts and unions required network ports across all application manifests.
resolve_manifests_ports() {
  if [ -n "$MANIFEST_FILES" ] && command -v jq >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    _rmp_ports=$(jq -r '([22, 80, 443, .infrastructure.network.ports[]?, (.ingress.listen | if type == "array" then .[] elif type == "number" or type == "string" then . else empty end), (.services | if type == "object" then .[].port? elif type == "array" then .[].port? else empty end)] | map(select(. != null and . != "")) | map(tostring) | unique | join(" "))' $MANIFEST_FILES 2>/dev/null | tr '\n' ' ' | tr ' ' '\n' | awk 'NF && !seen[$0]++' | tr '\n' ' ' | sed 's/ $//' || true)
    if [ -n "$_rmp_ports" ]; then
      printf '%s\n' "$_rmp_ports"
      return 0
    fi
  fi
  printf '%s\n' "22 80 443 3000 4200 8000 8001"
}

JSON_FILE="$REPO_PATH/libscript.json"
if [ ! -f "$JSON_FILE" ] && [ -n "$MANIFEST_FILES" ]; then
  for _first_mf in $MANIFEST_FILES; do
    JSON_FILE="$_first_mf"
    break
  done
fi

PORTS=$(resolve_manifests_ports)
VNET_NAME="${VNET_NAME:-${NODE}-vnet}"
NSG_NAME="${NSG_NAME:-${NODE}-nsg}"
VM_OS="${VM_IMAGE_OVERRIDE:-Ubuntu2204}"
VM_SIZE="${VM_SIZE_OVERRIDE:-}"
ADMIN_USER="${ADMIN_USER_OVERRIDE:-azureuser}"
DOMAIN=""
DNS_RG=""
STATE_BUCKET=""
STATE_ENDPOINT=""
STATE_PATHS=""

if [ -f "$JSON_FILE" ] && command -v jq >/dev/null 2>&1; then
  if [ -z "$VM_IMAGE_OVERRIDE" ]; then
    _j_os=$(jq -r '.infrastructure.node.os // empty' "$JSON_FILE" 2>/dev/null || true)
    [ -n "$_j_os" ] && [ "$_j_os" != "null" ] && VM_OS="$_j_os"
  fi
  if [ -z "$VM_SIZE_OVERRIDE" ]; then
    _j_sz=$(jq -r '.infrastructure.node.size // empty' "$JSON_FILE" 2>/dev/null || true)
    [ -n "$_j_sz" ] && [ "$_j_sz" != "null" ] && VM_SIZE="$_j_sz"
  fi
  if [ -z "$ADMIN_USER_OVERRIDE" ]; then
    _j_usr=$(jq -r '.infrastructure.node.admin_user // empty' "$JSON_FILE" 2>/dev/null || true)
    [ -n "$_j_usr" ] && [ "$_j_usr" != "null" ] && ADMIN_USER="$_j_usr"
  fi
  DOMAIN=$(jq -r '.domain // ""' "$JSON_FILE" 2>/dev/null || true)
  DNS_RG=$(jq -r '.infrastructure.dns.resource_group // ""' "$JSON_FILE" 2>/dev/null || true)
  STATE_BUCKET=$(jq -r '.state.bucket // ""' "$JSON_FILE" 2>/dev/null || true)
  STATE_ENDPOINT=$(jq -r '.state.endpoint // ""' "$JSON_FILE" 2>/dev/null || true)
  STATE_PATHS=$(jq -r '.state.paths[]? // empty' "$JSON_FILE" 2>/dev/null || true)
fi
export ADMIN_USER

STATE_FILE="$REPO_PATH/.deploy_state"
# ## record_state
# Performs the record_state operation and updates component state.
record_state() {
  key=$1
  val=$2
  if [ -f "$STATE_FILE" ]; then
    tmp_state=$(mktemp)
    grep -v "^${key}=" "$STATE_FILE" > "$tmp_state" || true
    mv "$tmp_state" "$STATE_FILE"
  fi
  printf '%s\n' "${key}=${val}" >> "$STATE_FILE"
}

if [ ! -f "$STATE_FILE" ]; then
  touch "$STATE_FILE" 2>/dev/null || STATE_FILE="${TMPDIR:-/tmp}/.deploy_state"
fi

# ## run_with_auth_check
# Executes a provider CLI command with automatic authentication error detection and retry.
run_with_auth_check() {
  cmd="$1"
  shift
  if [ "$DRY_RUN_MODE" -eq 1 ]; then
    "$cmd" "$@"
    return $?
  fi
  exit_code=0
  output_file="$LOG_DIR/auth_check.tmp"
  "$cmd" "$@" > "$output_file" 2>&1 || exit_code=$?
  if [ "$exit_code" -eq 0 ]; then
    cat "$output_file" >> "$LOG_FILE"
    rm -f "$output_file"
    return 0
  fi
  cat "$output_file" >> "$LOG_FILE"
  needs_auth=0
  provider_to_auth=""
  if grep -qEi "(not logged in|az login|Please run 'az login'|AuthenticationError|NoCredentialsError|AuthorizationFailed|InvalidAuthenticationTokenTenant)" "$output_file"; then
    needs_auth=1
    provider_to_auth="azure"
  elif grep -qEi "(Unable to locate credentials|aws configure|ExpiredToken|InvalidClientTokenId|AccessDenied|NotAuthorized)" "$output_file"; then
    needs_auth=1
    provider_to_auth="aws"
  elif grep -qEi "(gcloud auth login|Not authorized|Request had invalid authentication credentials|invalid_grant)" "$output_file"; then
    needs_auth=1
    provider_to_auth="gcp"
  fi
  if [ "$needs_auth" -eq 1 ]; then
    log "AUTH" "Authentication error detected for $provider_to_auth."
    if [ "$provider_to_auth" = "azure" ]; then
      az login </dev/tty >/dev/tty 2>&1 || { rm -f "$output_file"; return $exit_code; }
    elif [ "$provider_to_auth" = "aws" ]; then
      aws configure </dev/tty >/dev/tty 2>&1 || { rm -f "$output_file"; return $exit_code; }
    elif [ "$provider_to_auth" = "gcp" ]; then
      gcloud auth login </dev/tty >/dev/tty 2>&1 || { rm -f "$output_file"; return $exit_code; }
    fi
    rm -f "$output_file"
    "$cmd" "$@" >> "$LOG_FILE" 2>&1
    return $?
  fi
  rm -f "$output_file"
  return $exit_code
}

# -----------------------------------------------------------------------------
# Infrastructure Provisioning
# -----------------------------------------------------------------------------
CTX="$RG"
if [ "$PROVIDER" = "aws" ] || [ "$PROVIDER" = "gcp" ]; then CTX="$LOC"; fi

if [ "$SKIP_INFRA" -eq 0 ]; then
  if [ "$PROVIDER" = "azure" ]; then
    log "INFRA" "Ensuring Resource Group '$RG' in '$LOC'..."
    run_with_auth_check "$CLI" group ensure "$RG" --location "$LOC"
  fi
  log "INFRA" "Ensuring Network ($VNET_NAME)..."
  run_with_auth_check "$CLI" network create "$VNET_NAME" "$CTX" --location "$LOC"
  record_state "VNET" "$VNET_NAME"

  log "INFRA" "Ensuring Firewall ($NSG_NAME) with ports: $PORTS..."
  run_with_auth_check "$CLI" firewall create "$NSG_NAME" "$CTX" "$PORTS" --location "$LOC"
  record_state "NSG" "$NSG_NAME"

  log "INFRA" "Ensuring Compute Node ($NODE)..."
  SIZE_ARG=""
  if [ -n "$VM_SIZE" ]; then SIZE_ARG="--size $VM_SIZE"; fi
  TPU_ARG=""
  if [ "$IS_TPU" -eq 1 ]; then TPU_ARG="--tpu"; fi
  # shellcheck disable=SC2086
  run_with_auth_check "$CLI" node create "$NODE" "$VM_OS" "$CTX" --vnet-name "$VNET_NAME" --nsg "$NSG_NAME" $SIZE_ARG $TPU_ARG --admin-username "$ADMIN_USER"
  record_state "NODE" "$NODE"

  if [ -f "$JSON_FILE" ] && command -v jq >/dev/null 2>&1 && [ "$DRY_RUN_MODE" -eq 0 ]; then
    DISKS=$(jq -c '.infrastructure.node.data_disks[]? // empty' "$JSON_FILE" 2>/dev/null || true)
    if [ -n "$DISKS" ]; then
      printf '%s\n' "$DISKS" | while read -r disk_obj; do
        [ -n "$disk_obj" ] || continue
        DISK_SIZE=$(printf '%s\n' "$disk_obj" | jq -r '.size_gb // 100')
        DISK_MOUNT=$(printf '%s\n' "$disk_obj" | jq -r '.mount_path // "/mnt/data"')
        DISK_NAME=$(printf '%s\n' "$disk_obj" | jq -r '.name // "data-disk"')
        run_with_auth_check "$CLI" storage attach-disk "$NODE" "$CTX" "${NODE}-${DISK_NAME}" "$DISK_SIZE" "$DISK_MOUNT" || true
      done
    fi
  fi
fi

# -----------------------------------------------------------------------------
# Shared Node Preparation (Sync LibScript + Declarative Storage & Daemon Config)
# -----------------------------------------------------------------------------
log "SYNC" "Syncing LibScript runtime to '$NODE'..."
run_with_auth_check "$CLI" node sync "$NODE" "$CTX"

# Deploy each selected application repository and run prepare-storage once if not skipped
PREPARED_STORAGE=0
OIFS="$IFS"
IFS="|"
# shellcheck disable=SC2086
set -- $APP_SPECS
IFS="$OIFS"

for _app_entry in "$@"; do
  [ -n "$_app_entry" ] || continue
  _ae_domain=""
  case "$_app_entry" in
    *@*)
      _ae_domain="${_app_entry#*@}"
      _ae_path_dest="${_app_entry%%@*}"
      ;;
    *)
      _ae_path_dest="$_app_entry"
      ;;
  esac
  case "$_ae_path_dest" in
    *:*)
      _ae_repo="${_ae_path_dest%%:*}"
      _ae_dest="${_ae_path_dest#*:}"
      ;;
    *)
      _ae_repo="$_ae_path_dest"
      _ae_dest=$(basename "$_ae_path_dest")
      ;;
  esac
  _ae_name=$(basename "$_ae_repo")
  if [ -f "${_ae_repo}/libscript.json" ] && command -v jq >/dev/null 2>&1; then
    _j_name=$(jq -r '.name // empty' "${_ae_repo}/libscript.json" 2>/dev/null || true)
    [ -n "$_j_name" ] && [ "$_j_name" != "null" ] && _ae_name="$_j_name"
    if [ -z "$_ae_domain" ]; then
      _ae_domain=$(jq -r '.ingress.domain // .domain // empty' "${_ae_repo}/libscript.json" 2>/dev/null || true)
    fi
  fi

  if ! matches_only_target "$_ae_name" "$_ae_dest"; then
    continue
  fi

  log "DEPLOY" "Deploying '$_ae_name' ('$_ae_repo' -> '$_ae_dest', domain: '${_ae_domain:-none}')..."
  run_with_auth_check "$CLI" node deploy "$NODE" "$CTX" "$_ae_repo" "$_ae_dest"

  for _ef in .env .env.secrets; do
    if [ -f "${_ae_repo}/${_ef}" ]; then
      log "CONFIG" "Uploading $_ef for $_ae_name..."
      run_with_auth_check "$CLI" node upload "$NODE" "$CTX" "${_ae_repo}/${_ef}" "${_ae_dest}/${_ef}"
    fi
  done

  if [ "$SKIP_PREPARE" -eq 0 ] && [ "$PREPARED_STORAGE" -eq 0 ]; then
    log "PREPARE" "Preparing persistent storage and daemon overrides on '$NODE' via LibScript..."
    run_with_auth_check "$CLI" node exec "$NODE" "$CTX" "cd ~/${_ae_dest} && sudo SERVICE_USER='${ADMIN_USER}' REMOTE_USER='${ADMIN_USER}' LIBSCRIPT_ROOT_DIR=\"\$(cd ~/libscript && pwd)\" ~/libscript/libscript.sh prepare-storage libscript.json"
    PREPARED_STORAGE=1
  fi

  _deps_flags=""
  [ "$FORCE_REINSTALL" -eq 1 ] && _deps_flags="${_deps_flags} --force-reinstall"
  [ "$FORCE_REBUILD" -eq 1 ] && _deps_flags="${_deps_flags} --force-rebuild"

  log "START" "Installing dependencies, starting services, and configuring ingress for '$_ae_name'..."
  run_with_auth_check "$CLI" node exec "$NODE" "$CTX" "cd ~/${_ae_dest} && _REMOTE_HOME=\"\$(pwd | sed 's|/[^/]*\$||')\" && sudo SERVICE_USER='${ADMIN_USER}' REMOTE_USER='${ADMIN_USER}' REMOTE_HOME=\"\${_REMOTE_HOME}\" LIBSCRIPT_ROOT_DIR=\"\${_REMOTE_HOME}/libscript\" \"\${_REMOTE_HOME}/libscript/libscript.sh\" install-deps libscript.json${_deps_flags} && sudo SERVICE_USER='${ADMIN_USER}' REMOTE_USER='${ADMIN_USER}' REMOTE_HOME=\"\${_REMOTE_HOME}\" LIBSCRIPT_ROOT_DIR=\"\${_REMOTE_HOME}/libscript\" \"\${_REMOTE_HOME}/libscript/libscript.sh\" start libscript.json && sudo REMOTE_HOME=\"\${_REMOTE_HOME}\" LIBSCRIPT_ROOT_DIR=\"\${_REMOTE_HOME}/libscript\" \"\${_REMOTE_HOME}/libscript/libscript.sh\" netctl ingress libscript.json"
done

# -----------------------------------------------------------------------------
# Post-Deployment Health & Public Ingress Verification
# -----------------------------------------------------------------------------
if [ "$SKIP_VERIFY" -eq 0 ]; then
  for _app_entry in "$@"; do
    [ -n "$_app_entry" ] || continue
    _ae_domain=""
    case "$_app_entry" in
      *@*)
        _ae_domain="${_app_entry#*@}"
        _ae_path_dest="${_app_entry%%@*}"
        ;;
      *)
        _ae_path_dest="$_app_entry"
        ;;
    esac
    case "$_ae_path_dest" in
      *:*)
        _ae_repo="${_ae_path_dest%%:*}"
        _ae_dest="${_ae_path_dest#*:}"
        ;;
      *)
        _ae_repo="$_ae_path_dest"
        _ae_dest=$(basename "$_ae_path_dest")
        ;;
    esac
    _ae_name=$(basename "$_ae_repo")
    if [ -f "${_ae_repo}/libscript.json" ] && command -v jq >/dev/null 2>&1; then
      _j_name=$(jq -r '.name // empty' "${_ae_repo}/libscript.json" 2>/dev/null || true)
      [ -n "$_j_name" ] && [ "$_j_name" != "null" ] && _ae_name="$_j_name"
      if [ -z "$_ae_domain" ]; then
        _ae_domain=$(jq -r '.ingress.domain // .domain // empty' "${_ae_repo}/libscript.json" 2>/dev/null || true)
      fi
    fi

    if ! matches_only_target "$_ae_name" "$_ae_dest"; then
      continue
    fi

    _pub_arg=""
    if [ -n "$_ae_domain" ] && [ "$_ae_domain" != "null" ]; then
      _pub_arg=" --verify-ingress --public-url=https://${_ae_domain}"
    fi
    log "HEALTH" "Verifying '$_ae_name' health and ingress (${_ae_domain:-local})..."
    run_with_auth_check "$CLI" node exec "$NODE" "$CTX" "cd ~/${_ae_dest} && _REMOTE_HOME=\"\$(pwd | sed 's|/[^/]*\$||')\" && sudo SERVICE_USER='${ADMIN_USER}' REMOTE_USER='${ADMIN_USER}' REMOTE_HOME=\"\${_REMOTE_HOME}\" LIBSCRIPT_ROOT_DIR=\"\${_REMOTE_HOME}/libscript\" \"\${_REMOTE_HOME}/libscript/libscript.sh\" health libscript.json --remediate${_pub_arg}"
  done
fi

log "DONE" "Deployment complete. View full logs at $LOG_FILE"
