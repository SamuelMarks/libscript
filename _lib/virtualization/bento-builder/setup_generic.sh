#!/bin/sh
# ## Overview
# Generic setup module for Bento Builder virtualization stack.
#
# ## Usage
# Orchestrates installation of QEMU, VirtualBox, Packer, Vagrant, ISO tools, and Ruby.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
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
BENTO_DIR="${BENTO_DIR:-}"

# ## find_bento_dir
# Locates the bento project directory on the filesystem.
find_bento_dir() {
  if [ -n "$BENTO_DIR" ] && [ -d "$BENTO_DIR" ]; then
    printf '%s\n' "$BENTO_DIR"
    return 0
  fi
  for candidate in "$PWD" "$PWD/bento" "$PWD/../bento" "$PWD/../bento/bento" "$HOME/bento" "$HOME/bento/bento"; do
    if [ -f "$candidate/packer_templates/pkr-builder.pkr.hcl" ] || [ -f "$candidate/builds.yml" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

# ## configure_bento_repo
# Configures the local Bento repository dependencies and plugins.
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
    printf '%s\n' "Bento Builder virtualization environment"
    ;;
  install)
    if [ -x "${LIBSCRIPT_HOME:-$HOME/.libscript}/bento-builder/${VERSION:-latest}/bin/bento-builder" ]; then
      log_info "bento-builder ${VERSION:-latest} is already installed."
      exit 0
    fi
    log_info "Starting Bento Builder environment provisioning..."
    configure_bento_repo
    log_info "Bento Builder environment successfully provisioned!"
    ;;
  test)
    exec "$DIR/test.sh"
    ;;
  uninstall)
    log_info "Uninstalling Bento Builder stack components..."
    ;;
esac
