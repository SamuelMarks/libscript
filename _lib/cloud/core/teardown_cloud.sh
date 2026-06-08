#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
# @description Automatically handles teardown_cloud for the teardown_cloud.sh (cloud) component.
# @file teardown_cloud.sh


SCRIPT_DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
LIBSCRIPT_ROOT="${LIBSCRIPT_ROOT_DIR:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"

if [ "$#" -lt 4 ]; then
  log_info "Usage: ${THIS_FILE} <provider> <node_name> <rg_or_vpc_or_project> <region_or_zone> [local_repo_path] [remote_dest]"
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

CLI="$LIBSCRIPT_ROOT/_lib/cloud-providers/$PROVIDER/cli.sh"
if [ ! -f "$CLI" ]; then echo "Provider $PROVIDER not supported."; exit 1; fi

# -----------------------------------------------------------------------------
# Dependency Check
# -----------------------------------------------------------------------------
ensure_cli() {
  local cmd=$1
  local pkg=$2
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log "INFO" "Command '$cmd' not found. Installing '$pkg' via LibScript..."
    "$LIBSCRIPT_ROOT/libscript.sh" install "$pkg" "latest" || {
      log "ERROR" "Failed to auto-install $pkg. Please install it manually."
      exit 1
    }
    # Update PATH dynamically just in case it wasn't sourced yet
    export PATH="${PREFIX:-$LIBSCRIPT_ROOT/installed/$pkg}/bin:$PATH"
  fi
}

if [ "$PROVIDER" = "azure" ]; then
  ensure_cli "az" "azure-cli"
elif [ "$PROVIDER" = "aws" ]; then
  ensure_cli "aws" "awscli"
elif [ "$PROVIDER" = "gcp" ]; then
  ensure_cli "gcloud" "google-cloud-sdk"
fi

run_with_auth_check() {
  local cmd="$1"
  shift
  local exit_code=0
  local output_file="$LOG_DIR/auth_check.tmp"
  
  "$cmd" "$@" > "$output_file" 2>&1 || exit_code=$?
  
  if [ "$exit_code" -eq 0 ]; then
    cat "$output_file" >> "$LOG_FILE"
    rm -f "$output_file"
    return 0
  fi
  
  cat "$output_file" >> "$LOG_FILE"
  
  local needs_auth=0
  local provider_to_auth=""
  
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
    log "INFO" "Please authenticate to continue teardown."
    
    if [ "$provider_to_auth" = "azure" ]; then
      log "INFO" "Running 'az login'..."
      az login </dev/tty >/dev/tty 2>&1 || { log "ERROR" "Azure login failed."; rm -f "$output_file"; return $exit_code; }
    elif [ "$provider_to_auth" = "aws" ]; then
      log "INFO" "Running 'aws configure'..."
      aws configure </dev/tty >/dev/tty 2>&1 || { log "ERROR" "AWS configure failed."; rm -f "$output_file"; return $exit_code; }
    elif [ "$provider_to_auth" = "gcp" ]; then
      log "INFO" "Running 'gcloud auth login'..."
      gcloud auth login </dev/tty >/dev/tty 2>&1 || { log "ERROR" "GCP login failed."; rm -f "$output_file"; return $exit_code; }
    fi
    
    log "RETRY" "Authentication successful. Retrying command immediately..."
    rm -f "$output_file"
    "$cmd" "$@" >> "$LOG_FILE" 2>&1
    return $?
  fi
  
  rm -f "$output_file"
  return $exit_code
}

CTX="$RG"
if [ "$PROVIDER" = "aws" ] || [ "$PROVIDER" = "gcp" ]; then CTX="$LOC"; fi

log "STOP" "Stopping remote stack..."
run_with_auth_check "$CLI" node exec "$NODE" "$CTX" "cd $REMOTE_DEST && sudo ~/libscript/libscript.sh stop" || true

