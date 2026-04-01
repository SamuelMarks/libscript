#!/bin/sh
# shellcheck disable=SC2154,SC2086,SC2155,SC2046,SC2039,SC2006,SC2112,SC2002

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"

TAG_KEY="ManagedBy"
TAG_VAL="LibScript"
DEFAULT_TAGS="Key=$TAG_KEY,Value=$TAG_VAL"

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
      *"ec2 create-vpc"*) echo "vpc-12345678" ;;
      *"ec2 create-security-group"*) echo "sg-12345678" ;;
      *"ec2 run-instances"*) echo "i-12345678" ;;
      *"ec2 allocate-address"*) echo "eipalloc-12345678" ;;
      *"route53 create-hosted-zone"*) echo "Z12345678" ;;
      *"ec2 describe-vpcs"*) echo "vpc-12345678" ;;
      *"ec2 describe-security-groups"*|*"ec2 describe-instances"*|*"ec2 describe-addresses"*) echo "None" ;;
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
    echo "aws-cli not found, installing..."
    "$LIBSCRIPT_ROOT_DIR/libscript.sh" install awscli latest
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found, installing..."
    "$LIBSCRIPT_ROOT_DIR/libscript.sh" install jq latest
  fi
}

aws_network() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; CIDR=${2:-10.0.0.0/16}
      if [ -z "$NAME" ]; then echo "Usage: network create <name> [cidr] [--tags T] [--no-default-tags]"; exit 1; fi
      
      TAGS=$(parse_tags "$@")
      
      VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$NAME" --query "Vpcs[0].VpcId" --output text 2>/dev/null || true)
      if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
        echo "VPC '$NAME' already exists: $VPC_ID" >&2
      else
        VPC_ID=$(aws ec2 create-vpc --cidr-block "$CIDR" --query "Vpc.VpcId" --output text)
        if [ -n "$TAGS" ]; then
          aws ec2 create-tags --resources "$VPC_ID" --tags "Key=Name,Value=$NAME" $TAGS
        else
          aws ec2 create-tags --resources "$VPC_ID" --tags "Key=Name,Value=$NAME"
        fi
        echo "Created VPC '$NAME': $VPC_ID" >&2
      fi
      printf '%s\n' "$VPC_ID"
      ;;
    list)
      aws ec2 describe-vpcs --query "Vpcs[*].{ID:VpcId, Name:Tags[?Key=='Name']|[0].Value, CIDR:CidrBlock, Tags:Tags}" --output table
      ;;
    delete)
      NAME=$1; if [ -z "$NAME" ]; then echo "Usage: network delete <name>"; exit 1; fi
      VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$NAME" --query "Vpcs[0].VpcId" --output text 2>/dev/null || true)
      if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
        aws ec2 delete-vpc --vpc-id "$VPC_ID"
        echo "Deleted VPC '$NAME' ($VPC_ID)"
      else
        echo "VPC '$NAME' not found."
      fi
      ;;
    *) echo "Unknown network action: $ACTION"; exit 1 ;;
  esac
}

aws_firewall() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; VPC_NAME=$2; PORT=${3:-22}
      if [ -z "$NAME" ] || [ -z "$VPC_NAME" ]; then echo "Usage: firewall create <name> <vpc_name> [port] [--tags T] [--no-default-tags]"; exit 1; fi
      
      TAGS=$(parse_tags "$@")
      
      VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_NAME" --query "Vpcs[0].VpcId" --output text 2>/dev/null || true)
      SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$NAME" "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || true)
      if [ "$SG_ID" != "None" ] && [ -n "$SG_ID" ]; then
        echo "Security Group '$NAME' exists: $SG_ID" >&2
      else
        SG_ID=$(aws ec2 create-security-group --group-name "$NAME" --description "LibScript SG" --vpc-id "$VPC_ID" --query "GroupId" --output text)
        if [ -n "$TAGS" ]; then
          aws ec2 create-tags --resources "$SG_ID" --tags "Key=Name,Value=$NAME" $TAGS
        else
          aws ec2 create-tags --resources "$SG_ID" --tags "Key=Name,Value=$NAME"
        fi
        aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port "$PORT" --cidr 0.0.0.0/0
        echo "Created Security Group '$NAME': $SG_ID (Port $PORT open)" >&2
      fi
      printf '%s\n' "$SG_ID"
      ;;
    list)
      aws ec2 describe-security-groups --query "SecurityGroups[*].{ID:GroupId, Name:GroupName, VPC:VpcId, Tags:Tags}" --output table
      ;;
    *) echo "Unknown firewall action: $ACTION"; exit 1 ;;
  esac
}

