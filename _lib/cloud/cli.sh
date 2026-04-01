#!/bin/sh
# shellcheck disable=SC2154,SC2086,SC2155,SC2046,SC2039,SC2006,SC2112,SC2002

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

show_help() {
  echo "LibScript Multicloud Wrapper"
  echo "Usage: $0 cloud <provider> <resource> <action> [args...]"
  echo "       $0 cloud list-managed [tag_filter]"
  echo "       $0 cloud cleanup [--force-buckets] [tag_filter]"
  echo ""
  echo "Providers: aws, azure, gcp"
  echo "Resources: network, firewall, node, node-group, jumpbox, storage, cron"
  echo "Actions: create, list, delete, read, exec"
  echo ""
  echo "Tagging Options (for create actions):"
  echo "  --tags <T>          Add custom tags (AWS: Key=K,Value=V; Azure: K=V; GCP: K=V)"
  echo "  --no-default-tags   Disable the default 'ManagedBy=LibScript' tag"
  echo ""
  echo "Special Commands:"
  echo "  list-managed     View all managed resources. Optional filter e.g. 'Project=Postgres15'"
  echo "  cleanup          Delete all managed resources. Optional filter e.g. 'Project=Postgres15'"
}

if [ "$1" = "cloud" ]; then shift; fi

CMD=$1
if [ -z "$CMD" ] || [ "$CMD" = "--help" ] || [ "$CMD" = "-h" ]; then
  show_help
  exit 0
fi

case "$CMD" in
  list-managed)
    shift
    for p in aws azure gcp; do
      "$LIBSCRIPT_ROOT_DIR/libscript.sh" "$p" list-managed "$@" || true
    done
    ;;
  cleanup)
    shift
    PURGE_BUCKETS="false"
    FILTER_ARGS=""
    for arg in "$@"; do
      if [ "$arg" = "--force-buckets" ]; then
        PURGE_BUCKETS="true"
      else
        FILTER_ARGS="$FILTER_ARGS $arg"
      fi
    done
    
    if [ "$PURGE_BUCKETS" = "false" ]; then
      echo "Note: Storage buckets will NOT be deleted. Use --force-buckets to override."
    else
      echo "WARNING: ALL managed resources INCLUDING BUCKETS will be deleted!"
    fi
    
    for p in aws azure gcp; do
      echo "Cleaning up $p..."
      "$LIBSCRIPT_ROOT_DIR/libscript.sh" "$p" cleanup "$PURGE_BUCKETS" $FILTER_ARGS || true
    done
    ;;
  aws|azure|gcp)
    PROVIDER=$1; shift
    exec "$LIBSCRIPT_ROOT_DIR/libscript.sh" "$PROVIDER" "$@"
    ;;
  *)
    show_help
    exit 1
    ;;
esac
