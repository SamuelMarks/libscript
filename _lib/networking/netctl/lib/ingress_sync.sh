#!/bin/sh
# ## Overview
# Synchronizes declarative .ingress proxy timeout and buffering rules from libscript.json into netctl.
# ## Usage
# ./_lib/networking/netctl/lib/ingress_sync.sh [libscript.json] [netctl_args...]
set -feu
_nis_caller_this="${THIS_FILE:-}"
_nis_caller_dir="${SCRIPT_DIR:-}"
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
    [ -n "${_nis_caller_this}" ] && THIS_FILE="${_nis_caller_this}"
    [ -n "${_nis_caller_dir}" ] && SCRIPT_DIR="${_nis_caller_dir}"
    unset SCRIPT_NAME _nis_caller_this _nis_caller_dir || true
    if (return 0 2>/dev/null); then return 0; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
# ## netctl_synchronize_ingress
# Extracts .ingress proxy settings from libscript.json, normalizes units, exports NETCTL_PROXY_*, and invokes netctl apply.
netctl_synchronize_ingress() {
  _lsi_json="${1:-libscript.json}"
  shift || true
  if [ ! -f "$_lsi_json" ]; then
    unset _lsi_json || true
    return 0
  fi
  if command -v jq >/dev/null 2>&1; then
    if ! jq -e '.ingress != null' "$_lsi_json" >/dev/null 2>&1; then
      unset _lsi_json || true
      return 0
    fi
    _lsi_conn=$(jq -r '.ingress.proxy_connect_timeout // empty' "$_lsi_json" 2>/dev/null || true)
    _lsi_send=$(jq -r '.ingress.proxy_send_timeout // empty' "$_lsi_json" 2>/dev/null || true)
    _lsi_read=$(jq -r '.ingress.proxy_read_timeout // empty' "$_lsi_json" 2>/dev/null || true)
    _lsi_buf=$(jq -r '.ingress.proxy_buffering // empty' "$_lsi_json" 2>/dev/null || true)
  else
    _lsi_conn=''
    _lsi_send=''
    _lsi_read=''
    _lsi_buf=''
  fi
  if [ -z "$_lsi_conn" ] || [ "$_lsi_conn" = 'null' ]; then _lsi_conn="${NETCTL_PROXY_CONNECT_TIMEOUT:-60s}"; fi
  case "$_lsi_conn" in *[0-9]) _lsi_conn="${_lsi_conn}s" ;; esac
  if [ -z "$_lsi_send" ] || [ "$_lsi_send" = 'null' ]; then _lsi_send="${NETCTL_PROXY_SEND_TIMEOUT:-300s}"; fi
  case "$_lsi_send" in *[0-9]) _lsi_send="${_lsi_send}s" ;; esac
  if [ -z "$_lsi_read" ] || [ "$_lsi_read" = 'null' ]; then _lsi_read="${NETCTL_PROXY_READ_TIMEOUT:-300s}"; fi
  case "$_lsi_read" in *[0-9]) _lsi_read="${_lsi_read}s" ;; esac
  if [ -z "$_lsi_buf" ] || [ "$_lsi_buf" = 'null' ]; then _lsi_buf="${NETCTL_PROXY_BUFFERING:-off}"; fi
  case "$_lsi_buf" in
    true|1|on) _lsi_buf='on' ;;
    false|0|off) _lsi_buf='off' ;;
  esac
  NETCTL_PROXY_CONNECT_TIMEOUT="$_lsi_conn"
  NETCTL_PROXY_SEND_TIMEOUT="$_lsi_send"
  NETCTL_PROXY_READ_TIMEOUT="$_lsi_read"
  NETCTL_PROXY_BUFFERING="$_lsi_buf"
  export NETCTL_PROXY_CONNECT_TIMEOUT NETCTL_PROXY_SEND_TIMEOUT NETCTL_PROXY_READ_TIMEOUT NETCTL_PROXY_BUFFERING
  if [ "${LIBSCRIPT_DRY_RUN:-0}" = '1' ] && [ $# -eq 0 ]; then
    unset _lsi_json _lsi_conn _lsi_send _lsi_read _lsi_buf || true
    return 0
  fi
  _lsi_netctl="${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/netctl.sh"
  if [ ! -x "$_lsi_netctl" ]; then
    _lsi_netctl="${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh"
  fi
  if [ $# -eq 0 ]; then
    set -- --reload
  fi
  (
    unset SCRIPT_NAME || true
    env STACK='' "$_lsi_netctl" apply "$_lsi_json" \
      --proxy-connect-timeout "$NETCTL_PROXY_CONNECT_TIMEOUT" \
      --proxy-send-timeout "$NETCTL_PROXY_SEND_TIMEOUT" \
      --proxy-read-timeout "$NETCTL_PROXY_READ_TIMEOUT" \
      --proxy-buffering "$NETCTL_PROXY_BUFFERING" \
      "$@"
  )
}

if ! (return 0 2>/dev/null); then
  netctl_synchronize_ingress "$@"
fi

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_nis_caller_dir:-}" ] && SCRIPT_DIR="${_nis_caller_dir}"
[ -n "${_nis_caller_this:-}" ] && THIS_FILE="${_nis_caller_this}"
unset SCRIPT_NAME _nis_caller_this _nis_caller_dir || true
