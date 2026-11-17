#!/bin/sh
# ## Overview
# Generic setup and box-builder orchestration module for the Bento Builder virtualization stack,
# provisioning `Bento::VagrantMsdos` / `Bento::VagrantFreedos` plugins and delegating MS-DOS (`1.25`,
# `2.0`, `4.0`) and FreeDOS (`1.3`, `1.4`) `.box` builds to `../bento/{msdos,freedos}-builder.sh`.
#
# ## Usage
# ACTION=[install|build|box|register|ls|test|uninstall] ./_lib/virtualization/bento-builder/setup_generic.sh

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
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
_SG_THIS="${THIS_FILE}"

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
unset SCRIPT_NAME || true
THIS_FILE="${_SG_THIS}"
SCRIPT_DIR="${DIR}"

ACTION="${ACTION:-install}"
BENTO_DIR="${BENTO_DIR:-}"
BENTO_REPO_URL="${BENTO_REPO_URL:-${BENTO_BUILDER_REPO_URL:-https://github.com/SamuelMarks/bento.git}}"
BENTO_BRANCH="${BENTO_BRANCH:-${BENTO_BUILDER_BRANCH:-multi-os-qemu-aarch64}}"
BENTO_BUILDER_TARGET_OS="${BENTO_BUILDER_TARGET_OS:-}"
BENTO_BUILDER_FORCE_REBUILD="${BENTO_BUILDER_FORCE_REBUILD:-${FORCE_REBUILD:-0}}"

# ## find_bento_dir
# Locates the local Bento repository directory relative to LIBSCRIPT_ROOT_DIR, BENTO_DIR, or HOME.
find_bento_dir() {
  if [ -n "$BENTO_DIR" ] && [ -d "$BENTO_DIR" ]; then
    (cd -- "$BENTO_DIR" && pwd)
    return 0
  fi
  for candidate in \
    "${LIBSCRIPT_ROOT_DIR}/../bento" \
    "$PWD/../bento" \
    "$PWD/bento" \
    "${HOME:-/root}/bento" \
    "${HOME:-/root}/bento/bento"; do
    if [ -f "$candidate/bento.gemspec" ] || [ -f "$candidate/packer_templates/pkr-builder.pkr.hcl" ] || [ -f "$candidate/builds.yml" ] || [ -d "$candidate/os_pkrvars" ]; then
      (cd -- "$candidate" && pwd)
      return 0
    fi
  done
  return 1
}

# ## resolve_bento_arch
# Maps LibScript host architecture (`ARCH` from `os_info.sh`) to Bento's `aarch64` or `x86_64` identifier.
resolve_bento_arch() {
  case "${ARCH:-x86_64}" in
    arm64|aarch64) printf '%s\n' 'aarch64' ;;
    *) printf '%s\n' 'x86_64' ;;
  esac
}

# ## ensure_bento_fork_checkout
# Idempotently ensures the Bento repository uses the configured fork (`SamuelMarks/bento`) and branch (`multi-os-qemu-aarch64`).
ensure_bento_fork_checkout() {
  _b_target="${1:-${BENTO_DIR:-${LIBSCRIPT_ROOT_DIR}/../bento}}"
  if [ ! -d "$_b_target/.git" ]; then
    if [ -n "$BENTO_DIR" ] && command -v git >/dev/null 2>&1 && [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ]; then
      log_info "Cloning Bento fork ${BENTO_REPO_URL} (branch ${BENTO_BRANCH}) into ${_b_target}..."
      rm -rf "$_b_target"
      mkdir -p "$(dirname "$_b_target")"
      git clone --branch "$BENTO_BRANCH" "$BENTO_REPO_URL" "$_b_target" || log_warn "Could not clone ${BENTO_REPO_URL}."
    fi
  elif command -v git >/dev/null 2>&1 && [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ]; then
    _cur_branch=$(git -C "$_b_target" rev-parse --abbrev-ref HEAD 2>/dev/null || printf '%s' "")
    if [ -n "$_cur_branch" ] && [ "$_cur_branch" != "$BENTO_BRANCH" ] && [ -z "$(git -C "$_b_target" status --porcelain 2>/dev/null || true)" ]; then
      log_info "Switching Bento repository at ${_b_target} from ${_cur_branch} to ${BENTO_BRANCH}..."
      git -C "$_b_target" checkout "$BENTO_BRANCH" 2>/dev/null || log_warn "Branch ${BENTO_BRANCH} not checked out locally."
    fi
  fi
}

