#!/bin/sh

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
DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(D="${DIR}"; while [ ! -f "${D}/ROOT" ] && [ "${D}" != "/" ]; do D="$(dirname -- "${D}")"; done; [ "${D}" = "/" ] && D="${DIR}"; printf '%s' "${D}")}"

for LIB in _lib/_common/pkg_mgr.sh ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

if ! command -v micromamba >/dev/null 2>&1 && ! command -v mamba >/dev/null 2>&1; then
  log_info "Installing micromamba..."
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
