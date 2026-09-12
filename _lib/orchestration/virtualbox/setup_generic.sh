#!/bin/sh
# ## Overview
# Generic setup module for Oracle VirtualBox and Extension Pack.
#
# ## Usage
# Sourced by setup.sh to configure repository, install VirtualBox, and install Extension Pack.

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

VIRTUALBOX_INSTALL_METHOD="$(libscript_resolve_install_method "VIRTUALBOX")"
ACTION="${ACTION:-install}"
VIRTUALBOX_INSTALL_EXTPACK="${VIRTUALBOX_INSTALL_EXTPACK:-1}"

# ## configure_virtualbox_repo_debian
# Configures the Oracle VirtualBox apt repository on Debian/Ubuntu systems.
configure_virtualbox_repo_debian() {
  if [ -f /etc/apt/sources.list.d/virtualbox.list ]; then
    return 0
  fi

  log_info "Configuring Oracle VirtualBox APT repository..."
  priv mkdir -p /usr/share/keyrings

  key_tmp=$(mktemp)
  curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc -o "$key_tmp"
  priv gpg --dearmor -o /usr/share/keyrings/virtualbox-archive-keyring.gpg --yes < "$key_tmp"
  rm -f "$key_tmp"

  codename="jammy"
  if command -v lsb_release >/dev/null 2>&1; then
    codename=$(lsb_release -cs 2>/dev/null || printf '%s' "jammy")
  fi

  printf 'deb [arch=amd64 signed-by=/usr/share/keyrings/virtualbox-archive-keyring.gpg] https://download.virtualbox.org/virtualbox/debian %s contrib
' "$codename" | priv tee /etc/apt/sources.list.d/virtualbox.list >/dev/null

  priv apt-get update -y
}

# ## install_extension_pack
# Downloads and installs the Oracle VM VirtualBox Extension Pack.
install_extension_pack() {
  if ! command -v VBoxManage >/dev/null 2>&1; then
    return 0
  fi

  vbox_ver=$(VBoxManage --version | cut -d 'r' -f 1)
  if [ -z "$vbox_ver" ]; then
    return 0
  fi

  ext_name="Oracle VM VirtualBox Extension Pack"
  if VBoxManage list extpacks 2>/dev/null | grep -q "$ext_name"; then
    log_info "VirtualBox Extension Pack is already installed."
    return 0
  fi

  log_info "Downloading and installing VirtualBox Extension Pack for version $vbox_ver..."
  extpack_url="https://download.virtualbox.org/virtualbox/${vbox_ver}/Oracle_VM_VirtualBox_Extension_Pack-${vbox_ver}.vbox-extpack"
  ext_dir=$(mktemp -d)
  ext_file="$ext_dir/Oracle_VM_VirtualBox_Extension_Pack-${vbox_ver}.vbox-extpack"

  if curl -fsSL "$extpack_url" -o "$ext_file"; then
    echo "y" | priv VBoxManage extpack install --replace "$ext_file" || true
    rm -rf "$ext_dir"
  else
    rm -rf "$ext_dir"
    log_warn "Could not download Extension Pack from $extpack_url"
  fi
}

# ## setup_user_groups
# Adds the current user to the vboxusers group.
setup_user_groups() {
  target_user="${SUDO_USER:-$(id -un)}"
  if [ "$target_user" = "root" ]; then
    return 0
  fi

  if getent group vboxusers >/dev/null 2>&1; then
    log_info "Adding user $target_user to group vboxusers..."
    priv usermod -aG vboxusers "$target_user" 2>/dev/null || true
  fi
}

case "$ACTION" in
  ls)
    if command -v VBoxManage >/dev/null 2>&1; then
      VBoxManage --version
    else
      printf '%s
' "VirtualBox not installed."
    fi
    exit 0
    ;;
  ls-remote)
    printf '%s
' "7.0"
    printf '%s
' "7.1"
    exit 0
    ;;
  install)
    log_info "Installing VirtualBox via ${VIRTUALBOX_INSTALL_METHOD}..."
    if [ "$VIRTUALBOX_INSTALL_METHOD" = "system" ]; then
      case "${PKG_MGR}" in
        'apt-get')
          configure_virtualbox_repo_debian
          kver=$(uname -r)
          priv apt-get install -y "linux-headers-$kver" build-essential dkms 2>/dev/null || true
          libscript_depends "virtualbox"
          ;;
        'brew')
          brew install --cask virtualbox
          ;;
        *)
          libscript_depends "virtualbox"
          ;;
      esac
    fi

    if [ "${TARGET_OS}" != "darwin" ]; then
      setup_user_groups
    fi

    if [ "$VIRTUALBOX_INSTALL_EXTPACK" = "1" ]; then
      install_extension_pack
    fi
    ;;
  uninstall)
    log_info "Uninstalling VirtualBox..."
    case "${PKG_MGR}" in
      'apt-get')
        priv apt-get remove -y virtualbox-7.0 virtualbox 2>/dev/null || true
        ;;
      'brew')
        brew uninstall --cask virtualbox 2>/dev/null || true
        ;;
      'dnf'|'yum')
        priv "${PKG_MGR}" remove -y VirtualBox-7.0 virtualbox 2>/dev/null || true
        ;;
    esac
    exit 0
    ;;
esac
