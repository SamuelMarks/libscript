#!/bin/sh
# ## Overview
# Generic setup module for Zig.
#
# ## Usage
# Installs Zig by downloading release tarballs from ziglang.org or delegating to system/mise/asdf.


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

ZIG_INSTALL_METHOD="${ZIG_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript-native}}"
ZIG_VERSION="${ZIG_VERSION:-0.12.0}"
ACTION="${ACTION:-install}"

resolve_exact_version() {
  if [ "${ZIG_VERSION}" = "latest" ]; then
    # In a full implementation, we would curl ziglang.org/download/index.json
    EXACT_VERSION="0.12.0"
  else
    EXACT_VERSION="${ZIG_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "$ZIG_INSTALL_METHOD" = "mise" ]; then
      mise ls zig
    elif [ "$ZIG_INSTALL_METHOD" = "asdf" ]; then
      asdf list zig
    elif [ "$ZIG_INSTALL_METHOD" = "system" ]; then
      zig version || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/zig/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$ZIG_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote zig
    elif [ "$ZIG_INSTALL_METHOD" = "asdf" ]; then
      asdf list all zig
    elif [ "$ZIG_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      curl -sL "https://ziglang.org/download/index.json" | grep -o '"0\.[0-9]*\.[0-9]*"' | sed 's/"//g' | sort -u
    fi
    exit 0
    ;;
  use)
    if [ "$ZIG_INSTALL_METHOD" = "mise" ]; then
      mise use "zig@${ZIG_VERSION}"
    elif [ "$ZIG_INSTALL_METHOD" = "asdf" ]; then
      asdf global zig "${ZIG_VERSION}"
    elif [ "$ZIG_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "zig" "${ZIG_VERSION}" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  download|install|*)
    if [ "$ZIG_INSTALL_METHOD" = "system" ]; then
      if ! libscript_depends 'zig'; then
        if command -v snap >/dev/null 2>&1; then
          priv snap install zig --classic || priv snap install zig --classic --beta || true
        fi
      fi
    elif [ "$ZIG_INSTALL_METHOD" = "mise" ]; then
      mise install "zig@${ZIG_VERSION}"
    elif [ "$ZIG_INSTALL_METHOD" = "asdf" ]; then
      asdf install zig "${ZIG_VERSION}"
    else
      libscript_depends 'curl' 'tar' 'xz'
      resolve_exact_version
      
      ZIG_DIR=$(libscript_get_version_dir "zig" "${EXACT_VERSION}")
      
      if [ -x "${ZIG_DIR}/zig" ]; then
        libscript_symlink_alias "zig" "${ZIG_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      os="$(uname -s | tr '[:upper:]' '[:lower:]')"
      case "${os}" in
        'darwin'*) os='macos' ;;
        'freebsd'*) os='freebsd' ;;
        *) os='linux' ;;
      esac
      arch="$(uname -m)"
      case "${arch}" in
        'x86_64') arch='x86_64' ;;
        'aarch64'|'arm64') arch='aarch64' ;;
        *) ;;
      esac
      
      ZIG_URL="https://ziglang.org/download/${EXACT_VERSION}/zig-${os}-${arch}-${EXACT_VERSION}.tar.xz"
      ZIG_TARBALL=$(mktemp)
      libscript_download "${ZIG_URL}" "${ZIG_TARBALL}"
      
      mkdir -p "${ZIG_DIR}"
      tar -C "${ZIG_DIR}" --strip-components=1 -xf "${ZIG_TARBALL}"
      rm -f "${ZIG_TARBALL}"
      
      libscript_symlink_alias "zig" "${ZIG_VERSION}" "${EXACT_VERSION}"
    fi
    ;;
esac
