#!/bin/sh
# ## Overview
# Unified cross-platform test runner for .msi building, GUI wizard stage verification
# (quick-install and custom-install flows), window-cropped screenshot validation in
# ../cc0-assets/libscript, and ../bento Vagrant box verification across Windows, Linux,
# macOS, FreeBSD, and illumos (OmniOS). Uses SamuelMarks/msi-rs across all 5 platforms
# and restricts optional WiX comparison (--use-wix / --compare-wix) strictly to Windows.
#
# ## Usage
# ./tests/test_msi_vagrant_matrix.sh [--os <windows|linux|macos|freebsd|illumos|all>] [--target <openedx|wordpress|sqlite|all>] [--use-wix] [--compare-wix] [--live-vagrant]

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
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"

OS_TARGET='all'
PKG_TARGET='all'
USE_WIX=0
COMPARE_WIX=0
LIVE_VAGRANT=0

# ## show_help
# Displays usage instructions for test_msi_vagrant_matrix.sh.
show_help() {
  printf 'Usage: %s [--os <windows|linux|macos|freebsd|illumos|all>] [--target <openedx|wordpress|sqlite|all>] [--use-wix] [--compare-wix] [--live-vagrant]
' "$0"
  printf 'Runs the cross-platform msi-rs build, GUI stage capture, and ../bento Vagrant test matrix.
'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --os)
      OS_TARGET="$2"
      shift 2
      ;;
    --target)
      PKG_TARGET="$2"
      shift 2
      ;;
    --use-wix)
      USE_WIX=1
      shift
      ;;
    --compare-wix)
      COMPARE_WIX=1
      shift
      ;;
    --live-vagrant)
      LIVE_VAGRANT=1
      shift
      ;;
    --help|-h|/\?|-\?)
      show_help
      exit 0
      ;;
    *)
      PKG_TARGET="$1"
      shift
      ;;
  esac
done

# ## validate_wix_os_scope
# Enforces that WiX (--use-wix / --compare-wix) is never tested outside of Windows.
validate_wix_os_scope() {
  if [ "$USE_WIX" -eq 1 ] || [ "$COMPARE_WIX" -eq 1 ]; then
    if [ "$OS_TARGET" != "windows" ] && [ "$OS_TARGET" != "all" ]; then
      printf '[ERROR] WiX only supports Windows; refusing to test WiX on %s.
' "$OS_TARGET" >&2
      exit 1
    fi
  fi
}

# ## run_matrix
# Executes the end-to-end verification pipeline across requested OS and package targets.
run_matrix() {
  validate_wix_os_scope

  printf '==> [1/5] Verifying ../bento Vagrant boxes across all 5 OS families...
'
  "${LIBSCRIPT_ROOT_DIR}/tests/register_bento_boxes.sh"

  printf '==> [2/5] Verifying SamuelMarks/msi-rs Tier 1 component...
'
  "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/msi-rs/test.sh"

  printf '==> [3/5] Capturing window-cropped .msi GUI stages (quick-install & custom-install)...
'
  "${LIBSCRIPT_ROOT_DIR}/devtools/capture_msi_vagrant_matrix.sh" --target "$PKG_TARGET" --os "$OS_TARGET" --variant both --flow both

  printf '==> [4/5] Validating cropped installer window screenshots in ../cc0-assets/libscript...
'
  if [ "$PKG_TARGET" = "all" ]; then
    "${LIBSCRIPT_ROOT_DIR}/devtools/verify_screenshots.sh" --target openedx
    "${LIBSCRIPT_ROOT_DIR}/devtools/verify_screenshots.sh" --target wordpress
    "${LIBSCRIPT_ROOT_DIR}/devtools/verify_screenshots.sh" --target sqlite
  else
    "${LIBSCRIPT_ROOT_DIR}/devtools/verify_screenshots.sh" --target "$PKG_TARGET"
  fi

  if [ "$COMPARE_WIX" -eq 1 ]; then
    printf '==> [4b/5] Running Windows-only differential comparison against WiX...
'
    "${LIBSCRIPT_ROOT_DIR}/packaging/compare_msirs_wix.sh" --target "_lib/web-apps/openedx"
  fi

  if [ "$LIVE_VAGRANT" -eq 1 ]; then
    printf '==> [5/5] Executing live Vagrant guest verification across ../bento VMs...
'
    "${LIBSCRIPT_ROOT_DIR}/tests/test_msi_rs_vagrant.sh"
  else
    printf '==> [5/5] Matrix verification complete (pass --live-vagrant to boot full guest VMs).
'
  fi

  printf '[PASS] Cross-platform msi-rs Vagrant matrix succeeded!
'
}

run_matrix
