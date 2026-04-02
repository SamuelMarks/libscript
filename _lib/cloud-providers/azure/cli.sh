#!/bin/sh
# shellcheck disable=SC2154,SC2086,SC2155,SC2046,SC2039,SC2006,SC2112,SC2002

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"

TAG_KEY="ManagedBy"
TAG_VAL="LibScript"
DEFAULT_TAGS="$TAG_KEY=$TAG_VAL"

# Parse tags from arguments
# Returns a space-separated list of Key=V strings
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
az() {
  if [ "${DRY_RUN:-}" = "true" ]; then
    printf '[DRY_RUN] az %s\n' "$*" >&2
    case "$*" in
      *"show"*) return 1 ;; # Simulate resource not found
      *) return 0 ;;
    esac
  fi
  command az "$@"
}

# Ensure az and jq are installed
check_deps() {
  if ! command -v az >/dev/null 2>&1; then
    echo "azure-cli not found, installing..."
    "$LIBSCRIPT_ROOT_DIR/libscript.sh" install azure-cli latest
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found, installing..."
    "$LIBSCRIPT_ROOT_DIR/libscript.sh" install jq latest
  fi
}

azure_network() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; RG=${2:-$AZURE_RESOURCE_GROUP}
      if [ -z "$NAME" ] || [ -z "$RG" ]; then echo "Usage: network create <name> <rg> [--tags T] [--no-default-tags]"; exit 1; fi
      
      TAGS=$(parse_tags "$@")
      
      if ! az network vnet show --name "$NAME" --resource-group "$RG" >/dev/null 2>&1; then
        if [ -n "$TAGS" ]; then
          az network vnet create --name "$NAME" --resource-group "$RG" --address-prefix 10.0.0.0/16 --tags $TAGS
        else
          az network vnet create --name "$NAME" --resource-group "$RG" --address-prefix 10.0.0.0/16
        fi
        echo "Created VNET '$NAME'"
      fi
      ;;
    list)
      az network vnet list --query "[*].{Name:name, RG:resourceGroup, Tags:tags}" --output table
      ;;
    delete)
      NAME=$1; RG=${2:-$AZURE_RESOURCE_GROUP}
      az network vnet delete --name "$NAME" --resource-group "$RG"
      ;;
    *) echo "Unknown network action: $ACTION"; exit 1 ;;
  esac
}

azure_firewall() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; RG=${2:-$AZURE_RESOURCE_GROUP}; PORT=${3:-22}
      if [ -z "$NAME" ] || [ -z "$RG" ]; then echo "Usage: firewall create <name> <rg> [port] [--tags T] [--no-default-tags]"; exit 1; fi
      
      TAGS=$(parse_tags "$@")
      
      if ! az network nsg show --name "$NAME" --resource-group "$RG" >/dev/null 2>&1; then
        if [ -n "$TAGS" ]; then
          az network nsg create --name "$NAME" --resource-group "$RG" --tags $TAGS
        else
          az network nsg create --name "$NAME" --resource-group "$RG"
        fi
        az network nsg rule create --name AllowSSH --nsg-name "$NAME" --resource-group "$RG" --priority 100 --destination-port-ranges "$PORT" --access Allow --protocol Tcp
        echo "Created NSG '$NAME' (Port $PORT open)"
      fi
      ;;
    list)
      az network nsg list --query "[*].{Name:name, RG:resourceGroup, Tags:tags}" --output table
      ;;
    *) echo "Unknown firewall action: $ACTION"; exit 1 ;;
  esac
}

