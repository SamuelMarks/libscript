#!/bin/sh
# ## Overview
# Synthesizes a multi-unikernel AWS CloudFormation deployment template and AWS Marketplace Catalog
# API `StartChangeSet` payload (`CreateEntity`, `UpdateInformation`, `AddDeliveryOptions`).
#
# ## Usage
# ./cli/commands/marketplace/aws.sh <offer.json> --out-dir=<dir> [--stage-only] [--dry-run]

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

OFFER_FILE=''
OUT_DIR=''
STAGE_ONLY=0
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --out-dir=*) OUT_DIR="${1#*=}"; shift ;;
    --stage-only) STAGE_ONLY=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    *) [ -z "$OFFER_FILE" ] && OFFER_FILE="$1"; shift ;;
  esac
done

[ -f "$OFFER_FILE" ] || { printf '[ERROR] Valid offer.json required\n' >&2; exit 1; }
OFFER_ID=$(jq -r '.offer_id' "$OFFER_FILE")
[ -n "$OUT_DIR" ] || OUT_DIR="${LIBSCRIPT_ROOT_DIR}/build/marketplace/${OFFER_ID}/aws"
mkdir -p "$OUT_DIR"

jq '
  . as $offer
  | {
      AWSTemplateFormatVersion: "2010-09-09",
      Description: "\($offer.product_title) (\($offer.version)) - Multi-Unikernel AWS Marketplace Stack",
      Parameters: {
        VpcId: { Type: "AWS::EC2::VPC::Id", Description: "Target VPC for the unikernel appliance pod" },
        SubnetId: { Type: "AWS::EC2::Subnet::Id", Description: "Target subnet for unikernel instances" }
      },
      Resources: (
        {
          ApplianceSecurityGroup: {
            Type: "AWS::EC2::SecurityGroup",
            Properties: {
              GroupDescription: "Whitelisted ingress for \($offer.offer_id)",
              VpcId: { Ref: "VpcId" },
              SecurityGroupIngress: [
                $offer.exposed_endpoints[] | {
                  IpProtocol: .protocol,
                  FromPort: .port,
                  ToPort: .port,
                  CidrIp: "0.0.0.0/0"
                }
              ]
            }
          }
        }
        + (
          reduce $offer.appliance_images[] as $img ({};
            . + {
              ("Unikernel" + ($img.role | gsub("[^a-zA-Z0-9]"; ""))): {
                Type: "AWS::EC2::Instance",
                Properties: {
                  InstanceType: ($img.default_instance_types.aws // "m7i.large"),
                  ImageId: ("{{resolve:ssm:/libscript/marketplace/" + $offer.offer_id + "/" + $img.role + "/ami}}"),
                  SubnetId: { Ref: "SubnetId" },
                  SecurityGroupIds: [{ Ref: "ApplianceSecurityGroup" }],
                  Tags: [
                    { Key: "Name", Value: ($offer.offer_id + "-" + $img.role) },
                    { Key: "LibScriptRole", Value: $img.role }
                  ]
                }
              }
            }
          )
        )
      )
    }
' "$OFFER_FILE" > "${OUT_DIR}/cloudformation.template.json.tmp"
mv "${OUT_DIR}/cloudformation.template.json.tmp" "${OUT_DIR}/cloudformation.template.json"

jq '
  . as $o
  | {
      Catalog: "AWSMarketplace",
      ChangeSetName: ("libscript-" + $o.offer_id + "-" + ($o.version | gsub("\\."; "-"))),
      ChangeSet: [
        {
          ChangeType: "UpdateInformation",
          Entity: { Type: (($o.targets.aws_marketplace.product_type // "CloudFormationProduct") + "@1.0"), Identifier: $o.offer_id },
          DetailsDocument: {
            ProductTitle: $o.product_title,
            ShortDescription: $o.summary,
            PricingModel: $o.pricing.model
          }
        },
        {
          ChangeType: "AddDeliveryOptions",
          Entity: { Type: (($o.targets.aws_marketplace.product_type // "CloudFormationProduct") + "@1.0"), Identifier: $o.offer_id },
          DetailsDocument: {
            Version: { VersionTitle: $o.version, ReleaseNotes: ("Automated LibScript synthesis " + $o.version) },
            DeliveryOptions: [
              {
                Details: {
                  CloudFormationDeliveryOptionDetails: {
                    TemplateUrl: ("https://" + ($o.targets.aws_marketplace.s3_staging_bucket // "libscript-marketplace") + ".s3.amazonaws.com/" + $o.offer_id + "/" + $o.version + "/cloudformation.template.json")
                  }
                }
              }
            ]
          }
        }
      ]
    }
' "$OFFER_FILE" > "${OUT_DIR}/marketplace-changeset.json.tmp"
mv "${OUT_DIR}/marketplace-changeset.json.tmp" "${OUT_DIR}/marketplace-changeset.json"

if [ "$STAGE_ONLY" -eq 0 ] && [ "$DRY_RUN" -eq 0 ]; then
  _reg=$(jq -r '.targets.aws_marketplace.region // "us-east-1"' "$OFFER_FILE")
  _bkt=$(jq -r '.targets.aws_marketplace.s3_staging_bucket // "libscript-marketplace"' "$OFFER_FILE")
  _ver=$(jq -r '.version' "$OFFER_FILE")
  aws s3 cp "${OUT_DIR}/cloudformation.template.json" "s3://${_bkt}/${OFFER_ID}/${_ver}/cloudformation.template.json" --region "$_reg"
  aws marketplace-catalog start-change-set --region "$_reg" --cli-input-json "file://${OUT_DIR}/marketplace-changeset.json"
fi

printf '[OK] AWS Marketplace CloudFormation & Catalog ChangeSet synthesized at %s\n' "$OUT_DIR"
