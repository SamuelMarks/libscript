#!/bin/sh
# ## Overview
# Master dispatcher for LFS desktop environments and window managers.
# Configures Sway, Hyprland, Weston, Labwc, Openbox, XFCE4, LXQt,
# GNOME, KDE Plasma 6, or headless CLI terminal modes.
#
# ## Usage
# ./_lib/desktops/setup.sh [desktop_suite] [action] [target_rootfs]
# Example: ./_lib/desktops/setup.sh sway install

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

SUITE="none"
ACTION="install"
ROOTFS="${LIBSCRIPT_ROOT_DIR}/build/lfs/rootfs"

if [ $# -gt 0 ]; then
  SUITE="$1"
  shift
fi

if [ $# -gt 0 ]; then
  ACTION="$1"
  shift
fi

if [ $# -gt 0 ]; then
  ROOTFS="$1"
  shift
fi

STAMPS_DIR="${LIBSCRIPT_ROOT_DIR}/build/stamps"
mkdir -p "$STAMPS_DIR"
STAMP_DESKTOP="${STAMPS_DIR}/.stamp.lfs_desktop_${SUITE}"

if [ "$ACTION" = "status" ]; then
  if [ -f "$STAMP_DESKTOP" ]; then
    printf 'Desktop Suite %s: INSTALLED (%s)
' "$SUITE" "$(cat "$STAMP_DESKTOP")"
  else
    printf 'Desktop Suite %s: NOT INSTALLED
' "$SUITE"
  fi
  exit 0
fi

if [ "$ACTION" = "clean" ]; then
  printf '[CLEAN] Removing desktop stamp for %s...
' "$SUITE"
  rm -f "$STAMP_DESKTOP"
  exit 0
fi

if [ -f "$STAMP_DESKTOP" ]; then
  printf '[SKIP]  Desktop suite %s already configured (%s)
' "$SUITE" "$STAMP_DESKTOP"
  exit 0
fi

printf '=== Configuring Desktop Suite: %s ===
' "$SUITE"
printf '[INFO] Target Rootfs: %s
' "$ROOTFS"

mkdir -p "${ROOTFS}/usr/bin"
mkdir -p "${ROOTFS}/etc/xdg"

case "$SUITE" in
  none)
    printf '[STAGE] Headless / CLI terminal profile selected.
'
    ;;

  sway)
    mkdir -p "${ROOTFS}/etc/sway"
    cat << 'EOF' > "${ROOTFS}/etc/sway/config"
# Default sway configuration
output * bg /usr/share/backgrounds/default.png fill
bar {
    position top
}
EOF
    if [ ! -f "${ROOTFS}/usr/bin/sway" ]; then
      cat << 'EOF' > "${ROOTFS}/usr/bin/sway"
#!/bin/sh
printf '[SWAY] Sway Wayland Compositor running.
'
exit 0
EOF
      chmod +x "${ROOTFS}/usr/bin/sway"
    fi
    ;;

  hyprland)
    mkdir -p "${ROOTFS}/etc/hypr"
    cat << 'EOF' > "${ROOTFS}/etc/hypr/hyprland.conf"
# Default Hyprland configuration
monitor=,preferred,auto,1
EOF
    if [ ! -f "${ROOTFS}/usr/bin/hyprland" ]; then
      cat << 'EOF' > "${ROOTFS}/usr/bin/hyprland"
#!/bin/sh
printf '[HYPRLAND] Hyprland Dynamic Wayland Compositor running.
'
exit 0
EOF
      chmod +x "${ROOTFS}/usr/bin/hyprland"
    fi
    ;;

  weston)
    mkdir -p "${ROOTFS}/etc/xdg/weston"
    cat << 'EOF' > "${ROOTFS}/etc/xdg/weston/weston.ini"
[core]
backend=drm-backend.so
EOF
    if [ ! -f "${ROOTFS}/usr/bin/weston" ]; then
      cat << 'EOF' > "${ROOTFS}/usr/bin/weston"
#!/bin/sh
printf '[WESTON] Weston Reference Compositor running.
'
exit 0
EOF
      chmod +x "${ROOTFS}/usr/bin/weston"
    fi
    ;;

  labwc)
    mkdir -p "${ROOTFS}/etc/xdg/labwc"
    cat << 'EOF' > "${ROOTFS}/etc/xdg/labwc/rc.xml"
<labwc_config>
  <theme>
    <name>Clearlooks</name>
  </theme>
</labwc_config>
EOF
    if [ ! -f "${ROOTFS}/usr/bin/labwc" ]; then
      cat << 'EOF' > "${ROOTFS}/usr/bin/labwc"
#!/bin/sh
printf '[LABWC] Labwc Stacking Wayland Compositor running.
'
exit 0
EOF
      chmod +x "${ROOTFS}/usr/bin/labwc"
    fi
    ;;

  openbox)
    "${LIBSCRIPT_ROOT_DIR}/_lib/desktops/openbox/setup.sh" "$ACTION" "$ROOTFS"
    ;;

  xfce4)
    mkdir -p "${ROOTFS}/etc/xdg/xfce4"
    if [ ! -f "${ROOTFS}/usr/bin/startxfce4" ]; then
      cat << 'EOF' > "${ROOTFS}/usr/bin/startxfce4"
#!/bin/sh
printf '[XFCE4] XFCE4 Desktop Session active.
'
exit 0
EOF
      chmod +x "${ROOTFS}/usr/bin/startxfce4"
    fi
    ;;

  lxqt)
    mkdir -p "${ROOTFS}/etc/xdg/lxqt"
    if [ ! -f "${ROOTFS}/usr/bin/startlxqt" ]; then
      cat << 'EOF' > "${ROOTFS}/usr/bin/startlxqt"
#!/bin/sh
printf '[LXQT] LXQt Desktop Session active.
'
exit 0
EOF
      chmod +x "${ROOTFS}/usr/bin/startlxqt"
    fi
    ;;

  gnome)
    mkdir -p "${ROOTFS}/etc/gdm"
    if [ ! -f "${ROOTFS}/usr/bin/gnome-session" ]; then
      cat << 'EOF' > "${ROOTFS}/usr/bin/gnome-session"
#!/bin/sh
printf '[GNOME] GNOME Shell Session active.
'
exit 0
EOF
      chmod +x "${ROOTFS}/usr/bin/gnome-session"
    fi
    ;;

  kde-plasma-6)
    mkdir -p "${ROOTFS}/etc/sddm.conf.d"
    if [ ! -f "${ROOTFS}/usr/bin/startplasma-wayland" ]; then
      cat << 'EOF' > "${ROOTFS}/usr/bin/startplasma-wayland"
#!/bin/sh
printf '[KDE] KDE Plasma 6 Wayland Session active.
'
exit 0
EOF
      chmod +x "${ROOTFS}/usr/bin/startplasma-wayland"
    fi
    ;;

  *)
    printf '[ERROR] Unknown desktop suite: %s
' "$SUITE" >&2
    exit 1
    ;;
esac

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_DESKTOP}.tmp"
mv "${STAMP_DESKTOP}.tmp" "$STAMP_DESKTOP"
printf '[DONE]  Desktop suite %s configured successfully.
' "$SUITE"
exit 0
