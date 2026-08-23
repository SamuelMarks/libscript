#!/bin/sh
# ## Overview
# API implementation for CDN operations. Wraps native cloud CLIs.
#
# ## Usage
# Source this file and call libscript_cdn_create, libscript_cdn_delete, etc.

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

# shellcheck disable=SC1090
. "$LIBSCRIPT_ROOT_DIR/_lib/cloud/core/tags.sh"

# ## libscript_cdn_create
# Executes libscript_cdn_create functionality.
libscript_cdn_create() {
  provider="$1"
  bucket="$2"
  domain="${3:-}"
  cert_id="${4:-}"

  case "$provider" in
    aws)
      existing_dist=$(aws cloudfront list-distributions --query "DistributionList.Items[?Origins.Items[?Id=='S3-${bucket}']].DomainName | [0]" --output text 2>/dev/null || true)
      if [ -n "$existing_dist" ] && [ "$existing_dist" != "None" ]; then
        printf "CDN Distribution already exists for '%s': %s\n" "$bucket" "$existing_dist"
        dist_domain="$existing_dist"
      else
        # Create Origin Access Control
        oac_id=$(aws cloudfront create-origin-access-control \
          --origin-access-control-config "Name=${bucket}-oac,Description=libscript OAC for ${bucket},OriginAccessControlOriginType=s3,SigningBehavior=always,SigningProtocol=sigv4" \
          --query 'OriginAccessControl.Id' --output text 2>/dev/null || true)
        
        if [ -z "$oac_id" ] || [ "$oac_id" = "None" ]; then
          # If it already exists, fetch it
          oac_id=$(aws cloudfront list-origin-access-controls --query "OriginAccessControlList.Items[?Name=='${bucket}-oac'].Id" --output text)
        fi
  
        tmp_json=$(mktemp)
        cat <<JSON_EOF > "$tmp_json"
{
  "CallerReference": "libscript-$(date +%s)",
  "Comment": "libscript managed CDN for $bucket",
  "Enabled": true,
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-${bucket}",
        "DomainName": "${bucket}.s3.amazonaws.com",
        "OriginAccessControlId": "${oac_id}",
        "S3OriginConfig": {
          "OriginAccessIdentity": ""
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-${bucket}",
    "ViewerProtocolPolicy": "redirect-to-https",
    "MinTTL": 0,
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": { "Forward": "none" }
    }
  }
