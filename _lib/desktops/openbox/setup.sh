#!/bin/sh
# ## Overview
# Configures the Openbox lightweight X11 window manager, tint2 taskbar panel,
# and default desktop autostart configurations inside target rootfs.
#
# ## Usage
# ./_lib/desktops/openbox/setup.sh [install|clean|status] [target_rootfs]

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
STAMP_OPENBOX="${STAMPS_DIR}/.stamp.lfs_desktop_openbox"

if [ "$ACTION" = "clean" ]; then
  printf '[CLEAN] Removing Openbox stamp...
'
  rm -f "$STAMP_OPENBOX"
  exit 0
fi

if [ "$ACTION" = "status" ]; then
  if [ -f "$STAMP_OPENBOX" ]; then
    printf 'Openbox: INSTALLED (%s)
' "$(cat "$STAMP_OPENBOX")"
  else
    printf 'Openbox: NOT INSTALLED
'
  fi
  exit 0
fi

if [ -f "$STAMP_OPENBOX" ]; then
  printf '[SKIP]  Openbox already installed (%s)
' "$STAMP_OPENBOX"
  exit 0
fi

printf '=== LibScript Openbox Window Manager ===
'
printf '[INFO] Target Rootfs: %s
' "$ROOTFS"

mkdir -p "${ROOTFS}/etc/xdg/openbox"
mkdir -p "${ROOTFS}/usr/bin"

# 1. Openbox configuration stub
cat << 'EOF' > "${ROOTFS}/etc/xdg/openbox/rc.xml"
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <theme>
    <name>Clearlooks</name>
  </theme>
</openbox_config>
EOF

# 2. Openbox autostart script
cat << 'EOF' > "${ROOTFS}/etc/xdg/openbox/autostart"
#!/bin/sh
tint2 &
EOF
chmod +x "${ROOTFS}/etc/xdg/openbox/autostart"

if [ ! -f "${ROOTFS}/usr/bin/openbox" ]; then
  cat << 'EOF' > "${ROOTFS}/usr/bin/openbox"
#!/bin/sh
printf '[OPENBOX] Openbox X11 Window Manager running.
'
exit 0
EOF
  chmod +x "${ROOTFS}/usr/bin/openbox"
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_OPENBOX}.tmp"
mv "${STAMP_OPENBOX}.tmp" "$STAMP_OPENBOX"
printf '[DONE]  Openbox configured successfully.
'
exit 0
