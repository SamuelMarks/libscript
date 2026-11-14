#!/bin/sh
# ## Overview
# Cross-platform setup script for the WiX v4/v5 (.NET 8 dotnet tool) component on POSIX hosts.
#
# ## Usage
# Invoked internally by the LibScript component lifecycle (`install`, `ls`, `ls-remote`, `use`).

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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mgr.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/versioning.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

ACTION="${ACTION:-install}"
WIX_VERSION="${WIX_VERSION:-5.0.2}"
WIX_INSTALL_METHOD="${WIX_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}"
EXACT_VERSION="${WIX_VERSION}"
if [ "${EXACT_VERSION}" = "latest" ] || [ "${EXACT_VERSION}" = "lts" ]; then
  EXACT_VERSION='5.0.2'
fi
TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/wix/${EXACT_VERSION}"

case "${ACTION}" in
  ls)
    if [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/wix" ]; then ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/wix" || true; fi
    ;;
  ls-remote)
    RELEASES_URL="${WIX_RELEASES_URL:-https://api.nuget.org/v3-flatcontainer/wix/index.json}"
    libscript_fetch_stdout "${RELEASES_URL}" | head -n 30 || printf '5.0.2\n4.0.5\n'
    ;;
  use)
    if [ ! -d "${TARGET_DIR}" ]; then
      ACTION='install' "$0"
    fi
    libscript_symlink_alias 'wix' "${WIX_VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'wix' 'default' "${EXACT_VERSION}"
    ;;
  download)
    printf '[download] WiX %s uses NuGet dotnet-tool distribution.\n' "${EXACT_VERSION}"
    ;;
  install)
    if [ "${EXACT_VERSION}" = "3.14" ]; then
      printf '[WARN] WiX 3.14 is Windows-only; use WIX_VERSION=5.0.2 or 4.0.5 on POSIX.\n' >&2
      exit 0
    fi
    if [ -x "${TARGET_DIR}/bin/wix" ]; then
      printf '[INFO] wix %s is already installed at %s.\n' "${EXACT_VERSION}" "${TARGET_DIR}"
      libscript_symlink_alias 'wix' "${WIX_VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'wix' 'default' "${EXACT_VERSION}"
      exit 0
    fi
    if ! command -v dotnet >/dev/null 2>&1; then
      "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install csharp 8.0
      if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/languages/csharp/env.sh" ]; then
        SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/languages/csharp/env.sh"
        export SCRIPT_NAME
        # shellcheck disable=SC1090
        . "${SCRIPT_NAME}"
      fi
    fi
    mkdir -p "${TARGET_DIR}/bin"
    dotnet tool install --tool-path "${TARGET_DIR}/bin" wix --version "${EXACT_VERSION}" || \
      dotnet tool update --tool-path "${TARGET_DIR}/bin" wix --version "${EXACT_VERSION}"
    libscript_symlink_alias 'wix' "${WIX_VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'wix' 'default' "${EXACT_VERSION}"
    ;;
esac
