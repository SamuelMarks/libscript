#!/bin/sh
# ## Overview
# Generic setup module for Gitea.
#
# ## Usage
# Installs Gitea either via system package manager or by downloading the binary directly.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
DIR="${SCRIPT_DIR}"

for LIB in "_lib/_common/pkg_mgr.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

GITEA_INSTALL_METHOD="${GITEA_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-source}}"
GITEA_VERSION="${GITEA_VERSION:-latest}"

if [ "${GITEA_INSTALL_METHOD}" = 'system' ]; then
  libscript_depends 'gitea'
else
  # "source" install (direct download of binary)
  TARGET_OS="${TARGET_OS:-linux}"
  TARGET_ARCH="${TARGET_ARCH:-amd64}"

  if [ "${TARGET_ARCH}" = "x86_64" ]; then TARGET_ARCH="amd64"; fi
  if [ "${TARGET_ARCH}" = "aarch64" ]; then TARGET_ARCH="arm64"; fi
  if [ "${TARGET_ARCH}" = "armv7l" ]; then TARGET_ARCH="arm-6"; fi

  case "${TARGET_OS}" in
    macos*|darwin*) os_name="darwin" ;;
    linux*) os_name="linux" ;;
    *) printf '%s\n' "[ERROR] Unsupported OS for direct download: ${TARGET_OS}"; exit 1 ;;
  esac

  if [ "${GITEA_VERSION}" = "latest" ]; then
    GITEA_VERSION="1.22.3"
  fi
  dl_url="https://dl.gitea.com/gitea/${GITEA_VERSION}/gitea-${GITEA_VERSION}-${os_name}-${TARGET_ARCH}"

  PREFIX="${PREFIX:-${LIBSCRIPT_ROOT_DIR}/installed/gitea}"
  bin_dir="${PREFIX}/bin"
  mkdir -p "${bin_dir}"

  log_info "Downloading Gitea from ${dl_url}..."
  libscript_download "${dl_url}" "${bin_dir}/gitea"

  chmod +x "${bin_dir}/gitea"
  log_info "Gitea installed to ${bin_dir}/gitea"
fi
