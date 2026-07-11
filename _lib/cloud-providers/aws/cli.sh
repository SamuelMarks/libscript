#!/bin/sh
# ## Overview
# Provides a high-level orchestration wrapper around the native `aws` CLI for managing
# AWS cloud infrastructure. It implements custom sub-commands (`network`, `firewall`,
# `node`, `node-group`, `cron`, `jumpbox`, `storage`, `cleanup`) to simplify common
# declarative provisioning tasks using imperative logic. Features dry-run testing support.
# 
# ## Usage
# Execute this script with a sub-command, e.g., `./cli.sh jumpbox create <name> <ami>`.


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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh" ]; then
  # shellcheck disable=SC1091
  . "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh"
fi

TAG_KEY="${LIBSCRIPT_TAG_KEY:-ManagedBy}"
TAG_VAL="${LIBSCRIPT_TAG_VALUE:-LibScript}"
if [ "${LIBSCRIPT_TAG_ENABLE:-true}" = "true" ]; then
  DEFAULT_TAGS="Key=$TAG_KEY,Value=$TAG_VAL"
else
  DEFAULT_TAGS=""
fi

# Parse tags from arguments
# Returns a space-separated list of Key=V,Value=V strings
parse_tags() {
  USE_DEFAULT=true
  CUSTOM_TAGS=""
  
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-default-tags) USE_DEFAULT=false; shift ;;
      --tags)
        if [ -n "$CUSTOM_TAGS" ]; then CUSTOM_TAGS="$CUSTOM_TAGS $2"; else CUSTOM_TAGS="$2"; fi
        shift 2 ;;
      *) shift ;;
    esac
  done
  
  FINAL_TAGS=""
  if [ "$USE_DEFAULT" = "true" ]; then
    FINAL_TAGS="$DEFAULT_TAGS"
  fi
  if [ -n "$CUSTOM_TAGS" ]; then
    if [ -n "$FINAL_TAGS" ]; then FINAL_TAGS="$FINAL_TAGS $CUSTOM_TAGS"; else FINAL_TAGS="$CUSTOM_TAGS"; fi
  fi
  printf '%s' "$FINAL_TAGS"
}

# Dry run helper
aws() {
  if [ "${DRY_RUN:-}" = "true" ]; then
    printf '[DRY_RUN] aws %s\n' "$*" >&2
    case "$*" in
      *"ec2 create-vpc"*) printf '%s\n' "vpc-12345678" ;;
      *"ec2 create-security-group"*) printf '%s\n' "sg-12345678" ;;
      *"ec2 run-instances"*) printf '%s\n' "i-12345678" ;;
      *"ec2 allocate-address"*) printf '%s\n' "eipalloc-12345678" ;;
      *"route53 create-hosted-zone"*) printf '%s\n' "Z12345678" ;;
      *"ec2 describe-vpcs"*) printf '%s\n' "vpc-12345678" ;;
      *"ec2 describe-security-groups"*|*"ec2 describe-instances"*|*"ec2 describe-addresses"*) printf '%s\n' "None" ;;
      *"s3api head-bucket"*) return 1 ;;
      *) return 0 ;;
    esac
    return 0
  fi
  command aws "$@"
}

# Ensure aws-cli and jq are installed
check_deps() {
  if ! command -v aws >/dev/null 2>&1; then
    printf '%s\n' "aws-cli not found, installing..."
    "$LIBSCRIPT_ROOT_DIR/libscript.sh" install awscli latest
  fi
  if ! command -v jq >/dev/null 2>&1; then
    printf '%s\n' "jq not found, installing..."
    "$LIBSCRIPT_ROOT_DIR/libscript.sh" install jq latest
  fi
}

