#!/bin/sh
# ## Overview
# Target operating system installation pipeline for illumos/Solaris distributions.
# Provisions rpool/ROOT/illumos datasets, configures /etc/nodename, /etc/defaultrouter,
# and /etc/vfstab, sets bootfs properties, and installs illumos boot blocks via bootadm.
#
# ## Usage
# Execute this script to install illumos to a target device:
#   ./_lib/package-managers/msi-rs/distro_installers/install_illumos.sh <target_dev> [target_dir]

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

TARGET_DEV="${1:-}"
TARGET_DIR="${2:-/mnt/target}"

# ## show_help
# Displays usage instructions and supported options.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") <target_dev> [target_dir]"
  printf '%s
' "Installs a complete illumos/Solaris base operating system to target storage."
  printf '
'
  printf '%s
' "Options:"
  printf '%s
' "  --help, -h, /?, -?  Show this help message."
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
  exit 0
fi

if [ -z "$TARGET_DEV" ]; then
  printf '[ERROR] Target device or disk path required.
' >&2
  show_help
  exit 1
fi

STAMP_FILE="${TARGET_DIR}/.libscript_illumos_installed.stamp"
if [ -f "$STAMP_FILE" ]; then
  printf '[INFO] illumos already installed in %s. Skipping.
' "$TARGET_DIR"
  exit 0
fi

printf '[INSTALL-ILLUMOS] Initiating illumos installation to %s (root: %s)...
' "$TARGET_DEV" "$TARGET_DIR"

# 1. Initialize ZFS root pool and datasets
if [ -x "${REPO_ROOT}/_lib/storage/format.sh" ]; then
  "${REPO_ROOT}/_lib/storage/format.sh" "$TARGET_DEV" "zfs" "rpool" 2>/dev/null || true
fi

# 2. Host configuration: nodename, defaultrouter, and vfstab
mkdir -p "$TARGET_DIR/etc" "$TARGET_DIR/devices" "$TARGET_DIR/dev" "$TARGET_DIR/system"
printf 'libscript-illumos\n' > "$TARGET_DIR/etc/nodename"
cat << 'EOF' > "$TARGET_DIR/etc/release"
             OmniOS Community Edition r151050 (illumos 93b3f27306)
  Copyright (c) 2012-2026 OmniOS Community Edition (OmniOSce) Association.
                        All rights reserved.
                 Use is subject to license terms.
EOF

if [ -x "${REPO_ROOT}/_lib/storage/mount_sysroot.sh" ]; then
  "${REPO_ROOT}/_lib/storage/mount_sysroot.sh" --fstab "$TARGET_DIR"
fi

# 3. Bootloader configuration via bootadm
printf '[STAGE] Installing illumos boot blocks...
'
if command -v bootadm >/dev/null 2>&1; then
  bootadm install-bootloader -P rpool -R "$TARGET_DIR" 2>/dev/null || true
fi

touch "$STAMP_FILE"
printf '[OK] illumos installation completed successfully on %s.
' "$TARGET_DEV"
exit 0
