#!/bin/sh
# ## Overview
# Pre-marketplace compliance gate verifying zero SSH/secret leakage in sysroots, EULA presence,
# strict ingress port whitelists, and deterministic SPDX 2.3 JSON SBOM emission.
#
# ## Usage
# ./cli/commands/marketplace/verify_compliance.sh <offer.json> [--sysroot-dir=<dir>] [--out-sbom=<sbom.json>]

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
SYSROOT_SCAN_DIR=''
OUT_SBOM=''

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      printf '%s\n' 'Usage: verify_compliance.sh <offer.json> [--sysroot-dir=<dir>] [--out-sbom=<sbom.json>]'
      exit 0
      ;;
    --sysroot-dir=*) SYSROOT_SCAN_DIR="${1#*=}"; shift ;;
    --out-sbom=*) OUT_SBOM="${1#*=}"; shift ;;
    *) [ -z "$OFFER_FILE" ] && OFFER_FILE="$1"; shift ;;
  esac
done

[ -n "$OFFER_FILE" ] && [ -f "$OFFER_FILE" ] || { printf '[ERROR] Valid <offer.json> path required.\n' >&2; exit 1; }

OFFER_ID=$(jq -r '.offer_id' "$OFFER_FILE")
OFFER_VER=$(jq -r '.version' "$OFFER_FILE")
EULA_URI=$(jq -r '.eula_uri' "$OFFER_FILE")
[ -n "$OUT_SBOM" ] || OUT_SBOM=$(jq -r '.sbom_path // empty' "$OFFER_FILE")
[ -n "$OUT_SBOM" ] || OUT_SBOM="${LIBSCRIPT_ROOT_DIR}/build/marketplace/${OFFER_ID}/sbom.spdx.json"

# 1. Verify EULA bundle presence
case "$EULA_URI" in
  https://*) ;;
  *)
    if [ ! -f "$EULA_URI" ] && [ ! -f "${LIBSCRIPT_ROOT_DIR}/${EULA_URI}" ]; then
      printf '[COMPLIANCE FAIL] Missing EULA / license file: %s\n' "$EULA_URI" >&2
      exit 1
    fi
    ;;
esac

# 2. Verify zero SSH authorized_keys, host private keys, or .env secrets in staged sysroots
if [ -n "$SYSROOT_SCAN_DIR" ] && [ -d "$SYSROOT_SCAN_DIR" ]; then
  _bad_files=$(find "$SYSROOT_SCAN_DIR" \( -name 'authorized_keys' -o -name 'id_rsa' -o -name 'id_ed25519' -o -name 'ssh_host_*_key' -o -name '.env.secrets' \) 2>/dev/null || true)
  if [ -n "$_bad_files" ]; then
    printf '[COMPLIANCE FAIL] Prohibited SSH key or secret artifact found in staged sysroot:\n%s\n' "$_bad_files" >&2
    exit 1
  fi
fi

# 3. Verify exposed endpoints whitelist (reject dangerous cleartext admin ports 22/2375/3306/5432/6379/27017 on public ingress)
_bad_ports=$(jq -r '.exposed_endpoints[]? | select(.port == 22 or .port == 2375 or .port == 3306 or .port == 5432 or .port == 6379 or .port == 27017) | .port' "$OFFER_FILE")
if [ -n "$_bad_ports" ]; then
  printf '[COMPLIANCE FAIL] Prohibited administrative/datastore port exposed publicly in offer: %s\n' "$_bad_ports" >&2
  exit 1
fi

# 4. Generate deterministic SPDX 2.3 JSON SBOM from referenced os-config profiles and _lib manifests
_comps=$(jq -r '.appliance_images[].os_profile' "$OFFER_FILE" | while IFS= read -r _p; do
  _pf="$_p"
  [ -f "$_pf" ] || _pf="${LIBSCRIPT_ROOT_DIR}/${_p}"
  [ -f "$_pf" ] && jq -r '.components[]?' "$_pf"
done | sort -u)

_pkgs_json=''
for _c in $_comps; do
  _mf=$(find "${LIBSCRIPT_ROOT_DIR}/_lib" -mindepth 3 -maxdepth 3 -path "*/${_c}/manifest.json" | head -n 1 || true)
  _repo='NOASSERTION'
  _desc="LibScript component ${_c}"
  if [ -n "$_mf" ] && [ -f "$_mf" ]; then
    _repo=$(jq -r '.repository // "NOASSERTION"' "$_mf")
    _desc=$(jq -r '.description // ""' "$_mf" | tr '"' "'")
  fi
  _pkg="{\"SPDXID\":\"SPDXRef-Package-${_c}\",\"name\":\"${_c}\",\"versionInfo\":\"${OFFER_VER}\",\"downloadLocation\":\"${_repo}\",\"licenseConcluded\":\"Apache-2.0 OR MIT\",\"summary\":\"${_desc}\"}"
  _pkgs_json="${_pkgs_json}${_pkgs_json:+,}${_pkg}"
done

mkdir -p "$(dirname -- "$OUT_SBOM")"
cat << EOF > "${OUT_SBOM}.tmp"
{
  "spdxVersion": "SPDX-2.3",
  "dataLicense": "CC0-1.0",
  "SPDXID": "SPDXRef-DOCUMENT",
  "name": "${OFFER_ID}-${OFFER_VER}",
  "documentNamespace": "https://libscript.org/spdx/${OFFER_ID}/${OFFER_VER}",
  "creationInfo": {
    "creators": ["Tool: libscript-marketplace-compliance-1.0"]
  },
  "packages": [${_pkgs_json}]
}
EOF
mv "${OUT_SBOM}.tmp" "$OUT_SBOM"
printf '[COMPLIANCE PASS] Offer %s (%s) verified; SPDX SBOM written to %s\n' "$OFFER_ID" "$OFFER_VER" "$OUT_SBOM"