aws_auth() {
  ACTION=$1; shift
  case "$ACTION" in
    login)
      if [ "${1:-}" = "sso" ]; then
        aws sso login
      else
        aws configure
      fi
      ;;
    logout)
      if aws sso logout 2>/dev/null; then
        printf '%s\n' "SSO logout successful."
      else
        printf '%s\n' "SSO logout not applicable or failed."
      fi
      ;;
    status)
      aws sts get-caller-identity
      ;;
    *) printf '%s\n' "Unknown auth action: $ACTION. Supported: login, logout, status."; exit 1 ;;
  esac
}

aws_location() {
  ACTION=$1; shift
  case "$ACTION" in
    list)
      aws ec2 describe-regions --query "Regions[*].RegionName" --output table
      ;;
    select)
      REGION=$1
      if [ -z "$REGION" ]; then printf '%s\n' "Usage: location select <region>"; exit 1; fi
      aws configure set default.region "$REGION"
      printf '%s\n' "Default region set to $REGION."
      ;;
    *) printf '%s\n' "Unknown location action: $ACTION. Supported: list, select."; exit 1 ;;
  esac
}

aws_dns() {
  ACTION=$1; shift
  case "$ACTION" in
    zone)
      SUBACTION=$1; shift
      case "$SUBACTION" in
        create)
          NAME=$1; if [ -z "$NAME" ]; then printf '%s\n' "Usage: dns zone create <name>"; exit 1; fi
          CALLER_REF="$(date +%s)"
          aws route53 create-hosted-zone --name "$NAME" --caller-reference "$CALLER_REF"
          ;;
        list)
          aws route53 list-hosted-zones --query "HostedZones[*].{Id:Id, Name:Name}" --output table
          ;;
        delete)
          ID=$1; if [ -z "$ID" ]; then printf '%s\n' "Usage: dns zone delete <id>"; exit 1; fi
          libscript_verify_managed aws dns "$ID" || exit 1
          if aws route53 get-hosted-zone --id "$ID" 2>/dev/null >/dev/null; then
            aws route53 delete-hosted-zone --id "$ID"
            printf '%s\n' "Deleted DNS zone '$ID'"
          else
            printf '%s\n' "DNS zone '$ID' already deleted or not found."
          fi
          ;;
        *)
          printf '%s\n' "Unknown dns zone action: $SUBACTION"; exit 1 ;;
      esac
      ;;
    record)
      SUBACTION=$1; shift
      case "$SUBACTION" in
        create|update|delete)
          ZONE_ID=$1; NAME=$2; TYPE=$3; VALUE=$4; TTL=${5:-300}
          if [ -z "$VALUE" ]; then printf '%s\n' "Usage: dns record $SUBACTION <zone_id> <name> <type> <value> [ttl]"; exit 1; fi
          if [ "$SUBACTION" = "update" ] || [ "$SUBACTION" = "delete" ]; then
            libscript_verify_managed aws dns "$ZONE_ID" || exit 1
          fi
          ACTION_MAPPED="UPSERT"
          if [ "$SUBACTION" = "create" ]; then ACTION_MAPPED="CREATE"; fi
          if [ "$SUBACTION" = "delete" ]; then ACTION_MAPPED="DELETE"; fi
          BATCH="{\"Changes\":[{\"Action\":\"$ACTION_MAPPED\",\"ResourceRecordSet\":{\"Name\":\"$NAME\",\"Type\":\"$TYPE\",\"TTL\":$TTL,\"ResourceRecords\":[{\"Value\":\"$VALUE\"}]}}]}"
          aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch "$BATCH"
          ;;
        list)
          ZONE_ID=$1; if [ -z "$ZONE_ID" ]; then printf '%s\n' "Usage: dns record list <zone_id>"; exit 1; fi
          aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" --query "ResourceRecordSets[*].{Name:Name, Type:Type, TTL:TTL, Value:ResourceRecords[0].Value}" --output table
          ;;
        *)
          printf '%s\n' "Unknown dns record action: $SUBACTION"; exit 1 ;;
      esac
      ;;
    *)
      printf '%s\n' "Unknown dns action: $ACTION. Supported: zone, record."; exit 1 ;;
  esac
}

