#!/bin/sh
# ## Overview
# Implements the `azure` cloud provider CLI, managing Azure VNETs, VMs, and resources.
#
# ## Usage
# Provides commands like `network`, `node`, `jumpbox`, `cleanup`, and ensures `azure-cli` and `jq` are installed.
# Sub-commands manage resource lifecycles wrapping the native `az` command.


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
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
TAG_KEY="ManagedBy"
TAG_VAL="LibScript"
DEFAULT_TAGS="$TAG_KEY=$TAG_VAL"

# Parses tags from arguments and handles default tagging logic.
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

# Dry run helper wrapper for az command.
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

# Ensures required dependencies (az, jq) are installed.
check_deps() {
  if ! command -v az >/dev/null 2>&1; then
    printf '%s\n' "azure-cli not found, installing..."
    "$LIBSCRIPT_ROOT_DIR/libscript.sh" install azure-cli latest
  fi
  if ! command -v jq >/dev/null 2>&1; then
    printf '%s\n' "jq not found, installing..."
    "$LIBSCRIPT_ROOT_DIR/libscript.sh" install jq latest
  fi
}

# Manages Azure Virtual Networks (VNET).
azure_network() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; RG=${2:-$AZURE_RESOURCE_GROUP}
      if [ -z "$NAME" ] || [ -z "$RG" ]; then printf '%s\n' "Usage: network create <name> <rg> [--tags T] [--no-default-tags]"; exit 1; fi
      
      TAGS=$(parse_tags "$@")
      
      if ! az network vnet show --name "$NAME" --resource-group "$RG" >/dev/null 2>&1; then
        if [ -n "$TAGS" ]; then
          az network vnet create --name "$NAME" --resource-group "$RG" --address-prefix 10.0.0.0/16 --tags $TAGS
        else
          az network vnet create --name "$NAME" --resource-group "$RG" --address-prefix 10.0.0.0/16
        fi
        printf '%s\n' "Created VNET '$NAME'"
      fi
      ;;
    list)
      az network vnet list --query "[*].{Name:name, RG:resourceGroup, Tags:tags}" --output table
      ;;
    delete)
      NAME=$1; RG=${2:-$AZURE_RESOURCE_GROUP}
      az network vnet delete --name "$NAME" --resource-group "$RG"
      ;;
    *) printf '%s\n' "Unknown network action: $ACTION"; exit 1 ;;
  esac
}

# Manages Azure Network Security Groups (NSG).
azure_firewall() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; RG=${2:-$AZURE_RESOURCE_GROUP}; PORT=${3:-22}
      if [ -z "$NAME" ] || [ -z "$RG" ]; then printf '%s\n' "Usage: firewall create <name> <rg> [port] [--tags T] [--no-default-tags]"; exit 1; fi
      
      TAGS=$(parse_tags "$@")
      
      if ! az network nsg show --name "$NAME" --resource-group "$RG" >/dev/null 2>&1; then
        if [ -n "$TAGS" ]; then
          az network nsg create --name "$NAME" --resource-group "$RG" --tags $TAGS
        else
          az network nsg create --name "$NAME" --resource-group "$RG"
        fi
        az network nsg rule create --name AllowSSH --nsg-name "$NAME" --resource-group "$RG" --priority 100 --destination-port-ranges "$PORT" --access Allow --protocol Tcp
        printf '%s\n' "Created NSG '$NAME' (Port $PORT open)"
      fi
      ;;
    list)
      az network nsg list --query "[*].{Name:name, RG:resourceGroup, Tags:tags}" --output table
      ;;
    *) printf '%s\n' "Unknown firewall action: $ACTION"; exit 1 ;;
  esac
}

# Manages individual Azure VMs.
azure_node() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; IMAGE=$2; RG=${3:-$AZURE_RESOURCE_GROUP}
      if [ -z "$NAME" ] || [ -z "$IMAGE" ] || [ -z "$RG" ]; then 
        printf '%s\n' "Usage: node create <name> <image> <rg> [--bootstrap <script>] [--tags T] [--no-default-tags]"
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
        printf '%s\n' "Created VM '$NAME'"
        if [ -n "${USER_DATA_FILE:-}" ]; then rm -f "$USER_DATA_FILE"; fi
      fi
      ;;
    exec)
      NAME=$1; RG=${2:-$AZURE_RESOURCE_GROUP}; CMD=$3
      if [ -z "$NAME" ] || [ -z "$CMD" ]; then printf '%s\n' "Usage: node exec <name> <rg> <command>"; exit 1; fi
      IP=$(az vm show -d -g "$RG" -n "$NAME" --query publicIps -o tsv)
      printf '%s\n' "Executing on $NAME ($IP)..."
      ssh -o StrictHostKeyChecking=no "libscript@$IP" "$CMD"
      ;;
    list)
      az vm list --query "[*].{Name:name, RG:resourceGroup, Tags:tags}" --output table
      ;;
    delete)
      NAME=$1; RG=${2:-$AZURE_RESOURCE_GROUP}
      az vm delete --name "$NAME" --resource-group "$RG" --yes
      ;;
    *) printf '%s\n' "Unknown node action: $ACTION"; exit 1 ;;
  esac
}

