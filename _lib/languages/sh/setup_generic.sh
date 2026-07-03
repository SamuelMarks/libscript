#!/bin/sh
# ## Overview
# Generic setup module for SH/Dash.
#
# ## Usage
# Installs Dash from source or delegates to the system package manager.


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

SH_INSTALL_METHOD="${SH_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript-native}}"
SH_VERSION="${SH_VERSION:-0.5.12}"
ACTION="${ACTION:-install}"

resolve_exact_version() {
  if [ "${SH_VERSION}" = "latest" ]; then
    EXACT_VERSION="0.5.12"
  else
    EXACT_VERSION="${SH_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "$SH_INSTALL_METHOD" = "mise" ]; then
      mise ls sh || true
    elif [ "$SH_INSTALL_METHOD" = "asdf" ]; then
      asdf list sh || true
    elif [ "$SH_INSTALL_METHOD" = "system" ]; then
      dash -v || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/sh/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$SH_INSTALL_METHOD" = "mise" ] || [ "$SH_INSTALL_METHOD" = "asdf" ]; then
      printf '%s\n' "Not supported by standard plugins"
    elif [ "$SH_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      printf '%s\n' "0.5.12"
    fi
    exit 0
    ;;
  use)
    if [ "$SH_INSTALL_METHOD" = "mise" ]; then
      mise use "sh@${SH_VERSION}"
    elif [ "$SH_INSTALL_METHOD" = "asdf" ]; then
      asdf global sh "${SH_VERSION}"
    elif [ "$SH_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "sh" "${SH_VERSION}" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  download|install|*)
    if [ "$SH_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'dash' || libscript_depends 'sh' || true
    elif [ "$SH_INSTALL_METHOD" = "mise" ]; then
      printf '%s\n' "mise does not officially support sh/dash out of the box."
    elif [ "$SH_INSTALL_METHOD" = "asdf" ]; then
      printf '%s\n' "asdf does not officially support sh/dash out of the box."
    else
      libscript_depends 'curl' 'tar' 'make' 'gcc' 'autoconf' 'automake'
      resolve_exact_version
      
      SH_DIR=$(libscript_get_version_dir "sh" "${EXACT_VERSION}")
      
      if [ -x "${SH_DIR}/bin/dash" ]; then
        libscript_symlink_alias "sh" "${SH_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      SH_URL="https://git.kernel.org/pub/scm/utils/dash/dash.git/snapshot/dash-${EXACT_VERSION}.tar.gz"
      SH_TARBALL=$(mktemp)
      libscript_download "${SH_URL}" "${SH_TARBALL}"
      
      TMP_DIR=$(mktemp -d)
      tar -C "${TMP_DIR}" -xzf "${SH_TARBALL}"
      rm -f "${SH_TARBALL}"
      
      (
        cd "${TMP_DIR}/dash-${EXACT_VERSION}"
        ./autogen.sh
        ./configure --prefix="${SH_DIR}"
        make
        make install
      )
      
      rm -rf "${TMP_DIR}"
      
      # Also link dash as sh
      ln -sf dash "${SH_DIR}/bin/sh"
      
      libscript_symlink_alias "sh" "${SH_VERSION}" "${EXACT_VERSION}"
    fi
    ;;
esac
