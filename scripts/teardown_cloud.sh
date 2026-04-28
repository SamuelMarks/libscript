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
LOG_FILE="$LOG_DIR/teardown-${TIMESTAMP}.log"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2" | tee -a "$LOG_FILE"
}

log "INIT" "Starting $PROVIDER teardown for $NODE..."

STATE_FILE="$REPO_PATH/.deploy_state"
get_state() {
  local key=$1
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

CLI="$LIBSCRIPT_ROOT/_lib/cloud-providers/$PROVIDER/cli.sh"
if [ ! -f "$CLI" ]; then echo "Provider $PROVIDER not supported."; exit 1; fi

CTX="$RG"
if [ "$PROVIDER" = "aws" ] || [ "$PROVIDER" = "gcp" ]; then CTX="$LOC"; fi

log "STOP" "Stopping remote stack..."
"$CLI" node exec "$NODE" "$CTX" "cd $REMOTE_DEST && sudo ~/libscript/libscript.sh stop" >> "$LOG_FILE" 2>&1 || true

if [ -n "$STATE_PATHS" ]; then
  for PATH_ITEM in $STATE_PATHS; do
    log "SYNC" "Syncing $PATH_ITEM from node to prevent data loss..."
    # Explicitly use node scp-from for reliable state transfer out-of-band
    "$CLI" node scp-from "$NODE" "$CTX" "$REMOTE_DEST/$PATH_ITEM" "$REPO_PATH/$PATH_ITEM" >> "$LOG_FILE" 2>&1 || true

    if [ -n "$STATE_BUCKET" ] && [ -e "$REPO_PATH/$PATH_ITEM" ]; then
      log "STATE" "Backing up $PATH_ITEM to object storage ($STATE_BUCKET)..."
      if echo "$STATE_BUCKET" | grep -q "^s3://"; then
        S3_ARGS=""
        if [ -n "$STATE_ENDPOINT" ]; then S3_ARGS="--endpoint-url $STATE_ENDPOINT"; fi
        aws s3 cp $S3_ARGS "$REPO_PATH/$PATH_ITEM" "$STATE_BUCKET/$PATH_ITEM" >> "$LOG_FILE" 2>&1
      elif echo "$STATE_BUCKET" | grep -q "^gs://"; then
        gcloud storage cp "$REPO_PATH/$PATH_ITEM" "$STATE_BUCKET/$PATH_ITEM" >> "$LOG_FILE" 2>&1
      elif echo "$STATE_BUCKET" | grep -q "^azure://"; then
        CONTAINER=$(echo "$STATE_BUCKET" | awk -F/ '{print $3}')
        az storage blob upload --container-name "$CONTAINER" --name "$PATH_ITEM" --file "$REPO_PATH/$PATH_ITEM" --auth-mode login --overwrite >> "$LOG_FILE" 2>&1
      fi
    fi
  done
fi

if [ -n "$DOMAIN" ]; then
  log "DNS" "Unmapping DNS..."
  if [ "$PROVIDER" = "azure" ]; then
    ZONE_NAME=$(echo "$DOMAIN" | awk -F. '{print $(NF-1)"."$NF}')
    TARGET_DNS_RG="${DNS_RG:-${ZONE_NAME}-rg}"
    "$CLI" dns unmap-node "$NODE" "$RG" "$DOMAIN" "$ZONE_NAME" "$TARGET_DNS_RG" >> "$LOG_FILE" 2>&1 || true
  elif [ "$PROVIDER" = "aws" ]; then
    if [ -z "$AWS_ZONE_ID" ]; then
      AWS_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "$DOMAIN" --query "HostedZones[0].Id" --output text 2>/dev/null | awk -F/ '{print $NF}')
      if [ "$AWS_ZONE_ID" = "None" ]; then AWS_ZONE_ID=""; fi
    fi
    if [ -n "$AWS_ZONE_ID" ]; then
      "$CLI" dns unmap-node "$NODE" "$DOMAIN" "$AWS_ZONE_ID" >> "$LOG_FILE" 2>&1 || true
    fi
  elif [ "$PROVIDER" = "gcp" ]; then
    ZONE_NAME=$(echo "$DOMAIN" | awk -F. '{print $(NF-1)"-"$NF}')
    "$CLI" dns unmap-node "$NODE" "$LOC" "$DOMAIN" "$ZONE_NAME" >> "$LOG_FILE" 2>&1 || true
  fi
fi

log "INFRA" "Deleting Node..."
"$CLI" node delete "$NODE" "$CTX" >> "$LOG_FILE" 2>&1 || true

log "INFRA" "Deleting Firewall..."
if [ "$PROVIDER" = "azure" ]; then
  "$CLI" firewall delete "${NODE}-nsg" "$RG" >> "$LOG_FILE" 2>&1 || true
elif [ "$PROVIDER" = "aws" ]; then
  SG_ID=$(get_state "AWS_SG")
  if [ -z "$SG_ID" ]; then
    SG_ID=$("$CLI" firewall list | grep "${NODE}-sg" | awk '{print $2}' || true)
  fi
  if [ -n "$SG_ID" ]; then aws ec2 delete-security-group --group-id "$SG_ID" >> "$LOG_FILE" 2>&1 || true; fi
elif [ "$PROVIDER" = "gcp" ]; then
  "$CLI" firewall delete "${NODE}-fw" >> "$LOG_FILE" 2>&1 || true
fi

log "INFRA" "Deleting Network..."
if [ "$PROVIDER" = "azure" ]; then 
  "$CLI" network delete "${NODE}-vnet" "$RG" >> "$LOG_FILE" 2>&1 || true
elif [ "$PROVIDER" = "aws" ]; then 
  VPC_ID=$(get_state "AWS_VPC")
  if [ -n "$VPC_ID" ]; then
    aws ec2 delete-vpc --vpc-id "$VPC_ID" >> "$LOG_FILE" 2>&1 || true
  else
    "$CLI" network delete "${NODE}-vpc" >> "$LOG_FILE" 2>&1 || true
  fi
elif [ "$PROVIDER" = "gcp" ]; then 
  "$CLI" network delete "${NODE}-vpc" >> "$LOG_FILE" 2>&1 || true
fi

if [ -f "$STATE_FILE" ]; then
  log "STATE" "Cleaning up $STATE_FILE"
  rm "$STATE_FILE"
fi

log "DONE" "Teardown complete."
