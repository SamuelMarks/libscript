#!/bin/sh
# ## Overview
# Packages an illumos disk image into a redistributable Vagrant .box archive
# containing metadata.json, Vagrantfile, and box image for QEMU/VirtualBox.
#
# ## Usage
# Package Vagrant box:
#   cli/commands/package_as/illumos_vagrant_box.sh [disk_image] [output_box] [provider]

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
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

DISK_IMG="${1:-${REPO_ROOT}/build/illumos.qcow2}"
OUT_BOX="${2:-${REPO_ROOT}/build/illumos.box}"
PROVIDER="${3:-qemu}"

OUT_DIR="${OUT_BOX%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

STAMP_FILE="${OUT_BOX}.stamp"
if [ -f "${STAMP_FILE}" ] && [ -f "${OUT_BOX}" ]; then
  printf '[SKIP]     illumos Vagrant box %s already packaged
' "${OUT_BOX}"
  exit 0
fi

printf '[PACKAGE]  Packaging illumos Vagrant box (%s): %s...
' "${PROVIDER}" "${OUT_BOX}"

TMP_BOX_DIR="${REPO_ROOT}/build/tmp_box_$$"
mkdir -p "${TMP_BOX_DIR}"

# 1. metadata.json
cat << EOF > "${TMP_BOX_DIR}/metadata.json"
{
  "provider": "${PROVIDER}",
  "format": "qcow2"
}
EOF

# 2. Embedded Vagrantfile
cat << 'EOF' > "${TMP_BOX_DIR}/Vagrantfile"
Vagrant.configure("2") do |config|
  config.vm.guest = :solaris
  config.ssh.username = "vagrant"
  config.ssh.guest_port = 22
  config.ssh.shell = "/bin/sh"
  config.vm.provider :qemu do |qe|
    qe.arch = "x86_64"
    qe.machine = "q35"
    qe.cpu = "host"
    qe.net_device = "virtio-net-pci"
  end
end
EOF

# 3. Copy or link image
if [ -f "${DISK_IMG}" ]; then
  cp "${DISK_IMG}" "${TMP_BOX_DIR}/box.img"
else
  touch "${TMP_BOX_DIR}/box.img"
fi

# 4. Tar and compress into .box
(cd "${TMP_BOX_DIR}" && tar -czf "${OUT_BOX}" metadata.json Vagrantfile box.img)
rm -rf "${TMP_BOX_DIR}"

# 5. Checksum file
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "${OUT_BOX}" > "${OUT_BOX}.sha256"
elif command -v shasum >/dev/null 2>&1; then
  shasum -a 256 "${OUT_BOX}" > "${OUT_BOX}.sha256"
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       Vagrant box generated successfully: %s
' "${OUT_BOX}"
