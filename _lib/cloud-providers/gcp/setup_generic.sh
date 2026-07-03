#!/bin/sh
# ## Overview
# Implements the `gcp` cloud provider CLI, managing GCP networks, compute instances, and resources.
#
# ## Usage
# Provides commands like `network`, `node`, `jumpbox`, `cleanup`, and ensures `google-cloud-sdk` and `jq` are installed.
# Sub-commands manage resource lifecycles wrapping the native `gcloud` command.


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
TAG_KEY="managed-by"
TAG_VAL="libscript"
DEFAULT_LABELS="$TAG_KEY=$TAG_VAL"

# Parses labels from arguments and handles default labeling logic.
# Returns a comma-separated list of Key=V strings
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

# Dry run helper wrapper for gcloud command.
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

# Ensures required dependencies (gcloud, jq) are installed.
check_deps() {
  if ! command -v gcloud >/dev/null 2>&1; then
    printf '%s\n' "google-cloud-sdk not found, installing..."
    "$LIBSCRIPT_ROOT_DIR/libscript.sh" install google-cloud-sdk latest
  fi
  if ! command -v jq >/dev/null 2>&1; then
    printf '%s\n' "jq not found, installing..."
    "$LIBSCRIPT_ROOT_DIR/libscript.sh" install jq latest
  fi
}

# Manages GCP Virtual Networks (VPC).
gcp_network() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; if [ -z "$NAME" ]; then printf '%s\n' "Usage: network create <name>"; exit 1; fi
      if ! gcloud compute networks describe "$NAME" >/dev/null 2>&1; then
        gcloud compute networks create "$NAME" --subnet-mode=auto
        printf '%s\n' "Created Network '$NAME'"
      fi
      ;;
    list)
      gcloud compute networks list
      ;;
    delete)
      NAME=$1; gcloud compute networks delete "$NAME" --quiet
      ;;
    *) printf '%s\n' "Unknown network action: $ACTION"; exit 1 ;;
  esac
}

# Manages GCP Firewall Rules.
gcp_firewall() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; NETWORK=$2; PORT=${3:-22}
      if [ -z "$NAME" ] || [ -z "$NETWORK" ]; then printf '%s\n' "Usage: firewall create <name> <network> [port]"; exit 1; fi
      if ! gcloud compute firewall-rules describe "$NAME" >/dev/null 2>&1; then
        gcloud compute firewall-rules create "$NAME" --network="$NETWORK" --allow="tcp:$PORT" --description="LibScript firewall"
        printf '%s\n' "Created Firewall '$NAME' (Port $PORT open)"
      fi
      ;;
    list)
      gcloud compute firewall-rules list
      ;;
    *) printf '%s\n' "Unknown firewall action: $ACTION"; exit 1 ;;
  esac
}

# Manages individual GCP Compute Instances.
gcp_node() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; FAMILY=$2; PROJECT=$3
      if [ -z "$NAME" ] || [ -z "$FAMILY" ] || [ -z "$PROJECT" ]; then 
        printf '%s\n' "Usage: node create <name> <family> <project> [--bootstrap <script>] [--tags T] [--no-default-tags]"
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
        printf '%s\n' "Created Instance '$NAME'"
        if [ -n "${USER_DATA_FILE:-}" ]; then rm -f "$USER_DATA_FILE"; fi
      fi
      ;;
    exec)
      NAME=$1; CMD=$2
      if [ -z "$NAME" ] || [ -z "$CMD" ]; then printf '%s\n' "Usage: node exec <name> <command>"; exit 1; fi
      printf '%s\n' "Executing on $NAME via gcloud ssh..."
      gcloud compute ssh "$NAME" --command "$CMD"
      ;;
    list)
      gcloud compute instances list
      ;;
    *) printf '%s\n' "Unknown node action: $ACTION"; exit 1 ;;
  esac
}

# Manages groups of independent GCP Compute Instances.
gcp_node_group() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; COUNT=$2; FAMILY=$3; PROJECT=$4
      if [ -z "$NAME" ] || [ -z "$COUNT" ]; then printf '%s\n' "Usage: node-group create <name> <count> <family> <project> [args...]"; exit 1; fi
      shift 4
      printf '%s\n' "Provisioning GCP node-group '$NAME' ($COUNT independent nodes)..."
      i=1
      while [ "$i" -le "$COUNT" ]; do
        gcp_node create "${NAME}-${i}" "$FAMILY" "$PROJECT" "$@"
        i=$((i + 1))
      done
      ;;
    *) printf '%s\n' "Unknown node-group action: $ACTION"; exit 1 ;;
  esac
}

