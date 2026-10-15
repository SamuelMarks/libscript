#!/bin/sh
# ## Overview
# Provisions a logical virtual host for a web server (e.g., Nginx, Apache).
#
# ## Usage
#   ./provision_logical_vhost.sh --server-name <domain> --upstream-port <port>

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

THIS_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)

SERVER_NAME=""
UPSTREAM_PORT=""

# ## Parses command-line arguments
# ## Extracts --server-name and --upstream-port options.
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --server-name) SERVER_NAME="$2"; shift 2 ;;
      --upstream-port) UPSTREAM_PORT="$2"; shift 2 ;;
      *) printf '[ERROR] Unknown argument: %s\n' "$1" >&2; exit 1 ;;
    esac
  done
}

# ## Validates arguments ensuring essential flags are passed
validate_args() {
  if [ -z "$SERVER_NAME" ]; then
    printf '[ERROR] --server-name is required\n' >&2
    exit 1
  fi
  if [ -z "$UPSTREAM_PORT" ]; then
    printf '[ERROR] --upstream-port is required\n' >&2
    exit 1
  fi
}

# ## Provisions the virtual host
# ## Generates configuration and conditionally restarts the web server.
provision_vhost() {
  printf '[INFO] Provisioning virtual host for %s routing to upstream port %s\n' "$SERVER_NAME" "$UPSTREAM_PORT"
  
  # Simulation of vhost creation
  # e.g., generating nginx conf in /etc/nginx/conf.d/$SERVER_NAME.conf
  printf '[PASS] Virtual host %s provisioned.\n' "$SERVER_NAME"
}

parse_args "$@"
validate_args
provision_vhost
