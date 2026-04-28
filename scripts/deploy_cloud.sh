#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'
SCRIPT_DIR=$(cd "$(dirname -- "${this_file}")" && pwd)
LIBSCRIPT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

if [ "$#" -lt 4 ]; then
  echo "Usage: $0 <provider> <node_name> <rg_or_vpc_or_project> <region_or_zone> [local_repo_path] [remote_dest]"
  echo "Providers: azure, aws, gcp"
  exit 1
fi

PROVIDER=$1
NODE=$2
RG=$3
LOC=$4
REPO_PATH=${5:-.}
REMOTE_DEST=${6:-"~/$NODE"}

# -----------------------------------------------------------------------------
# Logging Configuration
# -----------------------------------------------------------------------------
LOG_DIR="$REPO_PATH/logs"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +%s)
LOG_FILE="$LOG_DIR/provision-${TIMESTAMP}.log"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2" | tee -a "$LOG_FILE"
}

log "INIT" "Starting $PROVIDER deployment for $NODE..."
log "INIT" "Logging to $LOG_FILE"

# -----------------------------------------------------------------------------
# Retries & Fault Tolerance
# -----------------------------------------------------------------------------
with_retry() {
  local max_attempts=5
  local timeout=5
  local attempt=1
  local exit_code=0

  while [ $attempt -le $max_attempts ]; do
    log "RETRY" "Attempt $attempt of $max_attempts: $*"
    if "$@" >> "$LOG_FILE" 2>&1; then
      log "RETRY" "Command succeeded: $*"
      return 0
    fi
    exit_code=$?
    log "RETRY" "Command failed (exit $exit_code). Waiting $timeout seconds..."
    sleep $timeout
    timeout=$((timeout * 2))
    attempt=$((attempt + 1))
  done
  log "ERROR" "Command failed after $max_attempts attempts: $*"
  return $exit_code
}

# -----------------------------------------------------------------------------
# Idempotent State Management
# -----------------------------------------------------------------------------
STATE_FILE="$REPO_PATH/.deploy_state"

record_state() {
  local key=$1
  local val=$2
  echo "${key}=${val}" >> "$STATE_FILE"
  log "STATE" "Recorded $key=$val"
}

if [ ! -f "$STATE_FILE" ]; then
  touch "$STATE_FILE"
fi

# -----------------------------------------------------------------------------
# Read Configuration
# -----------------------------------------------------------------------------
JSON_FILE="$REPO_PATH/libscript.json"
DOMAIN=""
DNS_RG=""
SECRETS_DIR=""
OS_IMAGE=""
SIZE=""
DISK_GB=""
PORTS="22 80 443"
STATE_BUCKET=""
STATE_ENDPOINT=""
STATE_PATHS=""

if [ -f "$JSON_FILE" ] && command -v jq >/dev/null 2>&1; then
  DOMAIN=$(jq -r '.domain // ""' "$JSON_FILE")
  DNS_RG=$(jq -r '.infrastructure.dns.resource_group // ""' "$JSON_FILE")
  SECRETS_DIR=$(jq -r '.secrets_dir // ""' "$JSON_FILE")
  OS_IMAGE=$(jq -r '.infrastructure.node.os // ""' "$JSON_FILE")
  SIZE=$(jq -r '.infrastructure.node.size // ""' "$JSON_FILE")
  DISK_GB=$(jq -r '.infrastructure.node.disk_gb // ""' "$JSON_FILE")
  JSON_PORTS=$(jq -r '.infrastructure.network.ports[]? // empty' "$JSON_FILE" | tr '\n' ' ')
  if [ -n "$JSON_PORTS" ]; then PORTS="$JSON_PORTS"; fi
  STATE_BUCKET=$(jq -r '.state.bucket // ""' "$JSON_FILE")
  STATE_ENDPOINT=$(jq -r '.state.endpoint // ""' "$JSON_FILE")
  STATE_PATHS=$(jq -r '.state.paths[]? // empty' "$JSON_FILE")
