#!/bin/sh
# ## Overview
# Test suite for the sdkman component.
#
# ## Usage
# Execute this script to perform a component-specific test.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
if [ -f "$SCRIPT_DIR/env.sh" ]; then
  unset SCRIPT_NAME || true
  . "$SCRIPT_DIR/env.sh"
fi

if [ -f /etc/alpine-release ]; then
  echo "sdkman contains binaries compiled against glibc and cannot run properly on Alpine Linux."
  exit 0
fi

if command -v bash >/dev/null 2>&1; then
  bash +eu -c "export SDKMAN_DIR=\"\${LIBSCRIPT_HOME:-\$HOME/.libscript}/sdkman/latest\"; source \"\$SDKMAN_DIR/bin/sdkman-init.sh\"; sdk version"
else
  printf '%s\n' "sdkman requires bash, which is not available."
  exit 0
fi
