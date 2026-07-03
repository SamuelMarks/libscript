#!/bin/sh
# ## Overview
# Generic setup module for C#.
#
# ## Usage
# Installs .NET SDK by downloading the official `dotnet-install.sh` script or via system/asdf/mise.


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

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/env.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

CSHARP_INSTALL_METHOD="${CSHARP_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript-native}}"
CSHARP_VERSION="${CSHARP_VERSION:-latest}"
ACTION="${ACTION:-install}"

resolve_csharp_channel() {
  if [ "${CSHARP_VERSION}" = "latest" ]; then
    CSHARP_CHANNEL="LTS"
  else
    CSHARP_CHANNEL="${CSHARP_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "$CSHARP_INSTALL_METHOD" = "mise" ]; then
      mise ls dotnet
    elif [ "$CSHARP_INSTALL_METHOD" = "asdf" ]; then
      asdf list dotnet-core
    elif [ "$CSHARP_INSTALL_METHOD" = "system" ]; then
      dotnet --list-sdks || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/csharp/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$CSHARP_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote dotnet
    elif [ "$CSHARP_INSTALL_METHOD" = "asdf" ]; then
      asdf list all dotnet-core
    elif [ "$CSHARP_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      # Not trivial to query Microsoft's release JSON purely in shell; 
      # provide a basic list of known channels as a fallback.
      printf '%s\n' "8.0"
      printf '%s\n' "9.0"
      printf '%s\n' "LTS"
      printf '%s\n' "STS"
    fi
    exit 0
    ;;
  use)
    if [ "$CSHARP_INSTALL_METHOD" = "mise" ]; then
      mise use "dotnet@${CSHARP_VERSION}"
    elif [ "$CSHARP_INSTALL_METHOD" = "asdf" ]; then
      asdf global dotnet-core "${CSHARP_VERSION}"
    elif [ "$CSHARP_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_csharp_channel
      libscript_symlink_alias "csharp" "${CSHARP_VERSION}" "${CSHARP_CHANNEL}"
    fi
    exit 0
    ;;
  download|install|*)
    if [ "$CSHARP_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'csharp'
    elif [ "$CSHARP_INSTALL_METHOD" = "mise" ]; then
      mise install "dotnet@${CSHARP_VERSION}"
    elif [ "$CSHARP_INSTALL_METHOD" = "asdf" ]; then
      asdf install dotnet-core "${CSHARP_VERSION}"
    else
      libscript_depends 'curl' 'bash'
      resolve_csharp_channel
      
      CSHARP_DIR=$(libscript_get_version_dir "csharp" "${CSHARP_CHANNEL}")
      
      if [ -x "${CSHARP_DIR}/dotnet" ]; then
        libscript_symlink_alias "csharp" "${CSHARP_VERSION}" "${CSHARP_CHANNEL}"
        exit 0
      fi

      INSTALL_SH=$(mktemp)
      libscript_download 'https://dot.net/v1/dotnet-install.sh' "${INSTALL_SH}"
      
      mkdir -p "${CSHARP_DIR}"
      bash "${INSTALL_SH}" --channel "${CSHARP_CHANNEL}" --install-dir "${CSHARP_DIR}"
      rm -f "${INSTALL_SH}"
      
      libscript_symlink_alias "csharp" "${CSHARP_VERSION}" "${CSHARP_CHANNEL}"
    fi
    ;;
esac
