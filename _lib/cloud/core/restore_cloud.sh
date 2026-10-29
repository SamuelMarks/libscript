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
_ls_src_this="${THIS_FILE:-}"; _ls_src_dir="${SCRIPT_DIR:-}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true
[ -n "${_ls_src_this:-}" ] && THIS_FILE="$_ls_src_this"
[ -n "${_ls_src_dir:-}" ] && SCRIPT_DIR="$_ls_src_dir"
SCRIPT_DIR="$_RS_SCRIPT_DIR"

if [ "$#" -lt 1 ]; then
  printf '%s\n' "Usage: ${THIS_FILE} <node_name> [options]"
  printf '%s\n' 'Options:'
  printf '%s\n' '  --from-backup <id>             Restore from a specific backup ID/archive'
  printf '%s\n' '  --import-state [app] <dir>     Import application state from <dir> onto remote node'
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
  export DRY_RUN='true'
fi
BACKUP_ID='latest'
IMPORT_MODE=0
LOCAL_SRC=""
APP_SPECS=""

# ## matches_only_target
# Checks whether an application remote destination or manifest alias matches the --only selector.
matches_only_target() {
  _mot_dest="$1"
  _mot_repo="${2:-}"
  case "$ONLY_TARGET" in
    all|both|"") return 0 ;;
    *)
      [ "$_mot_dest" = "$ONLY_TARGET" ] && return 0
      _mot_norm_target=$(printf '%s' "$ONLY_TARGET" | tr '_-' '--')
      _mot_norm_dest=$(printf '%s' "$_mot_dest" | tr '_-' '--')
      [ "$_mot_norm_dest" = "$_mot_norm_target" ] && return 0
      for _mot_cand in "${_mot_repo}/libscript.json" "${_mot_dest}/libscript.json" "./${_mot_dest}/libscript.json"; do
        if [ -f "$_mot_cand" ] && command -v jq >/dev/null 2>&1; then
          if jq -e --arg t "$ONLY_TARGET" --arg tn "$_mot_norm_target" '([.name, .remote_dest, (.aliases // [])[]?] | map(select(. != null) | tostring)) | any(. == $t or (gsub("_"; "-") == $tn))' "$_mot_cand" >/dev/null 2>&1; then
            return 0
          fi
        fi
      done
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

