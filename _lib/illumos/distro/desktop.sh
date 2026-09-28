#!/bin/sh
# ## Overview
# Configures desktop environments (MATE, XFCE4, CDE, Openbox, or none) and user
# session startup scripts (.xsession, .xinitrc) inside the illumos target sysroot.
#
# ## Usage
# Configure desktop environment:
#   _lib/illumos/distro/desktop.sh [sysroot_path] [environment] [primary_user]

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
ENVIRONMENT="${2:-none}"
PRIMARY_USER="${3:-vagrant}"

STAMP_DIR="${SYSROOT}/.libscript_stamps"
STAMP_FILE="${STAMP_DIR}/desktop.stamp"

mkdir -p "${STAMP_DIR}"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     illumos desktop environment %s already configured in %s
' "${ENVIRONMENT}" "${SYSROOT}"
  exit 0
fi

printf '[DESKTOP]  Configuring illumos desktop environment %s (user: %s)...
' "${ENVIRONMENT}" "${PRIMARY_USER}"

USER_HOME="${SYSROOT}/export/home/${PRIMARY_USER}"
mkdir -p "${USER_HOME}"
mkdir -p "${SYSROOT}/etc/skel"

case "${ENVIRONMENT}" in
  none)
    # Headless: zero session scripts
    printf 'DESKTOP_ENV="none"
' > "${SYSROOT}/etc/desktop.conf"
    ;;

  mate)
    # MATE desktop environment
    cat << 'EOF' > "${USER_HOME}/.xinitrc"
#!/bin/sh
exec mate-session
EOF
    cp "${USER_HOME}/.xinitrc" "${USER_HOME}/.xsession"
    chmod +x "${USER_HOME}/.xinitrc" "${USER_HOME}/.xsession" 2>/dev/null || true
    printf 'DESKTOP_ENV="mate"
' > "${SYSROOT}/etc/desktop.conf"
    ;;

  xfce4)
    # XFCE4 desktop suite
    cat << 'EOF' > "${USER_HOME}/.xinitrc"
#!/bin/sh
exec startxfce4
EOF
    cp "${USER_HOME}/.xinitrc" "${USER_HOME}/.xsession"
    chmod +x "${USER_HOME}/.xinitrc" "${USER_HOME}/.xsession" 2>/dev/null || true
    printf 'DESKTOP_ENV="xfce4"
' > "${SYSROOT}/etc/desktop.conf"
    ;;

  cde)
    # Common Desktop Environment (CDE)
    cat << 'EOF' > "${USER_HOME}/.xinitrc"
#!/bin/sh
export PATH="/usr/dt/bin:${PATH}"
exec /usr/dt/bin/Xsession
EOF
    cp "${USER_HOME}/.xinitrc" "${USER_HOME}/.xsession"
    chmod +x "${USER_HOME}/.xinitrc" "${USER_HOME}/.xsession" 2>/dev/null || true
    printf 'DESKTOP_ENV="cde"
' > "${SYSROOT}/etc/desktop.conf"
    ;;

  openbox|fluxbox|i3|dwm)
    # Lightweight window manager
    cat << EOF > "${USER_HOME}/.xinitrc"
#!/bin/sh
exec ${ENVIRONMENT}
EOF
    cp "${USER_HOME}/.xinitrc" "${USER_HOME}/.xsession"
    chmod +x "${USER_HOME}/.xinitrc" "${USER_HOME}/.xsession" 2>/dev/null || true
    printf 'DESKTOP_ENV="%s"
' "${ENVIRONMENT}" > "${SYSROOT}/etc/desktop.conf"
    ;;

  *)
    printf '[WARN]     Unknown desktop environment: %s, defaulting to none
' "${ENVIRONMENT}" >&2
    printf 'DESKTOP_ENV="none"
' > "${SYSROOT}/etc/desktop.conf"
    ;;
esac

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"

printf '[OK]       illumos desktop environment configuration complete: %s
' "${SYSROOT}"
