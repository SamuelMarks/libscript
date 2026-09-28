#!/bin/sh
# ## Overview
# Generic setup module for msi-rs.
# It resolves dependencies (C and Rust toolchains), handles repository compilation or binary fetching,
# and configures isolated version installations for msi-rs across POSIX operating systems.
#
# ## Usage
# Execute this script to perform generic initialization steps for msi-rs:
#   ./setup_generic.sh [install|use|download|uninstall|ls|ls-remote]

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
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf "%s
" "$d")}"
export DIR="${SCRIPT_DIR}"

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/env.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

MSI_RS_INSTALL_METHOD="${MSI_RS_INSTALL_METHOD:-libscript_native}"
MSI_RS_INSTALL_METHOD="$(libscript_resolve_install_method "MSI_RS")"
ACTION="${ACTION:-install}"
VERSION="${MSI_RS_VERSION:-latest}"
REPO_URL="${MSI_RS_REPO_URL:-https://github.com/SamuelMarks/msi-rs}"

# ## resolve_exact_version
# Resolves the exact semver or branch version for msi-rs.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$(git ls-remote --tags "${REPO_URL}" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -n 1 || true)
    if [ -n "$_latest" ]; then
      EXACT_VERSION="$_latest"
    else
      EXACT_VERSION="0.0.1"
    fi
  else
    EXACT_VERSION="${VERSION:-latest}"
  fi
}

# ## ensure_c_toolchain
# Verifies presence of a functional C compiler or installs it using libscript languages/c.
ensure_c_toolchain() {
  if ! command -v cc >/dev/null 2>&1 && ! command -v gcc >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1; then
    log_info "C toolchain not detected; bootstrapping standard C compiler..."
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/languages/c/setup.sh" ]; then
      unset SCRIPT_NAME || true
      ACTION="install" sh "${LIBSCRIPT_ROOT_DIR}/_lib/languages/c/setup.sh" install c latest || true
    elif type libscript_depends >/dev/null 2>&1; then
      libscript_depends "c" || true
    fi
  fi
}

# ## ensure_rust_toolchain
# Verifies presence of cargo and rustc or installs the Rust toolchain via libscript languages/rust.
ensure_rust_toolchain() {
  [ -f "${HOME}/.cargo/env" ] && . "${HOME}/.cargo/env"
  [ -d "${HOME}/.cargo/bin" ] && export PATH="${HOME}/.cargo/bin:${PATH}"
  [ -d "/opt/ooce/bin" ] && export PATH="/opt/ooce/bin:${PATH}"

  if ! command -v cargo >/dev/null 2>&1 || ! command -v rustc >/dev/null 2>&1; then
    log_info "Rust toolchain not detected; bootstrapping Rust and Cargo..."
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/languages/rust/setup.sh" ]; then
      unset SCRIPT_NAME || true
      ACTION="install" sh "${LIBSCRIPT_ROOT_DIR}/_lib/languages/rust/setup.sh" install rust latest || true
      [ -f "${HOME}/.cargo/env" ] && . "${HOME}/.cargo/env"
      [ -d "${HOME}/.cargo/bin" ] && export PATH="${HOME}/.cargo/bin:${PATH}"
    elif [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/rustup/setup.sh" ]; then
      unset SCRIPT_NAME || true
      ACTION="install" sh "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/rustup/setup.sh" install rustup latest || true
      [ -f "${HOME}/.cargo/env" ] && . "${HOME}/.cargo/env"
      [ -d "${HOME}/.cargo/bin" ] && export PATH="${HOME}/.cargo/bin:${PATH}"
    elif type libscript_depends >/dev/null 2>&1; then
      libscript_depends "rust" || true
    fi
  fi
}

# ## install_binaries_from_dir
# Copies built binaries from target release folder into the target prefix and links aliases.
install_binaries_from_dir() {
  src_dir="$1"
  dest_bin="${TARGET_DIR}/bin"
  mkdir -p "${dest_bin}"

  for bin_name in msi-cli candle light wix dark heat torch pyro lit smoke msiinfo msibuild msidump msidiff msiextract msi-gui; do
    if [ -f "${src_dir}/${bin_name}" ]; then
      cp "${src_dir}/${bin_name}" "${dest_bin}/${bin_name}"
      chmod +x "${dest_bin}/${bin_name}"
    fi
  done

  if [ -f "${dest_bin}/msi-cli" ]; then
    ln -sf "msi-cli" "${dest_bin}/msi-rs"
    ln -sf "msi-cli" "${dest_bin}/msi"
  fi
}

case "$ACTION" in
  ls)
    if [ "$MSI_RS_INSTALL_METHOD" = "mise" ]; then
      mise ls msi-rs || true
    elif [ "$MSI_RS_INSTALL_METHOD" = "asdf" ]; then
      asdf list msi-rs || true
    elif [ "$MSI_RS_INSTALL_METHOD" = "vfox" ]; then
      vfox ls msi-rs || true
    elif [ "$MSI_RS_INSTALL_METHOD" = "system" ]; then
      printf '%s