if [ -n "$STATE_PATHS" ]; then
  for PATH_ITEM in $STATE_PATHS; do
    log "SYNC" "Syncing $PATH_ITEM from node to prevent data loss..."
    # Explicitly use node scp-from for reliable state transfer out-of-band
    run_with_auth_check "$CLI" node scp-from "$NODE" "$CTX" "$REMOTE_DEST/$PATH_ITEM" "$REPO_PATH/$PATH_ITEM" || true

    if [ -n "$STATE_BUCKET" ] && [ -e "$REPO_PATH/$PATH_ITEM" ]; then
      log "STATE" "Backing up $PATH_ITEM to object storage ($STATE_BUCKET)..."
      if echo "$STATE_BUCKET" | grep -q "^s3://"; then
        S3_ARGS=""
        if [ -n "$STATE_ENDPOINT" ]; then S3_ARGS="--endpoint-url $STATE_ENDPOINT"; fi
        run_with_auth_check aws s3 cp $S3_ARGS "$REPO_PATH/$PATH_ITEM" "$STATE_BUCKET/$PATH_ITEM"
      elif echo "$STATE_BUCKET" | grep -q "^gs://"; then
        run_with_auth_check gcloud storage cp "$REPO_PATH/$PATH_ITEM" "$STATE_BUCKET/$PATH_ITEM"
      elif echo "$STATE_BUCKET" | grep -q "^azure://"; then
        CONTAINER=$(echo "$STATE_BUCKET" | awk -F/ '{print $3}')
        run_with_auth_check az storage blob upload --container-name "$CONTAINER" --name "$PATH_ITEM" --file "$REPO_PATH/$PATH_ITEM" --auth-mode login --overwrite
      fi
    fi
  done
fi

if [ -n "$DOMAIN" ]; then
  log "DNS" "Unmapping DNS..."
  if [ "$PROVIDER" = "azure" ]; then
    ZONE_NAME=$(echo "$DOMAIN" | awk -F. '{print $(NF-1)"."$NF}')
    TARGET_DNS_RG="${DNS_RG:-${ZONE_NAME}-rg}"
    run_with_auth_check "$CLI" dns unmap-node "$NODE" "$RG" "$DOMAIN" "$ZONE_NAME" "$TARGET_DNS_RG" || true
  elif [ "$PROVIDER" = "aws" ]; then
    if [ -z "$AWS_ZONE_ID" ]; then
      AWS_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "$DOMAIN" --query "HostedZones[0].Id" --output text 2>/dev/null | awk -F/ '{print $NF}')
      if [ "$AWS_ZONE_ID" = "None" ]; then AWS_ZONE_ID=""; fi
    fi
    if [ -n "$AWS_ZONE_ID" ]; then
      run_with_auth_check "$CLI" dns unmap-node "$NODE" "$DOMAIN" "$AWS_ZONE_ID" || true
    fi
  elif [ "$PROVIDER" = "gcp" ]; then
    ZONE_NAME=$(echo "$DOMAIN" | awk -F. '{print $(NF-1)"-"$NF}')
    run_with_auth_check "$CLI" dns unmap-node "$NODE" "$LOC" "$DOMAIN" "$ZONE_NAME" || true
  fi
fi

log "INFRA" "Deleting Node..."
run_with_auth_check "$CLI" node delete "$NODE" "$CTX" || true

log "INFRA" "Deleting Firewall..."
if [ "$PROVIDER" = "azure" ]; then
  run_with_auth_check "$CLI" firewall delete "${NODE}-nsg" "$RG" || true
elif [ "$PROVIDER" = "aws" ]; then
  SG_ID=$(get_state "AWS_SG")
  if [ -z "$SG_ID" ]; then
    SG_ID=$("$CLI" firewall list | grep "${NODE}-sg" | awk '{print $2}' || true)
  fi
  if [ -n "$SG_ID" ]; then run_with_auth_check aws ec2 delete-security-group --group-id "$SG_ID" || true; fi
elif [ "$PROVIDER" = "gcp" ]; then
  run_with_auth_check "$CLI" firewall delete "${NODE}-fw" || true
fi

log "INFRA" "Deleting Network..."
if [ "$PROVIDER" = "azure" ]; then
  run_with_auth_check "$CLI" network delete "${NODE}-vnet" "$RG" || true
elif [ "$PROVIDER" = "aws" ]; then
  VPC_ID=$(get_state "AWS_VPC")
  if [ -n "$VPC_ID" ]; then
    run_with_auth_check aws ec2 delete-vpc --vpc-id "$VPC_ID" || true
  else
    run_with_auth_check "$CLI" network delete "${NODE}-vpc" || true
  fi
elif [ "$PROVIDER" = "gcp" ]; then
  run_with_auth_check "$CLI" network delete "${NODE}-vpc" || true
fi

if [ -f "$STATE_FILE" ]; then
  log "STATE" "Cleaning up $STATE_FILE"
  rm "$STATE_FILE"
fi

log "DONE" "Teardown complete."
