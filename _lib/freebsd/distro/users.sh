#!/bin/sh
# ## Overview
# Provisions user accounts, passwords, wheel/operator groups, doas/sudo rules,
# and SSH public keys (including standard Vagrant insecure key) in FreeBSD target sysroot.
#
# ## Usage
# Provision users in sysroot:
#   _lib/freebsd/distro/users.sh [sysroot_path] [primary_user]

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
PRIMARY_USER="${2:-vagrant}"

STAMP_DIR="${SYSROOT}/.libscript_stamps"
STAMP_FILE="${STAMP_DIR}/users.stamp"

mkdir -p "${STAMP_DIR}"
mkdir -p "${SYSROOT}/etc"
mkdir -p "${SYSROOT}/usr/local/etc"
mkdir -p "${SYSROOT}/usr/local/etc/sudoers.d"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     FreeBSD users already provisioned in %s
' "${SYSROOT}"
  exit 0
fi

printf '[USERS]    Provisioning user accounts and security policies (%s)...
' "${PRIMARY_USER}"

# 1. doas.conf configuration (permit nopass :wheel)
cat << 'EOF' > "${SYSROOT}/usr/local/etc/doas.conf"
# doas.conf (managed by LibScript)
permit nopass keepenv :wheel
permit nopass keepenv root
EOF
chmod 0600 "${SYSROOT}/usr/local/etc/doas.conf" 2>/dev/null || true

# 2. sudoers configuration (permit nopass %wheel)
cat << 'EOF' > "${SYSROOT}/usr/local/etc/sudoers.d/00-wheel-nopass"
# sudoers rule for wheel group (managed by LibScript)
%wheel ALL=(ALL:ALL) NOPASSWD: ALL
EOF
chmod 0440 "${SYSROOT}/usr/local/etc/sudoers.d/00-wheel-nopass" 2>/dev/null || true

# 3. Create home directory and SSH keys for primary user
USER_HOME="${SYSROOT}/home/${PRIMARY_USER}"
mkdir -p "${USER_HOME}/.ssh"
chmod 0700 "${USER_HOME}" "${USER_HOME}/.ssh"

# Vagrant official insecure public key
cat << 'EOF' > "${USER_HOME}/.ssh/authorized_keys"
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLX6OKMQe1tRJyUk2LaKOqq4TLncREaqq5461b4wuSiUcMSKncsysyrsF21jrr5RsMtZVCnB955iVDD57Gh/O5KeGq88hEl7ZgpTNY4LCmpMZPV3NFWWDtYnuUIIggbJYJvKeOtnBgN+/yV+JQVCyb++t5xRQ3CzCd5KsvYXvRauMQBQjzcUuc276Q== vagrant insecure public key
EOF
chmod 0600 "${USER_HOME}/.ssh/authorized_keys"

# Also place into /root/.ssh for automated provisioning if desired
mkdir -p "${SYSROOT}/root/.ssh"
chmod 0700 "${SYSROOT}/root/.ssh"
cp "${USER_HOME}/.ssh/authorized_keys" "${SYSROOT}/root/.ssh/authorized_keys"
chmod 0600 "${SYSROOT}/root/.ssh/authorized_keys"

# 4. In native FreeBSD host, invoke pw useradd if chrooted
if [ "$(uname -s 2>/dev/null || true)" = "FreeBSD" ] && command -v pw >/dev/null 2>&1; then
  pw -R "${SYSROOT}" groupadd -n wheel -g 0 2>/dev/null || true
  pw -R "${SYSROOT}" groupadd -n operator -g 2 2>/dev/null || true
  pw -R "${SYSROOT}" groupadd -n video -g 44 2>/dev/null || true
  pw -R "${SYSROOT}" useradd -n "${PRIMARY_USER}" -u 1001 -g wheel -G operator,video -d "/home/${PRIMARY_USER}" -s "/bin/sh" -c "LibScript User" 2>/dev/null || true
  echo "${PRIMARY_USER}" | pw -R "${SYSROOT}" usermod -n "${PRIMARY_USER}" -h 0 2>/dev/null || true
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       FreeBSD user provisioning completed.
'
