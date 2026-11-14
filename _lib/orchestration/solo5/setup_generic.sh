#!/bin/sh
# ## Overview
# Solo5 and MirageOS tender installation and execution engine supporting solo5-hvt and solo5-spt.
# ## Usage
# ./_lib/orchestration/solo5/setup.sh [install|configure|compile|boot] [unikernel_bin] [hvt|spt]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
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
export LIBSCRIPT_ROOT_DIR

ACTION="${1:-install}"
BIN="${2:-${LIBSCRIPT_ROOT_DIR}/build/unikernel.hvt}"
TENDER="${3:-hvt}"
SOLO5_VER="${SOLO5_VERSION:-0.9.0}"
SOLO5_PREFIX="${LIBSCRIPT_HOME:-${HOME:-/tmp}/.libscript}/solo5/${SOLO5_VER}"

TARGET_SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}"
STAMPS_DIR="${TARGET_SYSROOT}/var/lib/libscript/stamps"
mkdir -p "$STAMPS_DIR"
STAMP_FILE="${STAMPS_DIR}/.stamp.solo5"

case "$ACTION" in
  install|configure|compile)
    if [ -x "${SOLO5_PREFIX}/bin/solo5-hvt" ] || command -v solo5-hvt >/dev/null 2>&1; then
      printf '[SKIP] Solo5 tender already installed.\n'
      printf 'mode=native\ntimestamp=%s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
      mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
      exit 0
    fi
    mkdir -p "${SOLO5_PREFIX}/bin"
    STAMP_MODE='stub'
    if command -v opam >/dev/null 2>&1 && [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ]; then
      opam install -y solo5 >/dev/null 2>&1 || true
      if command -v solo5-hvt >/dev/null 2>&1; then
        ln -sf "$(command -v solo5-hvt)" "${SOLO5_PREFIX}/bin/solo5-hvt"
        STAMP_MODE='native'
      fi
    elif [ "${SOLO5_BUILD_FROM_SOURCE:-0}" = "1" ] && command -v cc >/dev/null 2>&1 && command -v make >/dev/null 2>&1 && [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ]; then
      _src_tmp="${TMPDIR:-/tmp}/solo5_build_$$"
      mkdir -p "$_src_tmp"
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mgr.sh"; export SCRIPT_NAME
      # shellcheck disable=SC1090,SC1091
      . "${SCRIPT_NAME}"; unset SCRIPT_NAME || true
      if libscript_download "https://github.com/Solo5/solo5/releases/download/v${SOLO5_VER}/solo5-v${SOLO5_VER}.tar.gz" "${_src_tmp}/solo5.tar.gz" 2>/dev/null; then
        tar -xzf "${_src_tmp}/solo5.tar.gz" -C "$_src_tmp" --strip-components=1
        (cd "$_src_tmp" && ./configure.sh && make -j2) >/dev/null 2>&1 || true
        if [ -x "${_src_tmp}/tenders/hvt/solo5-hvt" ]; then
          cp -f "${_src_tmp}/tenders/hvt/solo5-hvt" "${SOLO5_PREFIX}/bin/solo5-hvt"
          STAMP_MODE='native'
        fi
        if [ -x "${_src_tmp}/tenders/spt/solo5-spt" ]; then
          cp -f "${_src_tmp}/tenders/spt/solo5-spt" "${SOLO5_PREFIX}/bin/solo5-spt"
        fi
      fi
      rm -rf "$_src_tmp"
    fi
    if [ "$STAMP_MODE" = "stub" ] && [ "${LIBSCRIPT_STRICT_IMAGE_BUILD:-0}" = "1" ] && [ "${LIBSCRIPT_ALLOW_STUB:-0}" != "1" ]; then
      printf '[ERROR] Solo5 tender binary unavailable in strict mode. Install opam/solo5 or set SOLO5_BUILD_FROM_SOURCE=1.\n' >&2
      exit 1
    fi
    printf 'mode=%s\ntimestamp=%s\n' "$STAMP_MODE" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
    mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
    printf '[OK] Solo5 tender environment configured (%s).\n' "$STAMP_MODE"
    ;;

  boot)
    TENDER_BIN="solo5-${TENDER}"
    if [ -x "${SOLO5_PREFIX}/bin/${TENDER_BIN}" ]; then
      TENDER_BIN="${SOLO5_PREFIX}/bin/${TENDER_BIN}"
    fi
    if [ ! -s "$BIN" ]; then
      printf '[ERROR] Unikernel image not found at %s. Synthesize image via package-as unikernel first.\n' "$BIN" >&2
      exit 1
    fi
    if command -v "$TENDER_BIN" >/dev/null 2>&1 || [ -x "$TENDER_BIN" ]; then
      printf '[ORCHESTRATION] Booting Solo5 unikernel with %s...\n' "$TENDER_BIN"
      "$TENDER_BIN" "$BIN"
    else
      printf '[INFO] %s not found in PATH; verified unikernel image at %s\n' "$TENDER_BIN" "$BIN"
    fi
    ;;
esac
exit 0
