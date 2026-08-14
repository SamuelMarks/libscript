#!/bin/sh
# ## Overview
# API implementation for SSL Certificate operations. Wraps native cloud CLIs.
#
# ## Usage
# Source this file and call libscript_cert_create, libscript_cert_delete, etc.

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

# ## libscript_cert_create
# Executes libscript_cert_create functionality.
libscript_cert_create() {
  provider="$1"
  domain="$2"

  case "$provider" in
    aws)
      arn=$(aws acm request-certificate --domain-name "$domain" --validation-method DNS --query 'CertificateArn' --output text)
      if [ "$LIBSCRIPT_TAG_ENABLE" = "true" ]; then
        aws acm add-tags-to-certificate --certificate-arn "$arn" --tags "Key=$LIBSCRIPT_TAG_KEY,Value=$LIBSCRIPT_TAG_VALUE"
      fi
      printf "Requested certificate: %s\n" "$arn"
      printf "Use 'aws acm describe-certificate --certificate-arn %s' to get DNS validation records.\n" "$arn"
      ;;
    gcp)
      cert_name=$(printf '%s' "$domain" | tr '.' '-')
      gcloud compute ssl-certificates create "$cert_name" --domains="$domain" --global
      printf "Requested certificate: %s\n" "$cert_name"
      ;;
    azure)
      printf "Azure Front Door managed certificates are typically provisioned automatically when adding a custom domain to a CDN endpoint.\n"
      ;;
  esac
}

# ## libscript_cert_delete
# Executes libscript_cert_delete functionality.
libscript_cert_delete() {
  provider="$1"
  domain="$2"
  
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh" ]; then
    # shellcheck disable=SC1091
    . "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh"
  fi
  
  case "$provider" in
    aws)
      # Requires ARN. We'll search for it if domain is provided but isn't an ARN
      if printf "%s" "$domain" | grep -q "^arn:aws:acm"; then
        libscript_verify_managed aws cert "$domain" || return 1
        aws acm delete-certificate --certificate-arn "$domain"
      else
        arn=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='$domain'].CertificateArn" --output text)
        if [ -n "$arn" ]; then
          libscript_verify_managed aws cert "$arn" || return 1
          aws acm delete-certificate --certificate-arn "$arn"
        else
          printf "Error: Certificate for domain %s not found.\n" "$domain" >&2
          return 1
        fi
      fi
      ;;
    gcp)
      cert_name=$(printf '%s' "$domain" | tr '.' '-')
      libscript_verify_managed gcp cert "$cert_name" || return 1
      gcloud compute ssl-certificates delete "$cert_name" --global --quiet
      ;;
    azure)
      printf "Azure managed CDN certificates are deleted when the custom domain mapping is removed.\n"
      ;;
  esac
}

# ## libscript_cert_list
# Executes libscript_cert_list functionality.
libscript_cert_list() {
  provider="$1"
  
  case "$provider" in
    aws)
      aws acm list-certificates
      ;;
    gcp)
      gcloud compute ssl-certificates list --global
      ;;
    azure)
      printf "Azure managed certificates are tied to CDN custom domains. Use CDN list commands.\n"
      ;;
  esac
}