aws_node() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; IMAGE_ID=$2; VPC_NAME=$3; TYPE=${4:-t2.micro}
      if [ -z "$NAME" ] || [ -z "$IMAGE_ID" ] || [ -z "$VPC_NAME" ]; then 
        echo "Usage: node create <name> <image_id> <vpc_name> [type] [--bootstrap <script>] [--tags T] [--no-default-tags]"
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
        echo "Node '$NAME' exists: $INSTANCE_ID" >&2
      else
        VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_NAME" --query "Vpcs[0].VpcId" --output text 2>/dev/null || true)
        SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[0].SubnetId" --output text 2>/dev/null || true)
        
        EXTRA_ARGS=""
        if [ -n "$BOOTSTRAP" ]; then
          USER_DATA_FILE=$(mktemp)
          printf '#!/bin/bash\n%s\n' "$BOOTSTRAP" > "$USER_DATA_FILE"
          EXTRA_ARGS="--user-data file://$USER_DATA_FILE"
        fi

        FINAL_TAG_SPECS="ResourceType=instance,Tags=[{Key=Name,Value=$NAME}]"
        if [ -n "$TAGS" ]; then
          TAG_STR=$(echo "$TAGS" | sed "s/Key=/{Key=/g" | sed "s/Value=/Value=/g" | sed "s/ /},/g")"}"
          FINAL_TAG_SPECS="ResourceType=instance,Tags=[{Key=Name,Value=$NAME},$TAG_STR]"
        fi

        # shellcheck disable=SC2086
        INSTANCE_ID=$(aws ec2 run-instances --image-id "$IMAGE_ID" --count 1 --instance-type "$TYPE" --subnet-id "$SUBNET_ID" --tag-specifications "$FINAL_TAG_SPECS" $EXTRA_ARGS --query "Instances[0].InstanceId" --output text)
        echo "Created Node '$NAME': $INSTANCE_ID" >&2
        if [ -n "${USER_DATA_FILE:-}" ]; then rm -f "$USER_DATA_FILE"; fi
      fi
      printf '%s\n' "$INSTANCE_ID"
      ;;
    exec)
      NAME=$1; CMD=$2
      if [ -z "$NAME" ] || [ -z "$CMD" ]; then echo "Usage: node exec <name> <command>"; exit 1; fi
      IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
      echo "Executing on $NAME ($IP)..."
      ssh -o StrictHostKeyChecking=no "ubuntu@$IP" "$CMD"
      ;;
    list)
      aws ec2 describe-instances --query "Reservations[*].Instances[*].{ID:InstanceId, Name:Tags[?Key=='Name']|[0].Value, State:State.Name, Tags:Tags}" --output table
      ;;
    *) echo "Unknown node action: $ACTION"; exit 1 ;;
  esac
}

aws_node_group() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; COUNT=$2; IMAGE=$3; VPC=$4
      if [ -z "$NAME" ] || [ -z "$COUNT" ]; then echo "Usage: node-group create <name> <count> <image> <vpc> [args...]"; exit 1; fi
      shift 4
      echo "Provisioning node-group '$NAME' ($COUNT independent nodes)..."
      i=1
      while [ "$i" -le "$COUNT" ]; do
        aws_node create "${NAME}-${i}" "$IMAGE" "$VPC" "$@"
        i=$((i + 1))
      done
      ;;
    *) echo "Unknown node-group action: $ACTION"; exit 1 ;;
  esac
}

aws_cron() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; SCHEDULE=$2; CMD=$3
      if [ -z "$NAME" ] || [ -z "$SCHEDULE" ]; then echo "Usage: cron create <target_node> <schedule> <command>"; exit 1; fi
      echo "Setting up cronjob on $NAME: $SCHEDULE $CMD"
      aws_node exec "$NAME" "(crontab -l 2>/dev/null; printf '%s %s\n' \"$SCHEDULE\" \"$CMD\") | crontab -"
      ;;
    *) echo "Unknown cron action: $ACTION"; exit 1 ;;
  esac
}

