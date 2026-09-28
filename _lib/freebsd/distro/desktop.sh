#!/bin/sh
# ## Overview
# Configures modular desktop environment and window manager staging
# inside FreeBSD target sysroot. Supports sway, hyprland, xfce4, kde-plasma-6,
# openbox, labwc, lxqt, gnome, weston, or none.
#
# ## Usage
# Configure desktop environment:
#   _lib/freebsd/distro/desktop.sh [sysroot_path] [environment] [username]

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
DESKTOP="${2:-none}"
PRIMARY_USER="${3:-freebsd}"

STAMP_DIR="${SYSROOT}/.libscript_stamps"
STAMP_FILE="${STAMP_DIR}/desktop_${DESKTOP}.stamp"

mkdir -p "${STAMP_DIR}"
USER_HOME="${SYSROOT}/home/${PRIMARY_USER}"
mkdir -p "${USER_HOME}"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     FreeBSD desktop %s already configured in %s
' "${DESKTOP}" "${SYSROOT}"
  exit 0
fi

printf '[DESKTOP]  Configuring desktop environment: %s...
' "${DESKTOP}"

case "${DESKTOP}" in
  none)
    printf '[DESKTOP]  CLI mode active; zero desktop startup scripts generated.
'
    ;;

  xfce4)
    cat << 'EOF' > "${USER_HOME}/.xinitrc"
#!/bin/sh
exec startxfce4
EOF
    chmod +x "${USER_HOME}/.xinitrc"
    ;;

  sway)
    mkdir -p "${USER_HOME}/.config/sway"
    cat << 'EOF' > "${USER_HOME}/.config/sway/config"
# Default minimal Sway configuration (managed by LibScript)
set $mod Mod4
set $term foot
bindsym $mod+Return exec $term
bindsym $mod+Shift+q kill
bindsym $mod+Shift+e exit
output * bg #1a1b26 solid_color
bar {
    position top
    status_command while date +'%Y-%m-%d %I:%M:%S %p'; do sleep 1; done
}
EOF
    ;;

  kde-plasma-6)
    cat << 'EOF' > "${USER_HOME}/.xinitrc"
#!/bin/sh
exec startplasma-x11
EOF
    chmod +x "${USER_HOME}/.xinitrc"
    ;;

  openbox)
    cat << 'EOF' > "${USER_HOME}/.xinitrc"
#!/bin/sh
exec openbox-session
EOF
    chmod +x "${USER_HOME}/.xinitrc"
    ;;

  hyprland|labwc|lxqt|gnome|weston)
    printf '[DESKTOP]  Staging base configuration for %s...
' "${DESKTOP}"
    mkdir -p "${USER_HOME}/.config/${DESKTOP}"
    ;;

  *)
    printf '[WARN]     Unknown desktop "%s", skipping config generation.
' "${DESKTOP}" >&2
    ;;
esac

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       Desktop %s configured.
' "${DESKTOP}"