# ## configure_bento_dos_plugins
# Configures `RUBYLIB` and verifies or installs `Bento::VagrantMsdos` and `Bento::VagrantFreedos` (with legacy `vagrant-msdos` fallback).
configure_bento_dos_plugins() {
  _b_dir="$1"
  if [ "${BENTO_BUILDER_INSTALL_MSDOS_PLUGIN:-1}" != "1" ]; then
    return 0
  fi

  if [ -d "${_b_dir}/lib" ]; then
    case ":${RUBYLIB:-}:" in
      *":${_b_dir}/lib:"*) ;;
      *)
        RUBYLIB="${_b_dir}/lib${RUBYLIB:+:${RUBYLIB}}"
        export RUBYLIB
        ;;
    esac
  fi

  if [ -f "${_b_dir}/lib/bento/vagrant_msdos.rb" ] && [ -f "${_b_dir}/lib/bento/vagrant_freedos.rb" ]; then
    log_info "Detected Bento DOS Vagrant plugins (Bento::VagrantMsdos & Bento::VagrantFreedos) in ${_b_dir}/lib."
    if [ -f "${_b_dir}/bento.gemspec" ] && [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ] && command -v vagrant >/dev/null 2>&1 && command -v gem >/dev/null 2>&1; then
      if vagrant plugin list 2>/dev/null | grep -q '^bento '; then
        log_info 'Bento Vagrant plugin gem is already installed.'
      fi
    fi
  elif [ -f "${_b_dir}/vagrant-msdos/vagrant-msdos.gemspec" ] && [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ] && command -v vagrant >/dev/null 2>&1 && command -v gem >/dev/null 2>&1; then
    if ! vagrant plugin list 2>/dev/null | grep -q 'vagrant-msdos'; then
      log_info 'Building and registering legacy vagrant-msdos plugin...'
      (cd "${_b_dir}/vagrant-msdos" && gem build vagrant-msdos.gemspec && vagrant plugin install vagrant-msdos-*.gem) || log_warn 'vagrant-msdos plugin install skipped.'
    fi
  fi
}

# ## configure_bento_repo
# Configures the local Bento repository dependencies, Packer plugins, and DOS Vagrant plugins.
configure_bento_repo() {
  ensure_bento_fork_checkout "${BENTO_DIR:-}"
  if b_dir=$(find_bento_dir); then
    log_info "Found Bento repository at $b_dir (target branch: ${BENTO_BRANCH})"

    if [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ] && [ -f "$b_dir/packer_templates/pkr-plugins.pkr.hcl" ] && command -v packer >/dev/null 2>&1; then
      log_info 'Initializing Packer plugins for Bento...'
      (cd "$b_dir/packer_templates" && packer init pkr-plugins.pkr.hcl) || log_warn 'Packer plugin init failed.'
    fi

    configure_bento_dos_plugins "$b_dir"

    if [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ] && [ -f "$b_dir/Gemfile" ] && command -v bundle >/dev/null 2>&1; then
      log_info 'Installing Bento Ruby bundle dependencies...'
      (cd "$b_dir" && bundle install) || log_warn 'Bundle install failed.'
    fi
  else
    log_info 'No local Bento repository detected; skipping repo-specific initialization.'
  fi
}

# ## install_bento_wrapper_bin
# Writes an idempotent `bento-builder` CLI wrapper into `${LIBSCRIPT_HOME}/bento-builder/${VERSION}/bin/`.
install_bento_wrapper_bin() {
  _inst_dir="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/bento-builder/${VERSION:-latest}"
  mkdir -p "${_inst_dir}/bin"
  cat <<WRAP_EOF > "${_inst_dir}/bin/bento-builder.tmp"
#!/bin/sh
exec "${LIBSCRIPT_ROOT_DIR}/_lib/virtualization/bento-builder/cli.sh" "\$@"
WRAP_EOF
  chmod +x "${_inst_dir}/bin/bento-builder.tmp"
  mv -f "${_inst_dir}/bin/bento-builder.tmp" "${_inst_dir}/bin/bento-builder"
}

# ## has_cached_bento_box
# Checks whether a built `.qemu.box` artifact already exists in `builds/build_complete/` for the given target stem.
has_cached_bento_box() {
  _b_dir="$1"
  _stem="$2"
  _arch=$(resolve_bento_arch)
  for _ca in "$_arch" aarch64 x86_64 i386; do
    if [ -f "${_b_dir}/builds/build_complete/${_stem}-${_ca}.qemu.box" ]; then
      printf '%s\n' "${_b_dir}/builds/build_complete/${_stem}-${_ca}.qemu.box"
      return 0
    fi
  done
  return 1
}