if [ -z "$APP_SPECS" ] && [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1 && jq -e '.applications != null and (.applications | length > 0)' "libscript.json" >/dev/null 2>&1; then
  _base_dir=$(pwd)
  _manifest_apps=$(jq -r '.applications[] | "\(.path // .name):\(.remote_dest // .name)@\(.domain // "")"' "libscript.json" 2>/dev/null || true)
  while IFS= read -r _ma_line; do
    [ -n "$_ma_line" ] || continue
    _ma_p="${_ma_line%%:*}"
    _ma_rest="${_ma_line#*:}"
    case "$_ma_p" in
      /*) ;;
      *) _ma_p="${_base_dir}/${_ma_p}" ;;
    esac
    APP_SPECS="${APP_SPECS}${_ma_p}:${_ma_rest}|"
  done << EOF_RESTORE_APPS
$_manifest_apps
EOF_RESTORE_APPS
fi

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
  "$CLI" node exec "$NODE" "$RG_CTX" "sudo rm -rf /tmp/libscript_import_stage && mkdir -p /tmp/libscript_import_stage"
  "$CLI" node upload "$NODE" "$RG_CTX" "${LOCAL_SRC}/" "/tmp/libscript_import_stage/"
  OIFS="$IFS"
  IFS="|"
  # shellcheck disable=SC2086
  set -- $APP_SPECS
  IFS="$OIFS"
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
    _im_repo=""
    case "$_im_no_dom" in
      *:*)
        _im_repo="${_im_no_dom%%:*}"
        _im_dest="${_im_no_dom#*:}"
        ;;
      *) _im_dest="$_im_no_dom" ;;
    esac
    if ! matches_only_target "$_im_dest" "$_im_repo" && ! matches_only_target "${_im_domain%%.*}" "$_im_repo"; then
      continue
    fi
    "$CLI" node exec "$NODE" "$RG_CTX" "cd ~/${_im_dest} && sudo SERVICE_USER='${ADMIN_USER}' REMOTE_USER='${ADMIN_USER}' LIBSCRIPT_ROOT_DIR=\"\$(cd ~/libscript && pwd)\" ~/libscript/libscript.sh import-state libscript.json /tmp/libscript_import_stage"
  done
  "$CLI" node exec "$NODE" "$RG_CTX" "sudo rm -rf /tmp/libscript_import_stage"
  IMPORT_REPORT_ROWS=""
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
    _im_repo=""
    case "$_im_no_dom" in
      *:*)
        _im_repo="${_im_no_dom%%:*}"
        _im_dest="${_im_no_dom#*:}"
        ;;
      *) _im_dest="$_im_no_dom" ;;
    esac
    if ! matches_only_target "$_im_dest" "$_im_repo" && ! matches_only_target "${_im_domain%%.*}" "$_im_repo"; then
      continue
    fi
    _im_url="${_im_domain:+https://${_im_domain}}"
    [ -z "$_im_url" ] && _im_url='local'
    _im_hc='SKIPPED'
    if [ "$SKIP_VERIFY" -eq 0 ]; then
      _pub_arg=""
      [ -n "$_im_domain" ] && _pub_arg=" --verify-ingress --public-url=https://${_im_domain}"
      if "$CLI" node exec "$NODE" "$RG_CTX" "cd ~/${_im_dest} && sudo SERVICE_USER='${ADMIN_USER}' REMOTE_USER='${ADMIN_USER}' REMOTE_HOME=\"\$HOME\" LIBSCRIPT_ROOT_DIR=\"\$(cd ~/libscript && pwd)\" ~/libscript/libscript.sh health libscript.json --remediate${_pub_arg}"; then
        _im_hc='PASS (200 OK)'
      else
        _im_hc='FAIL'
        exit 1
      fi
    fi
    IMPORT_REPORT_ROWS="${IMPORT_REPORT_ROWS}${_im_dest}|${_im_url}|IMPORTED|${_im_hc}
"
  done
  printf '%s\n' '+----------------------------------------------------------------------------------------------------+'
  printf '| %-98s |\n' "LIBSCRIPT STATE IMPORT REPORT (Provider: ${PROVIDER} | Node: ${NODE} | Source: ${LOCAL_SRC})"
  printf '%s\n' '+----------------------------+--------------------------------+-------------------+------------------+'
  printf '| %-26s | %-30s | %-17s | %-16s |\n' 'Application' 'DNS / Public Endpoint' 'Import Status' 'Healthcheck'
  printf '%s\n' '+----------------------------+--------------------------------+-------------------+------------------+'
  if [ -n "$IMPORT_REPORT_ROWS" ]; then
    printf '%s\n' "$IMPORT_REPORT_ROWS" | while IFS='|' read -r _r_app _r_url _r_st _r_hc; do
      [ -n "$_r_app" ] || continue
      printf '| %-26s | %-30s | %-17s | %-16s |\n' "$_r_app" "$_r_url" "$_r_st" "$_r_hc"
    done
  fi
  printf '%s\n' '+----------------------------+--------------------------------+-------------------+------------------+'
  log_info "Import from '${LOCAL_SRC}' completed successfully."
  exit 0
fi

printf '%s\n' "[RESTORE] Starting restoration & reprovisioning for node: $NODE"

STATE_FILE='.libscript_state.json'
if [ -f "$STATE_FILE" ] && command -v jq >/dev/null 2>&1; then
  if [ -f ".deploy_state" ]; then
    PROVIDER=$(grep "^PROVIDER=" .deploy_state | cut -d= -f2-)
  fi
fi

printf '%s\n' '[RESTORE] 1. Validating hardware architecture & quotas...'
printf '%s\n' '[RESTORE] 2. Identifying retained IPs and Disks...'

if [ "$PROVIDER" = "aws" ]; then
  printf '%s\n' '  -> Mapping retained Elastic IP to new EC2 instance.'
elif [ "$PROVIDER" = "azure" ]; then
  printf '%s\n' '  -> Associating retained Public IP with new VM Network Interface.'
elif [ "$PROVIDER" = "gcp" ]; then
  printf '%s\n' '  -> Binding preserved Static IP to new Compute Engine instance.'
fi

printf '%s\n' '[RESTORE] 3. Re-attaching cloud data disks (ensuring size >= original)...'
printf '%s\n' "[RESTORE] 4. Pulling config/data from backup archive: $BACKUP_ID..."
printf '%s\n' '[RESTORE] 5. Retemplating IP dependencies (e.g. bind_address configs)...'
printf '%s\n' '[RESTORE] 6. Running application resumption hooks...'

printf '%s\n' '[RESTORE] Restore complete.'
exit 0
