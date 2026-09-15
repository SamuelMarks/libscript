#!/bin/sh
# ## Overview
# Environment variable initialization script for the google-cloud-sdk component.
# It sets up necessary paths and environment variables required for the component
# to function correctly within the libscript context.
#
# ## Usage
# Source this script to load the environment variables. Do not execute it directly.


set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
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

GOOGLE_CLOUD_SDK_VERSION="${GOOGLE_CLOUD_SDK_VERSION:-latest}"
_GCLOUD_BIN="${LIBSCRIPT_HOME:-$HOME/.libscript}/google-cloud-sdk/${GOOGLE_CLOUD_SDK_VERSION}/bin"
case ":${PATH}:" in
  *":${_GCLOUD_BIN}:"*) ;;
  *) PATH="${_GCLOUD_BIN}:${PATH}"; export PATH ;;
esac

if command -v python3.12 >/dev/null 2>&1; then
  CLOUDSDK_PYTHON="$(command -v python3.12)"
  export CLOUDSDK_PYTHON
elif command -v python3.11 >/dev/null 2>&1; then
  CLOUDSDK_PYTHON="$(command -v python3.11)"
  export CLOUDSDK_PYTHON
fi
