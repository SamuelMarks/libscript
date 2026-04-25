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
        aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames "{\"Value\":true}"
        SUBNET_ID=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block "$CIDR" --query "Subnet.SubnetId" --output text)
        aws ec2 modify-subnet-attribute --subnet-id "$SUBNET_ID" --map-public-ip-on-launch
        IGW_ID=$(aws ec2 create-internet-gateway --query "InternetGateway.InternetGatewayId" --output text)
        aws ec2 attach-internet-gateway --vpc-id "$VPC_ID" --internet-gateway-id "$IGW_ID"
        RT_ID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query "RouteTables[0].RouteTableId" --output text)
        aws ec2 create-route --route-table-id "$RT_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID" >/dev/null
        
        if [ -n "$TAGS" ]; then
          aws ec2 create-tags --resources "$VPC_ID" "$SUBNET_ID" "$IGW_ID" --tags "Key=Name,Value=$NAME" $TAGS
        else
          aws ec2 create-tags --resources "$VPC_ID" "$SUBNET_ID" "$IGW_ID" --tags "Key=Name,Value=$NAME"
        fi
        echo "Created VPC '$NAME' with Subnet & IGW: $VPC_ID" >&2
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
        SGS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[?GroupName!='default'].GroupId" --output text 2>/dev/null)
        for SG in $SGS; do aws ec2 delete-security-group --group-id "$SG" || true; done
        
        IGWS=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[*].InternetGatewayId" --output text 2>/dev/null)
        for IGW in $IGWS; do
          aws ec2 detach-internet-gateway --internet-gateway-id "$IGW" --vpc-id "$VPC_ID" || true
          aws ec2 delete-internet-gateway --internet-gateway-id "$IGW" || true
        done
        
        SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output text 2>/dev/null)
        for SUBNET in $SUBNETS; do aws ec2 delete-subnet --subnet-id "$SUBNET" || true; done
        
        aws ec2 delete-vpc --vpc-id "$VPC_ID"
        echo "Deleted VPC '$NAME' ($VPC_ID) and cascading resources."
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
        for P in $PORT; do
          aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port "$P" --cidr 0.0.0.0/0 >/dev/null || true
        done
        echo "Created Security Group '$NAME': $SG_ID (Ports $PORT open)" >&2
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
      PARSED_EXTRA=""
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
          *) 
             if [ -n "$PARSED_EXTRA" ]; then PARSED_EXTRA="$PARSED_EXTRA $1"; else PARSED_EXTRA="$1"; fi
             shift
             ;;
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
        EXTRA_ARGS="$EXTRA_ARGS $PARSED_EXTRA"
        if [ -n "$BOOTSTRAP" ]; then
          USER_DATA_FILE=$(mktemp)
          printf '#!/bin/bash\n%s\n' "$BOOTSTRAP" > "$USER_DATA_FILE"
          EXTRA_ARGS="$EXTRA_ARGS --user-data file://$USER_DATA_FILE"
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
      NAME=$1; CTX=$2; CMD=$3
      if [ -z "$NAME" ] || [ -z "$CMD" ]; then echo "Usage: node exec <name> <ctx> <command>"; exit 1; fi
      IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
      if [ "$IP" = "None" ] || [ -z "$IP" ]; then echo "Node '$NAME' not found or not running."; exit 1; fi
      echo "Executing on $NAME ($IP)..."
      ssh -o StrictHostKeyChecking=no "ubuntu@$IP" "$CMD"
      ;;

    sync)
      NAME=$1; VPC=${2:-}; DEST_OVERRIDE=$3
      if [ -z "$NAME" ]; then echo "Usage: node sync <name> <vpc> [dest]"; exit 1; fi
      IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
      if [ "$IP" = "None" ] || [ -z "$IP" ]; then echo "Node '$NAME' not found or not running."; exit 1; fi
      PLATFORM=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" --query "Reservations[0].Instances[0].Platform" --output text)
      echo "Syncing LibScript root to $NAME ($IP, OS: ${PLATFORM:-Linux})..."
      
      STAGING=$(mktemp -d)
      cp -R "$LIBSCRIPT_ROOT_DIR" "$STAGING/libscript"
      rm -rf "$STAGING/libscript/.git" "$STAGING/libscript/.idea" "$STAGING/libscript/vagrant" 2>/dev/null || true
      
      if [ "$PLATFORM" = "windows" ]; then
        DEST=${DEST_OVERRIDE:-"C:\\libscript"}
        aws_node winrm-exec "$NAME" "$VPC" "New-Item -ItemType Directory -Force -Path '$DEST'" >/dev/null 2>&1 || true
        aws_node winrm-cp "$NAME" "$VPC" "$STAGING/libscript" "$DEST"
      else
        DEST=${DEST_OVERRIDE:-"~/libscript"}
        aws_node exec "$NAME" "$VPC" "mkdir -p $DEST"
        if command -v rsync >/dev/null 2>&1; then
          rsync -avz -e "ssh -o StrictHostKeyChecking=no" "$STAGING/libscript/" "ubuntu@$IP:$DEST/" >/dev/null 2>&1
        else
          scp -o StrictHostKeyChecking=no -r "$STAGING/libscript/"* "ubuntu@$IP:$DEST/" >/dev/null 2>&1
        fi
      fi
      rm -rf "$STAGING"
      ;;

    deploy)
      NAME=$1; CTX=$2; SRC=$3; DEST=$4
      if [ -z "$NAME" ] || [ -z "$SRC" ] || [ -z "$DEST" ]; then echo "Usage: node deploy <name> <ctx> <src> <dest>"; exit 1; fi
      IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
      if [ "$IP" = "None" ] || [ -z "$IP" ]; then echo "Node '$NAME' not found or not running."; exit 1; fi
      echo "Deploying to $NAME ($IP)..."
      if [ -n "${WINRM_PASS:-}" ]; then
        echo "WINRM_PASS is set, deploying via WinRM..."
        USER=${WINRM_USER:-Administrator}
        if command -v pwsh >/dev/null 2>&1; then
          pwsh -c "\$p = ConvertTo-SecureString '$WINRM_PASS' -AsPlainText -Force; \$c = New-Object System.Management.Automation.PSCredential ('$USER', \$p); \$s = New-PSSession -ComputerName '$IP' -Credential \$c; Copy-Item -Path '$SRC' -Destination '$DEST' -ToSession \$s -Recurse -Force; Remove-PSSession \$s"
        else
          echo "Error: pwsh required for WinRM deployment"; exit 1
        fi
      elif command -v rsync >/dev/null 2>&1; then
        EXCLUDES="--exclude=.git"
        if [ -f "$SRC/.gitignore" ]; then
          EXCLUDES="$EXCLUDES --exclude-from=$SRC/.gitignore"
        fi
        rsync -avz $EXCLUDES -e "ssh -o StrictHostKeyChecking=no" "$SRC/" "ubuntu@$IP:$DEST/"
      else
        echo "Warning: rsync not found, falling back to scp (which ignores .gitignore)"
        scp -o StrictHostKeyChecking=no -r "$SRC" "ubuntu@$IP:$DEST/"
      fi
      ;;
    scp)
      NAME=$1; CTX=$2; SRC=$3; DEST=$4
      if [ -z "$NAME" ] || [ -z "$SRC" ] || [ -z "$DEST" ]; then echo "Usage: node scp <name> <ctx> <src> <dest>"; exit 1; fi
      IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
      if [ "$IP" = "None" ] || [ -z "$IP" ]; then echo "Node '$NAME' not found or not running."; exit 1; fi
      OS_TYPE=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" --query "Reservations[0].Instances[0].Platform" --output text 2>/dev/null || true)
      if [ "$OS_TYPE" = "windows" ] || [ -n "${WINRM_PASS:-}" ]; then
        echo "Copying to $NAME ($IP) via WinRM..."
        aws_node winrm-cp "$NAME" "$CTX" "$SRC" "$DEST"
      else
        echo "Copying to $NAME ($IP)..."
        if command -v rsync >/dev/null 2>&1; then
          rsync -avz -e "ssh -o StrictHostKeyChecking=no" "$SRC" "ubuntu@$IP:$DEST"
        else
          scp -o StrictHostKeyChecking=no -r "$SRC" "ubuntu@$IP:$DEST"
        fi
      fi
      ;;
    scp-from)
      NAME=$1; CTX=$2; SRC=$3; DEST=$4
      if [ -z "$NAME" ] || [ -z "$SRC" ] || [ -z "$DEST" ]; then echo "Usage: node scp-from <name> <ctx> <remote_src> <local_dest>"; exit 1; fi
      IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
      if [ "$IP" = "None" ] || [ -z "$IP" ]; then echo "Node '$NAME' not found or not running."; exit 1; fi
      OS_TYPE=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" --query "Reservations[0].Instances[0].Platform" --output text 2>/dev/null || true)
      if [ "$OS_TYPE" = "windows" ] || [ -n "${WINRM_PASS:-}" ]; then
        echo "Copying from $NAME ($IP) via WinRM..."
        aws_node winrm-cp-from "$NAME" "$CTX" "$SRC" "$DEST"
      else
        echo "Copying from $NAME ($IP)..."
        if command -v rsync >/dev/null 2>&1; then
          rsync -avz -e "ssh -o StrictHostKeyChecking=no" "ubuntu@$IP:$SRC" "$DEST"
        else
          scp -o StrictHostKeyChecking=no -r "ubuntu@$IP:$SRC" "$DEST"
        fi
      fi
      ;;
    winrm-exec)
      NAME=$1; CTX=$2; CMD=$3
      if [ -z "$NAME" ] || [ -z "$CMD" ]; then echo "Usage: node winrm-exec <name> <ctx> <command>"; exit 1; fi
      IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
      if [ "$IP" = "None" ] || [ -z "$IP" ]; then echo "Node '$NAME' not found or not running."; exit 1; fi
      USER=${WINRM_USER:-Administrator}
      if [ -z "${WINRM_PASS:-}" ]; then echo "WINRM_PASS environment variable required for winrm operations"; exit 1; fi
      echo "Executing on $NAME ($IP) via WinRM..."
      if command -v pwsh >/dev/null 2>&1; then
        pwsh -c "\$p = ConvertTo-SecureString '$WINRM_PASS' -AsPlainText -Force; \$c = New-Object System.Management.Automation.PSCredential ('$USER', \$p); Invoke-Command -ComputerName '$IP' -Credential \$c -ScriptBlock { Invoke-Expression '$CMD' }"
      elif command -v winrs >/dev/null 2>&1; then
        winrs -r:http://$IP:5985 -u:"$USER" -p:"$WINRM_PASS" "$CMD"
      else
        echo "Error: pwsh or winrs required for winrm operations"; exit 1
      fi
      ;;
    winrm-cp)
      NAME=$1; CTX=$2; SRC=$3; DEST=$4
      if [ -z "$NAME" ] || [ -z "$SRC" ] || [ -z "$DEST" ]; then echo "Usage: node winrm-cp <name> <ctx> <src> <dest>"; exit 1; fi
      IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
      if [ "$IP" = "None" ] || [ -z "$IP" ]; then echo "Node '$NAME' not found or not running."; exit 1; fi
      USER=${WINRM_USER:-Administrator}
      if [ -z "${WINRM_PASS:-}" ]; then echo "WINRM_PASS environment variable required for winrm operations"; exit 1; fi
      echo "Copying to $NAME ($IP) via WinRM..."
      if command -v pwsh >/dev/null 2>&1; then
        pwsh -c "\$p = ConvertTo-SecureString '$WINRM_PASS' -AsPlainText -Force; \$c = New-Object System.Management.Automation.PSCredential ('$USER', \$p); \$s = New-PSSession -ComputerName '$IP' -Credential \$c; Copy-Item -Path '$SRC' -Destination '$DEST' -ToSession \$s -Recurse -Force; Remove-PSSession \$s"
      else
        echo "Error: pwsh required for winrm-cp"; exit 1
      fi
      ;;
    winrm-cp-from)
      NAME=$1; CTX=$2; SRC=$3; DEST=$4
      if [ -z "$NAME" ] || [ -z "$SRC" ] || [ -z "$DEST" ]; then echo "Usage: node winrm-cp-from <name> <ctx> <remote_src> <local_dest>"; exit 1; fi
      IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
      if [ "$IP" = "None" ] || [ -z "$IP" ]; then echo "Node '$NAME' not found or not running."; exit 1; fi
      USER=${WINRM_USER:-Administrator}
      if [ -z "${WINRM_PASS:-}" ]; then echo "WINRM_PASS environment variable required for winrm operations"; exit 1; fi
      echo "Copying from $NAME ($IP) via WinRM..."
      if command -v pwsh >/dev/null 2>&1; then
        pwsh -c "\$p = ConvertTo-SecureString '$WINRM_PASS' -AsPlainText -Force; \$c = New-Object System.Management.Automation.PSCredential ('$USER', \$p); \$s = New-PSSession -ComputerName '$IP' -Credential \$c; Copy-Item -Path '$SRC' -Destination '$DEST' -FromSession \$s -Recurse -Force; Remove-PSSession \$s"
      else
        echo "Error: pwsh required for winrm-cp-from"; exit 1
      fi
      ;;
    snapshot)
      NAME=$1; SNAP_NAME=$2
      if [ -z "$NAME" ] || [ -z "$SNAP_NAME" ]; then echo "Usage: node snapshot <name> <snap_name>"; exit 1; fi
      INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" "Name=instance-state-name,Values=running,stopped" --query "Reservations[0].Instances[0].InstanceId" --output text)
      if [ "$INSTANCE_ID" = "None" ] || [ -z "$INSTANCE_ID" ]; then echo "Node '$NAME' not found."; exit 1; fi
      echo "Creating AMI for $NAME ($INSTANCE_ID)..."
      AMI_ID=$(aws ec2 create-image --instance-id "$INSTANCE_ID" --name "$SNAP_NAME" --no-reboot --query "ImageId" --output text)
      echo "Created AMI $AMI_ID"
      printf '%s\n' "$AMI_ID"
      ;;
    restore)
      NAME=$1; SNAP_NAME=$2; VPC_NAME=$3; TYPE=${4:-t2.micro}
      if [ -z "$NAME" ] || [ -z "$SNAP_NAME" ] || [ -z "$VPC_NAME" ]; then echo "Usage: node restore <name> <snap_name> <vpc_name> [type]"; exit 1; fi
      # Find AMI ID by name
      AMI_ID=$(aws ec2 describe-images --filters "Name=name,Values=$SNAP_NAME" --query "Images[0].ImageId" --output text)
      if [ "$AMI_ID" = "None" ] || [ -z "$AMI_ID" ]; then echo "Snapshot '$SNAP_NAME' not found."; exit 1; fi
      echo "Restoring $NAME from $SNAP_NAME ($AMI_ID)..."
      # Terminate old instance
      INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" "Name=instance-state-name,Values=running,stopped" --query "Reservations[0].Instances[0].InstanceId" --output text)
      if [ "$INSTANCE_ID" != "None" ] && [ -n "$INSTANCE_ID" ]; then
        aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" >/dev/null
        echo "Terminated old instance $INSTANCE_ID. Waiting for termination..."
        aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID"
      fi
      # Create new instance
      aws_node create "$NAME" "$AMI_ID" "$VPC_NAME" "$TYPE"
      ;;
    delete)
      NAME=$1; CTX=$2
      if [ -z "$NAME" ]; then echo "Usage: node delete <name> [ctx]"; exit 1; fi
      INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" "Name=instance-state-name,Values=running,stopped" --query "Reservations[0].Instances[0].InstanceId" --output text)
      if [ "$INSTANCE_ID" != "None" ] && [ -n "$INSTANCE_ID" ]; then
        echo "Deleting node '$NAME' ($INSTANCE_ID)..."
        aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" >/dev/null
      else
        echo "Node '$NAME' not found."
      fi
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
      NAME=$1; CTX=$2; SCHEDULE=$3; CMD=$4
      if [ -z "$NAME" ] || [ -z "$SCHEDULE" ]; then echo "Usage: cron create <target_node> <ctx> <schedule> <command>"; exit 1; fi
      echo "Setting up cronjob on $NAME: $SCHEDULE $CMD"
      aws_node exec "$NAME" "$CTX" "(crontab -l 2>/dev/null; printf '%s %s\n' \"$SCHEDULE\" \"$CMD\") | crontab -"
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