azure_node() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; IMAGE=$2; RG=${3:-$AZURE_RESOURCE_GROUP}
      if [ -z "$NAME" ] || [ -z "$IMAGE" ] || [ -z "$RG" ]; then 
        echo "Usage: node create <name> <image> <rg> [--bootstrap <script>] [--tags T] [--no-default-tags]"
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

      if ! az vm show --name "$NAME" --resource-group "$RG" >/dev/null 2>&1; then
        EXTRA_ARGS=""
        if [ -n "$BOOTSTRAP" ]; then
          USER_DATA_FILE=$(mktemp)
          printf '#!/bin/bash\n%s\n' "$BOOTSTRAP" > "$USER_DATA_FILE"
          EXTRA_ARGS="--custom-data $USER_DATA_FILE"
        fi
        
        if [ -n "$TAGS" ]; then
          az vm create --name "$NAME" --resource-group "$RG" --image "$IMAGE" --admin-username libscript --generate-ssh-keys --tags $TAGS $EXTRA_ARGS
        else
          az vm create --name "$NAME" --resource-group "$RG" --image "$IMAGE" --admin-username libscript --generate-ssh-keys $EXTRA_ARGS
        fi
        echo "Created VM '$NAME'"
        if [ -n "${USER_DATA_FILE:-}" ]; then rm -f "$USER_DATA_FILE"; fi
      fi
      ;;
    exec)
      NAME=$1; RG=${2:-$AZURE_RESOURCE_GROUP}; CMD=$3
      if [ -z "$NAME" ] || [ -z "$CMD" ]; then echo "Usage: node exec <name> <rg> <command>"; exit 1; fi
      IP=$(az vm show -d -g "$RG" -n "$NAME" --query publicIps -o tsv)
      echo "Executing on $NAME ($IP)..."
      ssh -o StrictHostKeyChecking=no "libscript@$IP" "$CMD"
      ;;
    scp)
      NAME=$1; RG=${2:-$AZURE_RESOURCE_GROUP}; SRC=$3; DEST=$4
      if [ -z "$NAME" ] || [ -z "$SRC" ] || [ -z "$DEST" ]; then echo "Usage: node scp <name> <rg> <src> <dest>"; exit 1; fi
      IP=$(az vm show -d -g "$RG" -n "$NAME" --query publicIps -o tsv)
      echo "Copying to $NAME ($IP)..."
      scp -o StrictHostKeyChecking=no -r "$SRC" "libscript@$IP:$DEST"
      ;;
    scp-from)
      NAME=$1; RG=${2:-$AZURE_RESOURCE_GROUP}; SRC=$3; DEST=$4
      if [ -z "$NAME" ] || [ -z "$SRC" ] || [ -z "$DEST" ]; then echo "Usage: node scp-from <name> <rg> <remote_src> <local_dest>"; exit 1; fi
      IP=$(az vm show -d -g "$RG" -n "$NAME" --query publicIps -o tsv)
      echo "Copying from $NAME ($IP)..."
      scp -o StrictHostKeyChecking=no -r "libscript@$IP:$SRC" "$DEST"
      ;;
    winrm-exec)
      NAME=$1; RG=${2:-$AZURE_RESOURCE_GROUP}; CMD=$3
      if [ -z "$NAME" ] || [ -z "$CMD" ]; then echo "Usage: node winrm-exec <name> <rg> <command>"; exit 1; fi
      IP=$(az vm show -d -g "$RG" -n "$NAME" --query publicIps -o tsv)
      USER=${WINRM_USER:-libscript}
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
      NAME=$1; RG=${2:-$AZURE_RESOURCE_GROUP}; SRC=$3; DEST=$4
      if [ -z "$NAME" ] || [ -z "$SRC" ] || [ -z "$DEST" ]; then echo "Usage: node winrm-cp <name> <rg> <src> <dest>"; exit 1; fi
      IP=$(az vm show -d -g "$RG" -n "$NAME" --query publicIps -o tsv)
      USER=${WINRM_USER:-libscript}
      if [ -z "${WINRM_PASS:-}" ]; then echo "WINRM_PASS environment variable required for winrm operations"; exit 1; fi
      echo "Copying to $NAME ($IP) via WinRM..."
      if command -v pwsh >/dev/null 2>&1; then
        pwsh -c "\$p = ConvertTo-SecureString '$WINRM_PASS' -AsPlainText -Force; \$c = New-Object System.Management.Automation.PSCredential ('$USER', \$p); \$s = New-PSSession -ComputerName '$IP' -Credential \$c; Copy-Item -Path '$SRC' -Destination '$DEST' -ToSession \$s -Recurse -Force; Remove-PSSession \$s"
      else
        echo "Error: pwsh required for winrm-cp"; exit 1
      fi
      ;;
    winrm-cp-from)
      NAME=$1; RG=${2:-$AZURE_RESOURCE_GROUP}; SRC=$3; DEST=$4
      if [ -z "$NAME" ] || [ -z "$SRC" ] || [ -z "$DEST" ]; then echo "Usage: node winrm-cp-from <name> <rg> <remote_src> <local_dest>"; exit 1; fi
      IP=$(az vm show -d -g "$RG" -n "$NAME" --query publicIps -o tsv)
      USER=${WINRM_USER:-libscript}
      if [ -z "${WINRM_PASS:-}" ]; then echo "WINRM_PASS environment variable required for winrm operations"; exit 1; fi
      echo "Copying from $NAME ($IP) via WinRM..."
      if command -v pwsh >/dev/null 2>&1; then
        pwsh -c "\$p = ConvertTo-SecureString '$WINRM_PASS' -AsPlainText -Force; \$c = New-Object System.Management.Automation.PSCredential ('$USER', \$p); \$s = New-PSSession -ComputerName '$IP' -Credential \$c; Copy-Item -Path '$SRC' -Destination '$DEST' -FromSession \$s -Recurse -Force; Remove-PSSession \$s"
      else
        echo "Error: pwsh required for winrm-cp-from"; exit 1
      fi
      ;;
    snapshot)
      NAME=$1; RG=${2:-$AZURE_RESOURCE_GROUP}; SNAP_NAME=$3
      if [ -z "$NAME" ] || [ -z "$SNAP_NAME" ]; then echo "Usage: node snapshot <name> <rg> <snap_name>"; exit 1; fi
      # Azure requires deallocating the VM before capturing an image (if generalized)
      # For simple backup, we can just snapshot the OS disk or capture an image.
      # Capturing a specialized image (without sysprep)
      echo "Deallocating VM $NAME..."
      az vm deallocate -g "$RG" -n "$NAME" >/dev/null
      echo "Generalizing VM $NAME..."
      az vm generalize -g "$RG" -n "$NAME" >/dev/null
      echo "Creating image $SNAP_NAME..."
      IMAGE_ID=$(az image create -g "$RG" -n "$SNAP_NAME" --source "$NAME" --query id -o tsv)
      echo "Created Image $IMAGE_ID"
      printf '%s\n' "$IMAGE_ID"
      ;;
    restore)
      NAME=$1; RG=${2:-$AZURE_RESOURCE_GROUP}; SNAP_NAME=$3
      if [ -z "$NAME" ] || [ -z "$SNAP_NAME" ]; then echo "Usage: node restore <name> <rg> <snap_name>"; exit 1; fi
      IMAGE_ID=$(az image show -g "$RG" -n "$SNAP_NAME" --query id -o tsv)
      if [ -z "$IMAGE_ID" ]; then echo "Snapshot '$SNAP_NAME' not found."; exit 1; fi
      echo "Restoring $NAME from $SNAP_NAME ($IMAGE_ID)..."
      # Delete old VM to avoid conflicts
      az vm delete -g "$RG" -n "$NAME" --yes >/dev/null 2>&1 || true
      azure_node create "$NAME" "$IMAGE_ID" "$RG"
      ;;
    list)
      az vm list --query "[*].{Name:name, RG:resourceGroup, Tags:tags}" --output table
      ;;
    delete)
      NAME=$1; RG=${2:-$AZURE_RESOURCE_GROUP}
      az vm delete --name "$NAME" --resource-group "$RG" --yes
      ;;
    *) echo "Unknown node action: $ACTION"; exit 1 ;;
  esac
}

