#!/bin/sh
# ## Overview
# End-to-end test suite verifying Pillar 2 (`UK-01`..`UK-16`) unikernel constellations and AWS/Azure/GCP Marketplace publishing.
#
# ## Usage
# ./tests/test_unikernel_marketplace.sh

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

TEST_TMP=$(mktemp -d)

# ## fail_mkt_test
# Prints failure diagnostic, cleans temporary directory, and exits non-zero.
fail_mkt_test() {
  printf '[FAIL] %s\n' "$1" >&2
  rm -rf "${TEST_TMP}"
  exit 1
}

printf '%s\n' '=== 1. Open edX 8-Node Unikernel Constellation Assembly (2x Idempotency) ==='
"${LIBSCRIPT_ROOT_DIR}/workloads/constellations/unikernel_pod/setup_generic.sh" assemble \
  --topology="${LIBSCRIPT_ROOT_DIR}/workloads/constellations/openedx-unikernel-pod/topology.json" \
  --out-dir="${TEST_TMP}/pod" --cloud-boot=uefi-gpt --allow-stub-sdk >/dev/null
"${LIBSCRIPT_ROOT_DIR}/workloads/constellations/unikernel_pod/setup_generic.sh" assemble \
  --topology="${LIBSCRIPT_ROOT_DIR}/workloads/constellations/openedx-unikernel-pod/topology.json" \
  --out-dir="${TEST_TMP}/pod" --cloud-boot=uefi-gpt --allow-stub-sdk >/dev/null

jq -e '.appliances | length == 8' "${TEST_TMP}/pod/pod-manifest.json" >/dev/null || fail_mkt_test 'Expected 8 Open edX unikernel appliances in constellation'
[ -x "${TEST_TMP}/pod/appliances/lms-wsgi/rootfs/opt/openedx/lms/bin/openedx-lms" ] || fail_mkt_test 'Missing staged single-process LMS entrypoint'
[ -f "${TEST_TMP}/pod/appliances/lms-wsgi/lms-wsgi.unikernel.elf.uefi-gpt.json" ] || fail_mkt_test 'Missing UEFI/GPT boot wrapper manifest'

printf '%s\n' '=== 2. Multicloud Marketplace Publish (AWS CloudFormation + Azure Managed App + GCP Terraform) ==='
OUT_MKT="${TEST_TMP}/mkt"
OFFER_JSON="${LIBSCRIPT_ROOT_DIR}/workloads/constellations/openedx-unikernel-pod/marketplace/offer.json"
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" publish-marketplace \
  "${OFFER_JSON}" \
  --clouds=aws,azure,gcp --out-dir="${OUT_MKT}" --dry-run --allow-stub-sdk
OUT_SECOND=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" publish-marketplace \
  "${OFFER_JSON}" \
  --clouds=aws,azure,gcp --out-dir="${OUT_MKT}" --dry-run --allow-stub-sdk)

printf '%s\n' "$OUT_SECOND" | grep -q '\[SKIP\]' || fail_mkt_test 'Second publish-marketplace run did not hit idempotent [SKIP]'
jq -e '.spdxVersion == "SPDX-2.3" and (.packages | length >= 5)' "${OUT_MKT}/sbom.spdx.json" >/dev/null || fail_mkt_test 'Invalid SPDX 2.3 SBOM'
jq -e '.Resources.Unikernellmswsgi.Type == "AWS::EC2::Instance"' "${OUT_MKT}/aws/cloudformation.template.json" >/dev/null || fail_mkt_test 'Missing AWS CloudFormation LMS unikernel resource'
jq -e '.ChangeSet | length == 2' "${OUT_MKT}/aws/marketplace-changeset.json" >/dev/null || fail_mkt_test 'Invalid AWS Marketplace Catalog ChangeSet'
jq -e '.resources | length == 8' "${OUT_MKT}/azure/pkg/mainTemplate.json" >/dev/null || fail_mkt_test 'Expected 8 VM resources in Azure Managed App mainTemplate.json'
[ -s "${OUT_MKT}/azure/managed-app-package.tar.gz" ] || fail_mkt_test 'Missing packaged Azure Managed Application archive'
grep -q 'unikernel_lms_wsgi' "${OUT_MKT}/gcp/main.tf" || fail_mkt_test 'Missing GCE unikernel_lms_wsgi Terraform resource'

printf '%s\n' '=== 3. Pre-Marketplace Compliance Gate Rejects Leaked SSH Keys ==='
mkdir -p "${TEST_TMP}/dirty_sysroot/root/.ssh"
printf 'ssh-ed25519 test-public-key-material\n' > "${TEST_TMP}/dirty_sysroot/root/.ssh/authorized_keys"
if "${LIBSCRIPT_ROOT_DIR}/infrastructure/marketplace/verify_compliance.sh" \
  "${OFFER_JSON}" \
  --sysroot-dir="${TEST_TMP}/dirty_sysroot" >/dev/null 2>&1; then
  fail_mkt_test 'Compliance gate should have rejected leaked authorized_keys!'
fi

rm -rf "${TEST_TMP}"
printf '%s\n' '[PASS] All Pillar 2 Unikernel Constellation & Multicloud Marketplace tests passed!'
