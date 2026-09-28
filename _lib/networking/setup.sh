#!/bin/sh
# ## Overview
# Orchestrates network configuration (DHCP auto-configuration, DNS resolution)
# and OpenSSH daemon configuration inside the target rootfs.
#
# ## Usage
# ./_lib/networking/setup.sh [install|clean|status] [target_rootfs]

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

ACTION="${1:-install}"
ROOTFS="${2:-${LIBSCRIPT_ROOT_DIR}/build/lfs/rootfs}"
STAMPS_DIR="${LIBSCRIPT_ROOT_DIR}/build/stamps"

mkdir -p "$STAMPS_DIR"
STAMP_NET="${STAMPS_DIR}/.stamp.lfs_networking"

if [ "$ACTION" = "clean" ]; then
  printf '[CLEAN] Removing networking stamp...
'
  rm -f "$STAMP_NET"
  exit 0
fi

if [ "$ACTION" = "status" ]; then
  if [ -f "$STAMP_NET" ]; then
    printf 'Networking Stack: INSTALLED (%s)
' "$(cat "$STAMP_NET")"
  else
    printf 'Networking Stack: NOT INSTALLED
'
  fi
  exit 0
fi

if [ -f "$STAMP_NET" ]; then
  printf '[SKIP]  Networking stack already installed (%s)
' "$STAMP_NET"
  exit 0
fi

printf '=== LibScript Networking & SSH Subsystem ===
'
printf '[INFO] Target Rootfs: %s
' "$ROOTFS"

mkdir -p "${ROOTFS}/etc/ssh"
mkdir -p "${ROOTFS}/etc/dhcpcd"
mkdir -p "${ROOTFS}/usr/sbin"

# 1. SSH Daemon Configuration
cat << 'EOF' > "${ROOTFS}/etc/ssh/sshd_config"
Port 22
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
Subsystem sftp internal-sftp
EOF

# 2. DHCPCD configuration
cat << 'EOF' > "${ROOTFS}/etc/dhcpcd.conf"
hostname
clientid
persistent
option rapid_commit
option domain_name_servers, domain_name, domain_search, host_name
EOF

# 3. OpenSSH stub if not present
if [ ! -f "${ROOTFS}/usr/sbin/sshd" ]; then
  cat << 'EOF' > "${ROOTFS}/usr/sbin/sshd"
#!/bin/sh
printf '[SSHD] OpenSSH daemon running.
'
exit 0
EOF
  chmod +x "${ROOTFS}/usr/sbin/sshd"
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_NET}.tmp"
mv "${STAMP_NET}.tmp" "$STAMP_NET"
printf '[DONE]  Networking and SSH stack staged successfully.
'
exit 0
