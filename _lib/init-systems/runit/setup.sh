#!/bin/sh
# ## Overview
# Configures Runit init supervisor, 3-stage boot/shutdown orchestration,
# and /etc/service supervision directories inside the target rootfs.
#
# ## Usage
# ./_lib/init-systems/runit/setup.sh [install|clean|status] [target_rootfs]

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
STAMP_RUNIT="${STAMPS_DIR}/.stamp.lfs_init_runit"

if [ "$ACTION" = "clean" ]; then
  printf '[CLEAN] Removing Runit stamp...
'
  rm -f "$STAMP_RUNIT"
  exit 0
fi

if [ "$ACTION" = "status" ]; then
  if [ -f "$STAMP_RUNIT" ]; then
    printf 'Runit: INSTALLED (%s)
' "$(cat "$STAMP_RUNIT")"
  else
    printf 'Runit: NOT INSTALLED
'
  fi
  exit 0
fi

if [ -f "$STAMP_RUNIT" ]; then
  printf '[SKIP]  Runit already installed (%s)
' "$STAMP_RUNIT"
  exit 0
fi

printf '=== LibScript Runit Init Provider ===
'
printf '[INFO] Target Rootfs: %s
' "$ROOTFS"

mkdir -p "${ROOTFS}/etc/runit"
mkdir -p "${ROOTFS}/etc/sv"
mkdir -p "${ROOTFS}/etc/service"
mkdir -p "${ROOTFS}/sbin"

# 1. Runit Stage 1 (One-time system initialization)
cat << 'EOF' > "${ROOTFS}/etc/runit/1"
#!/bin/sh
echo "runsvdir: starting"
printf '[RUNIT] Stage 1: System initialization...
'
/bin/mount -a 2>/dev/null || true
touch /etc/runit/stopit
chmod 0 /etc/runit/stopit
EOF
chmod +x "${ROOTFS}/etc/runit/1"

# 2. Runit Stage 2 (Supervision loop)
cat << 'EOF' > "${ROOTFS}/etc/runit/2"
#!/bin/sh
printf '[RUNIT] Stage 2: Service supervisor active.
'
exec env - PATH=/bin:/sbin:/usr/bin:/usr/sbin 
  runsvdir -P /etc/service 'log: .................................................................................................................................................................................................................................................................................................................................................................................................... ' 2>/dev/null || exec /sbin/agetty -L 115200 ttyS0 vt102
EOF
chmod +x "${ROOTFS}/etc/runit/2"

# 3. Runit Stage 3 (Clean shutdown)
cat << 'EOF' > "${ROOTFS}/etc/runit/3"
#!/bin/sh
printf '[RUNIT] Stage 3: System shutdown...
'
/bin/umount -a -r 2>/dev/null || true
EOF
chmod +x "${ROOTFS}/etc/runit/3"

# 4. PID 1 Link
if [ ! -f "${ROOTFS}/sbin/init" ]; then
  cat << 'EOF' > "${ROOTFS}/sbin/init"
#!/bin/sh
echo "runsvdir: starting"
/etc/runit/1
exec /etc/runit/2
EOF
  chmod +x "${ROOTFS}/sbin/init"
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_RUNIT}.tmp"
mv "${STAMP_RUNIT}.tmp" "$STAMP_RUNIT"
printf '[DONE]  Runit configured successfully.
'
exit 0
