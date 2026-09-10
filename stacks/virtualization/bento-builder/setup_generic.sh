#!/bin/sh
# ## Overview
# Generic setup module for Bento Builder virtualization stack.
#
# ## Usage
# Orchestrates installation of QEMU, VirtualBox, Packer, Vagrant, ISO tools, and Ruby.

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

ACTION="${ACTION:-install}"
INSTALL_QEMU="${INSTALL_QEMU:-1}"
INSTALL_VIRTUALBOX="${INSTALL_VIRTUALBOX:-1}"
INSTALL_PACKER="${INSTALL_PACKER:-1}"
INSTALL_VAGRANT="${INSTALL_VAGRANT:-1}"
INSTALL_IMAGE_TOOLS="${INSTALL_IMAGE_TOOLS:-1}"
BENTO_DIR="${BENTO_DIR:-}"

find_bento_dir() {
  if [ -n "$BENTO_DIR" ] && [ -d "$BENTO_DIR" ]; then
    printf '%s\n' "$BENTO_DIR"
    return 0
  fi
  for candidate in "$PWD" "$PWD/bento" "$PWD/../bento" "$PWD/../bento/bento" "$HOME/bento" "$HOME/bento/bento" "/home/azureuser/bento/bento"; do
    if [ -f "$candidate/packer_templates/pkr-builder.pkr.hcl" ] || [ -f "$candidate/builds.yml" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

ensure_ruby() {
  ruby_ok=0
  if command -v ruby >/dev/null 2>&1; then
    major=$(ruby -e 'puts RUBY_VERSION.split(".")[0]')
    minor=$(ruby -e 'puts RUBY_VERSION.split(".")[1]')
    if [ "$major" -gt 3 ] || { [ "$major" -eq 3 ] && [ "$minor" -ge 1 ]; }; then
      ruby_ok=1
    fi
  fi

  if [ "$ruby_ok" = "1" ]; then
    log_info "Compatible Ruby runtime detected: $(ruby -v)"
  else
    log_info "Ruby >= 3.1 required. Installing modern Ruby..."
    if [ "${TARGET_OS}" = "darwin" ]; then
      brew install ruby
    elif command -v snap >/dev/null 2>&1; then
      priv snap install ruby --channel=3.3/stable --classic
      priv ln -sf /snap/bin/ruby /usr/local/bin/ruby 2>/dev/null || true
      priv ln -sf /snap/bin/gem /usr/local/bin/gem 2>/dev/null || true
      priv ln -sf /snap/bin/bundle /usr/local/bin/bundle 2>/dev/null || true
      priv ln -sf /snap/bin/bundler /usr/local/bin/bundler 2>/dev/null || true
    else
      case "${PKG_MGR}" in
        'apt-get')
          priv apt-get install -y ruby-full ruby-dev build-essential
          ;;
        'dnf'|'yum')
          priv "${PKG_MGR}" install -y ruby ruby-devel gcc make
          ;;
      esac
    fi
  fi

  if ! command -v bundle >/dev/null 2>&1; then
    log_info "Installing Bundler gem..."
    if [ -w "$(ruby -e 'puts Gem.dir' 2>/dev/null || true)" ]; then
      gem install bundler
    else
      priv gem install bundler
    fi
  fi
}

install_image_utilities() {
  log_info "Installing ISO and WIM image manipulation utilities..."
  case "${PKG_MGR}" in
    'apt-get')
      priv apt-get install -y p7zip-full xorriso genisoimage cabextract wimtools mtools dosfstools
      ;;
    'dnf'|'yum')
      priv "${PKG_MGR}" install -y p7zip p7zip-plugins xorriso genisoimage cabextract wimlib-utils mtools dosfstools 2>/dev/null || true
      ;;
    'brew')
      brew install p7zip xorriso wimlib 2>/dev/null || true
      ;;
    *)
      libscript_depends "wimtools" "xorriso" "7zip" 2>/dev/null || true
      ;;
  esac
}

configure_bento_repo() {
  if b_dir=$(find_bento_dir); then
    log_info "Found Bento repository at $b_dir"

    if [ -f "$b_dir/packer_templates/pkr-plugins.pkr.hcl" ] && command -v packer >/dev/null 2>&1; then
      log_info "Initializing Packer plugins for Bento..."
      (cd "$b_dir/packer_templates" && packer init pkr-plugins.pkr.hcl) || log_warn "Packer plugin init failed."
    fi

    if [ -f "$b_dir/Gemfile" ] && command -v bundle >/dev/null 2>&1; then
      log_info "Installing Bento Ruby bundle dependencies..."
      (cd "$b_dir" && bundle install) || log_warn "Bundle install failed."
    fi
  else
    log_info "No local Bento repository detected; skipping repo-specific initialization."
  fi
}

case "$ACTION" in
  ls)
    printf '%s
' "Bento Builder virtualization environment"
    ;;
  install)
    log_info "Starting Bento Builder environment provisioning..."

    if [ "$INSTALL_QEMU" = "1" ]; then
      log_info "Provisioning QEMU / KVM..."
      "$LIBSCRIPT_ROOT_DIR/libscript.sh" install qemu
    fi

    if [ "$INSTALL_VIRTUALBOX" = "1" ]; then
      log_info "Provisioning VirtualBox..."
      "$LIBSCRIPT_ROOT_DIR/libscript.sh" install virtualbox
    fi

    if [ "$INSTALL_PACKER" = "1" ]; then
      log_info "Provisioning Packer..."
      "$LIBSCRIPT_ROOT_DIR/libscript.sh" install packer
    fi

    if [ "$INSTALL_VAGRANT" = "1" ]; then
      log_info "Provisioning Vagrant..."
      "$LIBSCRIPT_ROOT_DIR/libscript.sh" install vagrant
    fi

    if [ "$INSTALL_IMAGE_TOOLS" = "1" ]; then
      install_image_utilities
    fi

    ensure_ruby

    configure_bento_repo

    log_info "Bento Builder environment successfully provisioned!"
    ;;
  test)
    exec "$DIR/test.sh"
    ;;
  uninstall)
    log_info "Uninstalling Bento Builder stack components..."
    "$LIBSCRIPT_ROOT_DIR/libscript.sh" uninstall qemu || true
    "$LIBSCRIPT_ROOT_DIR/libscript.sh" uninstall virtualbox || true
    "$LIBSCRIPT_ROOT_DIR/libscript.sh" uninstall packer || true
    "$LIBSCRIPT_ROOT_DIR/libscript.sh" uninstall vagrant || true
    ;;
esac