aws_network() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; CIDR=${2:-10.0.0.0/16}
      if [ -z "$NAME" ]; then printf '%s\n' "Usage: auth|location|dns|network create <name> [cidr] [--tags T] [--no-default-tags]"; exit 1; fi
      
      TAGS=$(parse_tags "$@")
      
      VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$NAME" --query "Vpcs[0].VpcId" --output text 2>/dev/null || true)
      if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
        printf '%s\n' "VPC '$NAME' already exists: $VPC_ID" >&2
      else
        VPC_ID=$(aws ec2 create-vpc --cidr-block "$CIDR" --query "Vpc.VpcId" --output text)
        if [ -n "$TAGS" ]; then
          aws ec2 create-tags --resources "$VPC_ID" --tags "Key=Name,Value=$NAME" $TAGS
        else
          aws ec2 create-tags --resources "$VPC_ID" --tags "Key=Name,Value=$NAME"
        fi
        printf '%s\n' "Created VPC '$NAME': $VPC_ID" >&2
      fi
      printf '%s\n' "$VPC_ID"
      ;;
    update)
      NAME=$1; shift
      if [ -z "$NAME" ]; then printf '%s\n' "Usage: network update <name> [--enable-dns true|false] [--tags T]"; exit 1; fi
      libscript_verify_managed aws network "$NAME" || exit 1
      VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$NAME" --query "Vpcs[0].VpcId" --output text 2>/dev/null || true)
      if [ "$VPC_ID" = "None" ] || [ -z "$VPC_ID" ]; then
        printf '%s\n' "VPC '$NAME' not found." >&2; exit 1
      fi
      while [ $# -gt 0 ]; do
        case "$1" in
          --enable-dns)
            aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-support "{\"Value\":$2}"
            aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames "{\"Value\":$2}"
            shift 2 ;;
          --tags)
            aws ec2 create-tags --resources "$VPC_ID" --tags "$2"
            shift 2 ;;
          *)
            printf '%s\n' "Unknown option: $1"; exit 1 ;;
        esac
      done
      printf '%s\n' "Updated VPC '$NAME'."
      ;;
    list)
      aws ec2 describe-vpcs --query "Vpcs[*].{ID:VpcId, Name:Tags[?Key=='Name']|[0].Value, CIDR:CidrBlock, Tags:Tags}" --output table
      ;;
    delete)
      NAME=$1; if [ -z "$NAME" ]; then printf '%s\n' "Usage: auth|location|dns|network delete <name>"; exit 1; fi
      libscript_verify_managed aws network "$NAME" || exit 1
      VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$NAME" --query "Vpcs[0].VpcId" --output text 2>/dev/null || true)
      if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
        # Graceful cleanup of dependencies is complex, so we will warn if it fails
        if ! aws ec2 delete-vpc --vpc-id "$VPC_ID" 2>/dev/null; then
          printf '%s\n' "Failed to delete VPC '$NAME' ($VPC_ID). It may have dependencies (subnets, IGWs, instances) that need to be deleted first."
          exit 1
        fi
        printf '%s\n' "Deleted VPC '$NAME' ($VPC_ID)"
      else
        printf '%s\n' "VPC '$NAME' not found."
      fi
      ;;
    *) printf '%s\n' "Unknown network action: $ACTION"; exit 1 ;;
  esac
}

