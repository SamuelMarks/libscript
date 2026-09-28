#!/bin/sh
# ## Overview
# Configures SysVinit PID 1 supervisor, classic /etc/inittab runlevels,
# and SysV service control scripts inside the target rootfs.
#
# ## Usage
# ./_lib/init-systems/sysvinit/setup.sh [install|clean|status] [target_rootfs]

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

ACTION="${1:-install}"
ROOTFS="${2:-${LIBSCRIPT_ROOT_DIR}/build/lfs/rootfs}"
STAMPS_DIR="${LIBSCRIPT_ROOT_DIR}/build/stamps"

mkdir -p "$STAMPS_DIR"
STAMP_SYSVINIT="${STAMPS_DIR}/.stamp.lfs_init_sysvinit"

if [ "$ACTION" = "clean" ]; then
  printf '[CLEAN] Removing SysVinit stamp...
'
  rm -f "$STAMP_SYSVINIT"
  exit 0
fi

if [ "$ACTION" = "status" ]; then
  if [ -f "$STAMP_SYSVINIT" ]; then
    printf 'SysVinit: INSTALLED (%s)
' "$(cat "$STAMP_SYSVINIT")"
  else
    printf 'SysVinit: NOT INSTALLED
'
  fi
  exit 0
fi

if [ -f "$STAMP_SYSVINIT" ]; then
  printf '[SKIP]  SysVinit already installed (%s)
' "$STAMP_SYSVINIT"
  exit 0
fi

printf '=== LibScript SysVinit Init Provider ===
'
printf '[INFO] Target Rootfs: %s
' "$ROOTFS"

mkdir -p "${ROOTFS}/etc/init.d"
mkdir -p "${ROOTFS}/etc/rc.d/rc0.d"
mkdir -p "${ROOTFS}/etc/rc.d/rc1.d"
mkdir -p "${ROOTFS}/etc/rc.d/rc2.d"
mkdir -p "${ROOTFS}/etc/rc.d/rc3.d"
mkdir -p "${ROOTFS}/etc/rc.d/rc4.d"
mkdir -p "${ROOTFS}/etc/rc.d/rc5.d"
mkdir -p "${ROOTFS}/etc/rc.d/rc6.d"
mkdir -p "${ROOTFS}/sbin"

# 1. Classical /etc/inittab
cat << 'EOF' > "${ROOTFS}/etc/inittab"
# /etc/inittab for LibScript LFS SysVinit
id:3:initdefault:

si::sysinit:/etc/rc.d/init.d/rc sysinit

l0:0:wait:/etc/rc.d/init.d/rc 0
l1:1:wait:/etc/rc.d/init.d/rc 1
l2:2:wait:/etc/rc.d/init.d/rc 2
l3:3:wait:/etc/rc.d/init.d/rc 3
l4:4:wait:/etc/rc.d/init.d/rc 4
l5:5:wait:/etc/rc.d/init.d/rc 5
l6:6:wait:/etc/rc.d/init.d/rc 6

ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

1:2345:respawn:/sbin/agetty --noclear tty1 38400 linux
s0:2345:respawn:/sbin/agetty -L 115200 ttyS0 vt102
EOF

# 2. RC dispatcher script
cat << 'EOF' > "${ROOTFS}/etc/init.d/rc"
#!/bin/sh
# SysV runlevel controller
RUNLEVEL="$1"
printf '[INIT] Entering runlevel %s
' "$RUNLEVEL"
exit 0
EOF
chmod +x "${ROOTFS}/etc/init.d/rc"

if [ ! -f "${ROOTFS}/sbin/init" ]; then
  cat << 'EOF' > "${ROOTFS}/sbin/init"
#!/bin/sh
# SysVinit PID 1 entrypoint
echo "INIT: Entering runlevel: 3"
/etc/init.d/rc 3
exec /sbin/agetty -L 115200 ttyS0 vt102 2>/dev/null || exec /bin/sh
EOF
  chmod +x "${ROOTFS}/sbin/init"
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_SYSVINIT}.tmp"
mv "${STAMP_SYSVINIT}.tmp" "$STAMP_SYSVINIT"
printf '[DONE]  SysVinit configured successfully.
'
exit 0
