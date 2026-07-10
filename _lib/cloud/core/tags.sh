#!/bin/sh
# ## Overview
# Provides global configuration for tag-based resource management, and utilities 
# for formatting tags according to provider requirements (AWS, GCP, Azure).
# 
# ## Usage
# Source this file to expose tagging variables and functions.

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

# Global Tagging Configuration
: "${LIBSCRIPT_TAG_ENABLE:=true}"
: "${LIBSCRIPT_TAG_KEY:=libscript}"
: "${LIBSCRIPT_TAG_VALUE:=managed}"

export LIBSCRIPT_TAG_ENABLE LIBSCRIPT_TAG_KEY LIBSCRIPT_TAG_VALUE

# Formats tags depending on the cloud provider.
# Example: 
#   libscript_format_tags aws
# Output:
#   --tags Key=libscript,Value=managed
#
#   libscript_format_tags gcp
# Output:
#   --labels=libscript=managed
#
#   libscript_format_tags azure
# Output:
#   --tags libscript=managed
libscript_format_tags() {
  provider="${1:-}"
  
  if [ "${LIBSCRIPT_TAG_ENABLE}" != "true" ]; then
    return 0
  fi

  case "${provider}" in
    aws)
      printf "%s" '--tags Key=%s,Value=%s' "${LIBSCRIPT_TAG_KEY}" "${LIBSCRIPT_TAG_VALUE}"
      ;;
    gcp)
      printf "%s" '--labels=%s=%s' "${LIBSCRIPT_TAG_KEY}" "${LIBSCRIPT_TAG_VALUE}"
      ;;
    azure)
      printf "%s" '--tags %s=%s' "${LIBSCRIPT_TAG_KEY}" "${LIBSCRIPT_TAG_VALUE}"
      ;;
    *)
      printf 'Error: Unknown cloud provider "%s" for tagging.\n' "${provider}" >&2
      return 1
      ;;
  esac
}

# Formats tag filters for querying resources
# Example:
#   libscript_format_tag_filter aws
# Output:
#   --filters Name=tag:libscript,Values=managed
#
#   libscript_format_tag_filter gcp
# Output:
#   --filter=labels.libscript=managed
libscript_format_tag_filter() {
  provider="${1:-}"
  
  if [ "${LIBSCRIPT_TAG_ENABLE}" != "true" ]; then
    return 0
  fi

  case "${provider}" in
    aws)
      printf "%s" '--filters Name=tag:%s,Values=%s' "${LIBSCRIPT_TAG_KEY}" "${LIBSCRIPT_TAG_VALUE}"
      ;;
    gcp)
      printf "%s" '--filter=labels.%s=%s' "${LIBSCRIPT_TAG_KEY}" "${LIBSCRIPT_TAG_VALUE}"
      ;;
    azure)
      # Azure CLI usually uses JMESPath queries to filter by tags
      printf "%s" '--query "[?tags.%s == ''%s'']"' "${LIBSCRIPT_TAG_KEY}" "${LIBSCRIPT_TAG_VALUE}"
      ;;
    *)
      printf 'Error: Unknown cloud provider "%s" for tag filtering.\n' "${provider}" >&2
      return 1
      ;;
  esac
}
