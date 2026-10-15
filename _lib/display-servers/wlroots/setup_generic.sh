#!/bin/sh
# ## Overview
# Generic installation and sysroot staging recipe for the wlroots component.
# Checks idempotency against target sysroot stamps and delegates package installation to libscript_depends.
#
# ## Usage
# ./setup_generic.sh [action]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
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

for LIB in "_lib/_common/log.sh" "_lib/_common/pkg_mgr.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

ACTION="${1:-${ACTION:-install}}"
VERSION="${VERSION:-latest}"
TARGET_SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}"
STAMPS_DIR="${TARGET_SYSROOT}/var/lib/libscript/stamps"
STAMP_FILE="${STAMPS_DIR}/.stamp.wlroots"
TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/wlroots/${VERSION}"

if [ -x "${TARGET_DIR}/bin/wlroots" ]; then
  log_info "wlroots ${VERSION} is already installed at ${TARGET_DIR}."
  exit 0
fi

mkdir -p "$STAMPS_DIR"
mkdir -p "$TARGET_DIR"

if [ -f "$STAMP_FILE" ]; then
  log_info "wlroots is already staged at ${STAMP_FILE}."
  exit 0
fi

if ! command -v "wlroots" >/dev/null 2>&1; then
  libscript_depends "wlroots"
fi

printf '[RECIPE] Staging %s into %s (action: %s)\n' "wlroots" "$TARGET_SYSROOT" "$ACTION"
date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK]    %s staged successfully: %s\n' "wlroots" "$STAMP_FILE"