azure_node_group() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; COUNT=$2; IMAGE=$3; RG=$4
      if [ -z "$NAME" ] || [ -z "$COUNT" ]; then echo "Usage: node-group create <name> <count> <image> <rg> [args...]"; exit 1; fi
      shift 4
      echo "Provisioning Azure node-group '$NAME' ($COUNT independent nodes)..."
      i=1
      while [ "$i" -le "$COUNT" ]; do
        azure_node create "${NAME}-${i}" "$IMAGE" "$RG" "$@"
        i=$((i + 1))
      done
      ;;
    *) echo "Unknown node-group action: $ACTION"; exit 1 ;;
  esac
}

azure_cron() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; RG=$2; SCHEDULE=$3; CMD=$4
      if [ -z "$NAME" ] || [ -z "$SCHEDULE" ]; then echo "Usage: cron create <target_node> <rg> <schedule> <command>"; exit 1; fi
      echo "Setting up cronjob on Azure VM $NAME: $SCHEDULE $CMD"
      azure_node exec "$NAME" "$RG" "(crontab -l 2>/dev/null; printf '%s %s\n' \"$SCHEDULE\" \"$CMD\") | crontab -"
      ;;
    *) echo "Unknown cron action: $ACTION"; exit 1 ;;
  esac
}

azure_jumpbox() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; IMAGE=$2; RG=${3:-$AZURE_RESOURCE_GROUP}
      echo "Setting up Azure Jump-box '$NAME'..."
      azure_network create "${NAME}-vnet" "$RG" "$@"
      azure_firewall create "${NAME}-nsg" "$RG" 22 "$@"
      azure_node create "$NAME" "$IMAGE" "$RG" "$@"
      echo "Azure Jump-box '$NAME' ready."
      ;;
    *) echo "Unknown jumpbox action: $ACTION"; exit 1 ;;
  esac
}

