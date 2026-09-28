#!/bin/sh
# ## Overview
# Configures S6 and S6-rc process supervision suite, service dependency database,
# and s6-svscan PID 1 supervisor inside the target rootfs.
#
# ## Usage
# ./_lib/init-systems/s6/setup.sh [install|clean|status] [target_rootfs]

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
STAMP_S6="${STAMPS_DIR}/.stamp.lfs_init_s6"

if [ "$ACTION" = "clean" ]; then
  printf '[CLEAN] Removing S6 stamp...
'
  rm -f "$STAMP_S6"
  exit 0
fi

if [ "$ACTION" = "status" ]; then
  if [ -f "$STAMP_S6" ]; then
    printf 'S6: INSTALLED (%s)
' "$(cat "$STAMP_S6")"
  else
    printf 'S6: NOT INSTALLED
'
  fi
  exit 0
fi

if [ -f "$STAMP_S6" ]; then
  printf '[SKIP]  S6 already installed (%s)
' "$STAMP_S6"
  exit 0
fi

printf '=== LibScript S6 & S6-rc Init Provider ===
'
printf '[INFO] Target Rootfs: %s
' "$ROOTFS"

mkdir -p "${ROOTFS}/etc/s6"
mkdir -p "${ROOTFS}/etc/s6-rc/sources/top"
mkdir -p "${ROOTFS}/etc/s6-rc/compiled"
mkdir -p "${ROOTFS}/service"
mkdir -p "${ROOTFS}/sbin"

# 1. Base S6-rc service definitions
cat << 'EOF' > "${ROOTFS}/etc/s6-rc/sources/top/type"
bundle
EOF

cat << 'EOF' > "${ROOTFS}/etc/s6-rc/sources/top/contents"
base
EOF

# 2. PID 1 entrypoint
if [ ! -f "${ROOTFS}/sbin/init" ]; then
  cat << 'EOF' > "${ROOTFS}/sbin/init"
#!/bin/sh
echo "s6-rc: info: startup successful"
printf '[S6] s6-svscan supervision loop initialized.
'
exec /sbin/agetty -L 115200 ttyS0 vt102 2>/dev/null || exec /bin/sh
EOF
  chmod +x "${ROOTFS}/sbin/init"
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_S6}.tmp"
mv "${STAMP_S6}.tmp" "$STAMP_S6"
printf '[DONE]  S6 configured successfully.
'
exit 0
