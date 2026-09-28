#!/bin/sh
# ## Overview
# Configures user accounts, RBAC execution profiles, passwordless sudoers,
# doas.conf, and SSH authorized keys inside the illumos target sysroot.
#
# ## Usage
# Provision users and RBAC:
#   _lib/illumos/distro/users.sh [sysroot_path] [primary_user]

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
PRIMARY_USER="${2:-vagrant}"

STAMP_DIR="${SYSROOT}/.libscript_stamps"
STAMP_FILE="${STAMP_DIR}/users.stamp"

mkdir -p "${STAMP_DIR}"
mkdir -p "${SYSROOT}/etc"
mkdir -p "${SYSROOT}/etc/sudoers.d"
mkdir -p "${SYSROOT}/export/home/${PRIMARY_USER}/.ssh"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     illumos users and RBAC already provisioned in %s
' "${SYSROOT}"
  exit 0
fi

printf '[USERS]    Provisioning illumos user accounts and RBAC (user: %s)...
' "${PRIMARY_USER}"

# 1. Base /etc/passwd and /etc/shadow
if [ ! -f "${SYSROOT}/etc/passwd" ]; then
  cat << 'EOF' > "${SYSROOT}/etc/passwd"
root:x:0:0:Super-User:/root:/bin/sh
daemon:x:1:1::/:
bin:x:2:2::/usr/bin:
sys:x:3:3::/:
adm:x:4:4:Admin:/var/adm:
noaccess:x:60002:60002:No Access User:/:
nobody:x:65534:65534:Nobody:/:
EOF
fi

if ! grep -q "^${PRIMARY_USER}:" "${SYSROOT}/etc/passwd" 2>/dev/null; then
  printf '%s:x:1000:10:%s User:/export/home/%s:/bin/sh
' 
    "${PRIMARY_USER}" "${PRIMARY_USER}" "${PRIMARY_USER}" >> "${SYSROOT}/etc/passwd"
fi

if [ ! -f "${SYSROOT}/etc/shadow" ]; then
  cat << 'EOF' > "${SYSROOT}/etc/shadow"
root::19000::::::
daemon:NP:6445::::::
bin:NP:6445::::::
sys:NP:6445::::::
adm:NP:6445::::::
noaccess:NP:6445::::::
nobody:NP:6445::::::
EOF
fi

if ! grep -q "^${PRIMARY_USER}:" "${SYSROOT}/etc/shadow" 2>/dev/null; then
  printf '%s::19000::::::
' "${PRIMARY_USER}" >> "${SYSROOT}/etc/shadow"
fi

# 2. Base /etc/group
if [ ! -f "${SYSROOT}/etc/group" ]; then
  cat << 'EOF' > "${SYSROOT}/etc/group"
root::0:
other::1:
bin::2:
sys::3:
adm::4:
staff::10:
sysadmin::14:
nogroup::65534:
EOF
fi

if ! grep -q "staff:.*${PRIMARY_USER}" "${SYSROOT}/etc/group" 2>/dev/null; then
  sed -i '' "s/^staff::10:/staff::10:${PRIMARY_USER}/" "${SYSROOT}/etc/group" 2>/dev/null || 
  sed -i "s/^staff::10:/staff::10:${PRIMARY_USER}/" "${SYSROOT}/etc/group" 2>/dev/null || true
fi

# 3. Solaris / illumos RBAC attributes (/etc/user_attr)
cat << EOF >> "${SYSROOT}/etc/user_attr"
# Solaris / illumos RBAC user attributes (managed by LibScript)
root::::type=normal;auths=solaris.*;profiles=All
${PRIMARY_USER}::::type=normal;profiles=Primary Administrator;defaultpriv=basic
EOF

# 4. Sudoers & doas
cat << EOF > "${SYSROOT}/etc/sudoers.d/${PRIMARY_USER}"
# LibScript passwordless sudo rule
${PRIMARY_USER} ALL=(ALL) NOPASSWD: ALL
EOF
chmod 0440 "${SYSROOT}/etc/sudoers.d/${PRIMARY_USER}" 2>/dev/null || true

cat << EOF > "${SYSROOT}/etc/doas.conf"
# OpenBSD / illumos doas configuration
permit nopass ${PRIMARY_USER} as root
EOF
chmod 0644 "${SYSROOT}/etc/doas.conf" 2>/dev/null || true

# 5. SSH authorized keys (Vagrant standard key)
VAGRANT_INSECURE_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjQKHWqvaDAfRqNVuiWCZCijNUQT7qvLo+8M8kXmZgHn8d79k0wE4bUu4f3t+48uXj0j4uC6K3yB7a1x2N9Z4aC8a0j7sF0r1d5V9o0K3l+2X1r3B5a8u9V0p1m8e4h7N6a7u9x3c1 vagrant insecure public key"
printf '%s
' "${VAGRANT_INSECURE_KEY}" > "${SYSROOT}/export/home/${PRIMARY_USER}/.ssh/authorized_keys"
chmod 0700 "${SYSROOT}/export/home/${PRIMARY_USER}/.ssh" 2>/dev/null || true
chmod 0600 "${SYSROOT}/export/home/${PRIMARY_USER}/.ssh/authorized_keys" 2>/dev/null || true

# 6. User environment (.profile)
cat << 'EOF' > "${SYSROOT}/export/home/${PRIMARY_USER}/.profile"
# User environment profile
export PATH="/usr/bin:/usr/sbin:/sbin:/opt/local/bin:/opt/local/sbin"
export PAGER="cat"
export EDITOR="vi"
EOF

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"

printf '[OK]       illumos user accounts and RBAC provisioned: %s
' "${SYSROOT}"
