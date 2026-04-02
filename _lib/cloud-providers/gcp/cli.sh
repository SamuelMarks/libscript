#!/bin/sh
# shellcheck disable=SC2154,SC2086,SC2155,SC2046,SC2039,SC2006,SC2112,SC2002

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"

TAG_KEY="managed-by"
TAG_VAL="libscript"
DEFAULT_LABELS="$TAG_KEY=$TAG_VAL"

# Parse labels from arguments
# Returns a comma-separated list of Key=V
parse_labels() {
  USE_DEFAULT=true
  CUSTOM_LABELS=""
  
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-default-tags) USE_DEFAULT=false; shift ;;
      --tags)
        if [ -n "$CUSTOM_LABELS" ]; then CUSTOM_LABELS="$CUSTOM_LABELS,$2"; else CUSTOM_LABELS="$2"; fi
        shift 2 ;;
      *) shift ;;
    esac
  done
  
  FINAL_LABELS=""
  if [ "$USE_DEFAULT" = "true" ]; then
    FINAL_LABELS="$DEFAULT_LABELS"
  fi
  if [ -n "$CUSTOM_LABELS" ]; then
    if [ -n "$FINAL_LABELS" ]; then FINAL_LABELS="$FINAL_LABELS,$CUSTOM_LABELS"; else FINAL_LABELS="$CUSTOM_LABELS"; fi
  fi
  printf '%s' "$FINAL_LABELS"
}

# Dry run helper
gcloud() {
  if [ "${DRY_RUN:-}" = "true" ]; then
    printf '[DRY_RUN] gcloud %s\n' "$*" >&2
    case "$*" in
      *"describe"*) return 1 ;; # Simulate resource not found
      *) return 0 ;;
    esac
  fi
  command gcloud "$@"
}

# Ensure gcloud and jq are installed
check_deps() {
  if ! command -v gcloud >/dev/null 2>&1; then
    echo "google-cloud-sdk not found, installing..."
    "$LIBSCRIPT_ROOT_DIR/libscript.sh" install google-cloud-sdk latest
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found, installing..."
    "$LIBSCRIPT_ROOT_DIR/libscript.sh" install jq latest
  fi
}

gcp_network() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; if [ -z "$NAME" ]; then echo "Usage: network create <name>"; exit 1; fi
      if ! gcloud compute networks describe "$NAME" >/dev/null 2>&1; then
        gcloud compute networks create "$NAME" --subnet-mode=auto
        echo "Created Network '$NAME'"
      fi
      ;;
    list)
      gcloud compute networks list
      ;;
    delete)
      NAME=$1; gcloud compute networks delete "$NAME" --quiet
      ;;
    *) echo "Unknown network action: $ACTION"; exit 1 ;;
  esac
}

gcp_firewall() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; NETWORK=$2; PORT=${3:-22}
      if [ -z "$NAME" ] || [ -z "$NETWORK" ]; then echo "Usage: firewall create <name> <network> [port]"; exit 1; fi
      if ! gcloud compute firewall-rules describe "$NAME" >/dev/null 2>&1; then
        gcloud compute firewall-rules create "$NAME" --network="$NETWORK" --allow="tcp:$PORT" --description="LibScript firewall"
        echo "Created Firewall '$NAME' (Port $PORT open)"
      fi
      ;;
    list)
      gcloud compute firewall-rules list
      ;;
    *) echo "Unknown firewall action: $ACTION"; exit 1 ;;
  esac
}

