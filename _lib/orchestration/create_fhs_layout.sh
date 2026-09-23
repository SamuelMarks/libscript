#!/bin/sh
# ## Overview
# Initializes a standard Filesystem Hierarchy Standard (FHS) directory layout
# within a target sysroot, populating default configuration skeletons
# (/etc/passwd, /etc/group, /etc/hosts, /etc/profile) and setting permissions.
#
# ## Usage
# Execute with target sysroot directory:
#   ./_lib/orchestration/create_fhs_layout.sh <target_sysroot>

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

TARGET_DIR="${1:-${LIBSCRIPT_TARGET_SYSROOT:-}}"

if [ -z "$TARGET_DIR" ]; then
  printf '[ERROR] Target sysroot directory required.
' >&2
  printf 'Usage: %s <target_sysroot>
' "$THIS_FILE" >&2
  exit 1
fi

STAMP_DIR="$TARGET_DIR/var/lib/libscript/stamps"
mkdir -p "$STAMP_DIR"
if [ -f "$STAMP_DIR/.stamp.fhs_layout" ]; then
  printf '[INFO] FHS layout already initialized at %s. Skipping.
' "$TARGET_DIR"
  exit 0
fi

printf '[INFO] Creating standard FHS layout in %s...
' "$TARGET_DIR"

# 1. Standard directories
mkdir -p "$TARGET_DIR/bin"
mkdir -p "$TARGET_DIR/sbin"
mkdir -p "$TARGET_DIR/etc"
mkdir -p "$TARGET_DIR/usr/bin"
mkdir -p "$TARGET_DIR/usr/sbin"
mkdir -p "$TARGET_DIR/usr/lib"
mkdir -p "$TARGET_DIR/usr/include"
mkdir -p "$TARGET_DIR/usr/share"
mkdir -p "$TARGET_DIR/usr/local/bin"
mkdir -p "$TARGET_DIR/usr/local/sbin"
mkdir -p "$TARGET_DIR/usr/local/lib"
mkdir -p "$TARGET_DIR/usr/local/share"
mkdir -p "$TARGET_DIR/var/log"
mkdir -p "$TARGET_DIR/var/run"
mkdir -p "$TARGET_DIR/var/lib"
mkdir -p "$TARGET_DIR/var/cache"
mkdir -p "$TARGET_DIR/var/tmp"
mkdir -p "$TARGET_DIR/tmp"
mkdir -p "$TARGET_DIR/boot"
mkdir -p "$TARGET_DIR/dev"
mkdir -p "$TARGET_DIR/proc"
mkdir -p "$TARGET_DIR/sys"
mkdir -p "$TARGET_DIR/mnt"
mkdir -p "$TARGET_DIR/opt"
mkdir -p "$TARGET_DIR/root"
mkdir -p "$TARGET_DIR/home"

chmod 1777 "$TARGET_DIR/tmp" "$TARGET_DIR/var/tmp" 2>/dev/null || true
chmod 0700 "$TARGET_DIR/root" 2>/dev/null || true

# Symlink /run -> var/run or var/run -> run if needed
if [ ! -e "$TARGET_DIR/run" ]; then
  ln -sf var/run "$TARGET_DIR/run" 2>/dev/null || mkdir -p "$TARGET_DIR/run"
fi

# 2. Skeleton configuration files (idempotent creation)
if [ ! -f "$TARGET_DIR/etc/passwd" ]; then
  cat <<'EOF' > "$TARGET_DIR/etc/passwd"
root:x:0:0:root:/root:/bin/sh
daemon:x:1:1:daemon:/usr/sbin:/bin/false
bin:x:2:2:bin:/bin:/bin/false
sys:x:3:3:sys:/dev:/bin/false
nobody:x:65534:65534:nobody:/:/bin/false
EOF
fi

if [ ! -f "$TARGET_DIR/etc/group" ]; then
  cat <<'EOF' > "$TARGET_DIR/etc/group"
root:x:0:
daemon:x:1:
bin:x:2:
sys:x:3:
adm:x:4:
tty:x:5:
disk:x:6:
wheel:x:10:root
sudo:x:27:
audio:x:29:
video:x:44:
input:x:104:
kvm:x:108:
nogroup:x:65534:
EOF
fi

if [ ! -f "$TARGET_DIR/etc/shadow" ]; then
  cat <<'EOF' > "$TARGET_DIR/etc/shadow"
root:*:19000:0:99999:7:::
daemon:*:19000:0:99999:7:::
bin:*:19000:0:99999:7:::
sys:*:19000:0:99999:7:::
nobody:*:19000:0:99999:7:::
EOF
  chmod 0600 "$TARGET_DIR/etc/shadow" 2>/dev/null || true
fi

if [ ! -f "$TARGET_DIR/etc/hosts" ]; then
  cat <<'EOF' > "$TARGET_DIR/etc/hosts"
127.0.0.1   localhost
::1         localhost ip6-localhost ip6-loopback
EOF
fi

if [ ! -f "$TARGET_DIR/etc/profile" ]; then
  cat <<'EOF' > "$TARGET_DIR/etc/profile"
export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"
export LANG="C.UTF-8"
export LC_ALL="C.UTF-8"
export PAGER="cat"
export EDITOR="vi"
umask 022
EOF
fi

if [ ! -f "$TARGET_DIR/etc/sh.shrc" ]; then
  cat <<'EOF' > "$TARGET_DIR/etc/sh.shrc"
# System-wide sh runtime configuration
PS1='\u@\h:\w\$ '
EOF
fi

if [ ! -f "$TARGET_DIR/etc/os-release" ]; then
  cat <<'EOF' > "$TARGET_DIR/etc/os-release"
NAME="LibScript OS"
ID="libscript"
PRETTY_NAME="LibScript Universal OS"
VERSION="1.0"
VERSION_ID="1.0"
HOME_URL="https://github.com/libscript/libscript"
EOF
fi

# 3. Sanitize ownership if running as root
if [ "$(id -u 2>/dev/null || printf '%s' '1000')" -eq 0 ]; then
  chown -R 0:0 "$TARGET_DIR" 2>/dev/null || true
fi

touch "$STAMP_DIR/.stamp.fhs_layout"
printf '[INFO] FHS layout successfully initialized: %s
' "$TARGET_DIR"
exit 0