fi

if [ -z "$OS_IMAGE" ]; then
  if [ "$PROVIDER" = "azure" ]; then OS_IMAGE="Ubuntu2204"
  elif [ "$PROVIDER" = "aws" ]; then OS_IMAGE="ami-0c7217cdde317cfec"
  elif [ "$PROVIDER" = "gcp" ]; then OS_IMAGE="ubuntu-2204-lts"
  fi
fi

if [ -z "$SIZE" ]; then
  if [ "$PROVIDER" = "azure" ]; then SIZE="Standard_B2s"
  elif [ "$PROVIDER" = "aws" ]; then SIZE="t3.medium"
  elif [ "$PROVIDER" = "gcp" ]; then SIZE="e2-medium"
  fi
else
  if echo "$SIZE" | grep -q "^Standard_D"; then
    if [ "$PROVIDER" = "aws" ]; then SIZE="t3.xlarge"
    elif [ "$PROVIDER" = "gcp" ]; then SIZE="e2-standard-4"
    fi
  elif echo "$SIZE" | grep -q "^Standard_B"; then
    if [ "$PROVIDER" = "aws" ]; then SIZE="t3.medium"
    elif [ "$PROVIDER" = "gcp" ]; then SIZE="e2-medium"
    fi
  elif echo "$SIZE" | grep -q "^t3."; then
    if [ "$PROVIDER" = "azure" ]; then SIZE="Standard_D4s_v3"
    elif [ "$PROVIDER" = "gcp" ]; then SIZE="e2-standard-4"
    fi
  fi
fi

CLI="$LIBSCRIPT_ROOT/_lib/cloud-providers/$PROVIDER/cli.sh"
if [ ! -f "$CLI" ]; then 
  log "ERROR" "Provider $PROVIDER not supported ($CLI missing)."
  exit 1
fi

record_state "PROVIDER" "$PROVIDER"
record_state "NODE" "$NODE"
record_state "RG" "$RG"
record_state "REGION" "$LOC"

# -----------------------------------------------------------------------------
# Infrastructure Provisioning
# -----------------------------------------------------------------------------
log "INFRA" "Provisioning Network and Compute..."

if [ "$PROVIDER" = "azure" ]; then
  with_retry az group create --name "$RG" --location "$LOC"
  record_state "AZURE_RG" "$RG"
  
  with_retry "$CLI" network create "${NODE}-vnet" "$RG" --location "$LOC"
  record_state "AZURE_VNET" "${NODE}-vnet"
  
  with_retry "$CLI" firewall create "${NODE}-nsg" "$RG" "$PORTS" --location "$LOC"
  record_state "AZURE_NSG" "${NODE}-nsg"
  
  NODE_ARGS="--size $SIZE --vnet-name ${NODE}-vnet --nsg ${NODE}-nsg"
  if [ -n "$DISK_GB" ]; then NODE_ARGS="$NODE_ARGS --os-disk-size-gb $DISK_GB"; fi
  with_retry "$CLI" node create "$NODE" "$OS_IMAGE" "$RG" $NODE_ARGS
  record_state "AZURE_NODE" "$NODE"

elif [ "$PROVIDER" = "aws" ]; then
  export AWS_DEFAULT_REGION="$LOC"
  VPC_ID=$("$CLI" network create "${NODE}-vpc" | tail -n 1)
  record_state "AWS_VPC" "$VPC_ID"
  
  SG_ID=$("$CLI" firewall create "${NODE}-sg" "${NODE}-vpc" "$PORTS" | tail -n 1)
  record_state "AWS_SG" "$SG_ID"
  
  with_retry "$CLI" node create "$NODE" "$OS_IMAGE" "${NODE}-vpc" "$SIZE"
  record_state "AWS_NODE" "$NODE"

