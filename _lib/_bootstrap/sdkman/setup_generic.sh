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

if ! command -v sdk >/dev/null 2>&1 && [ ! -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  echo "Installing sdkman..."
  export SDKMAN_DIR="${HOME}/.sdkman"
  if command -v curl >/dev/null 2>&1; then
    curl -s "https://get.sdkman.io" | bash
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "https://get.sdkman.io" | bash
  else
    echo "Error: curl or wget is required to install sdkman." >&2
    exit 1
  fi
  # We cannot export sdkman directly into PATH the standard way because it's a bash function.
  # The user's shell profile is modified automatically.
fi