# Manages cron jobs directly on GCP Instances via gcloud ssh.
gcp_cron() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; SCHEDULE=$2; CMD=$3
      if [ -z "$NAME" ] || [ -z "$SCHEDULE" ]; then printf '%s\n' "Usage: cron create <target_node> <schedule> <command>"; exit 1; fi
      printf '%s\n' "Setting up cronjob on GCP instance $NAME: $SCHEDULE $CMD"
      gcp_node exec "$NAME" "(crontab -l 2>/dev/null; printf '%s %s\n' \"$SCHEDULE\" \"$CMD\") | crontab -"
      ;;
    *) printf '%s\n' "Unknown cron action: $ACTION"; exit 1 ;;
  esac
}

# Provisions a complete Jumpbox environment (Network, Firewall, Instance) in GCP.
gcp_jumpbox() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      NAME=$1; FAMILY=$2; PROJECT=$3; NET=${4:-libscript-net}
      printf '%s\n' "Setting up GCP Jump-box '$NAME'..."
      gcp_network create "$NET" "$@"
      gcp_firewall create "${NAME}-ssh" "$NET" 22 "$@"
      gcp_node create "$NAME" "$FAMILY" "$PROJECT" "$@"
      printf '%s\n' "GCP Jump-box '$NAME' ready."
      ;;
    *) printf '%s\n' "Unknown jumpbox action: $ACTION"; exit 1 ;;
  esac
}

# Manages Google Cloud Storage (GCS) Buckets.
gcp_storage() {
  ACTION=$1; shift
  case "$ACTION" in
    create)
      BUCKET=$1; if [ -z "$BUCKET" ]; then printf '%s\n' "Usage: storage create <bucket> [--tags T] [--no-default-tags]"; exit 1; fi
      
      LABELS=$(parse_labels "$@")
      
      if ! gcloud storage buckets describe "gs://$BUCKET" >/dev/null 2>&1; then
        gcloud storage buckets create "gs://$BUCKET"
        if [ -n "$LABELS" ]; then
          gcloud storage buckets update "gs://$BUCKET" --update-labels="$LABELS"
        fi
        printf '%s\n' "Created Bucket '$BUCKET'"
      fi
      ;;
    delete)
      BUCKET=$1; gcloud storage buckets delete "gs://$BUCKET" --quiet
      ;;
    *) printf '%s\n' "Unknown storage action: $ACTION"; exit 1 ;;
  esac
}

# Lists resources managed by LibScript in GCP based on labels.
gcp_list_managed() {
  FILTER_LABEL=${1:-"$TAG_KEY=$TAG_VAL"}
  printf '%s\n' "--- GCP Resources (Filter: $FILTER_LABEL) ---"
  printf '%s\n' "Instances:"
  gcloud compute instances list --filter="labels.$FILTER_LABEL"
  printf '%s\n' "Buckets:"
  GCP_FILTER=$(printf '%s\n' "$FILTER_LABEL" | sed 's/=/: /')
  gcloud storage buckets list --format="table(name, labels)" | grep "$GCP_FILTER" || true
}

# Cleans up GCP resources provisioned by LibScript based on labels.
gcp_cleanup() {
  PURGE_BUCKETS=$1
  FILTER_LABEL=${2:-"$TAG_KEY=$TAG_VAL"}
  
  printf '%s\n' "Starting GCP Cleanup (Filter: $FILTER_LABEL)..."
  
  # Delete instances
  INSTANCES=$(gcloud compute instances list --filter="labels.$FILTER_LABEL" --format="value(name)")
  for INS in $INSTANCES; do
    printf '%s\n' "Deleting instance $INS..."
    gcloud compute instances delete "$INS" --quiet || true
  done
  
  # Delete buckets
  if [ "$PURGE_BUCKETS" = "true" ]; then
    GCP_FILTER=$(printf '%s\n' "$FILTER_LABEL" | sed 's/=/: /')
    BUCKETS=$(gcloud storage buckets list --format="value(name)" | while read -r B; do
      if gcloud storage buckets describe "gs://$B" --format="value(labels)" 2>/dev/null | grep -q "$GCP_FILTER"; then
        printf '%s\n' "$B"
      fi
    done)
    for B in $BUCKETS; do
      printf '%s\n' "Deleting bucket $B..."
      gcloud storage buckets delete "gs://$B" --quiet || true
    done
  else
    printf '%s\n' "Skipping GCP buckets (safety enabled)"
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
    printf '%s\n' "LibScript GCP Cloud Wrapper"
    printf '%s\n' "Usage: $0 {network|firewall|node|node-group|cron|jumpbox|storage|list-managed|cleanup|install} [args...]"
    exit 1
    ;;
esac