# ## build_or_register_bento_target
# Builds a requested OS or DOS target via `../bento/{msdos,freedos}-builder.sh` (or Packer) and registers boxes idempotently.
build_or_register_bento_target() {
  if ! b_dir=$(find_bento_dir); then
    log_error 'Could not locate ../bento directory; set BENTO_DIR to your Bento checkout.'
    exit 1
  fi
  configure_bento_dos_plugins "$b_dir"

  if [ "$ACTION" = "register" ] || [ -z "$BENTO_BUILDER_TARGET_OS" ]; then
    STACK="" "${LIBSCRIPT_ROOT_DIR}/tests/register_bento_boxes.sh" --bento-dir "$b_dir"
    return 0
  fi

  _tgt="$BENTO_BUILDER_TARGET_OS"
  case "$_tgt" in
    msdos-1.25|msdos-2.0|msdos-4.0)
      _ver="${_tgt#msdos-}"
      if [ "$BENTO_BUILDER_FORCE_REBUILD" != "1" ] && _cached=$(has_cached_bento_box "$b_dir" "$_tgt"); then
        log_info "[SKIP] ${_tgt} box already built at ${_cached}; registering idempotently."
      elif [ -f "${b_dir}/msdos-builder.sh" ]; then
        log_info "Building ${_tgt} via ${b_dir}/msdos-builder.sh (MSDOS_VERSION=${_ver})..."
        (cd "$b_dir" && MSDOS_VERSION="${_ver}" sh ./msdos-builder.sh all)
      else
        log_error "Missing ${b_dir}/msdos-builder.sh for ${_tgt}."
        exit 1
      fi
      ;;
    freedos|freedos-1.3|freedos-1.4)
      _ver="${_tgt#freedos-}"
      if [ "$_tgt" = "freedos" ]; then _ver='1.3'; fi
      _stem="freedos-${_ver}"
      if [ "$BENTO_BUILDER_FORCE_REBUILD" != "1" ] && _cached=$(has_cached_bento_box "$b_dir" "$_stem"); then
        log_info "[SKIP] ${_stem} box already built at ${_cached}; registering idempotently."
      elif [ "$BENTO_BUILDER_FORCE_REBUILD" != "1" ] && [ "$_ver" = "1.4" ] && _cached=$(has_cached_bento_box "$b_dir" "freedos-1.3") && [ "${LIBSCRIPT_OFFLINE:-0}" = "1" ]; then
        log_info "[SKIP] Offline mode: reusing cached ${_cached} for ${_tgt}."
      elif [ -f "${b_dir}/freedos-builder.sh" ]; then
        log_info "Building ${_stem} via ${b_dir}/freedos-builder.sh (FREEDOS_VERSION=${_ver})..."
        (cd "$b_dir" && FREEDOS_VERSION="${_ver}" sh ./freedos-builder.sh build && FREEDOS_VERSION="${_ver}" sh ./freedos-builder.sh box)
      else
        log_error "Missing ${b_dir}/freedos-builder.sh for ${_stem}."
        exit 1
      fi
      ;;
    *)
      _arch=$(resolve_bento_arch)
      if [ "$BENTO_BUILDER_FORCE_REBUILD" != "1" ] && _cached=$(has_cached_bento_box "$b_dir" "$_tgt"); then
        log_info "[SKIP] ${_tgt} box already built at ${_cached}; registering idempotently."
      else
        _os_fam="${_tgt%%-*}"
        _pkr_file="${b_dir}/os_pkrvars/${_os_fam}/${_tgt}-${_arch}.pkrvars.hcl"
        if [ -f "$_pkr_file" ] && command -v packer >/dev/null 2>&1; then
          log_info "Building ${_tgt} via Packer (${_pkr_file})..."
          (cd "${b_dir}/packer_templates" && packer build -var-file="$_pkr_file" .)
        else
          log_warn "No prebuilt box or matching Packer template for ${_tgt}; running box registration check."
        fi
      fi
      ;;
  esac

  STACK="" "${LIBSCRIPT_ROOT_DIR}/tests/register_bento_boxes.sh" --bento-dir "$b_dir"
}

case "$ACTION" in
  ls)
    printf '%s\n' 'Bento Builder virtualization environment'
    ;;
  install)
    if [ -x "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/bento-builder/${VERSION:-latest}/bin/bento-builder" ]; then
      log_info "bento-builder ${VERSION:-latest} is already installed."
      exit 0
    fi
    log_info 'Starting Bento Builder environment provisioning...'
    configure_bento_repo
    install_bento_wrapper_bin
    log_info 'Bento Builder environment successfully provisioned!'
    ;;
  build|box|register)
    build_or_register_bento_target
    ;;
  test)
    unset SCRIPT_NAME || true
    exec "$DIR/test.sh"
    ;;
  uninstall)
    log_info 'Uninstalling Bento Builder stack components...'
    rm -rf "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/bento-builder/${VERSION:-latest}"
    ;;
esac
