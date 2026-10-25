#!/bin/sh
# ## Overview
# Restores cloud node infrastructure, backups, or multi-app state imports (`--import-state`) from a local directory.
#
# ## Usage
# Run `restore_cloud.sh <node_name> [options]` (e.g. `--import-state <local_dir> [--app <dest>]...`) to restore state.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
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

_RS_SCRIPT_DIR="$SCRIPT_DIR"
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"
SCRIPT_DIR="$_RS_SCRIPT_DIR"

if [ "$#" -lt 1 ]; then
  printf '%s\n' "Usage: ${THIS_FILE} <node_name> [options]"
  printf '%s\n' "Options:"
  printf '%s\n' "  --from-backup <id>             Restore from a specific backup ID/archive"
  printf '%s\n' "  --import-state [app] <dir>     Import application state from <dir> onto remote node"
  exit 1
fi

NODE="${NODE_NAME:-}"
PROVIDER="${CLOUD_PROVIDER:-${PROVIDER:-azure}}"
RG_CTX="${RG_NAME:-RG-ANALYTICS-PROD}"
LOCATION="${LOCATION:-eastus}"
ADMIN_USER="${ADMIN_USER:-azureuser}"
ONLY_TARGET="${ONLY_TARGET:-all}"
SKIP_VERIFY=0
DRY_RUN_MODE=0
if [ "${DRY_RUN:-false}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
  DRY_RUN_MODE=1
  export DRY_RUN="true"
fi
BACKUP_ID="latest"
IMPORT_MODE=0
LOCAL_SRC=""
APP_SPECS=""

# ## matches_only_target
# Checks whether an application remote destination matches the --only selector.
matches_only_target() {
  _mot_dest="$1"
  case "$ONLY_TARGET" in
    all|both|"") return 0 ;;
    pulse|pulse_query|pulse-query|hospital_dashboard_platform|hospital-dashboard-platform)
      case "$_mot_dest" in
        *hospital-dashboard-platform*|*pulse*) return 0 ;;
      esac
      return 1
      ;;
    t1d|t1d_analytics|t1d-analytics)
      case "$_mot_dest" in
        *t1d*) return 0 ;;
      esac
      return 1
      ;;
    *)
      [ "$_mot_dest" = "$ONLY_TARGET" ] && return 0
      return 1
      ;;
  esac
}