elif [ "$PROVIDER" = "gcp" ]; then
  export GCP_ZONE="$LOC"
  with_retry "$CLI" network create "${NODE}-vpc" "10.0.0.0/16"
  record_state "GCP_VPC" "${NODE}-vpc"
  
  with_retry "$CLI" firewall create "${NODE}-fw" "${NODE}-vpc" "$PORTS"
  record_state "GCP_FW" "${NODE}-fw"
  
  with_retry "$CLI" node create "$NODE" "$OS_IMAGE" "$RG" --network "${NODE}-vpc" --machine-type "$SIZE"
  record_state "GCP_NODE" "$NODE"
fi

CTX="$RG"
if [ "$PROVIDER" = "gcp" ] || [ "$PROVIDER" = "aws" ]; then CTX="$LOC"; fi

# -----------------------------------------------------------------------------
# Status Checks & Health Polling
# -----------------------------------------------------------------------------
wait_for_ssh() {
  local target_node=$1
  local target_ctx=$2
  local max_attempts=30
  local attempt=1
  log "HEALTH" "Waiting for SSH readiness on node $target_node..."
  
  while [ $attempt -le $max_attempts ]; do
    if "$CLI" node exec "$target_node" "$target_ctx" "echo SSH_READY" >/dev/null 2>&1; then
      log "HEALTH" "SSH is ready."
      return 0
    fi
    log "HEALTH" "SSH not ready (attempt $attempt/$max_attempts). Waiting 10s..."
    sleep 10
    attempt=$((attempt + 1))
  done
  log "ERROR" "Node failed to become SSH-ready."
  return 1
}

wait_for_ssh "$NODE" "$CTX"

# -----------------------------------------------------------------------------
# Sync and Deploy
# -----------------------------------------------------------------------------
log "SYNC" "Syncing LibScript to remote node..."
with_retry "$CLI" node sync "$NODE" "$CTX"

log "SYNC" "Deploying Repository to remote node..."
with_retry "$CLI" node exec "$NODE" "$CTX" "mkdir -p $REMOTE_DEST"

# Explicit rsync fallback to scp/winrm behavior
transfer_files() {
  local src=$1
  local dst=$2
  log "SYNC" "Transferring $src to $dst..."
  if command -v rsync >/dev/null 2>&1; then
    log "SYNC" "Using rsync..."
    with_retry "$CLI" node deploy "$NODE" "$CTX" "$src" "$dst"
  else
    log "SYNC" "Using scp/winrm fallback..."
    with_retry "$CLI" node scp "$NODE" "$CTX" "$src" "$dst"
  fi
}

transfer_files "$REPO_PATH/" "$REMOTE_DEST/"

# -----------------------------------------------------------------------------
# Secrets Transfer
# -----------------------------------------------------------------------------
if [ -n "$SECRETS_DIR" ] && [ -d "$REPO_PATH/$SECRETS_DIR" ]; then
  log "SECRETS" "Transferring secrets explicitly out-of-band via node scp (bypassing .gitignore)..."
  # Use node scp directly for secrets to ensure they transfer regardless of .gitignore
  with_retry "$CLI" node scp "$NODE" "$CTX" "$REPO_PATH/$SECRETS_DIR" "$REMOTE_DEST/$SECRETS_DIR"
fi

