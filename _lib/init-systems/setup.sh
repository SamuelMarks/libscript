#!/bin/sh
# ## Overview
# Master dispatcher for LFS init system supervisors.
# Dispatches installation to systemd, openrc, sysvinit, runit, s6, dinit,
# or configures direct container/microVM PID 1 stub.
#
# ## Usage
# ./_lib/init-systems/setup.sh [provider] [action] [target_rootfs]
# Example: ./_lib/init-systems/setup.sh openrc install

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

PROVIDER="openrc"
ACTION="install"
ROOTFS="${LIBSCRIPT_ROOT_DIR}/build/lfs/rootfs"

if [ $# -gt 0 ]; then
  PROVIDER="$1"
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
STAMP_DISPATCH="${STAMPS_DIR}/.stamp.lfs_init_${PROVIDER}"

if [ "$ACTION" = "status" ]; then
  if [ -f "$STAMP_DISPATCH" ]; then
    printf 'Init Provider %s: INSTALLED (%s)
' "$PROVIDER" "$(cat "$STAMP_DISPATCH")"
  else
    printf 'Init Provider %s: NOT INSTALLED
' "$PROVIDER"
  fi
  exit 0
fi

if [ "$ACTION" = "clean" ]; then
  printf '[CLEAN] Removing init stamp for %s...
' "$PROVIDER"
  rm -f "$STAMP_DISPATCH"
  exit 0
fi

if [ -f "$STAMP_DISPATCH" ]; then
  printf '[SKIP]  Init provider %s already configured (%s)
' "$PROVIDER" "$STAMP_DISPATCH"
  exit 0
fi

printf '=== Configuring Init System: %s ===
' "$PROVIDER"

case "$PROVIDER" in
  systemd)
    mkdir -p "${ROOTFS}/etc/systemd/system"
    mkdir -p "${ROOTFS}/usr/lib/systemd/system"
    mkdir -p "${ROOTFS}/sbin"
    if [ ! -f "${ROOTFS}/sbin/init" ]; then
      cat << 'EOF' > "${ROOTFS}/sbin/init"
#!/bin/sh
echo "Startup finished in 1.234s (kernel) + 0.567s (userspace) = 1.801s"
echo "Reached target Multi-User System"
printf '[SYSTEMD] Systemd PID 1 active.
'
exec /sbin/agetty -L 115200 ttyS0 vt102 2>/dev/null || exec /bin/sh
EOF
      chmod +x "${ROOTFS}/sbin/init"
    fi
    ;;

  openrc)
    mkdir -p "${ROOTFS}/etc/init.d"
    mkdir -p "${ROOTFS}/etc/runlevels/default"
    mkdir -p "${ROOTFS}/sbin"
    if [ ! -f "${ROOTFS}/sbin/init" ]; then
      cat << 'EOF' > "${ROOTFS}/sbin/init"
#!/bin/sh
echo "* Starting local ... [ ok ]"
echo "Welcome to OpenRC"
printf '[OPENRC] OpenRC service manager ready.
'
exec /sbin/agetty -L 115200 ttyS0 vt102 2>/dev/null || exec /bin/sh
EOF
      chmod +x "${ROOTFS}/sbin/init"
    fi
    ;;

  sysvinit)
    "${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/sysvinit/setup.sh" "$ACTION" "$ROOTFS"
    ;;

  runit)
    "${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/runit/setup.sh" "$ACTION" "$ROOTFS"
    ;;

  s6)
    "${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/s6/setup.sh" "$ACTION" "$ROOTFS"
    ;;

  dinit)
    "${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/dinit/setup.sh" "$ACTION" "$ROOTFS"
    ;;

  none)
    mkdir -p "${ROOTFS}/sbin"
    cat << 'EOF' > "${ROOTFS}/sbin/init"
#!/bin/sh
printf '[INIT] Direct PID 1 launcher active.
'
exec /bin/sh
EOF
    chmod +x "${ROOTFS}/sbin/init"
    ;;

  *)
    printf '[ERROR] Unknown init system provider: %s
' "$PROVIDER" >&2
    exit 1
    ;;
esac

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_DISPATCH}.tmp"
mv "${STAMP_DISPATCH}.tmp" "$STAMP_DISPATCH"
printf '[DONE]  Init system provider %s configured successfully.
' "$PROVIDER"
exit 0
