#!/bin/sh
# ## Overview
# Setup wrapper for Bootstrap Toolchain.
#
# ## Usage
# ./setup.sh [action]

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
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}:"

SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"

TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/bootstrap/latest"
mkdir -p "$TARGET_DIR"

if ! command -v gcc >/dev/null 2>&1 && ! command -v cc >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1; then
  if command -v apk >/dev/null 2>&1; then
    if ! command -v priv >/dev/null 2>&1; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/priv.sh"
      export SCRIPT_NAME
      # shellcheck disable=SC1090
      . "${SCRIPT_NAME}"
    fi
    priv apk add --no-cache gcc musl-dev || true
  elif command -v apt-get >/dev/null 2>&1; then
    if ! command -v priv >/dev/null 2>&1; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/priv.sh"
      export SCRIPT_NAME
      # shellcheck disable=SC1090
      . "${SCRIPT_NAME}"
    fi
    priv apt-get update -qq || true
    priv apt-get install -y gcc build-essential || true
  elif command -v dnf >/dev/null 2>&1; then
    if ! command -v priv >/dev/null 2>&1; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/priv.sh"
      export SCRIPT_NAME
      # shellcheck disable=SC1090
      . "${SCRIPT_NAME}"
    fi
    priv dnf install -y gcc || true
  fi
fi

exit 0
