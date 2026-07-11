#!/bin/sh
# ## Overview
# API implementation for Block Storage (Volumes) operations. Wraps native cloud CLIs.
#
# ## Usage
# Source this file and call libscript_volume_create, libscript_volume_delete, etc.

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

# shellcheck disable=SC1090
. "$LIBSCRIPT_ROOT_DIR/_lib/cloud/core/tags.sh"

libscript_volume_create() {
  provider="$1"
  size="${2:-10}"
  zone="${3:-}"
  vtype="${4:-}"

  if [ -z "$zone" ]; then
    printf "Error: --zone (or LIBSCRIPT_VOLUME_ZONE) is required for volume creation.\n" >&2
    return 1
  fi

  case "$provider" in
    aws)
      vtype="${vtype:-gp3}"
      cmd="aws ec2 create-volume --availability-zone \"$zone\" --size \"$size\" --volume-type \"$vtype\""
      if [ "$LIBSCRIPT_TAG_ENABLE" = "true" ]; then
        cmd="$cmd --tag-specifications \"ResourceType=volume,Tags=[{Key=$LIBSCRIPT_TAG_KEY,Value=$LIBSCRIPT_TAG_VALUE}]\""
      fi
      eval "$cmd"
      ;;
    gcp)
      vtype="${vtype:-pd-standard}"
      vname="vol-$(date +%s)"
      cmd="gcloud compute disks create \"$vname\" --size=\"${size}GB\" --zone=\"$zone\" --type=\"$vtype\""
      if [ "$LIBSCRIPT_TAG_ENABLE" = "true" ]; then
        cmd="$cmd --labels=\"$LIBSCRIPT_TAG_KEY=$LIBSCRIPT_TAG_VALUE\""
      fi
      eval "$cmd"
      ;;
    azure)
      vtype="${vtype:-Standard_LRS}"
      vname="vol-$(date +%s)"
      rg="${LIBSCRIPT_AZURE_RESOURCE_GROUP:-}"
      if [ -z "$rg" ]; then
        printf "Error: LIBSCRIPT_AZURE_RESOURCE_GROUP must be set for Azure operations.\n" >&2
        return 1
      fi
      cmd="az disk create --name \"$vname\" --resource-group \"$rg\" --location \"$zone\" --size-gb \"$size\" --sku \"$vtype\""
      if [ "$LIBSCRIPT_TAG_ENABLE" = "true" ]; then
        cmd="$cmd --tags \"$LIBSCRIPT_TAG_KEY=$LIBSCRIPT_TAG_VALUE\""
      fi
      eval "$cmd"
      ;;
  esac
}

libscript_volume_delete() {
  provider="$1"
  vid="$2"
  
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh" ]; then
    # shellcheck disable=SC1091
    . "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh"
  fi
  
  case "$provider" in
    aws)
      libscript_verify_managed aws volume "$vid" || return 1
      aws ec2 delete-volume --volume-id "$vid"
      ;;
    gcp)
      zone="${LIBSCRIPT_VOLUME_ZONE:-}"
      if [ -z "$zone" ]; then
        printf "Error: --zone (or LIBSCRIPT_VOLUME_ZONE) is required for GCP delete.\n" >&2
        return 1
      fi
      libscript_verify_managed gcp volume "$vid" "$zone" || return 1
      gcloud compute disks delete "$vid" --zone="$zone" --quiet
      ;;
    azure)
      rg="${LIBSCRIPT_AZURE_RESOURCE_GROUP:-}"
      if [ -z "$rg" ]; then
        printf "Error: LIBSCRIPT_AZURE_RESOURCE_GROUP must be set for Azure operations.\n" >&2
        return 1
      fi
      libscript_verify_managed azure volume "$vid" "$rg" || return 1
      az disk delete --name "$vid" --resource-group "$rg" --yes
      ;;
  esac
}

libscript_volume_list() {
  provider="$1"
  
  case "$provider" in
    aws)
      if [ "$LIBSCRIPT_TAG_ENABLE" = "true" ]; then
        aws ec2 describe-volumes --filters "Name=tag:$LIBSCRIPT_TAG_KEY,Values=$LIBSCRIPT_TAG_VALUE" --query 'Volumes[*].[VolumeId,State,Attachments[0].State]' --output table
      else
        aws ec2 describe-volumes --query 'Volumes[*].[VolumeId,State,Attachments[0].State]' --output table
      fi
      ;;
    gcp)
      if [ "$LIBSCRIPT_TAG_ENABLE" = "true" ]; then
        gcloud compute disks list --filter="labels.$LIBSCRIPT_TAG_KEY=$LIBSCRIPT_TAG_VALUE"
      else
        gcloud compute disks list
      fi
      ;;
    azure)
      rg="${LIBSCRIPT_AZURE_RESOURCE_GROUP:-}"
      if [ -z "$rg" ]; then
        printf "Error: LIBSCRIPT_AZURE_RESOURCE_GROUP must be set for Azure operations.\n" >&2
        return 1
      fi
      if [ "$LIBSCRIPT_TAG_ENABLE" = "true" ]; then
        az disk list --resource-group "$rg" --query "[?tags.$LIBSCRIPT_TAG_KEY == '$LIBSCRIPT_TAG_VALUE'].[name,diskState]" --output tsv
      else
        az disk list --resource-group "$rg" --query "[].[name,diskState]" --output tsv
      fi
      ;;
  esac
}

libscript_volume_attach() {
  provider="$1"
  vid="$2"
  nid="$3"
  device="$4"
  
  if [ -z "$nid" ] || [ -z "$device" ]; then
    printf "Error: --node-id and --device are required for attach.\n" >&2
    return 1
  fi
  
  case "$provider" in
    aws)
      aws ec2 attach-volume --volume-id "$vid" --instance-id "$nid" --device "$device"
      ;;
    gcp)
      zone="${LIBSCRIPT_VOLUME_ZONE:-}"
      if [ -z "$zone" ]; then
        printf "Error: --zone is required for GCP attach.\n" >&2
        return 1
      fi
      gcloud compute instances attach-disk "$nid" --disk "$vid" --device-name "$device" --zone "$zone"
      ;;
    azure)
      rg="${LIBSCRIPT_AZURE_RESOURCE_GROUP:-}"
      if [ -z "$rg" ]; then
        printf "Error: LIBSCRIPT_AZURE_RESOURCE_GROUP must be set for Azure operations.\n" >&2
        return 1
      fi
      az vm disk attach --vm-name "$nid" --name "$vid" --resource-group "$rg" --new false
      ;;
  esac
}

libscript_volume_detach() {
  provider="$1"
  vid="$2"
  nid="$3"
  
  if [ -z "$nid" ]; then
    printf "Error: --node-id is required for detach.\n" >&2
    return 1
  fi
  
  case "$provider" in
    aws)
      aws ec2 detach-volume --volume-id "$vid" --instance-id "$nid"
      ;;
    gcp)
      zone="${LIBSCRIPT_VOLUME_ZONE:-}"
      if [ -z "$zone" ]; then
        printf "Error: --zone is required for GCP detach.\n" >&2
        return 1
      fi
      gcloud compute instances detach-disk "$nid" --disk "$vid" --zone "$zone"
      ;;
    azure)
      rg="${LIBSCRIPT_AZURE_RESOURCE_GROUP:-}"
      if [ -z "$rg" ]; then
        printf "Error: LIBSCRIPT_AZURE_RESOURCE_GROUP must be set for Azure operations.\n" >&2
        return 1
      fi
      az vm disk detach --vm-name "$nid" --name "$vid" --resource-group "$rg"
      ;;
  esac
}
