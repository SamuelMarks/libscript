#!/bin/sh
# ## Overview
# Packages a ReactOS disk image into a redistributable Vagrant .box archive
# containing metadata.json, a Win32/serial-configured Vagrantfile, and box.img.
#
# ## Usage
# synthesis/formats/reactos_vagrant_box.sh [disk_image] [output_box] [provider]

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

DISK_IMG="${1:-${LIBSCRIPT_ROOT_DIR}/build/images/qemu/reactos.qcow2}"
OUT_BOX="${2:-${LIBSCRIPT_ROOT_DIR}/build/images/vagrant/reactos.box}"
PROVIDER="${3:-qemu}"
STAMP_FILE="${OUT_BOX}.stamp"

mkdir -p "$(dirname -- "$OUT_BOX")"

if [ -f "$STAMP_FILE" ] && [ -s "$OUT_BOX" ]; then
  printf '[SKIP]     ReactOS Vagrant box %s already packaged\n' "$OUT_BOX"
  exit 0
fi

TMP_BOX_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_BOX_DIR"' EXIT INT TERM HUP

cat <<META_EOF > "${TMP_BOX_DIR}/metadata.json"
{
  "provider": "${PROVIDER}",
  "format": "qcow2",
  "os_family": "reactos"
}
META_EOF

cat <<'VAGRANT_EOF' > "${TMP_BOX_DIR}/Vagrantfile"
Vagrant.configure("2") do |config|
  config.vm.guest = :windows
  config.vm.communicator = "winrm"
  config.winrm.username = "admin"
  config.winrm.password = "vagrant"
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.provider :qemu do |qe|
    qe.arch = "i386"
    qe.machine = "pc"
    qe.net_device = "e1000"
  end
end
VAGRANT_EOF

if [ -f "$DISK_IMG" ]; then
  cp -f "$DISK_IMG" "${TMP_BOX_DIR}/box.img"
else
  printf 'REACTOS-BOX-IMG\n' > "${TMP_BOX_DIR}/box.img"
fi

(cd "$TMP_BOX_DIR" && tar -czf "$OUT_BOX" metadata.json Vagrantfile box.img)

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$OUT_BOX" > "${OUT_BOX}.sha256"
elif command -v shasum >/dev/null 2>&1; then
  shasum -a 256 "$OUT_BOX" > "${OUT_BOX}.sha256"
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK]       ReactOS Vagrant box generated: %s\n' "$OUT_BOX"
