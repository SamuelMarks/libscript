#!/bin/sh
# ## Overview
# Orchestrates Stage 3 LFS base system installation: constructs standard FHS 3.0
# filesystem hierarchy, configures essential system files (passwd, group, fstab,
# os-release, locale, networking defaults), and deploys essential base packages.
#
# ## Usage
# ./_lib/base-system/lfs-base/setup.sh [install|clean|status] [--hostname=lfs-node]

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

ACTION="install"
HOSTNAME="lfs-custom"

for arg in "$@"; do
  case "$arg" in
    install|clean|status)
      ACTION="$arg"
      ;;
    --hostname=*)
      HOSTNAME="${arg#*=}"
      ;;
    -h|--help)
      printf 'Usage: %s [install|clean|status] [--hostname=name]
' "$0"
      exit 0
      ;;
    *)
      ;;
  esac
done

LFS_ROOT="${LIBSCRIPT_ROOT_DIR}/build/lfs"
ROOTFS="${LFS_ROOT}/rootfs"
STAMPS_DIR="${LIBSCRIPT_ROOT_DIR}/build/stamps"

mkdir -p "$STAMPS_DIR"
STAMP_BASE="${STAMPS_DIR}/.stamp.lfs_base_system"

if [ "$ACTION" = "clean" ]; then
  printf '[CLEAN] Removing LFS base system stamp...
'
  rm -f "$STAMP_BASE"
  exit 0
fi

if [ "$ACTION" = "status" ]; then
  if [ -f "$STAMP_BASE" ]; then
    printf 'LFS Base System: INSTALLED (%s)
' "$(cat "$STAMP_BASE")"
  else
    printf 'LFS Base System: NOT INSTALLED
'
  fi
  exit 0
fi

if [ -f "$STAMP_BASE" ]; then
  printf '[SKIP]  LFS base system already installed (%s)
' "$STAMP_BASE"
  exit 0
fi

printf '=== LibScript LFS Base System & FHS Layout (Stage 3) ===
'
printf '[INFO] Rootfs:   %s
' "$ROOTFS"
printf '[INFO] Hostname: %s
' "$HOSTNAME"

# 1. Establish Standard FHS 3.0 Hierarchy
printf '[STAGE] Creating FHS directory layout...
'
mkdir -p "${ROOTFS}/bin"
mkdir -p "${ROOTFS}/boot/efi"
mkdir -p "${ROOTFS}/dev"
mkdir -p "${ROOTFS}/etc/opt"
mkdir -p "${ROOTFS}/etc/sysconfig"
mkdir -p "${ROOTFS}/etc/sudoers.d"
mkdir -p "${ROOTFS}/home/vagrant/.ssh"
mkdir -p "${ROOTFS}/lib"
mkdir -p "${ROOTFS}/mnt"
mkdir -p "${ROOTFS}/opt"
mkdir -p "${ROOTFS}/proc"
mkdir -p "${ROOTFS}/root"
mkdir -p "${ROOTFS}/run"
mkdir -p "${ROOTFS}/sbin"
mkdir -p "${ROOTFS}/srv"
mkdir -p "${ROOTFS}/sys"
mkdir -p "${ROOTFS}/tmp"
mkdir -p "${ROOTFS}/usr/bin"
mkdir -p "${ROOTFS}/usr/include"
mkdir -p "${ROOTFS}/usr/lib"
mkdir -p "${ROOTFS}/usr/local/bin"
mkdir -p "${ROOTFS}/usr/local/include"
mkdir -p "${ROOTFS}/usr/local/lib"
mkdir -p "${ROOTFS}/usr/local/sbin"
mkdir -p "${ROOTFS}/usr/local/share"
mkdir -p "${ROOTFS}/usr/sbin"
mkdir -p "${ROOTFS}/usr/share/man"
mkdir -p "${ROOTFS}/usr/share/misc"
mkdir -p "${ROOTFS}/usr/src"
mkdir -p "${ROOTFS}/var/cache"
mkdir -p "${ROOTFS}/var/lib"
mkdir -p "${ROOTFS}/var/lock"
mkdir -p "${ROOTFS}/var/log"
mkdir -p "${ROOTFS}/var/mail"
mkdir -p "${ROOTFS}/var/opt"
mkdir -p "${ROOTFS}/var/run"
mkdir -p "${ROOTFS}/var/spool"
mkdir -p "${ROOTFS}/var/tmp"

# FHS symlinks
ln -sf usr/bin "${ROOTFS}/bin_link" 2>/dev/null || true
chmod 1777 "${ROOTFS}/tmp" "${ROOTFS}/var/tmp" 2>/dev/null || true

# 2. Deploy Essential Identity & Authentication Files
printf '[STAGE] Configuring system identity files...
'
if [ ! -f "${ROOTFS}/etc/passwd" ]; then
  cat << 'EOF' > "${ROOTFS}/etc/passwd"
root:x:0:0:root:/root:/bin/sh
daemon:x:1:1:daemon:/usr/sbin:/bin/false
bin:x:2:2:bin:/bin:/bin/false
sys:x:3:3:sys:/dev:/bin/false
nobody:x:65534:65534:nobody:/nonexistent:/bin/false
vagrant:x:1000:1000:Vagrant User:/home/vagrant:/bin/sh
EOF
fi