' "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$MSI_RS_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote msi-rs || true
    elif [ "$MSI_RS_INSTALL_METHOD" = "asdf" ]; then
      asdf list all msi-rs || true
    elif [ "$MSI_RS_INSTALL_METHOD" = "vfox" ]; then
      vfox ls all msi-rs || true
    else
      if [ -n "${MSI_RS_RELEASES_URL:-}" ]; then
        curl -sSL "${MSI_RS_RELEASES_URL}" | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s
' "0.0.1"
      else
        _remote_tags=$(git ls-remote --tags "${REPO_URL}" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || true)
        if [ -n "$_remote_tags" ]; then
          printf '%s
' "$_remote_tags"
        else
          printf '%s
' "0.0.1"
        fi
      fi
    fi
    exit 0
    ;;
  use)
    if [ "$MSI_RS_INSTALL_METHOD" = "mise" ]; then
      mise use "msi-rs@${VERSION}"
    elif [ "$MSI_RS_INSTALL_METHOD" = "asdf" ]; then
      asdf global msi-rs "${VERSION}"
    elif [ "$MSI_RS_INSTALL_METHOD" = "vfox" ]; then
      vfox use "msi-rs@${VERSION}"
    elif [ "$MSI_RS_INSTALL_METHOD" = "system" ]; then
      printf '%s
