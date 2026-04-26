#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'
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
  echo "Node Actions: create, list, delete, exec, scp, scp-from, winrm-exec, winrm-cp, winrm-cp-from, snapshot, restore"
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