azure_storage() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; RG=${2:-$AZURE_RESOURCE_GROUP}
      if [ -z "$NAME" ] || [ -z "$RG" ]; then echo "Usage: storage create <name> <rg> [--tags T] [--no-default-tags]"; exit 1; fi
      
      TAGS=$(parse_tags "$@")
      
      if ! az storage account show --name "$NAME" --resource-group "$RG" >/dev/null 2>&1; then
        if [ -n "$TAGS" ]; then
          az storage account create --name "$NAME" --resource-group "$RG" --sku Standard_LRS --tags $TAGS
        else
          az storage account create --name "$NAME" --resource-group "$RG" --sku Standard_LRS
        fi
        echo "Created Storage Account '$NAME'"
      fi
      ;;
    delete)
      NAME=$1; RG=${2:-$AZURE_RESOURCE_GROUP}
      az storage account delete --name "$NAME" --resource-group "$RG" --yes
      ;;
    *) echo "Unknown storage action: $ACTION"; exit 1 ;;
  esac
}

azure_list_managed() {
  FILTER_TAG=${1:-"$TAG_KEY=$TAG_VAL"}
  echo "--- Azure Resources (Filter: $FILTER_TAG) ---"
  az resource list --tag "$FILTER_TAG" --output table
}

azure_cleanup() {
  PURGE_BUCKETS=$1
  FILTER_TAG=${2:-"$TAG_KEY=$TAG_VAL"}
  
  echo "Starting Azure Cleanup (Filter: $FILTER_TAG)..."
  RESOURCES=$(az resource list --tag "$FILTER_TAG" --query "[].id" -o tsv)
  for ID in $RESOURCES; do
    TYPE=$(echo "$ID" | awk -F/ '{print $(NF-1)}')
    if [ "$TYPE" = "storageAccounts" ] && [ "$PURGE_BUCKETS" != "true" ]; then
      echo "Skipping storage account $ID (safety enabled)"
      continue
    fi
    echo "Deleting $ID..."
    az resource delete --ids "$ID" || true
  done
}

# CLI Router
CMD=$1; shift
case "$CMD" in
  network) azure_network "$@" ;;
  firewall) azure_firewall "$@" ;;
  node) azure_node "$@" ;;
  node-group) azure_node_group "$@" ;;
  cron) azure_cron "$@" ;;
  jumpbox) azure_jumpbox "$@" ;;
  storage) azure_storage "$@" ;;
  list-managed) azure_list_managed "$@" ;;
  cleanup) azure_cleanup "$@" ;;
  install) check_deps ;;
  *)
    echo "LibScript Azure Cloud Wrapper"
    echo "Usage: $0 {network|firewall|node|node-group|cron|jumpbox|storage|list-managed|cleanup|install} [args...]"
    exit 1
    ;;
esac
