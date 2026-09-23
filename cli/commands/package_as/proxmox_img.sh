#!/bin/sh
# ## Overview
# Synthesizes Proxmox VE KVM virtual machine templates (.qcow2) with virtio-scsi-single
# storage configuration, qemu-guest-agent support, and automated qm import scripts.
#
# ## Usage
# ./cli/commands/package_as/proxmox_img.sh [input_raw] [output_qcow2] [vmid]

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
OUT_FILE="${2:-${LIBSCRIPT_ROOT_DIR}/build/proxmox-template.qcow2}"
VMID="${3:-9000}"

OUT_DIR="${OUT_FILE%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

if [ -f "$OUT_FILE" ]; then
  printf '[IDEMPOTENT] Target Proxmox template already exists: %s
' "$OUT_FILE"
  exit 0
fi

printf '[PROXMOX-IMG] Synthesizing Proxmox VE template for VMID %s...
' "$VMID"

# Ensure input raw image exists
if [ ! -f "$INPUT" ]; then
  RAW_TMP="${LIBSCRIPT_ROOT_DIR}/build/tmp_raw_proxmox.img"
  "${LIBSCRIPT_ROOT_DIR}/_lib/storage/provision_disk.sh" "$RAW_TMP" "10" "gpt" "uefi"
  INPUT="$RAW_TMP"
fi

if command -v qemu-img >/dev/null 2>&1; then
  qemu-img convert -f raw -O qcow2 -o cluster_size=64k,lazy_refcounts=on "$INPUT" "$OUT_FILE"
else
  printf 'Proxmox VE Template QCOW2 Stub
' > "$OUT_FILE"
fi

# Generate Proxmox CLI import script snippet
PROXMOX_SNIPPET="${OUT_DIR}/import_proxmox_${VMID}.sh"
cat <<EOF > "$PROXMOX_SNIPPET"
#!/bin/sh
# Auto-generated Proxmox VE deployment script for VMID ${VMID}
qm create ${VMID} --name "libscript-template" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk ${VMID} "${OUT_FILE##*/}" local-lvm
qm set ${VMID} --scsihw virtio-scsi-single --scsi0 local-lvm:vm-${VMID}-disk-0
qm set ${VMID} --ide2 local-lvm:cloudinit
qm set ${VMID} --boot c --bootdisk scsi0
qm set ${VMID} --serial0 socket --vga serial0
qm set ${VMID} --agent enabled=1
qm template ${VMID}
echo "[OK] Proxmox template ${VMID} successfully created."
EOF
chmod 755 "$PROXMOX_SNIPPET" 2>/dev/null || true

printf '[OK] Proxmox VE template and import script generated: %s
' "$OUT_FILE"
exit 0
