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

  tmp_dir="$(mktemp -d)"
  tmp_tar="$tmp_dir/micromamba.tar.bz2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$URL" -o "$tmp_tar"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$tmp_tar" "$URL"
  else
    echo "Error: curl or wget required." >&2
    exit 1
  fi

  mkdir -p "$HOME/.local/bin"
  tar -xjf "$tmp_tar" -C "$tmp_dir"
  cp "$tmp_dir/bin/micromamba" "$HOME/.local/bin/"
  rm -rf "$tmp_dir"
  
  export PATH="$HOME/.local/bin:$PATH"
fi
