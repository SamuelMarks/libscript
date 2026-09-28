#!/bin/sh
# ## Overview
# Configures core FreeBSD system files inside target sysroot:
# /boot/loader.conf, /etc/rc.conf, /etc/fstab, /etc/ttys, and /etc/resolv.conf.
#
# ## Usage
# Configure core system:
#   _lib/freebsd/distro/config.sh [sysroot_path] [hostname] [filesystem]

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

SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${REPO_ROOT}/build/freebsd-sysroot}}"
HOSTNAME="${2:-freebsd-distro}"
FILESYSTEM="${3:-ufs2}"

STAMP_DIR="${SYSROOT}/.libscript_stamps"
STAMP_FILE="${STAMP_DIR}/config.stamp"

mkdir -p "${STAMP_DIR}"
mkdir -p "${SYSROOT}/boot"
mkdir -p "${SYSROOT}/etc"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     FreeBSD core configuration already applied in %s
' "${SYSROOT}"
  exit 0
fi

printf '[CONFIG]   Configuring core FreeBSD files (hostname=%s, fs=%s)...
' "${HOSTNAME}" "${FILESYSTEM}"

# 1. /boot/loader.conf
cat << 'EOF' > "${SYSROOT}/boot/loader.conf"
# FreeBSD Bootloader Configuration (managed by LibScript)
autoboot_delay="2"
boot_multicons="YES"
boot_serial="YES"
comconsole_speed="115200"
console="comconsole,vidconsole"
EOF

if [ "${FILESYSTEM}" = "zfs" ]; then
  cat << 'EOF' >> "${SYSROOT}/boot/loader.conf"
zfs_load="YES"
vfs.root.mountfrom="zfs:zroot/ROOT/default"
EOF
fi

# 2. /etc/rc.conf
cat << EOF > "${SYSROOT}/etc/rc.conf"
# FreeBSD System Configuration (managed by LibScript)
hostname="${HOSTNAME}"
ifconfig_DEFAULT="DHCP"
sshd_enable="YES"
sendmail_enable="NONE"
dumpdev="NO"
EOF

if [ "${FILESYSTEM}" = "zfs" ]; then
  printf 'zfs_enable="YES"
' >> "${SYSROOT}/etc/rc.conf"
fi

# 3. /etc/fstab
if [ "${FILESYSTEM}" = "zfs" ]; then
  cat << 'EOF' > "${SYSROOT}/etc/fstab"
# Device        Mountpoint      FStype  Options Dump    Pass#
/dev/gpt/efiboot0 /boot/efi     msdosfs rw,noatime 0    0
EOF
else
  cat << 'EOF' > "${SYSROOT}/etc/fstab"
# Device        Mountpoint      FStype  Options Dump    Pass#
/dev/gpt/rootfs   /               ufs     rw,noatime 1    1
/dev/gpt/efiboot0 /boot/efi       msdosfs rw,noatime 0    0
EOF
fi

# 4. /etc/ttys (enable serial console for headless VMs)
cat << 'EOF' > "${SYSROOT}/etc/ttys"
# FreeBSD Terminal Initialization (managed by LibScript)
ttyv0   "/usr/libexec/getty Pc"         xterm   on  secure
ttyv1   "/usr/libexec/getty Pc"         xterm   on  secure
ttyv2   "/usr/libexec/getty Pc"         xterm   on  secure
ttyu0   "/usr/libexec/getty 3wire.115200" vt100 on  secure
EOF

# 5. /etc/resolv.conf
cat << 'EOF' > "${SYSROOT}/etc/resolv.conf"
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       Core configuration generated successfully.
'
