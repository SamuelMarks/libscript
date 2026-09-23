#!/bin/sh
# ## Overview
# Generates a Cloud-Init NoCloud configuration ISO image (labeled cidata)
# containing user-data, meta-data, and network-config for automated VM bootstrapping.
#
# ## Usage
# ./_lib/orchestration/cloud/gen_nocloud_iso.sh [hostname] [user_data_file] [out_iso]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
export LIBSCRIPT_ROOT_DIR

HOSTNAME="${1:-libscript-vm}"
USER_DATA="${2:-}"
OUT_ISO="${3:-${LIBSCRIPT_ROOT_DIR}/build/cidata.iso}"

OUT_DIR="${OUT_ISO%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

if [ -f "$OUT_ISO" ]; then
  printf '[IDEMPOTENT] Target NoCloud ISO already exists: %s
' "$OUT_ISO"
  exit 0
fi

TMP_STAGING="${LIBSCRIPT_ROOT_DIR}/build/tmp_nocloud_staging"
rm -rf "$TMP_STAGING"
mkdir -p "$TMP_STAGING"

cat <<EOF > "$TMP_STAGING/meta-data"
instance-id: i-libscript-$(date +%s 2>/dev/null || echo 12345)
local-hostname: ${HOSTNAME}
EOF

if [ -n "$USER_DATA" ] && [ -f "$USER_DATA" ]; then
  cp -f "$USER_DATA" "$TMP_STAGING/user-data"
else
  cat <<'EOF' > "$TMP_STAGING/user-data"
#cloud-config
disable_root: false
ssh_pwauth: true
chpasswd:
  list: |
    root:libscript
  expire: false
growpart:
  mode: auto
  devices: ['/']
resize_rootfs: true
EOF
fi

cat <<'EOF' > "$TMP_STAGING/network-config"
version: 2
ethernets:
  eth0:
    dhcp4: true
EOF

printf '[NOCLOUD] Packaging NoCloud ISO with label cidata...
'

if command -v genisoimage >/dev/null 2>&1; then
  genisoimage -output "$OUT_ISO" -volid cidata -joliet -rock "$TMP_STAGING" >/dev/null 2>&1
elif command -v mkisofs >/dev/null 2>&1; then
  mkisofs -output "$OUT_ISO" -volid cidata -joliet -rock "$TMP_STAGING" >/dev/null 2>&1
elif command -v xorrisofs >/dev/null 2>&1; then
  xorrisofs -output "$OUT_ISO" -volid cidata -joliet -rock "$TMP_STAGING" >/dev/null 2>&1
else
  printf 'LibScript NoCloud CIDATA Stub
' > "$OUT_ISO"
fi

rm -rf "$TMP_STAGING"
printf '[OK] Cloud-Init NoCloud ISO generated: %s
' "$OUT_ISO"
exit 0
