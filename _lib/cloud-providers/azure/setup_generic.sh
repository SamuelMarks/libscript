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

case "$ACTION" in
  network)
    SUBACTION="${1:-}"
    NET_NAME="${2:-}"
    RG="${3:-}"
    if [ "$SUBACTION" = "create" ]; then
      LOC="${location:-eastus}"
      log_info "Creating Azure VNet: $NET_NAME in $RG ($LOC)"
      az network vnet create --name "$NET_NAME" --resource-group "$RG" --location "$LOC"
    elif [ "$SUBACTION" = "delete" ]; then
      log_info "Deleting Azure VNet: $NET_NAME from $RG"
      az network vnet delete --name "$NET_NAME" --resource-group "$RG" --yes
    fi
    ;;
  firewall)
    SUBACTION="${1:-}"
    FW_NAME="${2:-}"
    RG="${3:-}"
    PORTS="${4:-}"
    if [ "$SUBACTION" = "create" ]; then
      LOC="${location:-eastus}"
      log_info "Creating Azure NSG: $FW_NAME in $RG ($LOC)"
      az network nsg create --name "$FW_NAME" --resource-group "$RG" --location "$LOC"
      if [ -n "$PORTS" ]; then
        PRIORITY=1000
        for PORT in $PORTS; do
          log_info "Opening port $PORT on $FW_NAME"
          az network nsg rule create --resource-group "$RG" --nsg-name "$FW_NAME" --name "Allow_$PORT" --priority $PRIORITY --destination-port-ranges "$PORT" --access Allow --protocol Tcp
          PRIORITY=$((PRIORITY + 10))
        done
      fi
    elif [ "$SUBACTION" = "delete" ]; then
      log_info "Deleting Azure NSG: $FW_NAME from $RG"
      az network nsg delete --name "$FW_NAME" --resource-group "$RG" --yes
    elif [ "$SUBACTION" = "list" ]; then
      az network nsg list -o table
    fi
    ;;
  node)
    SUBACTION="${1:-}"
    NODE_NAME="${2:-}"
    if [ "$SUBACTION" = "create" ]; then
      IMAGE="${3:-}"
      RG="${4:-}"
      SZ="${size:-Standard_D2s_v7}"
      VN="${vnet_name:-}"
      NSG="${nsg:-}"
      DSK="${os_disk_size_gb:-}"
      ARGS=""
      if [ -n "$VN" ]; then ARGS="$ARGS --vnet-name $VN"; fi
      if [ -n "$NSG" ]; then ARGS="$ARGS --nsg $NSG"; fi
      if [ -n "$DSK" ]; then ARGS="$ARGS --os-disk-size-gb $DSK"; fi
      log_info "Creating Azure VM: $NODE_NAME in $RG ($SZ, $IMAGE)"
      az vm create --resource-group "$RG" --name "$NODE_NAME" --image "$IMAGE" --size "$SZ" --admin-username azureuser --generate-ssh-keys --public-ip-sku Standard $ARGS
    elif [ "$SUBACTION" = "delete" ]; then
      RG="${3:-}"
      log_info "Deleting Azure VM: $NODE_NAME from $RG"
      az vm delete --name "$NODE_NAME" --resource-group "$RG" --yes
    elif [ "$SUBACTION" = "exec" ]; then
      RG="${3:-}"
      shift 3
      CMD="$*"
      log_info "Executing command on $NODE_NAME: $CMD"
      IP=$(az vm show -d -g "$RG" -n "$NODE_NAME" --query publicIps -o tsv)
      ssh -o StrictHostKeyChecking=no "azureuser@$IP" "$CMD"
    elif [ "$SUBACTION" = "deploy" ]; then
      RG="${3:-}"
      SRC="${4:-}"
      DST="${5:-}"
      IP=$(az vm show -d -g "$RG" -n "$NODE_NAME" --query publicIps -o tsv)
      log_info "Deploying $SRC to azureuser@$IP:$DST"
      rsync -avz -e "ssh -o StrictHostKeyChecking=no" "$SRC" "azureuser@$IP:$DST"
    elif [ "$SUBACTION" = "scp" ]; then
      RG="${3:-}"
      SRC="${4:-}"
      DST="${5:-}"
      IP=$(az vm show -d -g "$RG" -n "$NODE_NAME" --query publicIps -o tsv)
      log_info "Copying $SRC to azureuser@$IP:$DST"
      scp -o StrictHostKeyChecking=no "$SRC" "azureuser@$IP:$DST"
    elif [ "$SUBACTION" = "scp-from" ]; then
      RG="${3:-}"
      SRC="${4:-}"
      DST="${5:-}"
      IP=$(az vm show -d -g "$RG" -n "$NODE_NAME" --query publicIps -o tsv)
      log_info "Copying azureuser@$IP:$SRC to $DST"
      scp -o StrictHostKeyChecking=no "azureuser@$IP:$SRC" "$DST"
    elif [ "$SUBACTION" = "sync" ]; then
      RG="${3:-}"
      log_info "Syncing LibScript to remote node $NODE_NAME"
      IP=$(az vm show -d -g "$RG" -n "$NODE_NAME" --query publicIps -o tsv)
      ssh -o StrictHostKeyChecking=no "azureuser@$IP" "mkdir -p ~/libscript"
      rsync -avz -e "ssh -o StrictHostKeyChecking=no" "$LIBSCRIPT_ROOT_DIR/" "azureuser@$IP:~/libscript/"
    fi
    ;;
  dns)
    SUBACTION="${1:-}"
    NODE_NAME="${2:-}"
    if [ "$SUBACTION" = "map-node" ]; then
      RG="${3:-}"
      DOMAIN="${4:-}"
      ZONE="${5:-}"
      DNS_RG="${6:-}"
      if [ -z "$DNS_RG" ]; then DNS_RG="${ZONE}-rg"; fi
      log_info "Mapping $DOMAIN to $NODE_NAME"
      IP=$(az vm show -d -g "$RG" -n "$NODE_NAME" --query publicIps -o tsv)
      RECORD_NAME=$(echo "$DOMAIN" | sed "s/\.$ZONE//")
      if [ "$RECORD_NAME" = "$DOMAIN" ]; then RECORD_NAME="@"; fi
      az network dns record-set a add-record -g "$DNS_RG" -z "$ZONE" -n "$RECORD_NAME" -a "$IP"
    elif [ "$SUBACTION" = "unmap-node" ]; then
      RG="${3:-}"
      DOMAIN="${4:-}"
      ZONE="${5:-}"
      DNS_RG="${6:-}"
      if [ -z "$DNS_RG" ]; then DNS_RG="${ZONE}-rg"; fi
      log_info "Unmapping $DOMAIN from $NODE_NAME"
      IP=$(az vm show -d -g "$RG" -n "$NODE_NAME" --query publicIps -o tsv)
      RECORD_NAME=$(echo "$DOMAIN" | sed "s/\.$ZONE//")
      if [ "$RECORD_NAME" = "$DOMAIN" ]; then RECORD_NAME="@"; fi
      az network dns record-set a remove-record -g "$DNS_RG" -z "$ZONE" -n "$RECORD_NAME" -a "$IP"
    fi
    ;;
esac