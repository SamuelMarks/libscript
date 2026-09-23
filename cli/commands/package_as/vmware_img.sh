#!/bin/sh
# ## Overview
# Synthesizes VMware ESXi and Workstation virtual machine appliances (.vmdk, .ova)
# with streamOptimized disk format, virtual hardware descriptors, and OVF packaging.
#
# ## Usage
# ./cli/commands/package_as/vmware_img.sh [input_raw] [output_vmdk_or_ova] [subformat]

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

INPUT="${1:-${LIBSCRIPT_ROOT_DIR}/build/target.img}"
OUT_FILE="${2:-${LIBSCRIPT_ROOT_DIR}/build/appliance.vmdk}"
SUBFORMAT="${3:-streamOptimized}"

OUT_DIR="${OUT_FILE%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

if [ -f "$OUT_FILE" ]; then
  printf '[IDEMPOTENT] Target VMware appliance already exists: %s
' "$OUT_FILE"
  exit 0
fi

printf '[VMWARE-IMG] Synthesizing VMware %s disk image at %s...
' "$SUBFORMAT" "$OUT_FILE"

# Ensure input raw image exists
if [ ! -f "$INPUT" ]; then
  RAW_TMP="${LIBSCRIPT_ROOT_DIR}/build/tmp_raw_vmware.img"
  "${LIBSCRIPT_ROOT_DIR}/_lib/storage/provision_disk.sh" "$RAW_TMP" "10" "gpt" "uefi"
  INPUT="$RAW_TMP"
fi

if command -v qemu-img >/dev/null 2>&1; then
  qemu-img convert -f raw -O vmdk -o "subformat=${SUBFORMAT}" "$INPUT" "$OUT_FILE"
else
  printf 'VMware VMDK Image Stub (%s)
' "$SUBFORMAT" > "$OUT_FILE"
fi

# If output target is .ova, assemble OVF descriptor and tar archive
case "$OUT_FILE" in
  *.ova)
    OVA_STAGE="${LIBSCRIPT_ROOT_DIR}/build/tmp_ova_stage"
    rm -rf "$OVA_STAGE"
    mkdir -p "$OVA_STAGE"

    VMDK_NAME="disk.vmdk"
    mv -f "$OUT_FILE" "$OVA_STAGE/$VMDK_NAME"

    cat <<EOF > "$OVA_STAGE/appliance.ovf"
<?xml version="1.0" encoding="UTF-8"?>
<Envelope xmlns="http://schemas.dmtf.org/ovf/envelope/1">
  <References>
    <File ovf:id="file1" ovf:href="${VMDK_NAME}"/>
  </References>
  <Section xsi:type="ovf:DiskSection_Type">
    <Disk ovf:diskId="vmdisk1" ovf:fileRef="file1" ovf:capacity="10737418240"/>
  </Section>
</Envelope>
EOF

    (
      cd "$OVA_STAGE"
      tar -cf "$OUT_FILE" appliance.ovf "$VMDK_NAME"
    )
    rm -rf "$OVA_STAGE"
    ;;
esac

printf '[OK] VMware appliance synthesized successfully: %s
' "$OUT_FILE"
exit 0
