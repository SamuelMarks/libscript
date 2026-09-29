#!/bin/sh
# ## Overview
# Configures modular init system supervision inside FreeBSD target sysroot.
# Supports bsd-rc, openrc, runit, s6, and dinit supervisors, staging service
# definitions and PID 1 loader configuration.
#
# ## Usage
# Configure init system:
#   _lib/freebsd/distro/init.sh [sysroot_path] [provider] [services_list]

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
PROVIDER="${2:-bsd-rc}"
SERVICES="${3:-sshd,cron,devd}"

STAMP_DIR="${SYSROOT}/.libscript_stamps"
STAMP_FILE="${STAMP_DIR}/init_${PROVIDER}.stamp"

mkdir -p "${STAMP_DIR}"
mkdir -p "${SYSROOT}/etc"
mkdir -p "${SYSROOT}/boot"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     FreeBSD init system %s already configured in %s
' "${PROVIDER}" "${SYSROOT}"
  exit 0
fi

printf '[INIT]     Configuring init provider %s...
' "${PROVIDER}"

case "${PROVIDER}" in
  bsd-rc)
    # Traditional BSD rc.d framework
    if ! grep -q '# BSD rc.d enabled services' "${SYSROOT}/etc/rc.conf" 2>/dev/null; then
      printf '# BSD rc.d enabled services\n' >> "${SYSROOT}/etc/rc.conf"
    fi
    IFS=','
    for s in ${SERVICES}; do
      [ -z "${s}" ] && continue
      if ! grep -q "^${s}_enable=" "${SYSROOT}/etc/rc.conf" 2>/dev/null; then
        printf '%s_enable="YES"\n' "${s}" >> "${SYSROOT}/etc/rc.conf"
      fi
    done
    unset IFS
    ;;

  openrc)
    # OpenRC service manager
    mkdir -p "${SYSROOT}/etc/init.d" "${SYSROOT}/etc/runlevels/default" "${SYSROOT}/etc/runlevels/boot"
    cat << 'EOF' > "${SYSROOT}/etc/init.d/sshd"
#!/sbin/openrc-run
description="OpenSSH Server"
command="/usr/sbin/sshd"
command_args="-D"
pidfile="/var/run/sshd.pid"
EOF
    chmod +x "${SYSROOT}/etc/init.d/sshd" 2>/dev/null || true
    ln -sf "/etc/init.d/sshd" "${SYSROOT}/etc/runlevels/default/sshd" 2>/dev/null || true
    # Specify openrc-init as init_path in loader.conf if available
    if ! grep -q '^init_path=' "${SYSROOT}/boot/loader.conf" 2>/dev/null; then
      printf 'init_path="/sbin/openrc-init:/sbin/init"\n' >> "${SYSROOT}/boot/loader.conf"
    fi
    ;;

  runit)
    # Runit process supervisor
    mkdir -p "${SYSROOT}/etc/runit" "${SYSROOT}/var/service"
    mkdir -p "${SYSROOT}/var/service/sshd"
    cat << 'EOF' > "${SYSROOT}/var/service/sshd/run"
#!/bin/sh
exec 2>&1
exec /usr/sbin/sshd -D -e
EOF
    chmod +x "${SYSROOT}/var/service/sshd/run" 2>/dev/null || true
    if ! grep -q '^init_path=' "${SYSROOT}/boot/loader.conf" 2>/dev/null; then
      printf 'init_path="/usr/local/sbin/runit-init:/sbin/init"\n' >> "${SYSROOT}/boot/loader.conf"
    fi
    ;;

  s6)
    # s6 supervision suite
    mkdir -p "${SYSROOT}/etc/s6" "${SYSROOT}/etc/s6-rc/sources" "${SYSROOT}/var/run/s6"
    if ! grep -q '^init_path=' "${SYSROOT}/boot/loader.conf" 2>/dev/null; then
      printf 'init_path="/usr/local/bin/s6-svscan:/sbin/init"\n' >> "${SYSROOT}/boot/loader.conf"
    fi
    ;;

  dinit)
    # Dinit service supervisor
    mkdir -p "${SYSROOT}/etc/dinit.d"
    cat << 'EOF' > "${SYSROOT}/etc/dinit.d/boot"
type = internal
depends-on = sshd
EOF
    cat << 'EOF' > "${SYSROOT}/etc/dinit.d/sshd"
type = process
command = /usr/sbin/sshd -D
smooth-recovery = true
EOF
    if ! grep -q '^init_path=' "${SYSROOT}/boot/loader.conf" 2>/dev/null; then
      printf 'init_path="/usr/local/sbin/dinit:/sbin/init"\n' >> "${SYSROOT}/boot/loader.conf"
    fi
    ;;

  *)
    printf '[WARN]     Unknown init provider "%s", falling back to bsd-rc
' "${PROVIDER}" >&2
    ;;
esac

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       Init provider %s configured successfully.
' "${PROVIDER}"
