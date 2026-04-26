#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
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

for lib in '_lib/_common/pkg_mgr.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

if ! command -v dart >/dev/null 2>&1 && ! command -v pub >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    brew tap dart-lang/dart
    brew install dart
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y apt-transport-https
    _tmp_key="/tmp/dart-signing-key.pub"
    libscript_download "https://dl-ssl.google.com/linux/linux_signing_key.pub" "$_tmp_key"
    cat "$_tmp_key" | sudo gpg --dearmor -o /usr/share/keyrings/dart.gpg
    rm -f "$_tmp_key"
    echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | sudo tee /etc/apt/sources.list.d/dart_stable.list
    sudo apt-get update -y
    sudo apt-get install -y dart
    export PATH="$PATH:/usr/lib/dart/bin"
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm dart
  elif command -v dnf >/dev/null 2>&1; then
    # Unofficial, often people use precompiled binary or brew on linux
    printf "Please install dart manually on this distribution.\n" >&2
  else
    depends dart || printf "Warning: Could not automatically install Dart.\n" >&2
  fi
fi

# Try to link pub if only dart is present
if command -v dart >/dev/null 2>&1 && ! command -v pub >/dev/null 2>&1; then
  DART_BIN="$(command -v dart)"
  PUB_BIN="$(dirname "$DART_BIN")/pub"
  if [ -x "$PUB_BIN" ]; then
    # It exists but maybe not in PATH if PATH isn't updated yet in current shell
    :
  else
    # Create a shim for pub if it doesn't exist
    if [ -w "$(dirname "$DART_BIN")" ]; then
      printf '#!/bin/sh\nexec "%s" pub "$@"\n' "$DART_BIN" > "$PUB_BIN"
      chmod +x "$PUB_BIN"
    fi
  fi
fi