# -----------------------------------------------------------------------------
# State Restoration (DuckDB, S3, etc)
# -----------------------------------------------------------------------------
if [ -n "$STATE_PATHS" ]; then
  for PATH_ITEM in $STATE_PATHS; do
    if [ -n "$STATE_BUCKET" ]; then
      log "STATE" "Restoring $PATH_ITEM from object storage ($STATE_BUCKET)..."
      if echo "$STATE_BUCKET" | grep -q "^s3://"; then
        S3_ARGS=""
        if [ -n "$STATE_ENDPOINT" ]; then S3_ARGS="--endpoint-url $STATE_ENDPOINT"; fi
        aws s3 cp $S3_ARGS "$STATE_BUCKET/$PATH_ITEM" "$REPO_PATH/$PATH_ITEM" >> "$LOG_FILE" 2>&1 || true
      elif echo "$STATE_BUCKET" | grep -q "^gs://"; then
        gcloud storage cp "$STATE_BUCKET/$PATH_ITEM" "$REPO_PATH/$PATH_ITEM" >> "$LOG_FILE" 2>&1 || true
      elif echo "$STATE_BUCKET" | grep -q "^azure://"; then
        CONTAINER=$(echo "$STATE_BUCKET" | awk -F/ '{print $3}')
        az storage blob download --container-name "$CONTAINER" --name "$PATH_ITEM" --file "$REPO_PATH/$PATH_ITEM" --auth-mode login >> "$LOG_FILE" 2>&1 || true
      fi
    fi

    if [ -e "$REPO_PATH/$PATH_ITEM" ]; then
      log "STATE" "Deploying state $PATH_ITEM to node..."
      with_retry "$CLI" node scp "$NODE" "$CTX" "$REPO_PATH/$PATH_ITEM" "$REMOTE_DEST/$PATH_ITEM"
    fi
  done
fi

# -----------------------------------------------------------------------------
# DNS Mapping
# -----------------------------------------------------------------------------
if [ -n "$DOMAIN" ]; then
  log "DNS" "Mapping DNS for $DOMAIN..."
  if [ "$PROVIDER" = "azure" ]; then
    ZONE_NAME=$(echo "$DOMAIN" | awk -F. '{print $(NF-1)"."$NF}')
    TARGET_DNS_RG="${DNS_RG:-${ZONE_NAME}-rg}"
    with_retry "$CLI" dns map-node "$NODE" "$RG" "$DOMAIN" "$ZONE_NAME" "$TARGET_DNS_RG" || true
  elif [ "$PROVIDER" = "aws" ]; then
    if [ -z "$AWS_ZONE_ID" ]; then
      AWS_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "$DOMAIN" --query "HostedZones[0].Id" --output text 2>/dev/null | awk -F/ '{print $NF}')
      if [ "$AWS_ZONE_ID" = "None" ]; then AWS_ZONE_ID=""; fi
    fi
    if [ -n "$AWS_ZONE_ID" ]; then
      with_retry "$CLI" dns map-node "$NODE" "$DOMAIN" "$AWS_ZONE_ID" || true
    fi
  elif [ "$PROVIDER" = "gcp" ]; then
    ZONE_NAME=$(echo "$DOMAIN" | awk -F. '{print $(NF-1)"-"$NF}')
    with_retry "$CLI" dns map-node "$NODE" "$LOC" "$DOMAIN" "$ZONE_NAME" || true
  fi
fi

# -----------------------------------------------------------------------------
# Stack Start
# -----------------------------------------------------------------------------
log "START" "Installing Dependencies and Starting Application Stack..."
with_retry "$CLI" node exec "$NODE" "$CTX" "cd $REMOTE_DEST && sudo ~/libscript/libscript.sh install-deps"
with_retry "$CLI" node exec "$NODE" "$CTX" "cd $REMOTE_DEST && sudo ~/libscript/libscript.sh start"

wait_for_health() {
  log "HEALTH" "Polling application health (via libscript health)..."
  local max_attempts=12
  local attempt=1
  while [ $attempt -le $max_attempts ]; do
    if "$CLI" node exec "$NODE" "$CTX" "cd $REMOTE_DEST && sudo ~/libscript/libscript.sh health" >/dev/null 2>&1; then
      log "HEALTH" "Application stack is healthy."
      return 0
    fi
    log "HEALTH" "Application not ready (attempt $attempt/$max_attempts). Waiting 10s..."
    sleep 10
    attempt=$((attempt + 1))
  done
  log "WARNING" "Application health check failed or timed out. Please check logs manually."
}

wait_for_health

log "DONE" "Deployment complete. View full logs at $LOG_FILE"
