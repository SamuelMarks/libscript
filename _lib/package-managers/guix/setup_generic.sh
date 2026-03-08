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

if ! command -v guix >/dev/null 2>&1; then
  echo "Installing GNU Guix..."
  if [ "$(id -u)" != "0" ] && ! command -v sudo >/dev/null 2>&1; then
    echo "Error: Root access or sudo is required to install Guix." >&2
    exit 1
  fi

  tmp_sh="$(mktemp -d)/guix-install.sh"
  
  if command -v wget >/dev/null 2>&1; then
    wget -qO "$tmp_sh" "https://git.savannah.gnu.org/cgit/guix.git/plain/etc/guix-install.sh"
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "https://git.savannah.gnu.org/cgit/guix.git/plain/etc/guix-install.sh" -o "$tmp_sh"
  else
    echo "Error: curl or wget required to download guix install script." >&2
    exit 1
  fi
  
  chmod +x "$tmp_sh"
  
  if [ "$(id -u)" = "0" ]; then
    yes '' | "$tmp_sh"
  else
    yes '' | sudo "$tmp_sh"
  fi
  
  rm -f "$tmp_sh"
fi