aws_dns() {
  ACTION=$1; shift
  case "$ACTION" in

    unmap-node)
      NAME=$1; DOMAIN=$2; ZONE_ID=$3
      if [ -z "$NAME" ] || [ -z "$DOMAIN" ] || [ -z "$ZONE_ID" ]; then echo "Usage: dns unmap-node <node_name> <domain> <zone_id>"; exit 1; fi
      IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
      if [ "$IP" != "None" ] && [ -n "$IP" ]; then
        CHANGE_BATCH="{\"Changes\":[{\"Action\":\"DELETE\",\"ResourceRecordSet\":{\"Name\":\"$DOMAIN\",\"Type\":\"A\",\"TTL\":300,\"ResourceRecords\":[{\"Value\":\"$IP\"}]}}]}"
        aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch "$CHANGE_BATCH" || true
      fi
      ;;
    map-node)
      NAME=$1; DOMAIN=$2; ZONE_ID=$3
      if [ -z "$NAME" ] || [ -z "$DOMAIN" ] || [ -z "$ZONE_ID" ]; then echo "Usage: dns map-node <node_name> <domain> <zone_id>"; exit 1; fi
      IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
      if [ "$IP" = "None" ] || [ -z "$IP" ]; then echo "Node not found."; exit 1; fi
      CHANGE_BATCH="{\"Changes\":[{\"Action\":\"UPSERT\",\"ResourceRecordSet\":{\"Name\":\"$DOMAIN\",\"Type\":\"A\",\"TTL\":300,\"ResourceRecords\":[{\"Value\":\"$IP\"}]}}]}"
      aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch "$CHANGE_BATCH"
      ;;
    *) echo "Unknown dns action: $ACTION"; exit 1 ;;
  esac
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
  dns) aws_dns "$@" ;;
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
  --help|-h)
    echo "LibScript AWS Cloud Wrapper"
    echo "Usage: $0 {dns|network|firewall|node|node-group|cron|jumpbox|storage|list-managed|cleanup|install} [args...]"
    echo ""
    echo "Commands:"
    echo "  dns            Map node IPs to DNS records"
    echo "  network        Manage VPCs and subnets"
    echo "  firewall       Manage Security Groups / Firewalls"
    echo "  node           Manage Compute Instances"
    echo "  node-group     Manage Node Groups"
    echo "  cron           Manage Cronjobs on nodes"
    echo "  jumpbox        Provision a Jump-box"
    echo "  storage        Manage Storage Buckets"
    echo "  list-managed   List resources managed by LibScript"
    echo "  cleanup        Delete resources managed by LibScript"
    echo "  install        Install required CLI dependencies"
    echo ""
    echo "Use '$0 <command> --help' for command-specific options (if applicable)."
    exit 0
    ;;
  *)
    echo "LibScript AWS Cloud Wrapper"
    echo "Usage: $0 {dns|network|firewall|node|node-group|cron|jumpbox|storage|list-managed|cleanup|install} [args...]"
    exit 1
    ;;
esac
