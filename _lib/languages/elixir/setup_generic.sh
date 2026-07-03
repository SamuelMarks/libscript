#!/bin/sh
# ## Overview
# Generic setup module for Elixir.
#
# ## Usage
# Installs Elixir via from-source compilation or delegates to asdf/mise/system.


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

ELIXIR_INSTALL_METHOD="${ELIXIR_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript-native}}"
ELIXIR_VERSION="${ELIXIR_VERSION:-1.16.2}"
ACTION="${ACTION:-install}"

resolve_exact_version() {
  if [ "${ELIXIR_VERSION}" = "latest" ]; then
    EXACT_VERSION="1.16.2"
  else
    EXACT_VERSION="${ELIXIR_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "$ELIXIR_INSTALL_METHOD" = "mise" ]; then
      mise ls elixir
    elif [ "$ELIXIR_INSTALL_METHOD" = "asdf" ]; then
      asdf list elixir
    elif [ "$ELIXIR_INSTALL_METHOD" = "system" ]; then
      elixir -v || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/elixir/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$ELIXIR_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote elixir
    elif [ "$ELIXIR_INSTALL_METHOD" = "asdf" ]; then
      asdf list all elixir
    elif [ "$ELIXIR_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      curl -sL "https://api.github.com/repos/elixir-lang/elixir/releases" | grep -o '"tag_name": "v[^"]*"' | sed 's/"tag_name": "v//' | sed 's/"//' | head -n 100
    fi
    exit 0
    ;;
  use)
    if [ "$ELIXIR_INSTALL_METHOD" = "mise" ]; then
      mise use "elixir@${ELIXIR_VERSION}"
    elif [ "$ELIXIR_INSTALL_METHOD" = "asdf" ]; then
      asdf global elixir "${ELIXIR_VERSION}"
    elif [ "$ELIXIR_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "elixir" "${ELIXIR_VERSION}" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  download|install|*)
    if [ "$ELIXIR_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'elixir'
    elif [ "$ELIXIR_INSTALL_METHOD" = "mise" ]; then
      mise install "elixir@${ELIXIR_VERSION}"
    elif [ "$ELIXIR_INSTALL_METHOD" = "asdf" ]; then
      asdf install elixir "${ELIXIR_VERSION}"
    else
      libscript_depends 'curl' 'tar' 'make' 'erlang'
      resolve_exact_version
      
      ELIXIR_DIR=$(libscript_get_version_dir "elixir" "${EXACT_VERSION}")
      
      if [ -x "${ELIXIR_DIR}/bin/elixir" ]; then
        libscript_symlink_alias "elixir" "${ELIXIR_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      ELIXIR_URL="https://github.com/elixir-lang/elixir/archive/refs/tags/v${EXACT_VERSION}.tar.gz"
      ELIXIR_TARBALL=$(mktemp)
      libscript_download "${ELIXIR_URL}" "${ELIXIR_TARBALL}"
      
      TMP_DIR=$(mktemp -d)
      tar -C "${TMP_DIR}" -xzf "${ELIXIR_TARBALL}"
      rm -f "${ELIXIR_TARBALL}"
      
      (
        cd "${TMP_DIR}/elixir-${EXACT_VERSION}"
        make install PREFIX="${ELIXIR_DIR}"
      )
      
      rm -rf "${TMP_DIR}"
      
      libscript_symlink_alias "elixir" "${ELIXIR_VERSION}" "${EXACT_VERSION}"
    fi
    ;;
esac
