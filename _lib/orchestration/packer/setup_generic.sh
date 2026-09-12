#!/bin/sh
# ## Overview
# Generic setup module for HashiCorp Packer.
#
# ## Usage
# Sourced by setup.sh to configure repository and install Packer.

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

PACKER_INSTALL_METHOD="$(libscript_resolve_install_method "PACKER")"
ACTION="${ACTION:-install}"
PACKER_VERSION="${PACKER_VERSION:-latest}"

# ## configure_hashicorp_repo_debian
# Configures the official HashiCorp apt repository on Debian/Ubuntu systems.
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

  printf 'deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com %s main
' "$codename" | priv tee /etc/apt/sources.list.d/hashicorp.list >/dev/null

  priv apt-get update -y
}

case "$ACTION" in
  ls)
    if command -v packer >/dev/null 2>&1; then
      packer --version
    else
      printf '%s
' "Packer not installed."
    fi
    exit 0
    ;;
  ls-remote)
    curl -fsSL https://checkpoint-api.hashicorp.com/v1/check/packer | grep -oE '"current_version":"[^"]+"' | cut -d'"' -f4 || printf '%s
' "latest"
    exit 0
    ;;
  install)
    log_info "Installing Packer via ${PACKER_INSTALL_METHOD}..."
    if [ "$PACKER_INSTALL_METHOD" = "system" ]; then
      case "${PKG_MGR}" in
        'apt-get')
          configure_hashicorp_repo_debian
          libscript_depends "packer"
          ;;
        'brew')
          brew install hashicorp/tap/packer 2>/dev/null || brew install packer
          ;;
        *)
          libscript_depends "packer"
          ;;
      esac
    elif [ "$PACKER_INSTALL_METHOD" = "libscript_native" ]; then
      ver="1.11.2"
      if [ "$PACKER_VERSION" != "latest" ]; then
        ver="$PACKER_VERSION"
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

      target_dir="${LIBSCRIPT_HOME:-$HOME/.libscript}/packer/${ver}/bin"
      if [ -x "$target_dir/packer" ]; then
        log_info "Packer ${ver} is already installed at $target_dir/packer"
        exit 0
      fi
      mkdir -p "$target_dir"
      zip_url="https://releases.hashicorp.com/packer/${ver}/packer_${ver}_${os}_${arch}.zip"
      zip_tmp=$(mktemp)
      log_info "Downloading Packer binary from $zip_url..."
      curl -fsSL "$zip_url" -o "$zip_tmp"
      unzip -q -o "$zip_tmp" -d "$target_dir"
      chmod +x "$target_dir/packer"
      rm -f "$zip_tmp"
      log_info "Packer installed to $target_dir/packer"
    fi
    ;;
  uninstall)
    log_info "Uninstalling Packer..."
    case "${PKG_MGR}" in
      'apt-get')
        priv apt-get remove -y packer 2>/dev/null || true
        ;;
      'brew')
        brew uninstall packer 2>/dev/null || true
        ;;
      'dnf'|'yum')
        priv "${PKG_MGR}" remove -y packer 2>/dev/null || true
        ;;
    esac
    exit 0
    ;;
esac
