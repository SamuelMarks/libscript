#!/bin/sh
# ## Overview
# Generic setup module for QEMU and KVM hardware virtualization.
#
# ## Usage
# Sourced by setup.sh to install QEMU, libvirt, firmware, and configure permissions.

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
export DIR="${SCRIPT_DIR}"

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/env.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh" "_lib/_common/priv.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

QEMU_INSTALL_METHOD="$(libscript_resolve_install_method "QEMU")"
ACTION="${ACTION:-install}"
QEMU_SETUP_KVM_GROUPS="${QEMU_SETUP_KVM_GROUPS:-1}"
QEMU_SETUP_UEFI_FIRMWARE="${QEMU_SETUP_UEFI_FIRMWARE:-1}"

# ## setup_uefi_symlinks
# Configures standard UEFI firmware symlinks for QEMU/KVM.
setup_uefi_symlinks() {
  log_info "Configuring QEMU/OVMF UEFI firmware symlinks in /usr/local/share/qemu..."
  priv mkdir -p /usr/local/share/qemu

  # x86_64 code
  for path in /usr/share/OVMF/OVMF_CODE.fd /usr/share/edk2/ovmf/OVMF_CODE.fd /usr/share/qemu/OVMF.fd; do
    if [ -f "$path" ]; then
      priv ln -sf "$path" /usr/local/share/qemu/edk2-x86_64-code.fd
      break
    fi
  done

  # x86_64 vars
  for path in /usr/share/OVMF/OVMF_VARS.fd /usr/share/edk2/ovmf/OVMF_VARS.fd; do
    if [ -f "$path" ]; then
      priv ln -sf "$path" /usr/local/share/qemu/edk2-i386-vars.fd
      break
    fi
  done

  # aarch64 code
  for path in /usr/share/AAVMF/AAVMF_CODE.fd /usr/share/qemu-efi-aarch64/QEMU_EFI.fd /usr/share/edk2/aarch64/QEMU_EFI.fd; do
    if [ -f "$path" ]; then
      priv ln -sf "$path" /usr/local/share/qemu/edk2-aarch64-code.fd
      break
    fi
  done

  # aarch64 vars
  for path in /usr/share/AAVMF/AAVMF_VARS.fd /usr/share/edk2/aarch64/QEMU_VARS.fd; do
    if [ -f "$path" ]; then
      priv ln -sf "$path" /usr/local/share/qemu/edk2-arm-vars.fd
      break
    fi
  done
}

# ## setup_kvm_permissions
# Configures /dev/kvm permissions and group access.
setup_kvm_permissions() {
  if [ -e "/dev/kvm" ]; then
    priv chmod 666 /dev/kvm 2>/dev/null || true
  fi
  if [ -d "/etc/udev/rules.d" ]; then
    printf 'KERNEL=="kvm", GROUP="kvm", MODE="0666"\n' | priv tee /etc/udev/rules.d/65-kvm.rules >/dev/null 2>&1 || true
  fi
}

# ## setup_libvirt_network
# Ensures default libvirt NAT network is configured and started.
setup_libvirt_network() {
  if command -v virsh >/dev/null 2>&1; then
    for net_file in /etc/libvirt/qemu/networks/default.xml /usr/share/libvirt/networks/default.xml; do
      if [ -f "$net_file" ]; then
        priv virsh net-define "$net_file" 2>/dev/null || true
        priv virsh net-autostart default 2>/dev/null || true
        priv virsh net-start default 2>/dev/null || true
        break
      fi
    done
  fi
}

# ## setup_user_groups
# Adds the current user to libvirt and kvm groups.
setup_user_groups() {
  target_user="${SUDO_USER:-$(id -un)}"
  if [ "$target_user" = "root" ]; then
    return 0
  fi

  for grp in kvm libvirt; do
    if getent group "$grp" >/dev/null 2>&1; then
      log_info "Adding user $target_user to group $grp..."
      priv usermod -aG "$grp" "$target_user" 2>/dev/null || true
    fi
  done
}

case "$ACTION" in
  ls)
    if command -v qemu-system-x86_64 >/dev/null 2>&1; then
      qemu-system-x86_64 --version | head -n 1
    elif command -v qemu-img >/dev/null 2>&1; then
      qemu-img --version | head -n 1
    else
      printf '%s
' "QEMU not installed."
    fi
    exit 0
    ;;
  ls-remote)
    printf '%s
' "Managed via system package manager."
    exit 0
    ;;
  install)
    log_info "Installing QEMU and virtualization packages via ${QEMU_INSTALL_METHOD}..."
    if [ "$QEMU_INSTALL_METHOD" = "system" ]; then
      libscript_depends "qemu"
    elif [ "$QEMU_INSTALL_METHOD" = "brew" ]; then
      brew install qemu
    fi

    if [ "$QEMU_SETUP_UEFI_FIRMWARE" = "1" ] && [ "${TARGET_OS}" != "darwin" ]; then
      setup_uefi_symlinks
    fi

    if [ "$QEMU_SETUP_KVM_GROUPS" = "1" ] && [ "${TARGET_OS}" != "darwin" ]; then
      setup_user_groups
      setup_kvm_permissions
    fi

    if command -v systemctl >/dev/null 2>&1; then
      if systemctl list-unit-files libvirtd.service >/dev/null 2>&1; then
        log_info "Starting and enabling libvirtd service..."
        priv systemctl enable --now libvirtd 2>/dev/null || true
        setup_libvirt_network
      fi
    fi
    ;;
  uninstall)
    log_info "Uninstalling QEMU..."
    case "${PKG_MGR}" in
      'apt-get')
        priv apt-get remove -y qemu-system-x86 qemu-utils libvirt-daemon-system || true
        ;;
      'brew')
        brew uninstall qemu || true
        ;;
      'dnf'|'yum')
        priv "${PKG_MGR}" remove -y qemu-kvm libvirt || true
        ;;
    esac
    exit 0
    ;;
  start|stop|restart|status)
    if command -v systemctl >/dev/null 2>&1; then
      priv systemctl "$ACTION" libvirtd
    fi
    exit 0
    ;;
esac
