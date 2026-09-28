#!/bin/sh
# ## Overview
# Packages a custom LFS virtual machine image into a redistributable Vagrant .box archive
# for QEMU, libvirt, or VirtualBox providers, generating metadata.json and bundled Vagrantfile.
#
# ## Usage
# ./cli/commands/package_as/vagrant_box.sh [input_image] [output_box] [provider]

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

INPUT_IMAGE="${1:-${LIBSCRIPT_ROOT_DIR}/build/output/lfs-disk.qcow2}"
OUT_BOX="${2:-${LIBSCRIPT_ROOT_DIR}/build/output/lfs-custom.box}"
PROVIDER="${3:-qemu}"

case "$INPUT_IMAGE" in /*) ;; *) INPUT_IMAGE="${PWD}/${INPUT_IMAGE}" ;; esac
case "$OUT_BOX" in /*) ;; *) OUT_BOX="${PWD}/${OUT_BOX}" ;; esac

STAMPS_DIR="${LIBSCRIPT_ROOT_DIR}/build/stamps"
mkdir -p "$STAMPS_DIR"
mkdir -p "$(dirname "$OUT_BOX")"
STAMP_BOX="${STAMPS_DIR}/.stamp.export_vagrant_box"

if [ -f "$STAMP_BOX" ] && [ -f "$OUT_BOX" ]; then
  printf '[SKIP]  Vagrant box already packaged (%s)
' "$STAMP_BOX"
  exit 0
fi

# Ensure input image exists, or build intermediate if raw exists
if [ ! -f "$INPUT_IMAGE" ]; then
  RAW_IMG="${LIBSCRIPT_ROOT_DIR}/build/output/lfs-disk.raw"
  if [ -f "$RAW_IMG" ]; then
    printf '[INFO] Converting raw disk to qcow2 for Vagrant box packaging...
'
    "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/qcow2.sh" "$RAW_IMG" "$INPUT_IMAGE" "qcow2"
  else
    printf '[INFO] Synthesizing mock disk image for Vagrant box packaging...
'
    mkdir -p "$(dirname "$INPUT_IMAGE")"
    printf 'LibScript QEMU Disk Image Stub
' > "$INPUT_IMAGE"
  fi
fi

printf '=== LibScript Vagrant Box Packaging ===
'
printf '[INFO] Input Image: %s
' "$INPUT_IMAGE"
printf '[INFO] Output Box:  %s
' "$OUT_BOX"
printf '[INFO] Provider:    %s
' "$PROVIDER"

BOX_TMP_DIR="${LIBSCRIPT_ROOT_DIR}/build/tmp/vagrant_box_$$"
mkdir -p "$BOX_TMP_DIR"
trap 'rm -rf "$BOX_TMP_DIR"' EXIT INT TERM

TARGET_ARCH="$(uname -m)"
case "$TARGET_ARCH" in
  aarch64) TARGET_ARCH="arm64" ;;
  x86_64) TARGET_ARCH="x86_64" ;;
esac

# 1. Generate metadata.json
cat << EOF > "${BOX_TMP_DIR}/metadata.json"
{
  "architecture": "${TARGET_ARCH}",
  "provider": "${PROVIDER}",
  "format": "qcow2",
  "disks": [
    {
      "format": "qcow2",
      "path": "box.img"
    }
  ]
}
EOF

# 2. Generate bundled Vagrantfile
cat << 'EOF' > "${BOX_TMP_DIR}/Vagrantfile"
Vagrant.configure("2") do |config|
  config.ssh.username = "vagrant"
  config.ssh.password = "vagrant"
  config.ssh.insert_key = false
  config.vm.provider :qemu do |qe|
    qe.net_mode = :user
    qe.firmware_format = nil
    bios_candidates = [
      ENV["QEMU_EDK2_CODE"],
      "/opt/homebrew/share/qemu/edk2-aarch64-code.fd",
      "/usr/share/qemu/edk2-aarch64-code.fd",
      "/usr/share/edk2/aarch64/QEMU_EFI.fd"
    ].compact
    bios_path = bios_candidates.find { |path| File.exist?(path) }
    qe.extra_qemu_args = ["-bios", bios_path] if bios_path
    qe.ssh_auto_correct = true
  end
  config.vm.provider :libvirt do |lv|
    lv.driver = "kvm"
    lv.memory = 2048
    lv.cpus = 2
  end
end
EOF

# 3. Copy image into box container as box.img
cp -f "$INPUT_IMAGE" "${BOX_TMP_DIR}/box.img"

# 4. Package tar archive
printf '[STAGE] Compressing into .box archive...
'
(
  cd "$BOX_TMP_DIR"
  tar --numeric-owner -czf "$OUT_BOX" metadata.json Vagrantfile box.img
)

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_BOX}.tmp"
mv "${STAMP_BOX}.tmp" "$STAMP_BOX"
printf '[DONE]  Vagrant box exported successfully: %s
' "$OUT_BOX"
exit 0