' "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "msi-rs" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "msi-rs" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "msi-rs ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "msi-rs" "default" "${EXACT_VERSION}"
      log_info "Set default msi-rs version to ${EXACT_VERSION}."
      log_info "To apply to current shell, run:"
      log_info "  . "${DIR}/env.sh""
    fi
    exit 0
    ;;
  download)
    if [ "$MSI_RS_INSTALL_METHOD" = "libscript_native" ]; then
      resolve_exact_version
      target_cache_dir="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/msi-rs"
      log_info "Downloading msi-rs ${VERSION} artifacts to ${target_cache_dir}..."
      mkdir -p "${target_cache_dir}"
      if [ -n "${MSI_RS_DOWNLOAD_URL:-}" ]; then
        libscript_download "${MSI_RS_DOWNLOAD_URL}" "${target_cache_dir}/msi-rs-${EXACT_VERSION}.tar.gz"
      else
        archive_url="${REPO_URL}/archive/refs/heads/master.tar.gz"
        libscript_download "${archive_url}" "${target_cache_dir}/msi-rs-${EXACT_VERSION}.tar.gz" || true
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$MSI_RS_INSTALL_METHOD" = "system" ]; then
      libscript_depends "msi-rs" || true
    elif [ "$MSI_RS_INSTALL_METHOD" = "mise" ]; then
      mise install "msi-rs@${VERSION}"
    elif [ "$MSI_RS_INSTALL_METHOD" = "asdf" ]; then
      asdf install msi-rs "${VERSION}"
    elif [ "$MSI_RS_INSTALL_METHOD" = "vfox" ]; then
      vfox add msi-rs || true
      vfox install "msi-rs@${VERSION}"
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/${EXACT_VERSION}"
      
      # Idempotency check: skip compilation if already built
      if [ -x "${TARGET_DIR}/bin/msi-cli" ] || [ -x "${TARGET_DIR}/bin/msi-rs" ]; then
        log_info "msi-rs ${EXACT_VERSION} is already installed in ${TARGET_DIR}."
        libscript_symlink_alias "msi-rs" "$VERSION" "${EXACT_VERSION}"
        libscript_symlink_alias "msi-rs" "default" "${EXACT_VERSION}"
        exit 0
      fi

      log_info "Installing msi-rs ${VERSION} natively to ${TARGET_DIR}..."
      mkdir -p "${TARGET_DIR}/bin"

      ensure_c_toolchain
      ensure_rust_toolchain

      cache_tarball="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/msi-rs/msi-rs-${EXACT_VERSION}.tar.gz"
      build_stage_dir="${TMPDIR:-/tmp}/msi_rs_build_$$"

      if [ -f "$cache_tarball" ]; then
        log_info "Extracting from download cache..."
        mkdir -p "${build_stage_dir}"
        tar -xzf "$cache_tarball" -C "${build_stage_dir}" --strip-components=1 || true
        if [ -f "${build_stage_dir}/Cargo.toml" ]; then
          (cd "${build_stage_dir}" && cargo build --release -p msi-cli)
          install_binaries_from_dir "${build_stage_dir}/target/release"
          rm -rf "${build_stage_dir}"
        fi
      elif [ -n "${MSI_RS_DOWNLOAD_URL:-}" ]; then
        log_info "Fetching prebuilt binary release from ${MSI_RS_DOWNLOAD_URL}..."
        tmp_archive=$(mktemp)
        libscript_download "${MSI_RS_DOWNLOAD_URL}" "${tmp_archive}"
        tar -xzf "${tmp_archive}" -C "${TARGET_DIR}" --strip-components=1 2>/dev/null || unzip -q "${tmp_archive}" -d "${TARGET_DIR}" || true
        rm -f "${tmp_archive}"
      else
        log_info "Cloning upstream repository from ${REPO_URL}..."
        mkdir -p "${build_stage_dir}"
        git clone --depth 1 "${REPO_URL}" "${build_stage_dir}"
        (cd "${build_stage_dir}" && cargo build --release -p msi-cli)
        install_binaries_from_dir "${build_stage_dir}/target/release"
        rm -rf "${build_stage_dir}"
      fi

      libscript_symlink_alias "msi-rs" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "msi-rs" "default" "${EXACT_VERSION}"
      log_info "msi-rs ${EXACT_VERSION} installed successfully."
    fi
    exit 0
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$MSI_RS_INSTALL_METHOD" = "libscript_native" ] || [ "$MSI_RS_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      # shellcheck disable=SC1090
      . "${SCRIPT_NAME}"
    else
      log_info "$ACTION not implemented for $MSI_RS_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$MSI_RS_INSTALL_METHOD" = "libscript_native" ] || [ "$MSI_RS_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      # shellcheck disable=SC1090
      . "${SCRIPT_NAME}"
    else
      log_info "install-service not implemented for $MSI_RS_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$MSI_RS_INSTALL_METHOD" = "libscript_native" ] || [ "$MSI_RS_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      # shellcheck disable=SC1090
      . "${SCRIPT_NAME}"
    else
      log_info "uninstall-service not implemented for $MSI_RS_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$MSI_RS_INSTALL_METHOD" = "libscript_native" ]; then
      resolve_exact_version
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/$VERSION"
      log_info "msi-rs ${EXACT_VERSION} removed."
    else
      log_info "Uninstall not implemented or supported for $MSI_RS_INSTALL_METHOD."
    fi
    exit 0
    ;;
esac
