#!/bin/sh
# ## Overview
# Cert component CLI for SSL certificate operations.
#
# ## Usage
# libscript cert [create|delete|list] [--cloud aws|gcp|azure] [--domain name]

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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

CMD="${1:-}"
if [ -n "$CMD" ]; then
  shift
fi

export LIBSCRIPT_CLOUD="${LIBSCRIPT_CLOUD:-}"
export LIBSCRIPT_DOMAIN="${LIBSCRIPT_DOMAIN:-}"

while [ $# -gt 0 ]; do
  case "$1" in
    --cloud)
      LIBSCRIPT_CLOUD="$2"
      shift 2
      ;;
    --cloud=*)
      LIBSCRIPT_CLOUD="${1#*=}"
      shift
      ;;
    --domain)
      LIBSCRIPT_DOMAIN="$2"
      shift 2
      ;;
    --domain=*)
      LIBSCRIPT_DOMAIN="${1#*=}"
      shift
      ;;
    cert)
      shift
      ;;
    *)
      printf "Error: Unknown argument '%s'\n" "$1" >&2
      exit 1
      ;;
    esac
    done

    if [ -z "$CMD" ]; then
    printf "Error: Missing command for cert (issue|revoke|list|renew).\n" >&2
    exit 1
    fi

    case "$CMD" in
    install)
    printf "Cloud components are operational wrappers and do not require installation.\n"
    exit 0
    ;;
    test)
    printf "Running mock test for cert...\n"
    exit 0
    ;;
    issue|revoke|list|renew)
    # Execution
    . "$SCRIPT_DIR/api.sh"
    case "$CMD" in
      create)
        libscript_cert_create "$LIBSCRIPT_CLOUD" "$LIBSCRIPT_DOMAIN"
        ;;
      delete)
        libscript_cert_delete "$LIBSCRIPT_CLOUD" "$LIBSCRIPT_DOMAIN"
        ;;
      list)
        libscript_cert_list "$LIBSCRIPT_CLOUD"
        ;;
    esac
    ;;
  *)
    printf "Error: Unknown cert command '%s'\n" "$CMD" >&2
    exit 1
    ;;
esac