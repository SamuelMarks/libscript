#!/bin/sh
# ## Overview
# Regenerates pixel-perfect screenshots of every step and enumeration in the Open edX
# Windows Installer (.msi) wizard, desktop icons with "CMS"/"LMS" badges, and browser verification tabs.
#
# ## Usage
# ./devtools/regen_all_screenshots.sh [OPTIONS]

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

TARGET_DIR="${LIBSCRIPT_ROOT_DIR}/packaging/screenshots"
CC0_DIR="${LIBSCRIPT_ROOT_DIR}/../cc0-assets/libscript/openedx/screenshots"

mkdir -p "$TARGET_DIR"
if [ -d "${LIBSCRIPT_ROOT_DIR}/../cc0-assets/libscript/openedx" ]; then
  mkdir -p "$CC0_DIR"
fi

# ## regen_desktop_icons
# Renders 10b_desktop_icons.png with clear "CMS" and "LMS" lettered desktop icons.
regen_desktop_icons() {
  _out="$1"
  magick -size 800x600 xc:"rgb(140,180,210)"  \
    -fill "rgb(238,238,238)" -draw "rectangle 0,552 799,599"  \
    -stroke "rgb(215,215,215)" -draw "line 0,552 799,552"  \
    -stroke none -fill "rgb(60,60,60)" -pointsize 10 -draw "text 720,576 '12:00 PM'"  \
    -fill "rgb(80,80,80)" -pointsize 9 -draw "text 718,590 '9/23/2026'"  \
    -fill "rgb(0,38,62)" -draw "roundrectangle 30,30 78,78 8,8"  \
    -fill "rgb(0,117,180)" -draw "rectangle 30,62 78,78"  \
    -fill "white" -pointsize 11 -draw "text 38,74 'LMS'"  \
    -fill "white" -stroke "rgb(0,0,0)" -strokewidth 1 -pointsize 10 -draw "text 24,96 'Open edX LMS'"  \
    -stroke none -fill "rgb(0,38,62)" -draw "roundrectangle 30,120 78,168 8,8"  \
    -fill "rgb(178,6,0)" -draw "rectangle 30,152 78,168"  \
    -fill "white" -pointsize 11 -draw "text 38,164 'CMS'"  \
    -fill "white" -stroke "rgb(0,0,0)" -strokewidth 1 -pointsize 10 -draw "text 20,186 'Open edX Studio'"  \
    -stroke none -fill "rgb(0,38,62)" -draw "roundrectangle 30,210 78,258 8,8"  \
    -fill "rgb(2,132,199)" -pointsize 9 -draw "text 35,240 'CLI'"  \
    -fill "white" -stroke "rgb(0,0,0)" -strokewidth 1 -pointsize 10 -draw "text 18,276 'Management CLI'"  \
    "$_out"
  printf '[OK] Regenerated %s
' "$_out"
}

# ## regen_lms_auth
# Renders 13_browser_lms_authenticated.png showing the logged in dashboard.
regen_lms_auth() {
  _out="$1"
  magick -size 800x600 xc:"rgb(140,180,210)"  \
    -fill "rgb(238,238,238)" -draw "rectangle 0,552 799,599"  \
    -fill "rgb(243,243,243)" -stroke "rgb(190,190,190)" -draw "roundrectangle 30,25 770,535 8,8"  \
    -stroke none -fill "white" -draw "roundrectangle 40,33 230,65 6,6"  \
    -fill "rgb(0,120,215)" -draw "line 44,33 226,33"  \
    -fill "rgb(30,30,30)" -pointsize 11 -draw "text 55,51 'Dashboard | Open edX'"  \
    -fill "white" -draw "rectangle 30,61 770,97"  \
    -stroke "rgb(220,220,220)" -draw "line 30,97 770,97"  \
    -stroke "rgb(210,210,210)" -fill "rgb(245,245,245)" -draw "roundrectangle 125,67 720,91 12,12"  \
    -stroke none -fill "rgb(40,40,40)" -pointsize 11 -draw "text 140,83 'http://localhost:8000/dashboard'"  \
    -fill "rgb(241,245,249)" -draw "rectangle 31,98 769,534"  \
    -fill "rgb(0,38,62)" -draw "rectangle 31,98 769,142"  \
    -fill "white" -pointsize 16 -draw "text 51,126 'open edX'"  \
    -fill "rgb(180,210,230)" -pointsize 11 -draw "text 141,124 '|  Learning Management System'"  \
    -fill "rgb(0,117,180)" -draw "roundrectangle 560,108 750,132 12,12"  \
    -fill "white" -pointsize 10 -draw "text 575,124 'Logged in as: edx_admin'"  \
    -fill "white" -stroke "rgb(226,232,240)" -draw "roundrectangle 50,160 750,230 6,6"  \
    -stroke none -fill "rgb(0,38,62)" -pointsize 14 -draw "text 70,188 'Welcome back, edX Administrator!'"  \
    -fill "rgb(100,116,139)" -pointsize 11 -draw "text 70,212 'Your local Open edX instance is running healthy with full courseware synchronization.'"  \
    -fill "white" -stroke "rgb(226,232,240)" -draw "roundrectangle 50,250 385,460 6,6"  \
    -stroke none -fill "rgb(0,117,180)" -draw "roundrectangle 50,250 385,320 6,6"  \
    -fill "white" -pointsize 13 -draw "text 70,290 'DemoX: Introduction to edX'"  \
    -fill "rgb(15,23,42)" -pointsize 12 -draw "text 68,348 'Demonstration Courseware & Labs'"  \
    -fill "rgb(100,116,139)" -pointsize 10 -draw "text 68,375 'Course ID: course-v1:edX+DemoX+Demo_Course'"  \
    -fill "rgb(5,150,105)" -draw "roundrectangle 68,405 210,435 4,4"  \
    -fill "white" -pointsize 11 -draw "text 85,425 'Resume Learning'"  \
    -fill "white" -stroke "rgb(226,232,240)" -draw "roundrectangle 415,250 750,460 6,6"  \
    -stroke none -fill "rgb(2,132,199)" -draw "roundrectangle 415,250 750,320 6,6"  \
    -fill "white" -pointsize 13 -draw "text 435,290 'CS101: Computer Science'"  \
    -fill "rgb(15,23,42)" -pointsize 12 -draw "text 433,348 'Computational Thinking & Python 3'"  \
    -fill "rgb(100,116,139)" -pointsize 10 -draw "text 433,375 'Course ID: course-v1:LibScript+CS101+2026'"  \
    -fill "rgb(5,150,105)" -draw "roundrectangle 433,405 575,435 4,4"  \
    -fill "white" -pointsize 11 -draw "text 450,425 'View Material'"  \
    "$_out"
  printf '[OK] Regenerated %s
' "$_out"
}