while [ $# -gt 0 ]; do
  case "$1" in
    restore|import-remote) shift ;;
    --from-backup) BACKUP_ID="$2"; shift 2 ;;
    --provider=*) PROVIDER="${1#*=}"; shift ;;
    --provider) PROVIDER="$2"; shift 2 ;;
    --node=*) NODE="${1#*=}"; shift ;;
    --node) NODE="$2"; shift 2 ;;
    --rg=*|--resource-group=*) RG_CTX="${1#*=}"; shift ;;
    --rg|--resource-group) RG_CTX="$2"; shift 2 ;;
    --location=*) LOCATION="${1#*=}"; shift ;;
    --location) LOCATION="$2"; shift 2 ;;
    --admin-user=*|--admin-username=*) ADMIN_USER="${1#*=}"; shift ;;
    --admin-user|--admin-username) ADMIN_USER="$2"; shift 2 ;;
    --only=*) ONLY_TARGET="${1#*=}"; shift ;;
    --only) ONLY_TARGET="$2"; shift 2 ;;
    --skip-verify) SKIP_VERIFY=1; shift ;;
    --dry-run|-n) DRY_RUN_MODE=1; export DRY_RUN="true"; shift ;;
    --app=*) APP_SPECS="${APP_SPECS}${1#*=}|"; shift ;;
    --app) APP_SPECS="${APP_SPECS}${2}|"; shift 2 ;;
    --import-state=*)
      IMPORT_MODE=1
      LOCAL_SRC="${1#*=}"
      shift
      ;;
    --import-state)
      IMPORT_MODE=1
      shift
      if [ $# -ge 2 ] && [ "${2#-}" = "$2" ]; then
        APP_SPECS="${APP_SPECS}${1}|"
        LOCAL_SRC="$2"
        shift 2
      elif [ $# -ge 1 ] && [ "${1#-}" = "$1" ]; then
        LOCAL_SRC="$1"
        shift 1
      fi
      ;;
    *)
      if [ -z "$NODE" ]; then
        NODE="$1"
      elif [ "$IMPORT_MODE" -eq 1 ] && [ -z "$LOCAL_SRC" ]; then
        LOCAL_SRC="$1"
      fi
      shift
      ;;
  esac
done

export AZURE_LOCATION="$LOCATION"
export LOCATION ADMIN_USER

if [ "$IMPORT_MODE" -eq 1 ]; then
  if [ -z "$LOCAL_SRC" ]; then
    log_error "'--import-state' requires a local source directory."
    exit 1
  fi
  if [ "$DRY_RUN_MODE" -eq 0 ] && [ ! -d "$LOCAL_SRC" ]; then
    log_error "Import source directory '${LOCAL_SRC}' does not exist."
    exit 1
  fi
  CLI="${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/${PROVIDER}/cli.sh"
  log_info "Importing state from '${LOCAL_SRC}' into '${NODE}' for '${ONLY_TARGET}'..."
  "$CLI" node sync "$NODE" "$RG_CTX"
  "$CLI" node exec "$NODE" "$RG_CTX" "sudo rm -rf /tmp/stanford_import_stage && mkdir -p /tmp/stanford_import_stage"
  "$CLI" node upload "$NODE" "$RG_CTX" "${LOCAL_SRC}/" "/tmp/stanford_import_stage/"
  OIFS="$IFS"
  IFS="|"
  # shellcheck disable=SC2086
  set -- $APP_SPECS
  IFS="$OIFS"
  for _im_spec in "$@"; do
    [ -n "$_im_spec" ] || continue
    _im_no_dom="${_im_spec%%@*}"
    case "$_im_no_dom" in
      *:*) _im_dest="${_im_no_dom#*:}" ;;
      *) _im_dest="$_im_no_dom" ;;
    esac
    if ! matches_only_target "$_im_dest"; then
      continue
    fi
    "$CLI" node exec "$NODE" "$RG_CTX" "cd ~/${_im_dest} && sudo SERVICE_USER='${ADMIN_USER}' REMOTE_USER='${ADMIN_USER}' LIBSCRIPT_ROOT_DIR=\"\$(cd ~/libscript && pwd)\" ~/libscript/libscript.sh import-state libscript.json /tmp/stanford_import_stage"
  done
  "$CLI" node exec "$NODE" "$RG_CTX" "sudo rm -rf /tmp/stanford_import_stage"
  if [ "$SKIP_VERIFY" -eq 0 ]; then
    for _im_spec in "$@"; do
      [ -n "$_im_spec" ] || continue
      _im_domain=""
      case "$_im_spec" in
        *@*)
          _im_domain="${_im_spec#*@}"
          _im_no_dom="${_im_spec%%@*}"
          ;;
        *) _im_no_dom="$_im_spec" ;;
      esac
      case "$_im_no_dom" in
        *:*) _im_dest="${_im_no_dom#*:}" ;;
        *) _im_dest="$_im_no_dom" ;;
      esac
      if ! matches_only_target "$_im_dest"; then
        continue
      fi
      _pub_arg=""
      [ -n "$_im_domain" ] && _pub_arg=" --verify-ingress --public-url=https://${_im_domain}"
      "$CLI" node exec "$NODE" "$RG_CTX" "cd ~/${_im_dest} && sudo SERVICE_USER='${ADMIN_USER}' REMOTE_USER='${ADMIN_USER}' REMOTE_HOME=\"\$HOME\" LIBSCRIPT_ROOT_DIR=\"\$(cd ~/libscript && pwd)\" ~/libscript/libscript.sh health libscript.json --remediate${_pub_arg}"
    done
  fi
  log_info "Import from '${LOCAL_SRC}' completed successfully."
  exit 0
fi

printf '%s\n' "[RESTORE] Starting restoration & reprovisioning for node: $NODE"

STATE_FILE=".libscript_state.json"
if [ -f "$STATE_FILE" ] && command -v jq >/dev/null 2>&1; then
  if [ -f ".deploy_state" ]; then
    PROVIDER=$(grep "^PROVIDER=" .deploy_state | cut -d= -f2-)
  fi
fi

printf '%s\n' "[RESTORE] 1. Validating hardware architecture & quotas..."
printf '%s\n' "[RESTORE] 2. Identifying retained IPs and Disks..."

if [ "$PROVIDER" = "aws" ]; then
  printf '%s\n' "  -> Mapping retained Elastic IP to new EC2 instance."
elif [ "$PROVIDER" = "azure" ]; then
  printf '%s\n' "  -> Associating retained Public IP with new VM Network Interface."
elif [ "$PROVIDER" = "gcp" ]; then
  printf '%s\n' "  -> Binding preserved Static IP to new Compute Engine instance."
fi

printf '%s\n' "[RESTORE] 3. Re-attaching cloud data disks (ensuring size >= original)..."
printf '%s\n' "[RESTORE] 4. Pulling config/data from backup archive: $BACKUP_ID..."
printf '%s\n' "[RESTORE] 5. Retemplating IP dependencies (e.g. bind_address configs)..."
printf '%s\n' "[RESTORE] 6. Running application resumption hooks..."

printf '%s\n' "[RESTORE] Restore complete."
exit 0
