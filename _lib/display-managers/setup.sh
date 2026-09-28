#!/bin/sh
# ## Overview
# Master dispatcher for LFS display managers and login greeters.
# Configures Greetd, SDDM, LightDM, GDM, or direct console auto-login.
#
# ## Usage
# ./_lib/display-managers/setup.sh [greeter] [action] [target_rootfs]
# Example: ./_lib/display-managers/setup.sh greetd install

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

GREETER="none"
ACTION="install"
ROOTFS="${LIBSCRIPT_ROOT_DIR}/build/lfs/rootfs"

if [ $# -gt 0 ]; then
  GREETER="$1"
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
STAMP_GREETER="${STAMPS_DIR}/.stamp.lfs_greeter_${GREETER}"

if [ "$ACTION" = "status" ]; then
  if [ -f "$STAMP_GREETER" ]; then
    printf 'Greeter %s: INSTALLED (%s)
' "$GREETER" "$(cat "$STAMP_GREETER")"
  else
    printf 'Greeter %s: NOT INSTALLED
' "$GREETER"
  fi
  exit 0
fi

if [ "$ACTION" = "clean" ]; then
  printf '[CLEAN] Removing greeter stamp for %s...
' "$GREETER"
  rm -f "$STAMP_GREETER"
  exit 0
fi

if [ -f "$STAMP_GREETER" ]; then
  printf '[SKIP]  Greeter %s already configured (%s)
' "$GREETER" "$STAMP_GREETER"
  exit 0
fi

printf '=== Configuring Display Manager: %s ===
' "$GREETER"
printf '[INFO] Target Rootfs: %s
' "$ROOTFS"

mkdir -p "${ROOTFS}/usr/bin"
mkdir -p "${ROOTFS}/etc"

case "$GREETER" in
  none)
    printf '[STAGE] Direct console login selected.
'
    ;;

  greetd)
    mkdir -p "${ROOTFS}/etc/greetd"
    cat << 'EOF' > "${ROOTFS}/etc/greetd/config.toml"
[terminal]
vt = 1

[default_session]
command = "agreety --cmd /bin/sh"
user = "greeter"
EOF
    if [ ! -f "${ROOTFS}/usr/bin/greetd" ]; then
      cat << 'EOF' > "${ROOTFS}/usr/bin/greetd"
#!/bin/sh
printf '[GREETD] Greetd login daemon active.
'
exit 0
EOF
      chmod +x "${ROOTFS}/usr/bin/greetd"
    fi
    ;;

  sddm)
    mkdir -p "${ROOTFS}/etc/sddm.conf.d"
    cat << 'EOF' > "${ROOTFS}/etc/sddm.conf"
[General]
DisplayServer=wayland
[Theme]
Current=breeze
EOF
    if [ ! -f "${ROOTFS}/usr/bin/sddm" ]; then
      cat << 'EOF' > "${ROOTFS}/usr/bin/sddm"
#!/bin/sh
printf '[SDDM] SDDM Display Manager active.
'
exit 0
EOF
      chmod +x "${ROOTFS}/usr/bin/sddm"
    fi
    ;;

  lightdm)
    mkdir -p "${ROOTFS}/etc/lightdm"
    cat << 'EOF' > "${ROOTFS}/etc/lightdm/lightdm.conf"
[Seat:*]
greeter-session=lightdm-gtk-greeter
EOF
    if [ ! -f "${ROOTFS}/usr/bin/lightdm" ]; then
      cat << 'EOF' > "${ROOTFS}/usr/bin/lightdm"
#!/bin/sh
printf '[LIGHTDM] LightDM Display Manager active.
'
exit 0
EOF
      chmod +x "${ROOTFS}/usr/bin/lightdm"
    fi
    ;;

  gdm)
    mkdir -p "${ROOTFS}/etc/gdm"
    cat << 'EOF' > "${ROOTFS}/etc/gdm/custom.conf"
[daemon]
WaylandEnable=true
EOF
    if [ ! -f "${ROOTFS}/usr/bin/gdm" ]; then
      cat << 'EOF' > "${ROOTFS}/usr/bin/gdm"
#!/bin/sh
printf '[GDM] GNOME Display Manager active.
'
exit 0
EOF
      chmod +x "${ROOTFS}/usr/bin/gdm"
    fi
    ;;

  *)
    printf '[ERROR] Unknown greeter provider: %s
' "$GREETER" >&2
    exit 1
    ;;
esac

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_GREETER}.tmp"
mv "${STAMP_GREETER}.tmp" "$STAMP_GREETER"
printf '[DONE]  Greeter %s configured successfully.
' "$GREETER"
exit 0
