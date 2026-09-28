#!/bin/sh
# ## Overview
# Configures display managers (LightDM, Slim, XDM, or console ttymon) and SMF graphical-login
# services inside the illumos target sysroot.
#
# ## Usage
# Configure display manager:
#   _lib/illumos/distro/dm.sh [sysroot_path] [display_manager] [autologin_user]

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

SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${REPO_ROOT}/build/illumos-sysroot}}"
DM="${2:-none}"
AUTOLOGIN_USER="${3:-}"

STAMP_DIR="${SYSROOT}/.libscript_stamps"
STAMP_FILE="${STAMP_DIR}/dm.stamp"

mkdir -p "${STAMP_DIR}"
mkdir -p "${SYSROOT}/etc"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     illumos display manager %s already configured in %s
' "${DM}" "${SYSROOT}"
  exit 0
fi

printf '[DM]       Configuring illumos display manager %s...
' "${DM}"

case "${DM}" in
  none)
    # Console login via ttymon
    printf 'DISPLAY_MANAGER="none"
' > "${SYSROOT}/etc/dm.conf"
    ;;

  lightdm)
    # LightDM graphical login manager
    mkdir -p "${SYSROOT}/etc/lightdm" "${SYSROOT}/etc/lightdm/lightdm.conf.d"
    cat << EOF > "${SYSROOT}/etc/lightdm/lightdm.conf"
# LightDM Configuration on illumos (managed by LibScript)
[Seat:*]
greeter-session=lightdm-gtk-greeter
user-session=default
EOF
    if [ -n "${AUTOLOGIN_USER}" ]; then
      cat << EOF >> "${SYSROOT}/etc/lightdm/lightdm.conf"
autologin-user=${AUTOLOGIN_USER}
autologin-user-timeout=0
EOF
    fi
    printf 'DISPLAY_MANAGER="lightdm"
' > "${SYSROOT}/etc/dm.conf"
    ;;

  slim)
    # Simple Login Manager (SLiM)
    cat << EOF > "${SYSROOT}/etc/slim.conf"
# SLiM configuration for illumos
default_path        /usr/bin:/usr/sbin:/sbin
login_cmd           exec /bin/sh - ~/.xinitrc
sessions            mate,xfce4,cde,openbox
EOF
    if [ -n "${AUTOLOGIN_USER}" ]; then
      cat << EOF >> "${SYSROOT}/etc/slim.conf"
auto_login          yes
default_user        ${AUTOLOGIN_USER}
EOF
    fi
    printf 'DISPLAY_MANAGER="slim"
' > "${SYSROOT}/etc/dm.conf"
    ;;

  xdm|dtlogin)
    # Classic XDM / dtlogin
    mkdir -p "${SYSROOT}/etc/X11/xdm"
    printf 'DISPLAY_MANAGER="%s"
' "${DM}" > "${SYSROOT}/etc/dm.conf"
    ;;

  *)
    printf '[WARN]     Unknown display manager: %s, defaulting to none
' "${DM}" >&2
    printf 'DISPLAY_MANAGER="none"
' > "${SYSROOT}/etc/dm.conf"
    ;;
esac

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"

printf '[OK]       illumos display manager configuration complete: %s
' "${SYSROOT}"
