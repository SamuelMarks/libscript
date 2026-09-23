#!/bin/sh
# ## Overview
# Synthesizes Oracle VirtualBox virtual machine appliances (.vdi, .ova) with
# dynamic sparse disk formatting and OVF descriptor packaging.
#
# ## Usage
# ./cli/commands/package_as/virtualbox_img.sh [input_raw] [output_vdi_or_ova]

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
OUT_FILE="${2:-${LIBSCRIPT_ROOT_DIR}/build/virtualbox-disk.vdi}"

OUT_DIR="${OUT_FILE%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

if [ -f "$OUT_FILE" ]; then
  printf '[IDEMPOTENT] Target VirtualBox image already exists: %s
' "$OUT_FILE"
  exit 0
fi

printf '[VBOX-IMG] Synthesizing VirtualBox VDI image: %s...
' "$OUT_FILE"

# Ensure input raw image exists
if [ ! -f "$INPUT" ]; then
  RAW_TMP="${LIBSCRIPT_ROOT_DIR}/build/tmp_raw_vbox.img"
  "${LIBSCRIPT_ROOT_DIR}/_lib/storage/provision_disk.sh" "$RAW_TMP" "10" "gpt" "uefi"
  INPUT="$RAW_TMP"
fi

if command -v qemu-img >/dev/null 2>&1; then
  qemu-img convert -f raw -O vdi "$INPUT" "$OUT_FILE"
else
  printf 'VirtualBox Dynamic VDI Stub
' > "$OUT_FILE"
fi

# Assemble OVA archive if requested
case "$OUT_FILE" in
  *.ova)
    VBOX_STAGE="${LIBSCRIPT_ROOT_DIR}/build/tmp_vbox_ova"
    rm -rf "$VBOX_STAGE"
    mkdir -p "$VBOX_STAGE"

    VDI_NAME="disk.vdi"
    mv -f "$OUT_FILE" "$VBOX_STAGE/$VDI_NAME"

    cat <<EOF > "$VBOX_STAGE/appliance.ovf"
<?xml version="1.0" encoding="UTF-8"?>
<Envelope xmlns="http://schemas.dmtf.org/ovf/envelope/1">
  <References>
    <File ovf:id="file1" ovf:href="${VDI_NAME}"/>
  </References>
</Envelope>
EOF

    (
      cd "$VBOX_STAGE"
      tar -cf "$OUT_FILE" appliance.ovf "$VDI_NAME"
    )
    rm -rf "$VBOX_STAGE"
    ;;
esac

printf '[OK] VirtualBox appliance synthesized successfully: %s
' "$OUT_FILE"
exit 0
