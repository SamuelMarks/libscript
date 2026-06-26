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
SCRIPT_DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
if [ -z "${LIBSCRIPT_ROOT_DIR:-}" ]; then
  _tmp_dir="$SCRIPT_DIR"
  while [ "$_tmp_dir" != "/" ] && [ ! -f "$_tmp_dir/libscript.sh" ]; do
    _tmp_dir="$(dirname "$_tmp_dir")"
  done
  LIBSCRIPT_ROOT_DIR="$_tmp_dir"
fi
if ! command -v paru >/dev/null 2>&1; then
  if [ -f /etc/arch-release ]; then
    if ! command -v git >/dev/null 2>&1; then
      libscript_depends git base-devel || true
    fi
    tmp_dir="$(mktemp -d)"
    git clone https://aur.archlinux.org/paru-bin.git "$tmp_dir/paru-bin"
    (cd "$tmp_dir/paru-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp_dir"
  else
    echo "paru is only supported on Arch Linux." >&2
  fi
fi
