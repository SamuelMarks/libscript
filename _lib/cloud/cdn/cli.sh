#!/bin/sh
# ## Overview
# CDN component CLI for website distribution operations.
#
# ## Usage
# libscript cdn [create|delete|list|invalidate] [--cloud aws|gcp|azure] [--bucket name] [--domain custom.tld] [--cert-id id]

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
export LIBSCRIPT_BUCKET="${LIBSCRIPT_BUCKET:-}"
export LIBSCRIPT_DOMAIN="${LIBSCRIPT_DOMAIN:-}"
export LIBSCRIPT_CERT_ID="${LIBSCRIPT_CERT_ID:-}"
export LIBSCRIPT_DIST_ID="${LIBSCRIPT_DIST_ID:-}"
export LIBSCRIPT_PATHS="${LIBSCRIPT_PATHS:-}"

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
    --bucket)
      LIBSCRIPT_BUCKET="$2"
      shift 2
      ;;
    --bucket=*)
      LIBSCRIPT_BUCKET="${1#*=}"
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
    --cert-id)
      LIBSCRIPT_CERT_ID="$2"
      shift 2
      ;;
    --cert-id=*)
      LIBSCRIPT_CERT_ID="${1#*=}"
      shift
      ;;
    --dist-id)
      LIBSCRIPT_DIST_ID="$2"
      shift 2
      ;;
    --dist-id=*)
      LIBSCRIPT_DIST_ID="${1#*=}"
      shift
      ;;
    --paths)
      LIBSCRIPT_PATHS="$2"
      shift 2
      ;;
    --paths=*)
      LIBSCRIPT_PATHS="${1#*=}"
      shift
      ;;
    *)
      printf "Error: Unknown argument '%s'\n" "$1" >&2
      exit 1
      ;;
  esac
done

if [ -z "$CMD" ]; then
  printf "Error: Missing command for cdn (create|delete|list|invalidate).\n" >&2
  exit 1
fi

case "$CMD" in
  create|delete|list|invalidate)
    # Execution
    . "$SCRIPT_DIR/api.sh"
    case "$CMD" in
      create)
        libscript_cdn_create "$LIBSCRIPT_CLOUD" "$LIBSCRIPT_BUCKET" "$LIBSCRIPT_DOMAIN" "$LIBSCRIPT_CERT_ID"
        ;;
      delete)
        if [ -z "$LIBSCRIPT_DIST_ID" ]; then
          printf "Error: --dist-id (or LIBSCRIPT_DIST_ID) is required for delete.\n" >&2
          exit 1
        fi
        libscript_cdn_delete "$LIBSCRIPT_CLOUD" "$LIBSCRIPT_DIST_ID"
        ;;
      list)
        libscript_cdn_list "$LIBSCRIPT_CLOUD"
        ;;
      invalidate)
        if [ -z "$LIBSCRIPT_DIST_ID" ]; then
          printf "Error: --dist-id (or LIBSCRIPT_DIST_ID) is required for invalidate.\n" >&2
          exit 1
        fi
        libscript_cdn_invalidate "$LIBSCRIPT_CLOUD" "$LIBSCRIPT_DIST_ID" "${LIBSCRIPT_PATHS:-/*}"
        ;;
    esac
    ;;
  *)
    printf "Error: Unknown cdn command '%s'\n" "$CMD" >&2
    exit 1
    ;;
esac