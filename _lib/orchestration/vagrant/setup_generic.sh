#!/bin/sh
# ## Overview
# Generic setup module for HashiCorp Vagrant and plugins.
#
# ## Usage
# Sourced by setup.sh to configure repository, install Vagrant, and install plugins.

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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

VAGRANT_INSTALL_METHOD="$(libscript_resolve_install_method "VAGRANT")"
ACTION="${ACTION:-install}"
VAGRANT_VERSION="${VAGRANT_VERSION:-latest}"
VAGRANT_INSTALL_LIBVIRT_PLUGIN="${VAGRANT_INSTALL_LIBVIRT_PLUGIN:-1}"
VAGRANT_INSTALL_QEMU_PLUGIN="${VAGRANT_INSTALL_QEMU_PLUGIN:-1}"

configure_hashicorp_repo_debian() {
  if [ -f /etc/apt/sources.list.d/hashicorp.list ]; then
    return 0
  fi

  log_info "Configuring HashiCorp official APT repository..."
  priv mkdir -p /usr/share/keyrings

  key_tmp=$(mktemp)
  curl -fsSL https://apt.releases.hashicorp.com/gpg -o "$key_tmp"
  priv gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg --yes < "$key_tmp"
  rm -f "$key_tmp"

  codename="jammy"
  if command -v lsb_release >/dev/null 2>&1; then
    codename=$(lsb_release -cs 2>/dev/null || printf '%s' "jammy")
  fi

  printf 'deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com %s main\n' "$codename" | priv tee /etc/apt/sources.list.d/hashicorp.list >/dev/null

  priv apt-get update -y
}

install_libvirt_plugin() {
  if ! command -v vagrant >/dev/null 2>&1; then
    return 0
  fi

  if vagrant plugin list 2>/dev/null | grep -q "vagrant-libvirt"; then
    log_info "vagrant-libvirt plugin is already installed."
    return 0
  fi

  if [ "${TARGET_OS}" != "darwin" ]; then
    log_info "Installing libvirt build dependencies for vagrant-libvirt..."
    case "${PKG_MGR}" in
      'apt-get')
        priv apt-get install -y libvirt-dev build-essential ruby-dev libxml2-dev libxslt-dev libyaml-dev 2>/dev/null || true
        ;;
      'dnf'|'yum')
        priv "${PKG_MGR}" install -y libvirt-devel gcc make ruby-devel libxml2-devel libxslt-devel 2>/dev/null || true
        ;;
    esac

    log_info "Installing vagrant-libvirt plugin..."
    vagrant plugin install vagrant-libvirt || log_warn "Failed to install vagrant-libvirt plugin."
  fi
}

install_qemu_plugin() {
  if ! command -v vagrant >/dev/null 2>&1; then
    return 0
  fi

  if vagrant plugin list 2>/dev/null | grep -q "vagrant-qemu"; then
    log_info "vagrant-qemu plugin is already installed."
    return 0
  fi

  if [ "${TARGET_OS}" != "darwin" ]; then
    log_info "Installing vagrant-qemu plugin..."
    vagrant plugin install vagrant-qemu 2>/dev/null || log_warn "Failed to install vagrant-qemu plugin."
  fi
}

case "$ACTION" in
  ls)
    if command -v vagrant >/dev/null 2>&1; then
      vagrant --version
    else
      printf '%s
' "Vagrant not installed."
    fi
    exit 0
    ;;
  ls-remote)
    curl -fsSL https://checkpoint-api.hashicorp.com/v1/check/vagrant | grep -oE '"current_version":"[^"]+"' | cut -d'"' -f4 || printf '%s
' "latest"
    exit 0
    ;;
  install)
    log_info "Installing Vagrant via ${VAGRANT_INSTALL_METHOD}..."
    if [ "$VAGRANT_INSTALL_METHOD" = "system" ]; then
      case "${PKG_MGR}" in
        'apt-get')
          configure_hashicorp_repo_debian
          libscript_depends "vagrant"
          ;;
        'brew')
          brew install hashicorp/tap/vagrant 2>/dev/null || brew install --cask vagrant
          ;;
        *)
          libscript_depends "vagrant"
          ;;
      esac
    elif [ "$VAGRANT_INSTALL_METHOD" = "libscript_native" ]; then
      ver="2.4.3"
      if [ "$VAGRANT_VERSION" != "latest" ]; then
        ver="$VAGRANT_VERSION"
      fi
      os="linux"
      if [ "${TARGET_OS}" = "darwin" ]; then
        os="darwin"
      fi
      host_arch="${ARCH:-$(uname -m)}"
      arch="amd64"
      if [ "${host_arch}" = "aarch64" ] || [ "${host_arch}" = "arm64" ]; then
        arch="arm64"
      fi

      target_dir="${LIBSCRIPT_HOME:-$HOME/.libscript}/vagrant/${ver}/bin"
      mkdir -p "$target_dir"
      zip_url="https://releases.hashicorp.com/vagrant/${ver}/vagrant_${ver}_${os}_${arch}.zip"
      zip_tmp=$(mktemp)
      log_info "Downloading Vagrant binary from $zip_url..."
      curl -fsSL "$zip_url" -o "$zip_tmp"
      unzip -q -o "$zip_tmp" -d "$target_dir"
      chmod +x "$target_dir/vagrant"
      rm -f "$zip_tmp"
      log_info "Vagrant installed to $target_dir/vagrant"
    fi

    if [ "$VAGRANT_INSTALL_LIBVIRT_PLUGIN" = "1" ]; then
      install_libvirt_plugin
    fi

    if [ "$VAGRANT_INSTALL_QEMU_PLUGIN" = "1" ]; then
      install_qemu_plugin
    fi
    ;;
  uninstall)
    log_info "Uninstalling Vagrant..."
    case "${PKG_MGR}" in
      'apt-get')
        priv apt-get remove -y vagrant 2>/dev/null || true
        ;;
      'brew')
        brew uninstall vagrant 2>/dev/null || true
        ;;
      'dnf'|'yum')
        priv "${PKG_MGR}" remove -y vagrant 2>/dev/null || true
        ;;
    esac
    exit 0
    ;;
esac
