#!/bin/sh
# ## Overview
# API implementation for Object Storage operations. Wraps native cloud CLIs.
#
# ## Usage
# Source this file and call libscript_storage_create, libscript_storage_delete, etc.

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

libscript_storage_create() {
  provider="$1"
  bucket="$2"
  public_web="${3:-false}"
  
  case "$provider" in
    aws)
      if aws s3api head-bucket --bucket "$bucket" >/dev/null 2>&1; then
        printf "Storage bucket '%s' already exists.\n" "$bucket"
      else
        aws s3 mb "s3://$bucket"
      fi
      if [ "$LIBSCRIPT_TAG_ENABLE" = "true" ]; then
        aws s3api put-bucket-tagging --bucket "$bucket" --tagging "TagSet=[{Key=$LIBSCRIPT_TAG_KEY,Value=$LIBSCRIPT_TAG_VALUE}]"
      fi
      if [ "$public_web" = "true" ]; then
        aws s3 website "s3://$bucket/" --index-document index.html
        aws s3api put-public-access-block --bucket "$bucket" --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
      fi
      ;;
    gcp)
      if gcloud storage buckets describe "gs://$bucket" >/dev/null 2>&1; then
        printf "Storage bucket '%s' already exists.\n" "$bucket"
      else
        gcloud storage buckets create "gs://$bucket"
      fi
      if [ "$LIBSCRIPT_TAG_ENABLE" = "true" ]; then
        gcloud storage buckets update "gs://$bucket" --update-labels="$LIBSCRIPT_TAG_KEY=$LIBSCRIPT_TAG_VALUE"
      fi
      if [ "$public_web" = "true" ]; then
        gcloud storage buckets update "gs://$bucket" --web-main-page-suffix=index.html
        gcloud storage buckets add-iam-policy-binding "gs://$bucket" --member="allUsers" --role="roles/storage.objectViewer"
      fi
      ;;
    azure)
      acct="${LIBSCRIPT_AZURE_ACCOUNT_NAME:-}"
      if [ -z "$acct" ]; then
        printf "Error: LIBSCRIPT_AZURE_ACCOUNT_NAME must be set for Azure storage operations.\n" >&2
        return 1
      fi
      
      if az storage container show --name "$bucket" --account-name "$acct" >/dev/null 2>&1; then
        printf "Storage container '%s' already exists.\n" "$bucket"
      else
        cmd="az storage container create --name \"$bucket\" --account-name \"$acct\""
        if [ "$public_web" = "true" ]; then
          cmd="$cmd --public-access container"
        fi
        eval "$cmd"
      fi
      if [ "$LIBSCRIPT_TAG_ENABLE" = "true" ]; then
        az storage container metadata update --name "$bucket" --account-name "$acct" --metadata "$LIBSCRIPT_TAG_KEY=$LIBSCRIPT_TAG_VALUE"
      fi
      ;;
  esac
}

libscript_storage_delete() {
  provider="$1"
  bucket="$2"

  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh" ]; then
    # shellcheck disable=SC1091
    . "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh"
  fi

  case "$provider" in
    aws)
      libscript_verify_managed aws storage "$bucket" || return 1
      aws s3 rb "s3://$bucket" --force
      ;;
    gcp)
      libscript_verify_managed gcp storage "$bucket" || return 1
      gcloud storage buckets delete "gs://$bucket"
      ;;
    azure)
      acct="${LIBSCRIPT_AZURE_ACCOUNT_NAME:-}"
      if [ -z "$acct" ]; then
        printf "Error: LIBSCRIPT_AZURE_ACCOUNT_NAME must be set for Azure storage operations.\n" >&2
        return 1
      fi
      libscript_verify_managed azure storage "$bucket" "$acct" || return 1
      az storage container delete --name "$bucket" --account-name "$acct"
      ;;
  esac
}

libscript_storage_list() {
  provider="$1"
  
  case "$provider" in
    aws)
      if [ "$LIBSCRIPT_TAG_ENABLE" = "true" ]; then
        aws resourcegroupstaggingapi get-resources --resource-type-filters s3 --tag-filters "Key=$LIBSCRIPT_TAG_KEY,Values=$LIBSCRIPT_TAG_VALUE" --query 'ResourceTagMappingList[].ResourceARN' --output text
      else
        aws s3 ls
      fi
      ;;
    gcp)
      if [ "$LIBSCRIPT_TAG_ENABLE" = "true" ]; then
        gcloud storage buckets list --filter="labels.$LIBSCRIPT_TAG_KEY=$LIBSCRIPT_TAG_VALUE"
      else
        gcloud storage buckets list
      fi
      ;;
    azure)
      acct="${LIBSCRIPT_AZURE_ACCOUNT_NAME:-}"
      if [ -z "$acct" ]; then
        printf "Error: LIBSCRIPT_AZURE_ACCOUNT_NAME must be set for Azure storage operations.\n" >&2
        return 1
      fi
      if [ "$LIBSCRIPT_TAG_ENABLE" = "true" ]; then
        az storage container list --account-name "$acct" --query "[?metadata.$LIBSCRIPT_TAG_KEY == '$LIBSCRIPT_TAG_VALUE'].name" --output tsv
      else
        az storage container list --account-name "$acct" --query "[].name" --output tsv
      fi
      ;;
  esac
}

libscript_storage_sync() {
  provider="$1"
  bucket="$2"
  local_dir="$3"
  
  if [ ! -d "$local_dir" ]; then
    printf "Error: Local directory '%s' does not exist.\n" "$local_dir" >&2
    return 1
  fi

  case "$provider" in
    aws)
      aws s3 sync "$local_dir" "s3://$bucket/"
      ;;
    gcp)
      gcloud storage rsync -r "$local_dir" "gs://$bucket/"
      ;;
    azure)
      acct="${LIBSCRIPT_AZURE_ACCOUNT_NAME:-}"
      if [ -z "$acct" ]; then
        printf "Error: LIBSCRIPT_AZURE_ACCOUNT_NAME must be set for Azure storage operations.\n" >&2
        return 1
      fi
      az storage blob sync -c "$bucket" --account-name "$acct" -s "$local_dir"
      ;;
  esac
}