# Manages groups of independent Azure VMs.
azure_node_group() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; COUNT=$2; IMAGE=$3; RG=$4
      if [ -z "$NAME" ] || [ -z "$COUNT" ]; then printf '%s\n' "Usage: node-group create <name> <count> <image> <rg> [args...]"; exit 1; fi
      shift 4
      printf '%s\n' "Provisioning Azure node-group '$NAME' ($COUNT independent nodes)..."
      i=1
      while [ "$i" -le "$COUNT" ]; do
        azure_node create "${NAME}-${i}" "$IMAGE" "$RG" "$@"
        i=$((i + 1))
      done
      ;;
    *) printf '%s\n' "Unknown node-group action: $ACTION"; exit 1 ;;
  esac
}

# Manages cron jobs directly on Azure VMs over SSH.
azure_cron() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; RG=$2; SCHEDULE=$3; CMD=$4
      if [ -z "$NAME" ] || [ -z "$SCHEDULE" ]; then printf '%s\n' "Usage: cron create <target_node> <rg> <schedule> <command>"; exit 1; fi
      printf '%s\n' "Setting up cronjob on Azure VM $NAME: $SCHEDULE $CMD"
      azure_node exec "$NAME" "$RG" "(crontab -l 2>/dev/null; printf '%s %s\n' \"$SCHEDULE\" \"$CMD\") | crontab -"
      ;;
    *) printf '%s\n' "Unknown cron action: $ACTION"; exit 1 ;;
  esac
}

# Provisions a complete Jumpbox environment (VNET, NSG, VM) in Azure.
azure_jumpbox() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; IMAGE=$2; RG=${3:-$AZURE_RESOURCE_GROUP}
      printf '%s\n' "Setting up Azure Jump-box '$NAME'..."
      azure_network create "${NAME}-vnet" "$RG" "$@"
      azure_firewall create "${NAME}-nsg" "$RG" 22 "$@"
      azure_node create "$NAME" "$IMAGE" "$RG" "$@"
      printf '%s\n' "Azure Jump-box '$NAME' ready."
      ;;
    *) printf '%s\n' "Unknown jumpbox action: $ACTION"; exit 1 ;;
  esac
}

# Manages Azure Storage Accounts.
azure_storage() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; RG=${2:-$AZURE_RESOURCE_GROUP}
      if [ -z "$NAME" ] || [ -z "$RG" ]; then printf '%s\n' "Usage: storage create <name> <rg> [--tags T] [--no-default-tags]"; exit 1; fi
      
      TAGS=$(parse_tags "$@")
      
      if ! az storage account show --name "$NAME" --resource-group "$RG" >/dev/null 2>&1; then
        if [ -n "$TAGS" ]; then
          az storage account create --name "$NAME" --resource-group "$RG" --sku Standard_LRS --tags $TAGS
        else
          az storage account create --name "$NAME" --resource-group "$RG" --sku Standard_LRS
        fi
        printf '%s\n' "Created Storage Account '$NAME'"
      fi
      ;;
    delete)
      NAME=$1; RG=${2:-$AZURE_RESOURCE_GROUP}
      az storage account delete --name "$NAME" --resource-group "$RG" --yes
      ;;
    *) printf '%s\n' "Unknown storage action: $ACTION"; exit 1 ;;
  esac
}

# Lists resources managed by LibScript in Azure based on tags.
azure_list_managed() {
  FILTER_TAG=${1:-"$TAG_KEY=$TAG_VAL"}
  printf '%s\n' "--- Azure Resources (Filter: $FILTER_TAG) ---"
  az resource list --tag "$FILTER_TAG" --output table
}

# Cleans up Azure resources provisioned by LibScript based on tags.
azure_cleanup() {
  PURGE_BUCKETS=$1
  FILTER_TAG=${2:-"$TAG_KEY=$TAG_VAL"}
  
  printf '%s\n' "Starting Azure Cleanup (Filter: $FILTER_TAG)..."
  RESOURCES=$(az resource list --tag "$FILTER_TAG" --query "[].id" -o tsv)
  for ID in $RESOURCES; do
    TYPE=$(printf '%s\n' "$ID" | awk -F/ '{print $(NF-1)}')
    if [ "$TYPE" = "storageAccounts" ] && [ "$PURGE_BUCKETS" != "true" ]; then
      printf '%s\n' "Skipping storage account $ID (safety enabled)"
      continue
    fi
    printf '%s\n' "Deleting $ID..."
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
    printf '%s\n' "LibScript Azure Cloud Wrapper"
    printf '%s\n' "Usage: $0 {network|firewall|node|node-group|cron|jumpbox|storage|list-managed|cleanup|install} [args...]"
    exit 1
    ;;
esac
