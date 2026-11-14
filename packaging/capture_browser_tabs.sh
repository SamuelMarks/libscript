#!/bin/sh
# ## Overview
# Launches a browser with Open edX LMS and Studio URLs and captures screenshots using
# native POSIX Wayland/X11 utilities (chromium/firefox + grim/import) without pwsh.
#
# ## Usage
# ./packaging/capture_browser_tabs.sh [--lms-url <url>] [--studio-url <url>] [--out-dir <dir>]

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

LMS_URL='http://localhost:8000'
STUDIO_URL='http://localhost:8001'
OUT_DIR="${SCRIPT_DIR}/screenshots"

# ## show_help
# Displays usage instructions for browser tab screenshot capture.
show_help() {
  printf 'Usage: %s [--lms-url <url>] [--studio-url <url>] [--out-dir <dir>]\n' "$(basename "$THIS_FILE")"
  printf 'Captures LMS and Studio browser screenshots via Chromium/Firefox or X11/Wayland capture tools.\n'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h|/\?|-\?)
      show_help
      exit 0
      ;;
    -LmsUrl|--lms-url)
      LMS_URL="$2"
      shift 2
      ;;
    -StudioUrl|--studio-url)
      STUDIO_URL="$2"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if command -v cmd.exe >/dev/null 2>&1 && [ "${OS:-}" = "Windows_NT" ]; then
  cmd.exe /c "${SCRIPT_DIR}/capture_browser_tabs.cmd" -LmsUrl "$LMS_URL" -StudioUrl "$STUDIO_URL"
  exit $?
fi

mkdir -p "$OUT_DIR"

# ## capture_url_headless
# Captures a URL screenshot using headless Chromium/Chrome or Firefox when available.
capture_url_headless() {
  _url="$1"
  _dest="$2"
  for _browser in chromium chromium-browser google-chrome firefox; do
    if command -v "$_browser" >/dev/null 2>&1; then
      case "$_browser" in
        firefox)
          "$_browser" --headless --screenshot "$_dest" "$_url" >/dev/null 2>&1 && return 0
          ;;
        *)
          "$_browser" --headless --disable-gpu --no-sandbox --screenshot="$_dest" --window-size=1280,800 "$_url" >/dev/null 2>&1 && return 0
          ;;
      esac
    fi
  done
  return 1
}

if capture_url_headless "$LMS_URL" "${OUT_DIR}/lms_tab.png" && capture_url_headless "$STUDIO_URL" "${OUT_DIR}/studio_tab.png"; then
  printf '[OK] Captured LMS and Studio screenshots in %s\n' "$OUT_DIR"
  exit 0
fi

if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v grim >/dev/null 2>&1; then
  grim "${OUT_DIR}/desktop_tabs.png"
  exit 0
fi

if [ -n "${DISPLAY:-}" ] && command -v import >/dev/null 2>&1; then
  import -window root "${OUT_DIR}/desktop_tabs.png"
  exit 0
fi

printf '[ERROR] Browser screenshot capture requires chromium, firefox, grim (Wayland), or import (X11).\n' >&2
exit 1
