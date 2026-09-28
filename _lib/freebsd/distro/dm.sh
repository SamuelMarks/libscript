#!/bin/sh
# ## Overview
# Configures modular display managers (lightdm, sddm, greetd, gdm, or none)
# and autologin/pam security policies inside FreeBSD target sysroot.
#
# ## Usage
# Configure display manager:
#   _lib/freebsd/distro/dm.sh [sysroot_path] [dm] [autologin_user]

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
DM="${2:-none}"
AUTOLOGIN_USER="${3:-}"

STAMP_DIR="${SYSROOT}/.libscript_stamps"
STAMP_FILE="${STAMP_DIR}/dm_${DM}.stamp"

mkdir -p "${STAMP_DIR}"
mkdir -p "${SYSROOT}/etc"
mkdir -p "${SYSROOT}/usr/local/etc"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     FreeBSD display manager %s already configured in %s
' "${DM}" "${SYSROOT}"
  exit 0
fi

printf '[DM]       Configuring display manager: %s...
' "${DM}"

case "${DM}" in
  none)
    printf '[DM]       No display manager requested (console getty login).
'
    ;;

  lightdm)
    if ! grep -q 'lightdm_enable="YES"' "${SYSROOT}/etc/rc.conf" 2>/dev/null; then
      printf 'lightdm_enable="YES"\n' >> "${SYSROOT}/etc/rc.conf"
    fi
    mkdir -p "${SYSROOT}/usr/local/etc/lightdm"
    if [ -n "${AUTOLOGIN_USER}" ]; then
      cat << EOF > "${SYSROOT}/usr/local/etc/lightdm/lightdm.conf"
[Seat:*]
autologin-user=${AUTOLOGIN_USER}
autologin-user-timeout=0
user-session=xfce
EOF
    fi
    ;;

  sddm)
    if ! grep -q 'sddm_enable="YES"' "${SYSROOT}/etc/rc.conf" 2>/dev/null; then
      printf 'sddm_enable="YES"\n' >> "${SYSROOT}/etc/rc.conf"
    fi
    mkdir -p "${SYSROOT}/usr/local/etc/sddm.conf.d"
    if [ -n "${AUTOLOGIN_USER}" ]; then
      cat << EOF > "${SYSROOT}/usr/local/etc/sddm.conf.d/autologin.conf"
[Autologin]
User=${AUTOLOGIN_USER}
Session=plasmawayland
EOF
    fi
    ;;

  greetd)
    if ! grep -q 'greetd_enable="YES"' "${SYSROOT}/etc/rc.conf" 2>/dev/null; then
      printf 'greetd_enable="YES"\n' >> "${SYSROOT}/etc/rc.conf"
    fi
    mkdir -p "${SYSROOT}/usr/local/etc/greetd"
    cat << 'EOF' > "${SYSROOT}/usr/local/etc/greetd/config.toml"
[terminal]
vt = 7

[default_session]
command = "tuigreet --time --remember --cmd sway"
user = "greeter"
EOF
    ;;

  gdm)
    if ! grep -q 'gdm_enable="YES"' "${SYSROOT}/etc/rc.conf" 2>/dev/null; then
      printf 'gdm_enable="YES"\n' >> "${SYSROOT}/etc/rc.conf"
    fi
    ;;

  *)
    printf '[WARN]     Unknown display manager "%s", skipping.
' "${DM}" >&2
    ;;
esac

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       Display manager %s configured.
' "${DM}"
