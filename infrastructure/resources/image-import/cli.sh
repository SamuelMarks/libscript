#!/bin/sh
# ## Overview
# CLI router for idempotent multicloud VM/unikernel image import across AWS, Azure, and GCP.
#
# ## Usage
# ./infrastructure/resources/image-import/cli.sh <aws|azure|gcp|test> [options...]

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

SUB="${1:-}"
if [ "$SUB" = 'image-import' ]; then
  shift
  SUB="${1:-}"
fi

case "$SUB" in
  --help|-h|'')
    printf '%s\n' 'Usage: cli.sh <aws|azure|gcp|test> [--disk=<path>] [--name=<image_name>] [--dry-run]'
    exit 0
    ;;
  aws) shift; exec "${SCRIPT_DIR}/aws_import.sh" "$@" ;;
  azure) shift; exec "${SCRIPT_DIR}/azure_import.sh" "$@" ;;
  gcp) shift; exec "${SCRIPT_DIR}/gcp_import.sh" "$@" ;;
  test) shift; exec "${SCRIPT_DIR}/test.sh" "$@" ;;
  *)
    printf '[ERROR] Unsupported image-import action: %s\n' "$SUB" >&2
    exit 1
    ;;
esac
