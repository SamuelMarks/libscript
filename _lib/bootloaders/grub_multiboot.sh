#!/bin/sh
# ## Overview
# Generates GRUB2 configuration blocks for chainloading multiple operating systems.
# Synthesizes multiboot entries for Linux (direct initrd), FreeBSD (loader.efi chainload),
# and illumos (bootx64.efi multiboot2).
#
# ## Usage
#   ./_lib/bootloaders/grub_multiboot.sh [output_cfg]

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'

OUTPUT_CFG="${1:-/boot/grub/grub.cfg}"

# ## show_help
# Displays usage instructions.
show_help() {
  printf '%s\n' "Usage: $(basename "$THIS_FILE") [output_cfg]"
  printf '%s\n' "Generates a GRUB2 multiboot configuration file."
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
  exit 0
fi

printf '[BOOTLOADER] Synthesizing GRUB2 Multiboot configuration to %s...\n' "$OUTPUT_CFG"

mkdir -p "$(dirname "$OUTPUT_CFG")"

cat << 'EOF' > "$OUTPUT_CFG"
set default="0"
set timeout=5

menuentry "Linux (LibScript OS)" {
    search --no-floppy --fs-uuid --set=root LINUX_PART_UUID
    linux /boot/vmlinuz root=UUID=LINUX_PART_UUID ro quiet
    initrd /boot/initrd.img
}

menuentry "FreeBSD 15" {
    insmod part_gpt
    insmod fat
    search --no-floppy --file --set=root /EFI/freebsd/loader.efi
    chainloader /EFI/freebsd/loader.efi
}

menuentry "illumos (OmniOS)" {
    insmod part_gpt
    insmod zfs
    search --no-floppy --file --set=root /EFI/illumos/bootx64.efi
    chainloader /EFI/illumos/bootx64.efi
}
EOF

printf '[OK] Multiboot configuration generated successfully.\n'
exit 0