gcp_node() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; FAMILY=$2; PROJECT=$3
      if [ -z "$NAME" ] || [ -z "$FAMILY" ] || [ -z "$PROJECT" ]; then 
        echo "Usage: node create <name> <family> <project> [--bootstrap <script>] [--tags T] [--no-default-tags]"
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
      
      LABELS=$(parse_labels $filtered_args)

      if ! gcloud compute instances describe "$NAME" >/dev/null 2>&1; then
        EXTRA_ARGS=""
        if [ -n "$BOOTSTRAP" ]; then
          USER_DATA_FILE=$(mktemp)
          printf '#!/bin/bash\n%s\n' "$BOOTSTRAP" > "$USER_DATA_FILE"
          EXTRA_ARGS="--metadata-from-file startup-script=$USER_DATA_FILE"
        fi
        
        if [ -n "$LABELS" ]; then
          gcloud compute instances create "$NAME" --image-family="$FAMILY" --image-project="$PROJECT" --labels="$LABELS" $EXTRA_ARGS
        else
          gcloud compute instances create "$NAME" --image-family="$FAMILY" --image-project="$PROJECT" $EXTRA_ARGS
        fi
        echo "Created Instance '$NAME'"
        if [ -n "${USER_DATA_FILE:-}" ]; then rm -f "$USER_DATA_FILE"; fi
      fi
      ;;
    exec)
      NAME=$1; CMD=$2
      if [ -z "$NAME" ] || [ -z "$CMD" ]; then echo "Usage: node exec <name> <command>"; exit 1; fi
      echo "Executing on $NAME via gcloud ssh..."
      gcloud compute ssh "$NAME" --command "$CMD"
      ;;
    scp)
      NAME=$1; SRC=$2; DEST=$3
      if [ -z "$NAME" ] || [ -z "$SRC" ] || [ -z "$DEST" ]; then echo "Usage: node scp <name> <src> <dest>"; exit 1; fi
      echo "Copying to $NAME..."
      gcloud compute scp --recurse "$SRC" "$NAME:$DEST"
      ;;
    scp-from)
      NAME=$1; SRC=$2; DEST=$3
      if [ -z "$NAME" ] || [ -z "$SRC" ] || [ -z "$DEST" ]; then echo "Usage: node scp-from <name> <remote_src> <local_dest>"; exit 1; fi
      echo "Copying from $NAME..."
      gcloud compute scp --recurse "$NAME:$SRC" "$DEST"
      ;;
    winrm-exec)
      NAME=$1; CMD=$2
      if [ -z "$NAME" ] || [ -z "$CMD" ]; then echo "Usage: node winrm-exec <name> <command>"; exit 1; fi
      IP=$(gcloud compute instances describe "$NAME" --format="value(networkInterfaces[0].accessConfigs[0].natIP)")
      if [ -z "$IP" ]; then echo "Node '$NAME' public IP not found."; exit 1; fi
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
      NAME=$1; SRC=$2; DEST=$3
      if [ -z "$NAME" ] || [ -z "$SRC" ] || [ -z "$DEST" ]; then echo "Usage: node winrm-cp <name> <src> <dest>"; exit 1; fi
      IP=$(gcloud compute instances describe "$NAME" --format="value(networkInterfaces[0].accessConfigs[0].natIP)")
      if [ -z "$IP" ]; then echo "Node '$NAME' public IP not found."; exit 1; fi
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
      NAME=$1; SRC=$2; DEST=$3
      if [ -z "$NAME" ] || [ -z "$SRC" ] || [ -z "$DEST" ]; then echo "Usage: node winrm-cp-from <name> <remote_src> <local_dest>"; exit 1; fi
      IP=$(gcloud compute instances describe "$NAME" --format="value(networkInterfaces[0].accessConfigs[0].natIP)")
      if [ -z "$IP" ]; then echo "Node '$NAME' public IP not found."; exit 1; fi
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
      # Getting the boot disk
      DISK=$(gcloud compute instances describe "$NAME" --format="value(disks[0].source)" | awk -F/ '{print $NF}')
      ZONE=$(gcloud compute instances describe "$NAME" --format="value(zone)" | awk -F/ '{print $NF}')
      if [ -z "$DISK" ]; then echo "Node '$NAME' boot disk not found."; exit 1; fi
      echo "Creating snapshot $SNAP_NAME from disk $DISK..."
      gcloud compute snapshots create "$SNAP_NAME" --source-disk "$DISK" --source-disk-zone "$ZONE" >/dev/null
      echo "Created Snapshot $SNAP_NAME"
      printf '%s\n' "$SNAP_NAME"
      ;;
    restore)
      NAME=$1; SNAP_NAME=$2; PROJECT=$3; ZONE=${4:-us-central1-a}
      if [ -z "$NAME" ] || [ -z "$SNAP_NAME" ] || [ -z "$PROJECT" ]; then echo "Usage: node restore <name> <snap_name> <project> [zone]"; exit 1; fi
      # Restore involves deleting the old instance and creating a new one from a disk created from the snapshot.
      echo "Restoring $NAME from snapshot $SNAP_NAME..."
      gcloud compute instances delete "$NAME" --zone "$ZONE" --quiet >/dev/null 2>&1 || true
      gcloud compute disks create "${NAME}-disk" --source-snapshot "$SNAP_NAME" --zone "$ZONE" >/dev/null
      gcloud compute instances create "$NAME" --disk name="${NAME}-disk",boot=yes,auto-delete=yes --zone "$ZONE" >/dev/null
      echo "Restored instance $NAME"
      ;;
    list)
      gcloud compute instances list
      ;;
    *) echo "Unknown node action: $ACTION"; exit 1 ;;
  esac
}

gcp_node_group() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; COUNT=$2; FAMILY=$3; PROJECT=$4
      if [ -z "$NAME" ] || [ -z "$COUNT" ]; then echo "Usage: node-group create <name> <count> <family> <project> [args...]"; exit 1; fi
      shift 4
      echo "Provisioning GCP node-group '$NAME' ($COUNT independent nodes)..."
      i=1
      while [ "$i" -le "$COUNT" ]; do
        gcp_node create "${NAME}-${i}" "$FAMILY" "$PROJECT" "$@"
        i=$((i + 1))
      done
      ;;
    *) echo "Unknown node-group action: $ACTION"; exit 1 ;;
  esac
}