aws_firewall() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; VPC_NAME=$2; PORT=${3:-22}
      if [ -z "$NAME" ] || [ -z "$VPC_NAME" ]; then printf '%s\n' "Usage: firewall create <name> <vpc_name> [port] [--tags T] [--no-default-tags]"; exit 1; fi
      
      TAGS=$(parse_tags "$@")
      
      VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_NAME" --query "Vpcs[0].VpcId" --output text 2>/dev/null || true)
      SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$NAME" "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || true)
      if [ "$SG_ID" != "None" ] && [ -n "$SG_ID" ]; then
        printf '%s\n' "Security Group '$NAME' exists: $SG_ID" >&2
      else
        SG_ID=$(aws ec2 create-security-group --group-name "$NAME" --description "LibScript SG" --vpc-id "$VPC_ID" --query "GroupId" --output text)
        if [ -n "$TAGS" ]; then
          aws ec2 create-tags --resources "$SG_ID" --tags "Key=Name,Value=$NAME" $TAGS
        else
          aws ec2 create-tags --resources "$SG_ID" --tags "Key=Name,Value=$NAME"
        fi
        aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port "$PORT" --cidr 0.0.0.0/0
        printf '%s\n' "Created Security Group '$NAME': $SG_ID (Port $PORT open)" >&2
      fi
      printf '%s\n' "$SG_ID"
      ;;
    update)
      NAME=$1; shift
      if [ -z "$NAME" ]; then printf '%s\n' "Usage: firewall update <name> [--add-port PORT] [--remove-port PORT]"; exit 1; fi
      libscript_verify_managed aws firewall "$NAME" || exit 1
      SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$NAME" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || true)
      if [ "$SG_ID" = "None" ] || [ -z "$SG_ID" ]; then
        printf '%s\n' "Security Group '$NAME' not found." >&2; exit 1
      fi
      while [ $# -gt 0 ]; do
        case "$1" in
          --add-port)
            aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port "$2" --cidr 0.0.0.0/0
            shift 2 ;;
          --remove-port)
            aws ec2 revoke-security-group-ingress --group-id "$SG_ID" --protocol tcp --port "$2" --cidr 0.0.0.0/0
            shift 2 ;;
          *)
            printf '%s\n' "Unknown option: $1"; exit 1 ;;
        esac
      done
      printf '%s\n' "Updated Security Group '$NAME'."
      ;;
    delete)
      NAME=$1
      if [ -z "$NAME" ]; then printf '%s\n' "Usage: firewall delete <name>"; exit 1; fi
      libscript_verify_managed aws firewall "$NAME" || exit 1
      SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$NAME" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || true)
      if [ "$SG_ID" = "None" ] || [ -z "$SG_ID" ]; then
        printf '%s\n' "Security Group '$NAME' already deleted or not found." >&2; exit 0
      fi
      aws ec2 delete-security-group --group-id "$SG_ID"
      printf '%s\n' "Deleted Security Group '$NAME' ($SG_ID)."
      ;;
    list)
      aws ec2 describe-security-groups --query "SecurityGroups[*].{ID:GroupId, Name:GroupName, VPC:VpcId, Tags:Tags}" --output table
      ;;
    *) printf '%s\n' "Unknown firewall action: $ACTION"; exit 1 ;;
  esac
}

