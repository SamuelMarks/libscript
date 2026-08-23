#!/bin/sh
# ## Overview
# Provides global configuration for tag-based resource management, and utilities 
# for formatting tags according to provider requirements (AWS, GCP, Azure).
# 
# ## Usage
# Source this file to expose tagging variables and functions.

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054,SC3045
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

# Global Tagging Configuration
: "${LIBSCRIPT_TAG_ENABLE:=true}"
: "${LIBSCRIPT_TAG_KEY:=libscript}"
: "${LIBSCRIPT_TAG_VALUE:=managed}"

# Verifies if a cloud resource is managed by libscript (i.e. has the correct tag).
# If the resource is not managed, it exits with an error unless 
# LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION=1 is set, in which case it warns.
#
# Arguments:
#   $1 - Provider (aws, gcp, azure)
#   $2 - Resource Type (node, network, firewall, storage, dns, volume, cdn, cert, gpu-vm, tpu-vm, filestore)
#   $3 - Resource Name or ID
#   $4 - (Optional) Resource Group (for Azure) or Zone/Region (for GCP depending on resource)
#
# Returns:
#   0 if managed (or overridden), 1 if not managed.
libscript_verify_managed() {
  provider="${1:-}"
  type="${2:-}"
  name="${3:-}"
  rg="${4:-}"
  actual_val=""

  if [ "${LIBSCRIPT_TAG_ENABLE:-true}" != "true" ]; then
    return 0
  fi

  case "$provider" in
    aws)
      case "$type" in
        node) actual_val=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$name" --query "Reservations[0].Instances[0].Tags[?Key=='$LIBSCRIPT_TAG_KEY'].Value" --output text 2>/dev/null || true) ;;
        network) actual_val=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$name" --query "Vpcs[0].Tags[?Key=='$LIBSCRIPT_TAG_KEY'].Value" --output text 2>/dev/null || true) ;;
        firewall) actual_val=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$name" --query "SecurityGroups[0].Tags[?Key=='$LIBSCRIPT_TAG_KEY'].Value" --output text 2>/dev/null || true) ;;
        storage) actual_val=$(aws s3api get-bucket-tagging --bucket "$name" --query "TagSet[?Key=='$LIBSCRIPT_TAG_KEY'].Value" --output text 2>/dev/null || true) ;;
        dns) actual_val=$(aws route53 list-tags-for-resource --resource-type hostedzone --resource-id "$name" --query "ResourceTagSet.Tags[?Key=='$LIBSCRIPT_TAG_KEY'].Value" --output text 2>/dev/null || true) ;;
        volume) actual_val=$(aws ec2 describe-volumes --volume-ids "$name" --query "Volumes[0].Tags[?Key=='$LIBSCRIPT_TAG_KEY'].Value" --output text 2>/dev/null || true) ;;
        cdn) actual_val=$(aws cloudfront list-tags-for-resource --resource "$name" --query "Tags.Items[?Key=='$LIBSCRIPT_TAG_KEY'].Value" --output text 2>/dev/null || true) ;;
        cert) actual_val=$(aws acm list-tags-for-certificate --certificate-arn "$name" --query "Tags[?Key=='$LIBSCRIPT_TAG_KEY'].Value" --output text 2>/dev/null || true) ;;
        *) return 0 ;;
      esac
      ;;
    gcp)
      case "$type" in
        node) actual_val=$(gcloud compute instances describe "$name" --zone="${rg:-}" --format="value(labels.$LIBSCRIPT_TAG_KEY)" 2>/dev/null || true) ;;
        network) actual_val=$(gcloud compute networks describe "$name" --format="value(labels.$LIBSCRIPT_TAG_KEY)" 2>/dev/null || true) ;;
        firewall) actual_val=$(gcloud compute firewall-rules describe "$name" --format="value(labels.$LIBSCRIPT_TAG_KEY)" 2>/dev/null || true) ;;
        storage) actual_val=$(gcloud storage buckets describe "gs://$name" --format="value(labels.$LIBSCRIPT_TAG_KEY)" 2>/dev/null || true) ;;
        dns) actual_val=$(gcloud dns managed-zones describe "$name" --format="value(labels.$LIBSCRIPT_TAG_KEY)" 2>/dev/null || true) ;;
        volume) actual_val=$(gcloud compute disks describe "$name" --zone="${rg:-}" --format="value(labels.$LIBSCRIPT_TAG_KEY)" 2>/dev/null || true) ;;
        cdn) actual_val=$(gcloud compute backend-buckets describe "${name}-backend" --format="value(labels.$LIBSCRIPT_TAG_KEY)" 2>/dev/null || true) ;;
        cert) actual_val=$(gcloud compute ssl-certificates describe "$name" --global --format="value(labels.$LIBSCRIPT_TAG_KEY)" 2>/dev/null || true) ;;
        gpu-vm) actual_val=$(gcloud compute instances describe "$name" --zone="${rg:-}" --format="value(labels.$LIBSCRIPT_TAG_KEY)" 2>/dev/null || true) ;;
        tpu-vm) actual_val=$(gcloud compute tpus tpu-vm describe "$name" --zone="${rg:-}" --format="value(labels.$LIBSCRIPT_TAG_KEY)" 2>/dev/null || true) ;;
        filestore) actual_val=$(gcloud filestore instances describe "$name" --zone="${rg:-}" --format="value(labels.$LIBSCRIPT_TAG_KEY)" 2>/dev/null || true) ;;
        qr) actual_val=$(gcloud alpha compute tpus queued-resources describe "$name" --zone="${rg:-}" --format="value(labels.$LIBSCRIPT_TAG_KEY)" 2>/dev/null || true) ;;
        *) return 0 ;;
      esac
      ;;
    azure)
      case "$type" in
        node) actual_val=$(az vm show -g "$rg" -n "$name" --query "tags.$LIBSCRIPT_TAG_KEY" -o tsv 2>/dev/null || true) ;;
        network) actual_val=$(az network vnet show -g "$rg" -n "$name" --query "tags.$LIBSCRIPT_TAG_KEY" -o tsv 2>/dev/null || true) ;;
        firewall) actual_val=$(az network nsg show -g "$rg" -n "$name" --query "tags.$LIBSCRIPT_TAG_KEY" -o tsv 2>/dev/null || true) ;;
        storage) actual_val=$(az storage account show -g "$rg" -n "$name" --query "tags.$LIBSCRIPT_TAG_KEY" -o tsv 2>/dev/null || true) ;;
        dns) actual_val=$(az network dns zone show -g "$rg" -n "$name" --query "tags.$LIBSCRIPT_TAG_KEY" -o tsv 2>/dev/null || true) ;;
        volume) actual_val=$(az disk show -g "$rg" -n "$name" --query "tags.$LIBSCRIPT_TAG_KEY" -o tsv 2>/dev/null || true) ;;
        cdn) actual_val=$(az cdn profile show -g "$rg" -n "$name" --query "tags.$LIBSCRIPT_TAG_KEY" -o tsv 2>/dev/null || true) ;;
        cert) return 0 ;; # Cert tags implementation might vary
        *) return 0 ;;
      esac
      ;;
  esac

  if [ "$actual_val" = "$LIBSCRIPT_TAG_VALUE" ]; then
    return 0
  fi

  if [ "${LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION:-0}" = "1" ] || [ "${LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION:-}" = "true" ]; then
    printf '[WARNING] Resource "%s" is not managed by libscript. Proceeding due to override flag.\n' "$name" >&2
    return 0
  else
    printf '[ERROR] Refusing to modify "%s": Resource is not managed by libscript (missing tag). Set LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION=1 to override.\n' "$name" >&2
    return 1
  fi
}

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
      printf -- '--tags Key=%s,Value=%s' "${LIBSCRIPT_TAG_KEY}" "${LIBSCRIPT_TAG_VALUE}"
      ;;
    gcp)
      printf -- '--labels=%s=%s' "${LIBSCRIPT_TAG_KEY}" "${LIBSCRIPT_TAG_VALUE}"
      ;;
    azure)
      printf -- '--tags %s=%s' "${LIBSCRIPT_TAG_KEY}" "${LIBSCRIPT_TAG_VALUE}"
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
      printf -- '--filters Name=tag:%s,Values=%s' "${LIBSCRIPT_TAG_KEY}" "${LIBSCRIPT_TAG_VALUE}"
      ;;
    gcp)
      printf -- '--filter=labels.%s=%s' "${LIBSCRIPT_TAG_KEY}" "${LIBSCRIPT_TAG_VALUE}"
      ;;
    azure)
      # Azure CLI usually uses JMESPath queries to filter by tags
      printf -- '--query "[?tags.%s == ''%s'']"' "${LIBSCRIPT_TAG_KEY}" "${LIBSCRIPT_TAG_VALUE}"
      ;;
    *)
      printf 'Error: Unknown cloud provider "%s" for tag filtering.\n' "${provider}" >&2
      return 1
      ;;
  esac
}
