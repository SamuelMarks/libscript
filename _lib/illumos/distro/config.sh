#!/bin/sh
# ## Overview
# Configures core illumos system files: /etc/nodename, /etc/hosts, /etc/default/login,
# /etc/nsswitch.conf, /etc/resolv.conf, and /boot/loader.conf serial console parameters.
#
# ## Usage
# Configure core system:
#   _lib/illumos/distro/config.sh [sysroot_path] [hostname] [dhcp]

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
HOSTNAME="${2:-illumos-distro}"
USE_DHCP="${3:-true}"

STAMP_DIR="${SYSROOT}/.libscript_stamps"
STAMP_FILE="${STAMP_DIR}/config.stamp"

mkdir -p "${STAMP_DIR}"
mkdir -p "${SYSROOT}/etc"
mkdir -p "${SYSROOT}/etc/default"
mkdir -p "${SYSROOT}/boot"

if [ -f "${STAMP_FILE}" ]; then
  printf '[SKIP]     illumos core configuration already applied in %s
' "${SYSROOT}"
  exit 0
fi

printf '[CONFIG]   Configuring core illumos files (hostname=%s, dhcp=%s)...
' "${HOSTNAME}" "${USE_DHCP}"

# 1. /etc/nodename and /etc/hosts
printf '%s
' "${HOSTNAME}" > "${SYSROOT}/etc/nodename"

cat << EOF > "${SYSROOT}/etc/hosts"
# IPv4 and IPv6 hosts table (managed by LibScript)
127.0.0.1       localhost
::1             localhost
127.0.0.1       ${HOSTNAME}
::1             ${HOSTNAME}
EOF

# 2. /etc/default/login and /etc/default/su
cat << 'EOF' > "${SYSROOT}/etc/default/login"
# Solaris / illumos login defaults
CONSOLE=/dev/console
PASSREQ=YES
UMASK=022
PATH=/usr/bin:/usr/sbin:/sbin
SUPATH=/usr/sbin:/usr/bin:/sbin
EOF

cat << 'EOF' > "${SYSROOT}/etc/default/su"
# Solaris / illumos su defaults
SULOG=/var/adm/sulog
CONSOLE=/dev/console
PATH=/usr/bin:/usr/sbin:/sbin
SUPATH=/usr/sbin:/usr/bin:/sbin
EOF

# 3. /etc/nsswitch.conf
cat << 'EOF' > "${SYSROOT}/etc/nsswitch.conf"
# /etc/nsswitch.conf (managed by LibScript)
passwd:     files
group:      files
hosts:      files dns
ipnodes:    files dns
networks:   files
protocols:  files
rpc:        files
ethers:     files
netmasks:   files
bootparams: files
publickey:  files
netgroup:   files
automount:  files
aliases:    files
services:   files
printers:   user files
auth_attr:  files
prof_attr:  files
project:    files
EOF

# 4. /etc/resolv.conf
cat << 'EOF' > "${SYSROOT}/etc/resolv.conf"
# DNS resolver configuration (managed by LibScript)
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

# 5. /boot/loader.conf (illumos loader configuration)
cat << 'EOF' > "${SYSROOT}/boot/loader.conf"
# illumos Loader Configuration (managed by LibScript)
autoboot_delay="2"
boot_multicons="YES"
boot_serial="YES"
console="ttya,text"
ttya-mode="115200,8,n,1,-"
os_console="ttya"
EOF

# 6. Network startup script stub (ipadm)
mkdir -p "${SYSROOT}/etc/svc/profile"
cat << EOF > "${SYSROOT}/etc/ipadm-bootstrap.sh"
#!/bin/sh
# Boot-time ipadm interface configuration
IFACE=\$(dladm show-phys -p -o link | head -n 1)
if [ -n "\${IFACE}" ]; then
  ipadm create-if "\${IFACE}" 2>/dev/null || true
  if [ "${USE_DHCP}" = "true" ]; then
    ipadm create-addr -T dhcp "\${IFACE}/v4" 2>/dev/null || true
  fi
fi
EOF
chmod +x "${SYSROOT}/etc/ipadm-bootstrap.sh" 2>/dev/null || true

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"

printf '[OK]       illumos core configuration complete: %s
' "${SYSROOT}"