aws_node() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; IMAGE_ID=$2; VPC_NAME=$3; TYPE=${4:-t2.micro}
      if [ -z "$NAME" ] || [ -z "$IMAGE_ID" ] || [ -z "$VPC_NAME" ]; then 
        printf '%s\n' "Usage: node create <name> <image_id> <vpc_name> [type] [--bootstrap <script>] [--tags T] [--no-default-tags]"
        exit 1
      fi
      
      BOOTSTRAP=""
      # Complex arg parser
      filtered_args=""
      while [ $# -gt 0 ]; do
        case "$1" in
          --bootstrap) BOOTSTRAP="$2"; shift 2 ;;
          --tags|--no-default-tags) 
             if [ "$1" = "--tags" ]; then 
               filtered_args="$filtered_args $1 $2"
               shift 2
             else
               filtered_args="$filtered_args $1"
               shift
             fi
             ;;
          *) shift ;;
        esac
      done
      
      TAGS=$(parse_tags $filtered_args)
      
      INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" "Name=instance-state-name,Values=running,pending" --query "Reservations[0].Instances[0].InstanceId" --output text 2>/dev/null || true)
      if [ "$INSTANCE_ID" != "None" ] && [ -n "$INSTANCE_ID" ]; then
        printf '%s\n' "Node '$NAME' exists: $INSTANCE_ID" >&2
      else
        VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_NAME" --query "Vpcs[0].VpcId" --output text 2>/dev/null || true)
        SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[0].SubnetId" --output text 2>/dev/null || true)
        
        EXTRA_ARGS=""
        if [ -n "$BOOTSTRAP" ]; then
          USER_DATA_FILE=$(mktemp)
          printf '#!/bin/sh\n%s\n' "$BOOTSTRAP" > "$USER_DATA_FILE"
          EXTRA_ARGS="--user-data file://$USER_DATA_FILE"
        fi

        FINAL_TAG_SPECS="ResourceType=instance,Tags=[{Key=Name,Value=$NAME}]"
        if [ -n "$TAGS" ]; then
          TAG_STR=$(printf '%s\n' "$TAGS" | sed "s/Key=/{Key=/g" | sed "s/Value=/Value=/g" | sed "s/ /},/g")"}"
          FINAL_TAG_SPECS="ResourceType=instance,Tags=[{Key=Name,Value=$NAME},$TAG_STR]"
        fi

        # shellcheck disable=SC2086
        INSTANCE_ID=$(aws ec2 run-instances --image-id "$IMAGE_ID" --count 1 --instance-type "$TYPE" --subnet-id "$SUBNET_ID" --tag-specifications "$FINAL_TAG_SPECS" $EXTRA_ARGS --query "Instances[0].InstanceId" --output text)
        printf '%s\n' "Created Node '$NAME': $INSTANCE_ID" >&2
        if [ -n "${USER_DATA_FILE:-}" ]; then rm -f "$USER_DATA_FILE"; fi
      fi
      printf '%s\n' "$INSTANCE_ID"
      ;;
    update)
      NAME=$1; shift
      if [ -z "$NAME" ]; then printf '%s\n' "Usage: node update <name> [--type TYPE]"; exit 1; fi
      libscript_verify_managed aws node "$NAME" || exit 1
      INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" "Name=instance-state-name,Values=running,pending,stopped" --query "Reservations[0].Instances[0].InstanceId" --output text 2>/dev/null || true)
      if [ "$INSTANCE_ID" = "None" ] || [ -z "$INSTANCE_ID" ]; then
        printf '%s\n' "Node '$NAME' not found." >&2; exit 1
      fi
      while [ $# -gt 0 ]; do
        case "$1" in
          --type)
            aws ec2 modify-instance-attribute --instance-id "$INSTANCE_ID" --instance-type "{\"Value\": \"$2\"}"
            shift 2 ;;
          *)
            printf '%s\n' "Unknown option: $1"; exit 1 ;;
        esac
      done
      printf '%s\n' "Updated Node '$NAME'."
      ;;
    delete)
      NAME=$1
      if [ -z "$NAME" ]; then printf '%s\n' "Usage: node delete <name>"; exit 1; fi
      libscript_verify_managed aws node "$NAME" || exit 1
      INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" "Name=instance-state-name,Values=running,pending,stopped" --query "Reservations[0].Instances[0].InstanceId" --output text 2>/dev/null || true)
      if [ "$INSTANCE_ID" = "None" ] || [ -z "$INSTANCE_ID" ]; then
        printf '%s\n' "Node '$NAME' already deleted or not found." >&2; exit 0
      fi
      aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"
      printf '%s\n' "Terminating Node '$NAME' ($INSTANCE_ID)."
      ;;
    exec)
      NAME=$1; CMD=$2
      if [ -z "$NAME" ] || [ -z "$CMD" ]; then printf '%s\n' "Usage: node exec <name> <command>"; exit 1; fi
      IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
      printf '%s\n' "Executing on $NAME ($IP)..."
      ssh -o StrictHostKeyChecking=no "ubuntu@$IP" "$CMD"
      ;;
    list)
      aws ec2 describe-instances --query "Reservations[*].Instances[*].{ID:InstanceId, Name:Tags[?Key=='Name']|[0].Value, State:State.Name, Tags:Tags}" --output table
      ;;
    *) printf '%s\n' "Unknown node action: $ACTION"; exit 1 ;;
  esac
}

