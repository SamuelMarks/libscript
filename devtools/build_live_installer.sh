#!/bin/sh
# ## Overview
# Unified Live Media Generator CLI for LibScript msi-rs live-CD and live-USB distributions.
# Orchestrates building bootable ISO and raw disk images for Linux, FreeBSD, and illumos
# with support for headless, TUI, and GUI kiosk interaction modes.
#
# ## Usage
# Execute this script to generate target live media:
#   ./devtools/build_live_installer.sh [--target <linux|freebsd|illumos|all>] [--mode <all|headless|tui|gui>] [--output <path>]

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
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

TARGET_OS="all"
MODE="all"
OUTPUT_PATH=""

# ## show_help
# Displays usage instructions and supported build parameters.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") [OPTIONS]"
  printf '%s
' "Builds bootable live-CD/live-USB images containing msi-rs."
  printf '
'
  printf '%s
' "Targets:"
  printf '%s
' "  --target <linux|freebsd|illumos|all>   Target OS distribution family (default: all)"
  printf '
'
  printf '%s
' "Modes:"
  printf '%s
' "  --mode <all|headless|tui|gui>          Installer interaction mode embedded (default: all)"
  printf '
'
  printf '%s
' "Options:"
  printf '%s
' "  --output <file_path>                   Output image path override"
  printf '%s
' "  --help, -h, /?, -?                     Show this help message"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target)
      TARGET_OS="${2:-all}"
      shift 2
      ;;
    --mode)
      MODE="${2:-all}"
      shift 2
      ;;
    --output)
      OUTPUT_PATH="${2:-}"
      shift 2
      ;;
    --help|-h|/\?|-\?)
      show_help
      exit 0
      ;;
    *)
      printf '[WARN] Unknown option: %s
' "$1" >&2
      shift
      ;;
  esac
done

mkdir -p "${REPO_ROOT}/build"

# ## build_linux
# Builds live Linux media.
build_linux() {
  _out="${OUTPUT_PATH:-${REPO_ROOT}/build/msi-linux-live.iso}"
  printf '[ORCHESTRATE] Building Live Linux installer (%s)...
' "$MODE"
  "${REPO_ROOT}/_lib/orchestration/distro/live_linux.sh" "alpine" "$_out" "${REPO_ROOT}/build/live-linux-stage"
}

# ## build_freebsd
# Builds live FreeBSD media.
build_freebsd() {
  _out="${OUTPUT_PATH:-${REPO_ROOT}/build/msi-freebsd-live.iso}"
  printf '[ORCHESTRATE] Building Live FreeBSD installer (%s)...
' "$MODE"
  "${REPO_ROOT}/_lib/freebsd/distro/live_freebsd.sh" "$_out" "${REPO_ROOT}/build/live-freebsd-stage"
}

# ## build_illumos
# Builds live illumos media.
build_illumos() {
  _out="${OUTPUT_PATH:-${REPO_ROOT}/build/msi-illumos-live.iso}"
  printf '[ORCHESTRATE] Building Live illumos installer (%s)...
' "$MODE"
  "${REPO_ROOT}/_lib/illumos/distro/live_illumos.sh" "$_out" "${REPO_ROOT}/build/live-illumos-stage"
}

case "$TARGET_OS" in
  linux)
    build_linux
    ;;
  freebsd)
    build_freebsd
    ;;
  illumos)
    build_illumos
    ;;
  all)
    build_linux
    build_freebsd
    build_illumos
    ;;
  *)
    printf '[ERROR] Unsupported target OS: %s
' "$TARGET_OS" >&2
    exit 1
    ;;
esac

printf '[OK] Live media generation completed successfully.
'
exit 0