if [ ! -f "${ROOTFS}/etc/group" ]; then
  cat << 'EOF' > "${ROOTFS}/etc/group"
root:x:0:
daemon:x:1:
bin:x:2:
sys:x:3:
adm:x:4:vagrant
tty:x:5:
disk:x:6:
wheel:x:10:vagrant
sudo:x:27:vagrant
audio:x:29:vagrant
video:x:44:vagrant
input:x:104:vagrant
nogroup:x:65534:
vagrant:x:1000:
EOF
fi

if [ ! -f "${ROOTFS}/etc/shadow" ]; then
  # vagrant password hash for 'vagrant'
  cat << 'EOF' > "${ROOTFS}/etc/shadow"
root:$6$rounds=4096$vgr$nZc49GfWjQ4Q6iGZ/kFj0Q0qgKx9v5ZzF3t1Uu8.:19000:0:99999:7:::
vagrant:$6$rounds=4096$vgr$nZc49GfWjQ4Q6iGZ/kFj0Q0qgKx9v5ZzF3t1Uu8.:19000:0:99999:7:::
EOF
  chmod 0600 "${ROOTFS}/etc/shadow" 2>/dev/null || true
fi

if [ ! -f "${ROOTFS}/etc/shells" ]; then
  cat << 'EOF' > "${ROOTFS}/etc/shells"
/bin/sh
/bin/bash
/bin/ash
EOF
fi

# 3. Deploy Filesystem Table & Release Information
printf '[STAGE] Configuring filesystem mounts and release metadata...
'
if [ ! -f "${ROOTFS}/etc/fstab" ]; then
  cat << 'EOF' > "${ROOTFS}/etc/fstab"
# /etc/fstab: static file system information
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
LABEL=lfs-root  /               ext4    defaults,noatime 0       1
LABEL=ESP       /boot/efi       vfat    defaults,noatime 0       2
tmpfs           /tmp            tmpfs   defaults,nosuid,nodev 0 0
devpts          /dev/pts        devpts  gid=5,mode=620   0       0
proc            /proc           proc    defaults         0       0
sysfs           /sys            sysfs   defaults         0       0
EOF
fi

if [ ! -f "${ROOTFS}/etc/os-release" ]; then
  cat << EOF > "${ROOTFS}/etc/os-release"
NAME="LibScript LFS"
ID=libscript-lfs
PRETTY_NAME="LibScript Linux From Scratch 1.0"
VERSION="1.0"
VERSION_ID="1.0"
HOME_URL="https://github.com/SamuelMarks/libscript"
SUPPORT_URL="https://github.com/SamuelMarks/libscript"
BUG_REPORT_URL="https://github.com/SamuelMarks/libscript/issues"
EOF
fi

# 4. Networking Defaults & Hostname
printf '[STAGE] Configuring hostname and network resolution...
'
printf '%s
' "$HOSTNAME" > "${ROOTFS}/etc/hostname"

if [ ! -f "${ROOTFS}/etc/hosts" ]; then
  cat << EOF > "${ROOTFS}/etc/hosts"
127.0.0.1   localhost
127.0.1.1   ${HOSTNAME}
::1         localhost ip6-localhost ip6-loopback
EOF
fi

if [ ! -f "${ROOTFS}/etc/resolv.conf" ]; then
  cat << 'EOF' > "${ROOTFS}/etc/resolv.conf"
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
fi

# 5. Vagrant Defaults & Sudoers
printf '[STAGE] Provisioning Vagrant user defaults and sudoers policies...
'
cat << 'EOF' > "${ROOTFS}/etc/sudoers.d/vagrant"
vagrant ALL=(ALL) NOPASSWD: ALL
EOF
chmod 0440 "${ROOTFS}/etc/sudoers.d/vagrant" 2>/dev/null || true

# Official Vagrant Insecure Public Key
cat << 'EOF' > "${ROOTFS}/home/vagrant/.ssh/authorized_keys"
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLX6OKMQqSEKDmkNXKZ05XX3Cc9BRTV/5TDvv095CoJhOOOTLub6/9qTUHHTc+/bur/898ellBogOWOOBlEZHY7KSaGsdPTIxA== vagrant insecure public key
EOF
chmod 0700 "${ROOTFS}/home/vagrant/.ssh" 2>/dev/null || true
chmod 0600 "${ROOTFS}/home/vagrant/.ssh/authorized_keys" 2>/dev/null || true

# 6. Global Profile & Environment
if [ ! -f "${ROOTFS}/etc/profile" ]; then
  cat << 'EOF' > "${ROOTFS}/etc/profile"
export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
export PAGER="less"
export EDITOR="vi"
if [ "$PS1" ]; then
  PS1='\u@\h:\w\$ '
fi
EOF
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_BASE}.tmp"
mv "${STAMP_BASE}.tmp" "$STAMP_BASE"
printf '[DONE]  LFS Base System initialized successfully.
'
exit 0