gcp_cron() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; SCHEDULE=$2; CMD=$3
      if [ -z "$NAME" ] || [ -z "$SCHEDULE" ]; then echo "Usage: cron create <target_node> <schedule> <command>"; exit 1; fi
      echo "Setting up cronjob on GCP instance $NAME: $SCHEDULE $CMD"
      gcp_node exec "$NAME" "(crontab -l 2>/dev/null; printf '%s %s\n' \"$SCHEDULE\" \"$CMD\") | crontab -"
      ;;
    *) echo "Unknown cron action: $ACTION"; exit 1 ;;
  esac
}

gcp_jumpbox() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; FAMILY=$2; PROJECT=$3; NET=${4:-libscript-net}
      echo "Setting up GCP Jump-box '$NAME'..."
      gcp_network create "$NET" "$@"
      gcp_firewall create "${NAME}-ssh" "$NET" 22 "$@"
      gcp_node create "$NAME" "$FAMILY" "$PROJECT" "$@"
      echo "GCP Jump-box '$NAME' ready."
      ;;
    *) echo "Unknown jumpbox action: $ACTION"; exit 1 ;;
  esac
}

gcp_storage() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      BUCKET=$1; if [ -z "$BUCKET" ]; then echo "Usage: storage create <bucket> [--tags T] [--no-default-tags]"; exit 1; fi
      
      LABELS=$(parse_labels "$@")
      
      if ! gcloud storage buckets describe "gs://$BUCKET" >/dev/null 2>&1; then
        gcloud storage buckets create "gs://$BUCKET"
        if [ -n "$LABELS" ]; then
          gcloud storage buckets update "gs://$BUCKET" --update-labels="$LABELS"
        fi
        echo "Created Bucket '$BUCKET'"
      fi
      ;;
    delete)
      BUCKET=$1; gcloud storage buckets delete "gs://$BUCKET" --quiet
      ;;
    *) echo "Unknown storage action: $ACTION"; exit 1 ;;
  esac
}

gcp_list_managed() {
  FILTER_LABEL=${1:-"$TAG_KEY=$TAG_VAL"}
  echo "--- GCP Resources (Filter: $FILTER_LABEL) ---"
  echo "Instances:"
  gcloud compute instances list --filter="labels.$FILTER_LABEL"
  echo "Buckets:"
  GCP_FILTER=$(echo "$FILTER_LABEL" | sed 's/=/: /')
  gcloud storage buckets list --format="table(name, labels)" | grep "$GCP_FILTER" || true
}

gcp_cleanup() {
  PURGE_BUCKETS=$1
  FILTER_LABEL=${2:-"$TAG_KEY=$TAG_VAL"}
  
  echo "Starting GCP Cleanup (Filter: $FILTER_LABEL)..."
  
  # Delete instances
  INSTANCES=$(gcloud compute instances list --filter="labels.$FILTER_LABEL" --format="value(name)")
  for INS in $INSTANCES; do
    echo "Deleting instance $INS..."
    gcloud compute instances delete "$INS" --quiet || true
  done
  
  # Delete buckets
  if [ "$PURGE_BUCKETS" = "true" ]; then
    GCP_FILTER=$(echo "$FILTER_LABEL" | sed 's/=/: /')
    BUCKETS=$(gcloud storage buckets list --format="value(name)" | while read -r B; do
      if gcloud storage buckets describe "gs://$B" --format="value(labels)" 2>/dev/null | grep -q "$GCP_FILTER"; then
        echo "$B"
      fi
    done)
    for B in $BUCKETS; do
      echo "Deleting bucket $B..."
      gcloud storage buckets delete "gs://$B" --quiet || true
    done
  else
    echo "Skipping GCP buckets (safety enabled)"
  fi
}

# CLI Router
CMD=$1; shift
case "$CMD" in
  network) gcp_network "$@" ;;
  firewall) gcp_firewall "$@" ;;
  node) gcp_node "$@" ;;
  node-group) gcp_node_group "$@" ;;
  cron) gcp_cron "$@" ;;
  jumpbox) gcp_jumpbox "$@" ;;
  storage) gcp_storage "$@" ;;
  list-managed) gcp_list_managed "$@" ;;
  cleanup) gcp_cleanup "$@" ;;
  install) check_deps ;;
  *)
    echo "LibScript GCP Cloud Wrapper"
    echo "Usage: $0 {network|firewall|node|node-group|cron|jumpbox|storage|list-managed|cleanup|install} [args...]"
    exit 1
    ;;
esac
