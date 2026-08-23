#!/bin/sh
# ## Overview
# Pre-flight checker to verify native cloud CLI (aws, gcloud, az) installations and authentication status.
#
# ## Usage
# Source and execute `libscript_check_preflight "aws"`

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

# ## libscript_check_preflight
# Executes libscript_check_preflight functionality.
libscript_check_preflight() {
  provider="${1:-}"
  
  if [ -z "$provider" ]; then
    printf "Error: Provider not specified for pre-flight check.\n" >&2
    return 1
  fi
  
  case "$provider" in
    aws)
      if ! command -v aws >/dev/null 2>&1; then
        printf "Error: 'aws' CLI is not installed or not in PATH.\n" >&2
        return 1
      fi
      if ! aws sts get-caller-identity >/dev/null 2>&1; then
        printf "Error: AWS CLI is not authenticated. Please run 'aws configure'.\n" >&2
        return 1
      fi
      ;;
    gcp)
      if ! command -v gcloud >/dev/null 2>&1; then
        printf "Error: 'gcloud' CLI is not installed or not in PATH.\n" >&2
        return 1
      fi
      if ! gcloud auth print-access-token >/dev/null 2>&1; then
        printf "Error: GCP CLI is not authenticated. Please run 'gcloud auth login'.\n" >&2
        return 1
      fi
      ;;
    azure)
      if ! command -v az >/dev/null 2>&1; then
        printf "Error: 'az' CLI is not installed or not in PATH.\n" >&2
        return 1
      fi
      if ! az account show >/dev/null 2>&1; then
        printf "Error: Azure CLI is not authenticated. Please run 'az login'.\n" >&2
        return 1
      fi
      ;;
    *)
      printf "Error: Unknown provider '%s' for pre-flight check.\n" "$provider" >&2
      return 1
      ;;
  esac
  
  return 0
}