aws_node_group() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; COUNT=$2; IMAGE=$3; VPC=$4
      if [ -z "$NAME" ] || [ -z "$COUNT" ]; then printf '%s\n' "Usage: node-group create <name> <count> <image> <vpc> [args...]"; exit 1; fi
      shift 4
      printf '%s\n' "Provisioning node-group '$NAME' ($COUNT independent nodes)..."
      i=1
      while [ "$i" -le "$COUNT" ]; do
        aws_node create "${NAME}-${i}" "$IMAGE" "$VPC" "$@"
        i=$((i + 1))
      done
      ;;
    *) printf '%s\n' "Unknown node-group action: $ACTION"; exit 1 ;;
  esac
}

aws_cron() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; SCHEDULE=$2; CMD=$3
      if [ -z "$NAME" ] || [ -z "$SCHEDULE" ]; then printf '%s\n' "Usage: cron create <target_node> <schedule> <command>"; exit 1; fi
      printf '%s\n' "Setting up cronjob on $NAME: $SCHEDULE $CMD"
      aws_node exec "$NAME" "(crontab -l 2>/dev/null; printf '%s %s\n' \"$SCHEDULE\" \"$CMD\") | crontab -"
      ;;
    *) printf '%s\n' "Unknown cron action: $ACTION"; exit 1 ;;
  esac
}

aws_jumpbox() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; IMAGE_ID=$2; VPC_NAME=${3:-LibScriptVPC}
      if [ -z "$NAME" ] || [ -z "$IMAGE_ID" ]; then printf '%s\n' "Usage: jumpbox create <name> <image_id> [vpc_name] [tags...]"; exit 1; fi
      printf '%s\n' "Setting up Jump-box '$NAME'..."
      VPC_ID=$(aws_network create "$VPC_NAME" "$@")
      SG_ID=$(aws_firewall create "${NAME}-sg" "$VPC_NAME" 22 "$@")
      INSTANCE_ID=$(aws_node create "$NAME" "$IMAGE_ID" "$VPC_NAME" "$@")
      printf '%s\n' "Jump-box '$NAME' ($INSTANCE_ID) is ready in VPC '$VPC_NAME' with SG '$SG_ID'."
      ;;
    *) printf '%s\n' "Unknown jumpbox action: $ACTION"; exit 1 ;;
  esac
}

aws_storage() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      BUCKET=$1; if [ -z "$BUCKET" ]; then printf '%s\n' "Usage: storage create <bucket> [--tags T] [--no-default-tags]"; exit 1; fi
      
      TAGS=$(parse_tags "$@")
      
      if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
        printf '%s\n' "Bucket '$BUCKET' exists." >&2
      else
        aws s3 mb "s3://$BUCKET"
        if [ -n "$TAGS" ]; then
          TAG_STR=$(printf '%s\n' "$TAGS" | sed "s/Key=/{Key=/g" | sed "s/Value=/Value=/g" | sed "s/ /},/g")"}"
          aws s3api put-bucket-tagging --bucket "$BUCKET" --tagging "TagSet=[$TAG_STR]"
        fi
        printf '%s\n' "Created Bucket '$BUCKET'." >&2
      fi
      ;;
    list)
      aws s3 ls
      ;;
    delete)
      BUCKET=$1
      if [ -z "$BUCKET" ]; then printf '%s\n' "Usage: storage delete <bucket>"; exit 1; fi
      libscript_verify_managed aws storage "$BUCKET" || exit 1
      if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
        aws s3 rb "s3://$BUCKET" --force
        printf '%s\n' "Deleted Bucket '$BUCKET'"
      else
        printf '%s\n' "Bucket '$BUCKET' already deleted or not found."
      fi
      ;;
    *) printf '%s\n' "Unknown storage action: $ACTION"; exit 1 ;;
  esac
}

