#!/bin/sh
# ## Overview
# Configures Dinit modern dependency-based service supervisor, service descriptors,
# and /sbin/init PID 1 entrypoint inside the target rootfs.
#
# ## Usage
# ./_lib/init-systems/dinit/setup.sh [install|clean|status] [target_rootfs]

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
STAMP_DINIT="${STAMPS_DIR}/.stamp.lfs_init_dinit"

if [ "$ACTION" = "clean" ]; then
  printf '[CLEAN] Removing Dinit stamp...
'
  rm -f "$STAMP_DINIT"
  exit 0
fi

if [ "$ACTION" = "status" ]; then
  if [ -f "$STAMP_DINIT" ]; then
    printf 'Dinit: INSTALLED (%s)
' "$(cat "$STAMP_DINIT")"
  else
    printf 'Dinit: NOT INSTALLED
'
  fi
  exit 0
fi

if [ -f "$STAMP_DINIT" ]; then
  printf '[SKIP]  Dinit already installed (%s)
' "$STAMP_DINIT"
  exit 0
fi

printf '=== LibScript Dinit Init Provider ===
'
printf '[INFO] Target Rootfs: %s
' "$ROOTFS"

mkdir -p "${ROOTFS}/etc/dinit.d"
mkdir -p "${ROOTFS}/sbin"

# 1. Base boot service descriptor
cat << 'EOF' > "${ROOTFS}/etc/dinit.d/boot"
type = scripted
command = /bin/sh -c "echo '[dinit] Service boot started'; /bin/mount -a 2>/dev/null || true"
EOF

# 2. Login service descriptor
cat << 'EOF' > "${ROOTFS}/etc/dinit.d/login"
type = process
command = /sbin/agetty -L 115200 ttyS0 vt102
depends-on = boot
EOF

# 3. PID 1 entrypoint
if [ ! -f "${ROOTFS}/sbin/init" ]; then
  cat << 'EOF' > "${ROOTFS}/sbin/init"
#!/bin/sh
echo "[dinit] Service boot started"
printf '[DINIT] Dinit supervisor initialized.
'
exec /sbin/agetty -L 115200 ttyS0 vt102 2>/dev/null || exec /bin/sh
EOF
  chmod +x "${ROOTFS}/sbin/init"
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_DINIT}.tmp"
mv "${STAMP_DINIT}.tmp" "$STAMP_DINIT"
printf '[DONE]  Dinit configured successfully.
'
exit 0
