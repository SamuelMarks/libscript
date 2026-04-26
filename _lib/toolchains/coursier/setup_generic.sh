#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'
DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

for lib in '_lib/_common/pkg_mgr.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

COURSIER_INSTALL_METHOD="${COURSIER_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-source}}"
COURSIER_VERSION="${COURSIER_VERSION:-latest}"

if [ "${COURSIER_INSTALL_METHOD}" = 'system' ]; then
  depends 'coursier'
else
  # "source" install (direct download of binary)
  if [ "${COURSIER_VERSION}" = "latest" ]; then
    COURSIER_VERSION="2.1.24"
  fi

  TARGET_OS="${TARGET_OS:-linux}"
  TARGET_ARCH="${TARGET_ARCH:-amd64}"

  if [ "${TARGET_ARCH}" = "amd64" ] || [ "${TARGET_ARCH}" = "x86_64" ]; then arch="x86_64"; else arch="${TARGET_ARCH}"; fi
  if [ "${TARGET_ARCH}" = "arm64" ] || [ "${TARGET_ARCH}" = "aarch64" ]; then arch="aarch64"; fi

  case "${TARGET_OS}" in
    macos*|darwin*) os_name="apple-darwin" ;;
    linux*) os_name="pc-linux" ;;
    *) log_error "Unsupported OS for direct download: ${TARGET_OS}"; exit 1 ;;
  esac

  dl_url="https://github.com/coursier/coursier/releases/download/v${COURSIER_VERSION}/cs-${arch}-${os_name}.gz"

  PREFIX="${PREFIX:-${LIBSCRIPT_ROOT_DIR}/installed/coursier}"
  bin_dir="${PREFIX}/bin"
  mkdir -p "${bin_dir}"

  log_info "Downloading Coursier from ${dl_url}..."
  libscript_download "${dl_url}" "${bin_dir}/cs.gz"

  gzip -d "${bin_dir}/cs.gz" || gunzip "${bin_dir}/cs.gz"
  mv "${bin_dir}/cs" "${bin_dir}/coursier"
  chmod +x "${bin_dir}/coursier"
  ln -sf "${bin_dir}/coursier" "${bin_dir}/cs"

  log_success "Coursier installed to ${bin_dir}/coursier"
fi