aws_jumpbox() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; IMAGE_ID=$2; VPC_NAME=${3:-LibScriptVPC}
      if [ -z "$NAME" ] || [ -z "$IMAGE_ID" ]; then echo "Usage: jumpbox create <name> <image_id> [vpc_name] [tags...]"; exit 1; fi
      echo "Setting up Jump-box '$NAME'..."
      VPC_ID=$(aws_network create "$VPC_NAME" "$@")
      SG_ID=$(aws_firewall create "${NAME}-sg" "$VPC_NAME" 22 "$@")
      INSTANCE_ID=$(aws_node create "$NAME" "$IMAGE_ID" "$VPC_NAME" "$@")
      echo "Jump-box '$NAME' ($INSTANCE_ID) is ready in VPC '$VPC_NAME' with SG '$SG_ID'."
      ;;
    *) echo "Unknown jumpbox action: $ACTION"; exit 1 ;;
  esac
}

aws_storage() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      BUCKET=$1; if [ -z "$BUCKET" ]; then echo "Usage: storage create <bucket> [--tags T] [--no-default-tags]"; exit 1; fi
      
      TAGS=$(parse_tags "$@")
      
      if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
        echo "Bucket '$BUCKET' exists." >&2
      else
        aws s3 mb "s3://$BUCKET"
        if [ -n "$TAGS" ]; then
          TAG_STR=$(echo "$TAGS" | sed "s/Key=/{Key=/g" | sed "s/Value=/Value=/g" | sed "s/ /},/g")"}"
          aws s3api put-bucket-tagging --bucket "$BUCKET" --tagging "TagSet=[$TAG_STR]"
        fi
        echo "Created Bucket '$BUCKET'." >&2
      fi
      ;;
    list)
      aws s3 ls
      ;;
    delete)
      BUCKET=$1; aws s3 rb "s3://$BUCKET" --force
      echo "Deleted Bucket '$BUCKET'"
      ;;
    *) echo "Unknown storage action: $ACTION"; exit 1 ;;
  esac
}

aws_list_managed() {
  FILTER_KEY=${1:-$TAG_KEY}
  FILTER_VAL=${2:-$TAG_VAL}
  echo "--- AWS Resources (Filter: $FILTER_KEY=$FILTER_VAL) ---"
  aws resourcegroupstaggingapi get-resources --tag-filters "Key=$FILTER_KEY,Values=$FILTER_VAL" \
    --query "ResourceTagMappingList[*].{ARN:ResourceARN, Tags:Tags}" --output table
}

aws_cleanup() {
  PURGE_BUCKETS=$1
  FILTER_KEY=${2:-$TAG_KEY}
  FILTER_VAL=${3:-$TAG_VAL}
  
  echo "Starting AWS Cleanup (Filter: $FILTER_KEY=$FILTER_VAL)..."
  RESOURCES=$(aws resourcegroupstaggingapi get-resources --tag-filters "Key=$FILTER_KEY,Values=$FILTER_VAL" --query "ResourceTagMappingList[*].ResourceARN" --output text)
  for ARN in $RESOURCES; do
    TYPE=$(echo "$ARN" | cut -d: -f3)
    SUBTYPE=$(echo "$ARN" | cut -d: -f6 | cut -d/ -f1)
    ID=$(echo "$ARN" | cut -d/ -f2)
    
    case "$TYPE" in
      ec2)
        case "$SUBTYPE" in
          instance) echo "Terminating instance $ID..."; aws ec2 terminate-instances --instance-ids "$ID" --quiet || true ;;
          vpc) echo "Deleting VPC $ID..."; aws ec2 delete-vpc --vpc-id "$ID" --quiet || true ;;
          security-group) echo "Deleting SG $ID..."; aws ec2 delete-security-group --group-id "$ID" --quiet || true ;;
          address) echo "Releasing IP $ID..."; aws ec2 release-address --allocation-id "$ID" --quiet || true ;;
        esac
        ;;
      s3)
        if [ "$PURGE_BUCKETS" = "true" ]; then
          BUCKET_NAME=$(echo "$ARN" | cut -d: -f6)
          echo "Deleting bucket $BUCKET_NAME..."
          aws s3 rb "s3://$BUCKET_NAME" --force || true
        else
          echo "Skipping bucket $ARN (safety enabled)"
        fi
        ;;
      route53)
        ZONE_ID=$(echo "$ARN" | cut -d/ -f2)
        echo "Deleting DNS zone $ZONE_ID..."; aws route53 delete-hosted-zone --id "$ZONE_ID" || true
        ;;
    esac
  done
}

# CLI Router
CMD=$1; shift
case "$CMD" in
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
  *)
    echo "LibScript AWS Cloud Wrapper"
    echo "Usage: $0 {network|firewall|node|node-group|cron|jumpbox|storage|list-managed|cleanup|install} [args...]"
    exit 1
    ;;
esac