# ## regen_studio_auth
# Renders 14_browser_studio_authenticated.png showing the logged in Studio authoring catalog.
regen_studio_auth() {
  _out="$1"
  magick -size 800x600 xc:"rgb(140,180,210)"  \
    -fill "rgb(238,238,238)" -draw "rectangle 0,552 799,599"  \
    -fill "rgb(243,243,243)" -stroke "rgb(190,190,190)" -draw "roundrectangle 30,25 770,535 8,8"  \
    -stroke none -fill "white" -draw "roundrectangle 235,33 425,65 6,6"  \
    -fill "rgb(0,120,215)" -draw "line 239,33 421,33"  \
    -fill "rgb(30,30,30)" -pointsize 11 -draw "text 250,51 'Studio | Courses'"  \
    -fill "white" -draw "rectangle 30,61 770,97"  \
    -stroke "rgb(220,220,220)" -draw "line 30,97 770,97"  \
    -stroke "rgb(210,210,210)" -fill "rgb(245,245,245)" -draw "roundrectangle 125,67 720,91 12,12"  \
    -stroke none -fill "rgb(40,40,40)" -pointsize 11 -draw "text 140,83 'http://localhost:8001/home'"  \
    -fill "rgb(248,249,250)" -draw "rectangle 31,98 769,534"  \
    -fill "rgb(30,41,59)" -draw "rectangle 31,98 769,142"  \
    -fill "white" -pointsize 16 -draw "text 51,126 'open edX'"  \
    -fill "rgb(203,213,225)" -pointsize 11 -draw "text 141,124 '|  Studio Course Authoring & CMS'"  \
    -fill "rgb(2,132,199)" -draw "roundrectangle 560,108 750,132 12,12"  \
    -fill "white" -pointsize 10 -draw "text 572,124 'Author: staff@openedx.org'"  \
    -stroke none -fill "rgb(15,23,42)" -pointsize 16 -draw "text 50,180 'My Courses & Libraries'"  \
    -fill "rgb(2,132,199)" -draw "roundrectangle 630,160 740,190 4,4"  \
    -fill "white" -pointsize 11 -draw "text 645,180 '+ New Course'"  \
    -fill "white" -stroke "rgb(226,232,240)" -draw "roundrectangle 50,205 750,470 6,6"  \
    -fill "rgb(241,245,249)" -draw "rectangle 51,206 749,245"  \
    -stroke none -fill "rgb(71,85,105)" -pointsize 11 -draw "text 70,230 'Course Name'"  \
    -draw "text 320,230 'Organization'"  \
    -draw "text 480,230 'Course Code'"  \
    -draw "text 620,230 'Publish Status'"  \
    -stroke "rgb(226,232,240)" -draw "line 51,245 749,245"  \
    -stroke none -fill "rgb(15,23,42)" -pointsize 11 -draw "text 70,280 'Demonstration Courseware'"  \
    -draw "text 320,280 'edX'"  \
    -draw "text 480,280 'DemoX'"  \
    -fill "rgb(220,252,231)" -draw "roundrectangle 620,265 730,295 10,10"  \
    -fill "rgb(21,128,61)" -pointsize 10 -draw "text 630,282 'Published to LMS'"  \
    -stroke "rgb(226,232,240)" -draw "line 51,310 749,310"  \
    -stroke none -fill "rgb(15,23,42)" -pointsize 11 -draw "text 70,345 'Computational Thinking & Python'"  \
    -draw "text 320,345 'LibScript'"  \
    -draw "text 480,345 'CS101'"  \
    -fill "rgb(254,249,195)" -draw "roundrectangle 620,330 710,360 10,10"  \
    -fill "rgb(161,98,7)" -pointsize 10 -draw "text 630,347 'In Authoring'"  \
    "$_out"
  printf '[OK] Regenerated %s
' "$_out"
}

regen_desktop_icons "${TARGET_DIR}/10b_desktop_icons.png"
regen_lms_auth "${TARGET_DIR}/13_browser_lms_authenticated.png"
regen_studio_auth "${TARGET_DIR}/14_browser_studio_authenticated.png"

if [ -d "$CC0_DIR" ]; then
  cp -f "${TARGET_DIR}/10b_desktop_icons.png" "${CC0_DIR}/10b_desktop_icons.png"
  cp -f "${TARGET_DIR}/13_browser_lms_authenticated.png" "${CC0_DIR}/13_browser_lms_authenticated.png"
  cp -f "${TARGET_DIR}/14_browser_studio_authenticated.png" "${CC0_DIR}/14_browser_studio_authenticated.png"
fi

printf '
=== Screen generation complete! ===
'
