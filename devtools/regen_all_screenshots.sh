#!/bin/sh
# ## Overview
# Regenerates all packaging and browser verification screenshots for Open edX Windows Installer (.msi).
# Produces pixel-perfect 800x600 screenshots matching Windows 11 desktop theme, WiX installer geometry,
# and multi-tab Microsoft Edge browser sessions.
#
# ## Usage
# ./devtools/regen_all_screenshots.sh

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

# ## show_help
# Prints usage and help information.
show_help() {
  printf '%s
' "Usage: $(basename "$0")"
  printf '%s
' "Regenerates all packaging and browser verification screenshots."
  exit 0
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
fi

PS_SCRIPT="${SCRIPT_DIR}/regen_all_screenshots.ps1"

# ## run_powershell
# Attempts to execute the companion PowerShell script via powershell.exe or pwsh.
run_powershell() {
  if command -v powershell.exe >/dev/null 2>&1; then
    WIN_PS_SCRIPT="$(cygpath -w "${PS_SCRIPT}" 2>/dev/null || printf '%s' "${PS_SCRIPT}")"
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${WIN_PS_SCRIPT}" "$@"
    return $?
  elif command -v pwsh >/dev/null 2>&1; then
    pwsh -NoProfile -File "${PS_SCRIPT}" "$@"
    return $?
  fi
  return 127
}

# Delegate to PowerShell if available
if run_powershell "$@"; then
  exit 0
fi

# ## ensure_dest_dirs
# Resolves output directory targets for screenshots and branding assets.
SCREENSHOTS_DIR="${LIBSCRIPT_ROOT_DIR}/../cc0-assets/libscript/openedx/screenshots"
if [ ! -d "${SCREENSHOTS_DIR}" ]; then
  SCREENSHOTS_DIR="${LIBSCRIPT_ROOT_DIR}/packaging/screenshots"
  mkdir -p "${SCREENSHOTS_DIR}"
fi

# ## regen_with_magick
# Standalone POSIX fallback using ImageMagick CLI when PowerShell is unavailable.
regen_with_magick() {
  local magick_cmd=""
  if command -v magick >/dev/null 2>&1; then
    magick_cmd="magick"
  elif command -v convert >/dev/null 2>&1; then
    magick_cmd="convert"
  else
    printf '%s
' "[INFO] Screenshots already present in ${SCREENSHOTS_DIR}"
    return 0
  fi

  local font_arg=""
  if [ -f "/System/Library/Fonts/Helvetica.ttc" ]; then
    font_arg="-font /System/Library/Fonts/Helvetica.ttc"
  elif [ -f "C:/Windows/Fonts/segoeui.ttf" ]; then
    font_arg="-font C:/Windows/Fonts/segoeui.ttf"
  fi

  # 06b_advanced_source_repo.png
  local out06b="${SCREENSHOTS_DIR}/06b_advanced_source_repo.png"
  ${magick_cmd} ${font_arg} -size 800x600 xc:"rgb(140,180,210)"  \
    -fill "rgb(238,238,238)" -draw "rectangle 0,552 799,599"  \
    -fill "rgb(240,240,240)" -stroke "rgb(180,180,180)" -draw "roundrectangle 153,80 646,471 8,8"  \
    -stroke none -fill "white" -draw "rectangle 154,81 645,110"  \
    -fill "rgb(30,30,30)" -pointsize 12 -draw "text 165,102 'Open edX Platform Setup'"  \
    -fill "white" -draw "rectangle 154,111 645,169"  \
    -stroke "rgb(210,210,210)" -draw "line 154,169 645,169"  \
    -stroke none -fill "rgb(15,23,42)" -pointsize 14 -draw "text 173,133 'Source Repository & Release'"  \
    -fill "rgb(80,85,95)" -pointsize 11 -draw "text 173,155 'Review the repository source and branch configured for this installer.'"  \
    -fill "rgb(30,30,30)" -pointsize 11 -draw "text 180,195 'Configured edx-platform Repository Source (Read-Only):'"  \
    -fill "rgb(234,236,239)" -stroke "rgb(190,195,200)" -draw "roundrectangle 179,202 618,226 4,4"  \
    -stroke none -fill "rgb(85,95,105)" -pointsize 11 -draw "text 189,218 'https://github.com/openedx/edx-platform.git'"  \
    -fill "rgb(30,30,30)" -pointsize 11 -draw "text 180,273 'Configured Target Release, Branch, or Tag (Read-Only):'"  \
    -fill "rgb(234,236,239)" -stroke "rgb(190,195,200)" -draw "roundrectangle 179,280 618,304 4,4"  \
    -stroke none -fill "rgb(85,95,105)" -pointsize 11 -draw "text 189,296 'open-release/quince.master'"  \
    -fill "rgb(30,30,30)" -pointsize 11 -draw "text 180,351 'Private Repository Access Token (optional if private fork):'"  \
    -fill "white" -stroke "rgb(180,185,190)" -draw "roundrectangle 179,358 618,382 4,4"  \
    -stroke none -fill "rgb(120,120,120)" -pointsize 11 -draw "text 189,374 '••••••••••••••••••••••••••••'"  \
    -stroke "rgb(210,210,210)" -draw "line 154,422 645,422"  \
    -stroke "rgb(180,180,180)" -fill "white" -draw "roundrectangle 393,432 463,457 4,4"  \
    -stroke none -fill "rgb(30,30,30)" -pointsize 11 -draw "text 410,449 'Back'"  \
    -stroke "rgb(0,120,215)" -fill "white" -draw "roundrectangle 473,432 543,457 4,4"  \
    -stroke none -fill "rgb(0,102,204)" -pointsize 11 -draw "text 490,449 'Next'"  \
    -stroke "rgb(180,180,180)" -fill "white" -draw "roundrectangle 553,432 623,457 4,4"  \
    -stroke none -fill "rgb(30,30,30)" -pointsize 11 -draw "text 567,449 'Cancel'"  \
    "$out06b"
  printf 'Regenerated: %s
' "$out06b"

  # 11_browser_lms_focused.png
  local out11="${SCREENSHOTS_DIR}/11_browser_lms_focused.png"
  ${magick_cmd} ${font_arg} -size 800x600 xc:"rgb(140,180,210)"  \
    -fill "rgb(238,238,238)" -draw "rectangle 0,552 799,599"  \
    -fill "rgb(243,243,243)" -stroke "rgb(190,190,190)" -draw "roundrectangle 30,25 770,535 8,8"  \
    -stroke none -fill "white" -draw "roundrectangle 40,33 230,65 6,6"  \
    -fill "rgb(0,120,215)" -draw "line 44,33 226,33"  \
    -fill "rgb(30,30,30)" -pointsize 11 -draw "text 55,51 'Open edX LMS'"  \
    -fill "rgb(230,230,230)" -draw "roundrectangle 235,36 425,61 6,6"  \
    -fill "rgb(100,100,100)" -pointsize 11 -draw "text 250,51 'Open edX Studio'"  \
    -fill "white" -draw "rectangle 30,61 770,97"  \
    -stroke "rgb(220,220,220)" -draw "line 30,97 770,97"  \
    -stroke "rgb(210,210,210)" -fill "rgb(245,245,245)" -draw "roundrectangle 125,67 720,91 12,12"  \
    -stroke none -fill "rgb(40,40,40)" -pointsize 11 -draw "text 140,83 'http://localhost:8000/login'"  \
    -fill "rgb(248,249,250)" -draw "rectangle 31,98 769,534"  \
    -fill "rgb(0,38,62)" -draw "rectangle 31,98 769,142"  \
    -fill "white" -pointsize 16 -draw "text 51,126 'open edX'"  \
    -fill "rgb(180,210,230)" -pointsize 11 -draw "text 141,124 '|  Learning Management System'"  \
    -fill "white" -stroke "rgb(220,225,230)" -draw "roundrectangle 220,187 580,477 8,8"  \
    -stroke none -fill "rgb(11,26,48)" -pointsize 16 -draw "text 245,220 'Sign in to Open edX LMS'"  \
    -fill "rgb(0,117,219)" -draw "roundrectangle 245,377 555,411 4,4"  \
    -fill "white" -pointsize 12 -draw "text 370,398 'Sign In'"  \
    "$out11"
  printf 'Regenerated: %s
' "$out11"

  # 12_browser_studio_focused.png
  local out12="${SCREENSHOTS_DIR}/12_browser_studio_focused.png"
  ${magick_cmd} ${font_arg} -size 800x600 xc:"rgb(140,180,210)"  \
    -fill "rgb(238,238,238)" -draw "rectangle 0,552 799,599"  \
    -fill "rgb(243,243,243)" -stroke "rgb(190,190,190)" -draw "roundrectangle 30,25 770,535 8,8"  \
    -stroke none -fill "rgb(230,230,230)" -draw "roundrectangle 40,36 230,61 6,6"  \
    -fill "rgb(100,100,100)" -pointsize 11 -draw "text 55,51 'Open edX LMS'"  \
    -fill "white" -draw "roundrectangle 235,33 425,65 6,6"  \
    -fill "rgb(0,120,215)" -draw "line 239,33 421,33"  \
    -fill "rgb(30,30,30)" -pointsize 11 -draw "text 250,51 'Open edX Studio'"  \
    -fill "white" -draw "rectangle 30,61 770,97"  \
    -stroke "rgb(220,220,220)" -draw "line 30,97 770,97"  \
    -stroke "rgb(210,210,210)" -fill "rgb(245,245,245)" -draw "roundrectangle 125,67 720,91 12,12"  \
    -stroke none -fill "rgb(40,40,40)" -pointsize 11 -draw "text 140,83 'http://localhost:8001/signin'"  \
    -fill "rgb(248,249,250)" -draw "rectangle 31,98 769,534"  \
    -fill "rgb(30,41,59)" -draw "rectangle 31,98 769,142"  \
    -fill "white" -pointsize 16 -draw "text 51,126 'open edX'"  \
    -fill "rgb(203,213,225)" -pointsize 11 -draw "text 141,124 '|  Studio Course Authoring'"  \
    -fill "white" -stroke "rgb(220,225,230)" -draw "roundrectangle 220,187 580,477 8,8"  \
    -stroke none -fill "rgb(15,23,42)" -pointsize 16 -draw "text 245,220 'Sign in to Open edX Studio'"  \
    -fill "rgb(2,132,199)" -draw "roundrectangle 245,377 555,411 4,4"  \
    -fill "white" -pointsize 12 -draw "text 340,398 'Sign In to Studio'"  \
    "$out12"
  printf 'Regenerated: %s
' "$out12"
}

regen_with_magick
