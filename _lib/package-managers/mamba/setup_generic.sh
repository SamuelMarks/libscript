#!/bin/sh
set -feu
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${0}"
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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091,SC2034
. "${SCRIPT_NAME}"

if ! command -v micromamba >/dev/null 2>&1 && ! command -v mamba >/dev/null 2>&1; then
  echo "Installing micromamba..."
  OS="$(uname -s)"
  ARCH="$(uname -m)"
  
  if [ "$OS" = "Linux" ]; then
    if [ "$ARCH" = "x86_64" ]; then
      URL="https://micro.mamba.pm/api/micromamba/linux-64/latest"
    elif [ "$ARCH" = "aarch64" ]; then
      URL="https://micro.mamba.pm/api/micromamba/linux-aarch64/latest"
    else
      echo "Error: Unsupported architecture $ARCH for micromamba." >&2
      exit 1
    fi
  elif [ "$OS" = "Darwin" ]; then
    if [ "$ARCH" = "x86_64" ]; then
      URL="https://micro.mamba.pm/api/micromamba/osx-64/latest"
    elif [ "$ARCH" = "arm64" ]; then
      URL="https://micro.mamba.pm/api/micromamba/osx-arm64/latest"
    else
      echo "Error: Unsupported architecture $ARCH for micromamba." >&2
      exit 1
    fi
  else
    echo "Error: Unsupported OS $OS for micromamba automated install." >&2
    exit 1
  fi

  tmp_dir="/tmp/micromamba-install"
  mkdir -p "$tmp_dir"
  tmp_tar="$tmp_dir/micromamba.tar.bz2"
  libscript_download "$URL" "$tmp_tar"

  mkdir -p "$HOME/.local/bin"
  tar -xjf "$tmp_tar" -C "$tmp_dir"
  cp "$tmp_dir/bin/micromamba" "$HOME/.local/bin/"
  rm -rf "$tmp_dir"
  
  export PATH="$HOME/.local/bin:$PATH"
fi