JSON_EOF
  
        if [ -n "$domain" ] && [ -n "$cert_id" ]; then
          cat <<JSON_EOF_EXT >> "$tmp_json"
  ,
  "Aliases": {
    "Quantity": 1,
    "Items": [ "${domain}" ]
  },
  "ViewerCertificate": {
    "ACMCertificateArn": "${cert_id}",
    "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1.2_2021"
  }
}
JSON_EOF_EXT
        else
          cat <<JSON_EOF_EXT >> "$tmp_json"
  ,
  "ViewerCertificate": {
    "CloudFrontDefaultCertificate": true
  }
}
JSON_EOF_EXT
        fi
  
        dist_domain=$(aws cloudfront create-distribution --distribution-config "file://$tmp_json" --query 'Distribution.DomainName' --output text)
        rm -f "$tmp_json"
        
        if [ "$LIBSCRIPT_TAG_ENABLE" = "true" ]; then
          dist_arn=$(aws cloudfront list-distributions --query "DistributionList.Items[?DomainName=='$dist_domain'].ARN" --output text)
          if [ -n "$dist_arn" ] && [ "$dist_arn" != "None" ]; then
            aws cloudfront tag-resource --resource "$dist_arn" --tags "Items=[{Key=$LIBSCRIPT_TAG_KEY,Value=$LIBSCRIPT_TAG_VALUE}]"
          fi
        fi
        printf "CDN Distribution created: %s\n" "$dist_domain"
      fi

      # Output bucket policy that needs to be applied
      printf "IMPORTANT: You must apply the following bucket policy to '%s' to allow OAC access:\n" "$bucket"
      cat <<POLICY_EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": { "Service": "cloudfront.amazonaws.com" },
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::$bucket/*",
    "Condition": {
      "StringEquals": { "AWS:SourceArn": "arn:aws:cloudfront::YOUR_ACCOUNT_ID:distribution/YOUR_DIST_ID" }
    }
  }
}
POLICY_EOF
      ;;
    gcp)
      if gcloud compute backend-buckets describe "${bucket}-backend" >/dev/null 2>&1; then
        printf "CDN backend-bucket already exists for %s\n" "$bucket"
      else
        # Create Backend Bucket
        gcloud compute backend-buckets create "${bucket}-backend" --gcs-bucket-name="${bucket}" --enable-cdn
        # Create URL Map
        gcloud compute url-maps create "${bucket}-urlmap" --default-backend-bucket="${bucket}-backend"
        
        if [ -n "$domain" ] && [ -n "$cert_id" ]; then
          # Create Target HTTPS Proxy
          gcloud compute target-https-proxies create "${bucket}-https-proxy" --url-map="${bucket}-urlmap" --ssl-certificates="${cert_id}"
          # Create Global Forwarding Rule for HTTPS
          gcloud compute forwarding-rules create "${bucket}-https-rule" --target-https-proxy="${bucket}-https-proxy" --ports=443 --global
          ip=$(gcloud compute forwarding-rules describe "${bucket}-https-rule" --global --format="value(IPAddress)")
          printf "HTTPS CDN created on IP: %s\n" "$ip"
        else
          # Create Target HTTP Proxy
          gcloud compute target-http-proxies create "${bucket}-http-proxy" --url-map="${bucket}-urlmap"
          # Create Global Forwarding Rule for HTTP
          gcloud compute forwarding-rules create "${bucket}-http-rule" --target-http-proxy="${bucket}-http-proxy" --ports=80 --global
          ip=$(gcloud compute forwarding-rules describe "${bucket}-http-rule" --global --format="value(IPAddress)")
          printf "HTTP CDN created on IP: %s\n" "$ip"
        fi
      fi
      ;;
    azure)
      printf "Azure CDN creation requires an existing CDN Profile. Skipping complex scaffolding for now.\n"
      ;;
  esac
}

# ## libscript_cdn_delete
# Executes libscript_cdn_delete functionality.
libscript_cdn_delete() {
  provider="$1"
  dist_id="$2"
  
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh" ]; then
    # shellcheck disable=SC1091
    . "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh"
  fi
  
  case "$provider" in
    aws)
      libscript_verify_managed aws cdn "$dist_id" || return 1
      etag=$(aws cloudfront get-distribution --id "$dist_id" --query 'ETag' --output text)
      aws cloudfront delete-distribution --id "$dist_id" --if-match "$etag"
      ;;
    gcp)
      # Assuming dist_id is the bucket prefix used in creation
      libscript_verify_managed gcp cdn "$dist_id" || return 1
      gcloud compute forwarding-rules delete "${dist_id}-https-rule" "${dist_id}-http-rule" --global --quiet 2>/dev/null || true
      gcloud compute target-https-proxies delete "${dist_id}-https-proxy" --quiet 2>/dev/null || true
      gcloud compute target-http-proxies delete "${dist_id}-http-proxy" --quiet 2>/dev/null || true
      gcloud compute url-maps delete "${dist_id}-urlmap" --quiet 2>/dev/null || true
      gcloud compute backend-buckets delete "${dist_id}-backend" --quiet 2>/dev/null || true
      ;;
    azure)
      printf "Azure CDN delete not implemented in stub.\n"
      ;;
  esac
}

# ## libscript_cdn_list
# Executes libscript_cdn_list functionality.
libscript_cdn_list() {
  provider="$1"
  
  case "$provider" in
    aws)
      aws cloudfront list-distributions --query 'DistributionList.Items[*].[Id,DomainName,Status]' --output table
      ;;
    gcp)
      gcloud compute backend-buckets list
      gcloud compute url-maps list
      ;;
    azure)
      printf "Azure CDN list not implemented in stub.\n"
      ;;
  esac
}

# ## libscript_cdn_invalidate
# Executes libscript_cdn_invalidate functionality.
libscript_cdn_invalidate() {
  provider="$1"
  dist_id="$2"
  paths="${3:-/*}"

  case "$provider" in
    aws)
      aws cloudfront create-invalidation --distribution-id "$dist_id" --paths "$paths"
      ;;
    gcp)
      gcloud compute url-maps invalidate-cdn-cache "${dist_id}-urlmap" --path "$paths"
      ;;
    azure)
      printf "Azure CDN invalidate not implemented in stub.\n"
      ;;
  esac
}