aws_list_managed() {
  FILTER_KEY=${1:-$TAG_KEY}
  FILTER_VAL=${2:-$TAG_VAL}
  printf '%s\n' "--- AWS Resources (Filter: $FILTER_KEY=$FILTER_VAL) ---"
  aws resourcegroupstaggingapi get-resources --tag-filters "Key=$FILTER_KEY,Values=$FILTER_VAL" \
    --query "ResourceTagMappingList[*].{ARN:ResourceARN, Tags:Tags}" --output table
}

aws_cleanup() {
  PURGE_BUCKETS=$1
  FILTER_KEY=${2:-$TAG_KEY}
  FILTER_VAL=${3:-$TAG_VAL}
  
  printf '%s\n' "Starting AWS Cleanup (Filter: $FILTER_KEY=$FILTER_VAL)..."
  RESOURCES=$(aws resourcegroupstaggingapi get-resources --tag-filters "Key=$FILTER_KEY,Values=$FILTER_VAL" --query "ResourceTagMappingList[*].ResourceARN" --output text)
  for ARN in $RESOURCES; do
    TYPE=$(printf '%s\n' "$ARN" | cut -d: -f3)
    SUBTYPE=$(printf '%s\n' "$ARN" | cut -d: -f6 | cut -d/ -f1)
    ID=$(printf '%s\n' "$ARN" | cut -d/ -f2)
    
    case "$TYPE" in
      ec2)
        case "$SUBTYPE" in
          instance) printf '%s\n' "Terminating instance $ID..."; aws ec2 terminate-instances --instance-ids "$ID" --quiet || true ;;
          vpc) printf '%s\n' "Deleting VPC $ID..."; aws ec2 delete-vpc --vpc-id "$ID" --quiet || true ;;
          security-group) printf '%s\n' "Deleting SG $ID..."; aws ec2 delete-security-group --group-id "$ID" --quiet || true ;;
          address) printf '%s\n' "Releasing IP $ID..."; aws ec2 release-address --allocation-id "$ID" --quiet || true ;;
        esac
        ;;
      s3)
        if [ "$PURGE_BUCKETS" = "true" ]; then
          BUCKET_NAME=$(printf '%s\n' "$ARN" | cut -d: -f6)
          printf '%s\n' "Deleting bucket $BUCKET_NAME..."
          aws s3 rb "s3://$BUCKET_NAME" --force || true
        else
          printf '%s\n' "Skipping bucket $ARN (safety enabled)"
        fi
        ;;
      route53)
        ZONE_ID=$(printf '%s\n' "$ARN" | cut -d/ -f2)
        printf '%s\n' "Deleting DNS zone $ZONE_ID..."; aws route53 delete-hosted-zone --id "$ZONE_ID" || true
        ;;
    esac
  done
}

# CLI Router
CMD="${1:-}"
if [ -n "$CMD" ]; then shift; fi
case "$CMD" in
  auth) aws_auth "$@" ;;
  dns) aws_dns "$@" ;;
  location) aws_location "$@" ;;
  network) aws_network "$@" ;;
  firewall) aws_firewall "$@" ;;
  node) aws_node "$@" ;;
  node-group) aws_node_group "$@" ;;
  cron) aws_cron "$@" ;;
  jumpbox) aws_jumpbox "$@" ;;
  storage) aws_storage "$@" ;;
  list-managed) aws_list_managed "$@" ;;
  cleanup) aws_cleanup "$@" ;;
  install) check_deps ;;
  --help|-h|/\?|"-?")
    printf '%s\n' "LibScript AWS Cloud Wrapper"
    printf '%s\n' "Usage: $0 {auth|location|dns|network|firewall|node|node-group|cron|jumpbox|storage|list-managed|cleanup|install} [args...]"
    exit 0
    ;;
  *)
    printf '%s\n' "LibScript AWS Cloud Wrapper"
    printf '%s\n' "Usage: $0 {auth|location|dns|network|firewall|node|node-group|cron|jumpbox|storage|list-managed|cleanup|install} [args...]"
    exit 1
    ;;
esac
