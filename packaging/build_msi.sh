#!/bin/sh
# ## Overview
# Generic library engine for generating WiX Windows Installer (.msi) packages.
#
# ## Usage
# ./packaging/build_msi.sh [TARGET_DIR] [OPTIONS]

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

# Arguments:
#   TARGET_DIR            Component or stack path (e.g. _lib/web-apps/openedx)
#
# Options:
#   --out <name>          Output base file name (default derived from target)
#   --variant <mode>      Distribution variant: online or offline (default: online)
#   --offline             Shorthand for --variant offline
#   --online              Shorthand for --variant online
#   --cache-dir <dir>     Path to pre-hydrated offline cache directory
#   --version <ver>       Package version
#   --upgrade-code <guid> Upgrade code GUID
#   --icon <path>         Path to .ico icon file
#   --banner-top <path>   Path to 493x58 top banner BMP
#   --banner-side <path>  Path to 164x312 side splash BMP
#   --license <path>      Path to EULA (RTF or TXT)
#   --install-dir <dir>   Default application installation folder
#   --data-dir <dir>      Default mutable datastore folder
#   --log-dir <dir>       Default logs folder
#   --repo <url>          Source Git repository URL
#   --branch <branch>     Target Git release branch or tag
#   --auth-token <token>  Private repository authentication token
#   --mode <mode>         Default setup mode (Simple or Advanced)
#   --use-wix             Use traditional WiX Toolset instead of msi-rs
#   --help, -h            Show this help text

# ## show_help
# Prints script usage instructions and available command-line switches.
show_help() {
  printf '%s\n' "Usage: $0 [TARGET_DIR] [OPTIONS]"
  printf '%s\n' 'Generates a generic WiX Windows Installer (.msi) package.'
  printf '%s\n' 'Options:'
  printf '%s\n' '  --out <name>          Output base file name'
  printf '%s\n' '  --version <ver>       Package version'
  printf '%s\n' '  --upgrade-code <guid> Upgrade code GUID'
  printf '%s\n' '  --icon <path>         Path to .ico icon file'
  printf '%s\n' '  --banner-top <path>   Path to 493x58 top banner BMP'
  printf '%s\n' '  --banner-side <path>  Path to 164x312 side splash BMP'
  printf '%s\n' '  --license <path>      Path to EULA (RTF or TXT)'
  printf '%s\n' '  --install-dir <dir>   Default application installation folder'
  printf '%s\n' '  --data-dir <dir>      Default mutable datastore folder'
  printf '%s\n' '  --log-dir <dir>       Default logs folder'
  printf '%s\n' '  --repo <url>          Source Git repository URL'
  printf '%s\n' '  --branch <branch>     Target Git release branch or tag'
  printf '%s\n' '  --auth-token <token>  Private repository authentication token'
  printf '%s\n' '  --mode <mode>         Default setup mode (Simple or Advanced)'
  printf '%s\n' '  --help, -h            Show this help text'
}

TARGET_DIR=""
OUT_FILE=""
APP_VERSION=""
UPGRADE_CODE=""
ICON_PATH=""
BANNER_TOP_PATH=""
BANNER_SIDE_PATH=""
LICENSE_PATH=""
INSTALL_DIR=""
DATA_DIR=""
LOGS_DIR=""
REPO_URL=""
REPO_BRANCH=""
REPO_AUTH_TOKEN=""
SETUP_MODE='Simple'

VARIANT='online'
[ "${LIBSCRIPT_OFFLINE:-0}" = "1" ] && VARIANT="offline"
CACHE_DIR="${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}"
USE_WIX="${LIBSCRIPT_USE_WIX:-0}"
TARGET_ARCH="${LIBSCRIPT_TARGET_ARCH:-x64}"

while [ $# -gt 0 ]; do
  case "$1" in
    --use-wix)
      USE_WIX='1'
      shift
      ;;
    --arch)
      TARGET_ARCH="$2"
      shift 2
      ;;
    --arch=*)
      TARGET_ARCH="${1#*=}"
      shift
      ;;
    --help|-h|/\?|-\?)
      show_help
      exit 0
      ;;
    --variant)
      VARIANT="$2"
      shift 2
      ;;
    --variant=*)
      VARIANT="${1#*=}"
      shift
      ;;
    --offline)
      VARIANT='offline'
      shift
      ;;
    --online)
      VARIANT='online'
      shift
      ;;
    --cache-dir)
      CACHE_DIR="$2"
      shift 2
      ;;
    --cache-dir=*)
      CACHE_DIR="${1#*=}"
      shift
      ;;
    --out)
      OUT_FILE="$2"
      shift 2
      ;;
    --version)
      APP_VERSION="$2"
      shift 2
      ;;
    --upgrade-code)
      UPGRADE_CODE="$2"
      shift 2
      ;;
    --icon)
      ICON_PATH="$2"
      shift 2
      ;;
    --banner-top)
      BANNER_TOP_PATH="$2"
      shift 2
      ;;
    --banner-side)
      BANNER_SIDE_PATH="$2"
      shift 2
      ;;
    --license)
      LICENSE_PATH="$2"
      shift 2
      ;;
    --install-dir)
      INSTALL_DIR="$2"
      shift 2
      ;;
    --data-dir)
      DATA_DIR="$2"
      shift 2
      ;;
    --log-dir)
      LOGS_DIR="$2"
      shift 2
      ;;
    --repo)
      REPO_URL="$2"
      shift 2
      ;;
    --branch)
      REPO_BRANCH="$2"
      shift 2
      ;;
    --auth-token)
      export REPO_AUTH_TOKEN="$2"
      shift 2
      ;;
    --mode)
      SETUP_MODE="$2"
      shift 2
      ;;
    -*)
      printf '[WARN] Unknown option: %s\n' "$1" >&2
      shift
      ;;
    *)
      if [ -z "$TARGET_DIR" ]; then
        TARGET_DIR="$1"
      fi
      shift
      ;;
  esac
done

if [ -z "$TARGET_DIR" ]; then
  TARGET_DIR='_lib/web-apps/openedx'
fi

# Resolve absolute path to TARGET_DIR
if [ -d "${LIBSCRIPT_ROOT_DIR}/${TARGET_DIR}" ]; then
  RESOLVED_TARGET_DIR="${LIBSCRIPT_ROOT_DIR}/${TARGET_DIR}"
elif [ -d "$TARGET_DIR" ]; then
  RESOLVED_TARGET_DIR="$(cd -- "$TARGET_DIR" && pwd)"
else
  printf '[FAIL] Target directory does not exist: %s\n' "$TARGET_DIR" >&2
  exit 1
fi

PACKAGING_JSON="${RESOLVED_TARGET_DIR}/packaging.json"
export VARS_SCHEMA="${RESOLVED_TARGET_DIR}/vars.schema.json"
export MANIFEST_JSON="${RESOLVED_TARGET_DIR}/manifest.json"

# Extract metadata from packaging.json if present
APP_NAME="Open edX Platform"
export APP_IDENTIFIER='openedx'
APP_PUBLISHER="LibScript Open Source Project"
APP_URL='https://openedx.org'
PRODUCT_CODE="*"

if [ -f "$PACKAGING_JSON" ] && command -v jq >/dev/null 2>&1; then
  _pkg_name=$(jq -r '.name // empty' "$PACKAGING_JSON")
  _pkg_title=$(jq -r '.title // empty' "$PACKAGING_JSON")
  _pkg_ver=$(jq -r '.version // empty' "$PACKAGING_JSON")
  _pkg_pub=$(jq -r '.publisher // empty' "$PACKAGING_JSON")
  _pkg_guid=$(jq -r '.upgrade_code // empty' "$PACKAGING_JSON")
  _pkg_icon=$(jq -r '.branding.icon // empty' "$PACKAGING_JSON")
  _pkg_btop=$(jq -r '.branding.banner_top // empty' "$PACKAGING_JSON")
  _pkg_bside=$(jq -r '.branding.banner_side // empty' "$PACKAGING_JSON")
  _pkg_lic=$(jq -r '.branding.license_rtf // empty' "$PACKAGING_JSON")
  _pkg_appdir=$(jq -r '.directories.app_default // empty' "$PACKAGING_JSON")
  _pkg_datadir=$(jq -r '.directories.data_default // empty' "$PACKAGING_JSON")
  _pkg_logsdir=$(jq -r '.directories.logs_default // empty' "$PACKAGING_JSON")
  _pkg_repourl=$(jq -r '.source_repository.default_url // empty' "$PACKAGING_JSON")
  _pkg_repobranch=$(jq -r '.source_repository.default_branch // empty' "$PACKAGING_JSON")

  [ -n "$_pkg_name" ] && APP_IDENTIFIER="$_pkg_name"
  [ -n "$_pkg_title" ] && APP_NAME="$_pkg_title"
  [ -z "$APP_VERSION" ] && [ -n "$_pkg_ver" ] && APP_VERSION="$_pkg_ver"
  [ -n "$_pkg_pub" ] && APP_PUBLISHER="$_pkg_pub"
  [ -z "$UPGRADE_CODE" ] && [ -n "$_pkg_guid" ] && UPGRADE_CODE="$_pkg_guid"
  [ -z "$ICON_PATH" ] && [ -n "$_pkg_icon" ] && [ -f "${LIBSCRIPT_ROOT_DIR}/${_pkg_icon}" ] && ICON_PATH="${LIBSCRIPT_ROOT_DIR}/${_pkg_icon}"
  [ -z "$BANNER_TOP_PATH" ] && [ -n "$_pkg_btop" ] && [ -f "${LIBSCRIPT_ROOT_DIR}/${_pkg_btop}" ] && BANNER_TOP_PATH="${LIBSCRIPT_ROOT_DIR}/${_pkg_btop}"
  [ -z "$BANNER_SIDE_PATH" ] && [ -n "$_pkg_bside" ] && [ -f "${LIBSCRIPT_ROOT_DIR}/${_pkg_bside}" ] && BANNER_SIDE_PATH="${LIBSCRIPT_ROOT_DIR}/${_pkg_bside}"
  [ -z "$LICENSE_PATH" ] && [ -n "$_pkg_lic" ] && [ -f "${LIBSCRIPT_ROOT_DIR}/${_pkg_lic}" ] && LICENSE_PATH="${LIBSCRIPT_ROOT_DIR}/${_pkg_lic}"
  [ -z "$INSTALL_DIR" ] && [ -n "$_pkg_appdir" ] && INSTALL_DIR="$_pkg_appdir"
  [ -z "$DATA_DIR" ] && [ -n "$_pkg_datadir" ] && DATA_DIR="$_pkg_datadir"
  [ -z "$LOGS_DIR" ] && [ -n "$_pkg_logsdir" ] && LOGS_DIR="$_pkg_logsdir"
  [ -z "$REPO_URL" ] && [ -n "$_pkg_repourl" ] && REPO_URL="$_pkg_repourl"
  [ -z "$REPO_BRANCH" ] && [ -n "$_pkg_repobranch" ] && REPO_BRANCH="$_pkg_repobranch"
elif [ -f "$MANIFEST_JSON" ] && command -v jq >/dev/null 2>&1; then
  _pkg_name=$(jq -r '.name // empty' "$MANIFEST_JSON")
  _pkg_title=$(jq -r '.title // empty' "$MANIFEST_JSON")
  _pkg_ver=$(jq -r '.default_version // .version // empty' "$MANIFEST_JSON")
  [ -z "$_pkg_name" ] && _pkg_name=$(basename "$RESOLVED_TARGET_DIR")
  [ -z "$_pkg_title" ] && _pkg_title="${_pkg_name} Component"
  APP_IDENTIFIER="$_pkg_name"
  APP_NAME="$_pkg_title"
  case "${_pkg_ver:-}" in
    [0-9]*.[0-9]*.[0-9]*) [ -z "$APP_VERSION" ] && APP_VERSION="${_pkg_ver}.0" ;;
    *) [ -z "$APP_VERSION" ] && APP_VERSION="1.0.0.0" ;;
  esac
fi

case "${APP_VERSION:-}" in
  *verawood*|*Verawood*) APP_VERSION="22.1.0.0" ;;
  *ulmo*|*Ulmo*) APP_VERSION="21.1.0.0" ;;
  *teak*|*Teak*) APP_VERSION="20.1.0.0" ;;
  *sumac*|*Sumac*) APP_VERSION="19.1.0.0" ;;
  *redwood*|*Redwood*) APP_VERSION="18.1.0.0" ;;
  *quince*|*Quince*) APP_VERSION="17.1.0.0" ;;
  *palm*|*Palm*) APP_VERSION="16.1.0.0" ;;
esac

: "${APP_VERSION:=22.1.0.0}"
: "${UPGRADE_CODE:=B8C8E64E-9B5A-4B7C-A5D8-0F18B9918239}"
: "${INSTALL_DIR:=[ProgramFiles64Folder]OpenEdX}"
: "${DATA_DIR:=C:\ProgramData\OpenEdX\data}"
: "${LOGS_DIR:=C:\ProgramData\OpenEdX\logs}"
: "${REPO_URL:=https://github.com/openedx/openedx-platform.git}"
: "${REPO_BRANCH:=release/verawood.1}"

_clean_branch="${REPO_BRANCH##*/}"
_clean_branch="${_clean_branch%.master}"
[ -z "$_clean_branch" ] && _clean_branch="${APP_VERSION}"

if [ "$VARIANT" = "offline" ]; then
  PROP_OPENEDX_OFFLINE='1'
  case "$APP_NAME" in
    *"(Offline"*) ;;
    *) APP_NAME="${APP_NAME} (Offline Air-Gapped)" ;;
  esac
  : "${OUT_FILE:=${LIBSCRIPT_ROOT_DIR}/build/packages/msi/${APP_IDENTIFIER}-${TARGET_ARCH}-${_clean_branch}-${VARIANT}}"
  mkdir -p "${OUT_FILE%/*}" 2>/dev/null || true
  WELCOME_DESC=""
  if [ -f "$PACKAGING_JSON" ] && command -v jq >/dev/null 2>&1; then
    WELCOME_DESC=$(jq -r '.wizard_copy.welcome_description_offline // empty' "$PACKAGING_JSON")
  fi
  : "${WELCOME_DESC:=The Setup Wizard will deploy ${APP_NAME} and pre-bundled air-gapped runtimes on your computer.}"
  COMP_TAG=" [Pre-bundled / Offline]"
else
  PROP_OPENEDX_OFFLINE='0'
  case "$APP_NAME" in
    *"(Online)"*) ;;
    *) APP_NAME="${APP_NAME} (Online)" ;;
  esac
  : "${OUT_FILE:=${LIBSCRIPT_ROOT_DIR}/build/packages/msi/${APP_IDENTIFIER}-${TARGET_ARCH}-${_clean_branch}-${VARIANT}}"
  mkdir -p "${OUT_FILE%/*}" 2>/dev/null || true
  WELCOME_DESC=""
  if [ -f "$PACKAGING_JSON" ] && command -v jq >/dev/null 2>&1; then
    WELCOME_DESC=$(jq -r '.wizard_copy.welcome_description_online // empty' "$PACKAGING_JSON")
  fi
  : "${WELCOME_DESC:=The Setup Wizard will download and install ${APP_NAME} and required runtimes on your computer.}"
  COMP_TAG=""
fi

EXIT_DESC="${APP_NAME} services have been successfully installed and started."
SHORTCUT_1_TEXT="Create ${APP_NAME} desktop shortcut"
SHORTCUT_2_TEXT="Create ${APP_NAME} management console shortcut"
LAUNCH_1_TEXT="Launch ${APP_NAME} in Web Browser"
LAUNCH_2_TEXT="Launch ${APP_NAME} Administration Dashboard"
NON_OPT_LIST="- ${APP_NAME} Core Binary &amp; CLI Tools&#13;&#10;- LibScript Autonomous Version Manager Substrate&#13;&#10;- Service Daemon Supervisor (systemd / launchd / Windows Service)&#13;&#10;- Automated Healthcheck &amp; Diagnostic Suite"
CHK_LMS_TEXT="${APP_NAME} Primary Service Daemon"
CHK_CMS_TEXT="${APP_NAME} Management &amp; Telemetry Endpoint"
CHK_WORKERS_TEXT="Launch Background Maintenance Workers"
CHK_DEMO_TEXT="Initialize Default Sample Database &amp;&amp; Schema"
CHK_MFES_TEXT="Register Environment Paths &amp;&amp; CLI Wrappers"
RT_DESC="Configure ${APP_NAME} execution runtime and toolchain providers."
GRP_RT1_TEXT="${APP_NAME} Primary Execution Runtime"
RAD_RT1_EX="Reuse existing system runtime (Detected)"
RAD_RT1_ISO="Install isolated private runtime via LibScript"
GRP_RT2_TEXT="Auxiliary Toolchain &amp; Build Dependencies"
RAD_RT2_EX="Reuse existing system toolchain (Detected)"
RAD_RT2_ISO="Install isolated private toolchain via LibScript"
LBL_PORT1="Primary Service Port:"
LBL_PORT2="Management Port:"
DEFAULT_PORT1='8000'
DEFAULT_PORT2='8001'
DEFAULT_ADMIN_EMAIL="admin@${APP_IDENTIFIER}.local"

if [ -f "$PACKAGING_JSON" ] && command -v jq >/dev/null 2>&1; then
  _w_exit=$(jq -r '.wizard_copy.exit_description // empty' "$PACKAGING_JSON")
  _w_non_opt=$(jq -r '.wizard_copy.non_optional_summary // empty' "$PACKAGING_JSON" | sed 's/&/\&amp;/g' | awk '{printf "%s%s", (NR>1?"&#13;&#10;":""), $0}')
  _w_rt_desc=$(jq -r '.wizard_copy.runtime_selection_description // empty' "$PACKAGING_JSON")
  _w_p1_lbl=$(jq -r '.wizard_copy.port_1_label // empty' "$PACKAGING_JSON")
  _w_p1_def=$(jq -r '.wizard_copy.port_1_default // empty' "$PACKAGING_JSON")
  _w_p2_lbl=$(jq -r '.wizard_copy.port_2_label // empty' "$PACKAGING_JSON")
  _w_p2_def=$(jq -r '.wizard_copy.port_2_default // empty' "$PACKAGING_JSON")
  _w_email=$(jq -r '.wizard_copy.default_admin_email // empty' "$PACKAGING_JSON")

  _sc1=$(jq -r '.shortcuts[0].title // empty' "$PACKAGING_JSON" | sed 's/&/\&amp;\&amp;/g')
  _sc2=$(jq -r '.shortcuts[1].title // empty' "$PACKAGING_JSON" | sed 's/&/\&amp;\&amp;/g')
  _bl1=$(jq -r '.browser_launch.targets[0].title // empty' "$PACKAGING_JSON" | sed 's/&/\&amp;\&amp;/g')
  _bl2=$(jq -r '.browser_launch.targets[1].title // empty' "$PACKAGING_JSON" | sed 's/&/\&amp;\&amp;/g')

  _f0=$(jq -r '.features[0].title // empty' "$PACKAGING_JSON" | sed 's/&/\&amp;\&amp;/g')
  _f1=$(jq -r '.features[1].title // empty' "$PACKAGING_JSON" | sed 's/&/\&amp;\&amp;/g')
  _f2=$(jq -r '.features[2].title // empty' "$PACKAGING_JSON" | sed 's/&/\&amp;\&amp;/g')
  _f3=$(jq -r '.features[3].title // empty' "$PACKAGING_JSON" | sed 's/&/\&amp;\&amp;/g')
  _f4=$(jq -r '.features[4].title // empty' "$PACKAGING_JSON" | sed 's/&/\&amp;\&amp;/g')

  _rt1_title=$(jq -r '.runtime_searches[0].title // empty' "$PACKAGING_JSON" | sed 's/&/\&amp;/g')
  _rt1_name=$(jq -r '.runtime_searches[0].name // empty' "$PACKAGING_JSON")
  _rt2_title=$(jq -r '.runtime_searches[1].title // empty' "$PACKAGING_JSON" | sed 's/&/\&amp;/g')
  _rt2_name=$(jq -r '.runtime_searches[1].name // empty' "$PACKAGING_JSON")

  [ -n "$_w_exit" ] && EXIT_DESC="$_w_exit"
  [ -n "$_w_non_opt" ] && NON_OPT_LIST="$_w_non_opt"
  [ -n "$_w_rt_desc" ] && RT_DESC="$_w_rt_desc"
  [ -n "$_w_p1_lbl" ] && LBL_PORT1="$_w_p1_lbl"
  [ -n "$_w_p1_def" ] && DEFAULT_PORT1="$_w_p1_def"
  [ -n "$_w_p2_lbl" ] && LBL_PORT2="$_w_p2_lbl"
  [ -n "$_w_p2_def" ] && DEFAULT_PORT2="$_w_p2_def"
  [ -n "$_w_email" ] && DEFAULT_ADMIN_EMAIL="$_w_email"

  [ -n "$_sc1" ] && SHORTCUT_1_TEXT="Create ${_sc1} shortcut"
  [ -n "$_sc2" ] && SHORTCUT_2_TEXT="Create ${_sc2} shortcut"
  [ -n "$_bl1" ] && LAUNCH_1_TEXT="$_bl1"
  [ -n "$_bl2" ] && LAUNCH_2_TEXT="$_bl2"

  [ -n "$_f0" ] && CHK_LMS_TEXT="$_f0"
  [ -n "$_f1" ] && CHK_CMS_TEXT="$_f1"
  [ -n "$_f2" ] && CHK_WORKERS_TEXT="$_f2"
  [ -n "$_f3" ] && CHK_DEMO_TEXT="$_f3"
  [ -n "$_f4" ] && CHK_MFES_TEXT="$_f4"

  if [ -n "$_rt1_title" ]; then
    GRP_RT1_TEXT="$_rt1_title"
    RAD_RT1_EX="Reuse existing system ${_rt1_name} (Detected)"
    RAD_RT1_ISO="Install isolated private ${_rt1_name} runtime via LibScript"
  fi
  if [ -n "$_rt2_title" ]; then
    GRP_RT2_TEXT="$_rt2_title"
    RAD_RT2_EX="Reuse existing system ${_rt2_name} (Detected)"
    RAD_RT2_ISO="Install isolated private ${_rt2_name} runtime via LibScript"
  fi
fi

TMP_WORK_DIR="${LIBSCRIPT_ROOT_DIR}/tmp/msi_build_$$"
mkdir -p "$TMP_WORK_DIR"

# ## cleanup_tmp
# Performs the cleanup_tmp operation and updates component state.
# ## Overview
# Removes temporary build directory.
# shellcheck disable=SC2317,SC2329
# ## Usage
#   Internal function.
# ## cleanup_tmp
# Performs the cleanup_tmp operation and updates component state.
cleanup_tmp() {
  rm -rf "$TMP_WORK_DIR"
  rm -f "${OUT_FILE}.wixobj" "${OUT_FILE}_payload.wixobj" "${OUT_FILE}.candle.wxs" "${OUT_FILE}_wixl.wxs" "${OUT_FILE}_payload_wixl.wxs"
}
trap cleanup_tmp EXIT INT TERM

# ## ensure_branding_assets
# Performs the ensure_branding_assets operation and updates component state.
# ## Overview
# Validates or synthesizes placeholder branding assets via synthesize_branding.sh.
# ## Usage
#   Internal function.
# ## ensure_branding_assets
# Performs the ensure_branding_assets operation and updates component state.
ensure_branding_assets() {
  synth_script="${LIBSCRIPT_ROOT_DIR}/packaging/synthesize_branding.sh"
  cc0_assets_dir="${LIBSCRIPT_ROOT_DIR}/../cc0-assets/libscript/${APP_IDENTIFIER}/assets"
  if [ -d "$cc0_assets_dir" ]; then
    set +f
    cp -f "$cc0_assets_dir"/* "$TMP_WORK_DIR"/ 2>/dev/null || true
    set -f
  fi

  if { [ -z "$ICON_PATH" ] || [ ! -f "$ICON_PATH" ]; } && [ ! -f "${TMP_WORK_DIR}/${APP_IDENTIFIER}.ico" ] || \
     { [ -z "$BANNER_TOP_PATH" ] || [ ! -f "$BANNER_TOP_PATH" ]; } && [ ! -f "${TMP_WORK_DIR}/${APP_IDENTIFIER}_banner_top.bmp" ] || \
     { [ -z "$BANNER_SIDE_PATH" ] || [ ! -f "$BANNER_SIDE_PATH" ]; } && [ ! -f "${TMP_WORK_DIR}/${APP_IDENTIFIER}_banner_side.bmp" ] || \
     { [ -z "$LICENSE_PATH" ] || [ ! -f "$LICENSE_PATH" ]; } && [ ! -f "${TMP_WORK_DIR}/${APP_IDENTIFIER}_eula.rtf" ]; then
    if [ -f "$synth_script" ]; then
      "$synth_script" "$RESOLVED_TARGET_DIR" --output-dir "$TMP_WORK_DIR" >/dev/null 2>&1 || true
    fi
  fi

  if [ -d "$cc0_assets_dir" ]; then
    set +f
    cp -f "$cc0_assets_dir"/* "$TMP_WORK_DIR"/ 2>/dev/null || true
    set -f
  fi

  if [ -n "$ICON_PATH" ] && [ -f "$ICON_PATH" ]; then
    cp -f "$ICON_PATH" "${TMP_WORK_DIR}/openedx.ico" 2>/dev/null || true
    ICON_PATH="${TMP_WORK_DIR}/openedx.ico"
  elif [ -f "${TMP_WORK_DIR}/${APP_IDENTIFIER}.ico" ]; then
    ICON_PATH="${TMP_WORK_DIR}/${APP_IDENTIFIER}.ico"
  elif [ -f "${TMP_WORK_DIR}/openedx.ico" ]; then
    ICON_PATH="${TMP_WORK_DIR}/openedx.ico"
  elif [ -f "${TMP_WORK_DIR}/app.ico" ]; then
    ICON_PATH="${TMP_WORK_DIR}/app.ico"
  elif [ -f "${LIBSCRIPT_ROOT_DIR}/../cc0-assets/libscript/openedx/assets/openedx.ico" ]; then
    cp -f "${LIBSCRIPT_ROOT_DIR}/../cc0-assets/libscript/openedx/assets/openedx.ico" "${TMP_WORK_DIR}/openedx.ico" 2>/dev/null || true
    ICON_PATH="${TMP_WORK_DIR}/openedx.ico"
  elif [ -f "${LIBSCRIPT_ROOT_DIR}/packaging/assets/openedx.ico" ]; then
    cp -f "${LIBSCRIPT_ROOT_DIR}/packaging/assets/openedx.ico" "${TMP_WORK_DIR}/openedx.ico" 2>/dev/null || true
    ICON_PATH="${TMP_WORK_DIR}/openedx.ico"
  fi

  if [ -n "$BANNER_TOP_PATH" ] && [ -f "$BANNER_TOP_PATH" ]; then
    cp -f "$BANNER_TOP_PATH" "${TMP_WORK_DIR}/openedx_banner_top.bmp" 2>/dev/null || true
    BANNER_TOP_PATH="${TMP_WORK_DIR}/openedx_banner_top.bmp"
  elif [ -f "${TMP_WORK_DIR}/${APP_IDENTIFIER}_banner_top.bmp" ]; then
    BANNER_TOP_PATH="${TMP_WORK_DIR}/${APP_IDENTIFIER}_banner_top.bmp"
  elif [ -f "${TMP_WORK_DIR}/openedx_banner_top.bmp" ]; then
    BANNER_TOP_PATH="${TMP_WORK_DIR}/openedx_banner_top.bmp"
  elif [ -f "${TMP_WORK_DIR}/banner_top.bmp" ]; then
    BANNER_TOP_PATH="${TMP_WORK_DIR}/banner_top.bmp"
  elif [ -f "${LIBSCRIPT_ROOT_DIR}/../cc0-assets/libscript/openedx/assets/openedx_banner_top.bmp" ]; then
    cp -f "${LIBSCRIPT_ROOT_DIR}/../cc0-assets/libscript/openedx/assets/openedx_banner_top.bmp" "${TMP_WORK_DIR}/openedx_banner_top.bmp" 2>/dev/null || true
    BANNER_TOP_PATH="${TMP_WORK_DIR}/openedx_banner_top.bmp"
  elif [ -f "${LIBSCRIPT_ROOT_DIR}/packaging/assets/openedx_banner_top.bmp" ]; then
    cp -f "${LIBSCRIPT_ROOT_DIR}/packaging/assets/openedx_banner_top.bmp" "${TMP_WORK_DIR}/openedx_banner_top.bmp" 2>/dev/null || true
    BANNER_TOP_PATH="${TMP_WORK_DIR}/openedx_banner_top.bmp"
  fi

  if [ -n "$BANNER_SIDE_PATH" ] && [ -f "$BANNER_SIDE_PATH" ]; then
    cp -f "$BANNER_SIDE_PATH" "${TMP_WORK_DIR}/openedx_banner_side.bmp" 2>/dev/null || true
    BANNER_SIDE_PATH="${TMP_WORK_DIR}/openedx_banner_side.bmp"
  elif [ -f "${TMP_WORK_DIR}/${APP_IDENTIFIER}_banner_side.bmp" ]; then
    BANNER_SIDE_PATH="${TMP_WORK_DIR}/${APP_IDENTIFIER}_banner_side.bmp"
  elif [ -f "${TMP_WORK_DIR}/openedx_banner_side.bmp" ]; then
    BANNER_SIDE_PATH="${TMP_WORK_DIR}/openedx_banner_side.bmp"
  elif [ -f "${TMP_WORK_DIR}/banner_side.bmp" ]; then
    BANNER_SIDE_PATH="${TMP_WORK_DIR}/banner_side.bmp"
  elif [ -f "${LIBSCRIPT_ROOT_DIR}/../cc0-assets/libscript/openedx/assets/openedx_banner_side.bmp" ]; then
    cp -f "${LIBSCRIPT_ROOT_DIR}/../cc0-assets/libscript/openedx/assets/openedx_banner_side.bmp" "${TMP_WORK_DIR}/openedx_banner_side.bmp" 2>/dev/null || true
    BANNER_SIDE_PATH="${TMP_WORK_DIR}/openedx_banner_side.bmp"
  elif [ -f "${LIBSCRIPT_ROOT_DIR}/packaging/assets/openedx_banner_side.bmp" ]; then
    cp -f "${LIBSCRIPT_ROOT_DIR}/packaging/assets/openedx_banner_side.bmp" "${TMP_WORK_DIR}/openedx_banner_side.bmp" 2>/dev/null || true
    BANNER_SIDE_PATH="${TMP_WORK_DIR}/openedx_banner_side.bmp"
  fi

  if [ -n "$LICENSE_PATH" ] && [ -f "$LICENSE_PATH" ]; then
    cp -f "$LICENSE_PATH" "${TMP_WORK_DIR}/openedx_eula.rtf" 2>/dev/null || true
    LICENSE_PATH="${TMP_WORK_DIR}/openedx_eula.rtf"
  elif [ -f "${TMP_WORK_DIR}/${APP_IDENTIFIER}_eula.rtf" ]; then
    LICENSE_PATH="${TMP_WORK_DIR}/${APP_IDENTIFIER}_eula.rtf"
  elif [ -f "${TMP_WORK_DIR}/openedx_eula.rtf" ]; then
    LICENSE_PATH="${TMP_WORK_DIR}/openedx_eula.rtf"
  elif [ -f "${TMP_WORK_DIR}/license.rtf" ]; then
    LICENSE_PATH="${TMP_WORK_DIR}/license.rtf"
  elif [ -f "${LIBSCRIPT_ROOT_DIR}/../cc0-assets/libscript/openedx/assets/openedx_eula.rtf" ]; then
    cp -f "${LIBSCRIPT_ROOT_DIR}/../cc0-assets/libscript/openedx/assets/openedx_eula.rtf" "${TMP_WORK_DIR}/openedx_eula.rtf" 2>/dev/null || true
    LICENSE_PATH="${TMP_WORK_DIR}/openedx_eula.rtf"
  elif [ -f "${LIBSCRIPT_ROOT_DIR}/packaging/assets/openedx_eula.rtf" ]; then
    cp -f "${LIBSCRIPT_ROOT_DIR}/packaging/assets/openedx_eula.rtf" "${TMP_WORK_DIR}/openedx_eula.rtf" 2>/dev/null || true
    LICENSE_PATH="${TMP_WORK_DIR}/openedx_eula.rtf"
  else
    printf '{\\rtf1\\ansi\\deff0 {\\fonttbl {\\f0 Courier;}}\\fs20 %s End-User License Agreement\\par}\n' "$APP_NAME" > "${TMP_WORK_DIR}/openedx_eula.rtf"
    LICENSE_PATH="${TMP_WORK_DIR}/openedx_eula.rtf"
  fi
}

ensure_branding_assets

rtf_license_file=""
if [ -n "$LICENSE_PATH" ] && [ -f "$LICENSE_PATH" ]; then
  case "$LICENSE_PATH" in
    *.rtf)
      rtf_license_file="$LICENSE_PATH"
      ;;
    *)
      rtf_license_file="${OUT_FILE}_license.rtf"
      printf '{\\rtf1\\ansi\\deff0 {\\fonttbl {\\f0 Courier;}}\\fs20\n' > "$rtf_license_file"
      sed 's/\\/\\\\/g; s/{/\\{/g; s/}/\\}/g; s/$/\\par/' "$LICENSE_PATH" >> "$rtf_license_file"
      printf '}\n' >> "$rtf_license_file"
      ;;
  esac
fi

WXS_FILE="${OUT_FILE}.wxs"

# ## generate_wxs
# Performs the generate_wxs operation and updates component state.
# ## Overview
# Generates the WiX XML (.wxs) manifest synthesizing properties from schema and packaging config.
# ## Usage
#   Internal function.
# ## generate_wxs
# Performs the generate_wxs operation and updates component state.
generate_wxs() {
  _esc_pub=$(printf '%s\n' "$APP_PUBLISHER" | sed 's/&/\&amp;/g')
  _esc_name=$(printf '%s\n' "$APP_NAME" | sed 's/&/\&amp;/g')

  # Harvest licenses for bundled dependencies
  HARVESTED_LICENSES_DIR="${TMP_WORK_DIR}/licenses"
  MULTI_LICENSE_XML=""
  MULTI_LICENSE_UI_SEQ=""
  MULTI_LICENSE_PROPS=""
  MULTI_LICENSE_EXEC_COND=""
  LAST_LICENSE_DLG='Dlg_License'

  _lic_mode='consolidated_eula'
  if [ -n "$TARGET_DIR" ] && [ -f "${TARGET_DIR}/packaging.json" ]; then
    _lic_mode=$(jq -r '.branding.license_mode // "consolidated_eula"' "${TARGET_DIR}/packaging.json" 2>/dev/null || printf 'consolidated_eula')
  fi

  if [ "$_lic_mode" = "chained_dialogs" ] && [ -f "${LIBSCRIPT_ROOT_DIR}/packaging/harvest_licenses.sh" ] && [ -n "$TARGET_DIR" ] && [ -d "$TARGET_DIR" ]; then
    "${LIBSCRIPT_ROOT_DIR}/packaging/harvest_licenses.sh" "$TARGET_DIR" --out-dir "$HARVESTED_LICENSES_DIR" --force >/dev/null 2>&1 || true
    if [ -f "$HARVESTED_LICENSES_DIR/licenses_manifest.json" ]; then
      _lic_count=$(jq '.licenses | length' "$HARVESTED_LICENSES_DIR/licenses_manifest.json" 2>/dev/null || printf '0')
      _lidx=0
      while [ "$_lidx" -lt "$_lic_count" ]; do
        _lname=$(jq -r ".licenses[$_lidx].name" "$HARVESTED_LICENSES_DIR/licenses_manifest.json")
        _ltitle=$(jq -r ".licenses[$_lidx].title" "$HARVESTED_LICENSES_DIR/licenses_manifest.json")
        _lspdx=$(jq -r ".licenses[$_lidx].spdx" "$HARVESTED_LICENSES_DIR/licenses_manifest.json")
        _esc_ltitle=$(printf '%s\n' "$_ltitle" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')
        _esc_lspdx=$(printf '%s\n' "$_lspdx" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')
        _lrtf="${HARVESTED_LICENSES_DIR}/${_lname}_license.rtf"

        # Skip top-level app if already shown in Dlg_License
        if [ "$_lname" != "openedx" ] && [ "$_lname" != "app" ] && [ -f "$_lrtf" ]; then
          _dlg_id="Dlg_License_${_lname}"
          _lname_upper=$(printf '%s\n' "$_lname" | tr '[:lower:]' '[:upper:]')
          _prop_id="LICENSE_ACCEPTED_${_lname_upper}"

          MULTI_LICENSE_PROPS="${MULTI_LICENSE_PROPS}
      <Property Id=\"${_prop_id}\" Value=\"0\" Secure=\"yes\" />"
          MULTI_LICENSE_EXEC_COND="${MULTI_LICENSE_EXEC_COND} AND NOT (${_prop_id}=\"1\")"

          MULTI_LICENSE_XML="${MULTI_LICENSE_XML}
      <!-- License Agreement Dialog: ${_esc_ltitle} -->
      <Dialog Id=\"${_dlg_id}\" Width=\"370\" Height=\"270\" Title=\"[ProductName] Setup - ${_esc_ltitle} License\">
        <Control Id=\"BannerBitmap\" Type=\"Bitmap\" X=\"0\" Y=\"0\" Width=\"370\" Height=\"44\" Text=\"WixUIBannerBmp\" />
        <Control Id=\"BannerLine\" Type=\"Line\" X=\"0\" Y=\"44\" Width=\"370\" Height=\"0\" />
        <Control Id=\"BottomLine\" Type=\"Line\" X=\"0\" Y=\"234\" Width=\"370\" Height=\"0\" />
        <Control Id=\"Title\" Type=\"Text\" X=\"15\" Y=\"6\" Width=\"260\" Height=\"15\" Transparent=\"yes\" NoPrefix=\"yes\" Text=\"${_esc_ltitle} License Agreement\" />
        <Control Id=\"Description\" Type=\"Text\" X=\"25\" Y=\"22\" Width=\"260\" Height=\"20\" Transparent=\"yes\" NoPrefix=\"yes\" Text=\"Please review and accept the terms for ${_esc_ltitle} (${_esc_lspdx}).\" />
        <Control Id=\"AgreementText\" Type=\"ScrollableText\" X=\"20\" Y=\"48\" Width=\"330\" Height=\"155\" Sunken=\"yes\" TabSkip=\"no\">
          <Text SourceFile=\"${_lrtf}\" />
        </Control>
        <Control Id=\"Chk_Accept_${_lname}\" Type=\"CheckBox\" X=\"20\" Y=\"210\" Width=\"330\" Height=\"18\" Property=\"${_prop_id}\" CheckBoxValue=\"1\" Text=\"I accept the terms in the ${_esc_ltitle} (${_esc_lspdx}) License Agreement\" />
        <Control Id=\"Back\" Type=\"PushButton\" X=\"180\" Y=\"243\" Width=\"56\" Height=\"17\" Text=\"Back\">
          <Publish Event=\"EndDialog\" Value=\"Return\">1</Publish>
        </Control>
        <Control Id=\"Next\" Type=\"PushButton\" X=\"236\" Y=\"243\" Width=\"56\" Height=\"17\" Default=\"yes\" Text=\"I Agree\">
          <Publish Event=\"EndDialog\" Value=\"Return\"><![CDATA[${_prop_id}=\"1\"]]></Publish>
          <Condition Action=\"disable\"><![CDATA[${_prop_id}<>\"1\"]]></Condition>
          <Condition Action=\"enable\"><![CDATA[${_prop_id}=\"1\"]]></Condition>
        </Control>
        <Control Id=\"Cancel\" Type=\"PushButton\" X=\"304\" Y=\"243\" Width=\"56\" Height=\"17\" Cancel=\"yes\" Text=\"Cancel\">
          <Publish Event=\"EndDialog\" Value=\"Exit\">1</Publish>
        </Control>
      </Dialog>"

          MULTI_LICENSE_UI_SEQ="${MULTI_LICENSE_UI_SEQ}
        <Show Dialog=\"${_dlg_id}\" After=\"${LAST_LICENSE_DLG}\">NOT Installed</Show>"
          LAST_LICENSE_DLG="${_dlg_id}"
        fi
        _lidx=$((_lidx + 1))
      done
    fi
  fi

  # Prevent absolute host paths from leaking into the generated WiX source files
  strip_root() {
    _path="$1"
    _root="$2"
    case "$_path" in
      "${_root}"/*) printf '%s' "${_path#"${_root}/"}" ;;
      "${_root}") printf '.' ;;
      *) printf '%s' "$_path" ;;
    esac
  }
  [ -n "$ICON_PATH" ] && ICON_PATH=$(strip_root "$ICON_PATH" "$LIBSCRIPT_ROOT_DIR")
  [ -n "$BANNER_TOP_PATH" ] && BANNER_TOP_PATH=$(strip_root "$BANNER_TOP_PATH" "$LIBSCRIPT_ROOT_DIR")
  [ -n "$BANNER_SIDE_PATH" ] && BANNER_SIDE_PATH=$(strip_root "$BANNER_SIDE_PATH" "$LIBSCRIPT_ROOT_DIR")
  [ -n "${rtf_license_file:-}" ] && rtf_license_file=$(strip_root "$rtf_license_file" "$LIBSCRIPT_ROOT_DIR")

  cat << EOF_XML > "$WXS_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="$PRODUCT_CODE" Name="$_esc_name" Language="1033" Version="$APP_VERSION" Manufacturer="$_esc_pub" UpgradeCode="$UPGRADE_CODE">
    <Package InstallerVersion="200" Compressed="yes" SummaryCodepage="1252" Platform="${TARGET_ARCH}" InstallScope="perMachine" Description="$_esc_name Windows Installer" />
EOF_XML

  if [ "$VARIANT" = "offline" ]; then
    cat << EOF_MEDIA >> "$WXS_FILE"
    <!-- Offline Variant (Multi-cab partition) -->
    <Media Id="1" Cabinet="engine.cab" EmbedCab="yes" CompressionLevel="mszip" />
    <Media Id="2" Cabinet="runtimes.cab" EmbedCab="yes" CompressionLevel="medium" />
    <Media Id="3" Cabinet="databases.cab" EmbedCab="yes" CompressionLevel="medium" />
    <Media Id="4" Cabinet="codebase.cab" EmbedCab="yes" CompressionLevel="medium" />
EOF_MEDIA
  else
    cat << EOF_MEDIA >> "$WXS_FILE"
    <!-- Online Variant (Single compressed cab) -->
    <Media Id="1" Cabinet="engine.cab" EmbedCab="yes" CompressionLevel="mszip" />
EOF_MEDIA
  fi

  cat << EOF_UPGRADE >> "$WXS_FILE"
    <!-- Major Upgrade Rules: Seamlessly replaces superseded binaries and prevents downgrades -->
    <MajorUpgrade
        DowngradeErrorMessage="A newer version of [ProductName] is already installed. Setup will now exit."
        Schedule="afterInstallInitialize"
        AllowSameVersionUpgrades="no"
        IgnoreRemoveFailure="no" />

    <Icon Id="AppIcon.ico" SourceFile="$ICON_PATH" />
    <Icon Id="LmsIcon.ico" SourceFile="$(if [ -f "${TMP_WORK_DIR}/openedx_lms.ico" ]; then strip_root "${TMP_WORK_DIR}/openedx_lms.ico" "$LIBSCRIPT_ROOT_DIR"; elif [ -f "packaging/assets/openedx_lms.ico" ]; then printf 'packaging/assets/openedx_lms.ico'; else printf '%s' "$ICON_PATH"; fi)" />
    <Icon Id="StudioIcon.ico" SourceFile="$(if [ -f "${TMP_WORK_DIR}/openedx_studio.ico" ]; then strip_root "${TMP_WORK_DIR}/openedx_studio.ico" "$LIBSCRIPT_ROOT_DIR"; elif [ -f "packaging/assets/openedx_studio.ico" ]; then printf 'packaging/assets/openedx_studio.ico'; else printf '%s' "$ICON_PATH"; fi)" />
    <Property Id="ARPPRODUCTICON" Value="AppIcon.ico" />
    <Property Id="ARPURLINFOABOUT" Value="$APP_URL" />
    <Property Id="PROP_OPENEDX_OFFLINE" Value="$PROP_OPENEDX_OFFLINE" Secure="yes" />
EOF_UPGRADE

  if [ -n "$BANNER_TOP_PATH" ] && [ -f "$BANNER_TOP_PATH" ]; then
    printf '    <Binary Id="WixUIBannerBmp" SourceFile="%s" />\n    <WixVariable Id="WixUIBannerBmp" Value="%s" />\n' "$BANNER_TOP_PATH" "$BANNER_TOP_PATH" >> "$WXS_FILE"
  fi
  if [ -n "$BANNER_SIDE_PATH" ] && [ -f "$BANNER_SIDE_PATH" ]; then
    printf '    <Binary Id="WixUIDialogBmp" SourceFile="%s" />\n    <WixVariable Id="WixUIDialogBmp" Value="%s" />\n' "$BANNER_SIDE_PATH" "$BANNER_SIDE_PATH" >> "$WXS_FILE"
  fi
  if [ -n "$rtf_license_file" ] && [ -f "$rtf_license_file" ]; then
    printf '    <WixVariable Id="WixUILicenseRtf" Value="%s" />\n' "$rtf_license_file" >> "$WXS_FILE"
  fi

  cat << EOF_PROPS >> "$WXS_FILE"
    <!-- Runtime Properties & Setup Mode Defaults -->
    <Property Id="SETUP_MODE" Value="$SETUP_MODE" Secure="yes" />
    <Property Id="LICENSE_ACCEPTED" Value="0" Secure="yes" />
    <Property Id="LAUNCH_BROWSER" Value="1" Secure="yes" />
    <Property Id="LAUNCH_STUDIO" Value="0" Secure="yes" />

    <!-- Directory Configuration Properties -->
    <Property Id="WIXUI_INSTALLDIR" Value="INSTALLFOLDER" />

    <Property Id="USE_EXISTING_PYTHON" Value="1" Secure="yes" />
    <Property Id="USE_EXISTING_NODE" Value="1" Secure="yes" />
    <Property Id="USE_EXISTING_MYSQL" Value="0" Secure="yes" />

    <!-- Git Repository & Branch Customization -->
    <Property Id="PROP_OPENEDX_EDX_PLATFORM_REPOSITORY" Value="$REPO_URL" Secure="yes" />
    <Property Id="PROP_OPENEDX_VERSION" Value="$REPO_BRANCH" Secure="yes" />
    <Property Id="PROP_OPENEDX_REPO_TYPE" Value="Upstream" Secure="yes" />
    <Property Id="PROP_OPENEDX_BRANCH_TYPE" Value="NamedRelease" Secure="yes" />
    <Property Id="PROP_OPENEDX_REPO_AUTH_TOKEN" Hidden="yes" Secure="yes" />
    <Property Id="PROP_OPENEDX_GIT_DEPTH" Value="1" Secure="yes" />
    <Property Id="PROP_OPENEDX_BRANCH_PRESET" Value="Verawood" Secure="yes" />

    <!-- Open edX Stack Properties Synthesized from vars.schema.json -->
    <Property Id="PROP_LMS_HOST" Value="localhost" Secure="yes" />
    <Property Id="PROP_LMS_PORT" Value="${DEFAULT_PORT1}" Secure="yes" />
    <Property Id="PROP_CMS_HOST" Value="localhost" Secure="yes" />
    <Property Id="PROP_CMS_PORT" Value="${DEFAULT_PORT2}" Secure="yes" />
    <Property Id="PROP_OPENEDX_ADMIN_EMAIL" Value="${DEFAULT_ADMIN_EMAIL}" Secure="yes" />
    <Property Id="PROP_OPENEDX_ADMIN_USERNAME" Value="admin" Secure="yes" />
    <Property Id="PROP_OPENEDX_ADMIN_PASSWORD" Value="admin" Hidden="yes" Secure="yes" />
    <Property Id="PROP_OPENEDX_SECRET_KEY" Value="insecure-secret-key-replace-in-production" Hidden="yes" Secure="yes" />

    <!-- DBaaS and Datastore Properties -->
    <Property Id="PROP_MYSQL_PORT" Value="3306" Secure="yes" />
    <Property Id="PROP_MYSQL_REMOTE_URL" Hidden="yes" Secure="yes" />
    <Property Id="PROP_MYSQL_ROOT_PASSWORD" Hidden="yes" Secure="yes" />

    <Property Id="PROP_REDIS_PORT" Value="6379" Secure="yes" />
    <Property Id="PROP_REDIS_HOST" Value="127.0.0.1" Secure="yes" />
    <Property Id="PROP_REDIS_URL" Hidden="yes" Secure="yes" />
    <Property Id="PROP_REDIS_PASSWORD" Hidden="yes" Secure="yes" />

    <Property Id="PROP_MONGODB_PORT" Value="27017" Secure="yes" />
    <Property Id="PROP_MONGODB_URI" Hidden="yes" Secure="yes" />

    <Property Id="PROP_MEILISEARCH_PORT" Value="7700" Secure="yes" />
    <Property Id="PROP_MEILISEARCH_CUSTOM_URL" Secure="yes" />
    <Property Id="PROP_MEILISEARCH_MASTER_KEY" Hidden="yes" Secure="yes" />

    <Property Id="INSTALL_MYSQL" Value="1" Secure="yes" />
    <Property Id="INSTALL_REDIS" Value="1" Secure="yes" />
    <Property Id="INSTALL_MONGODB" Value="1" Secure="yes" />
    <Property Id="INSTALL_MEILISEARCH" Value="1" Secure="yes" />
    <Property Id="INSTALL_LMS" Value="1" Secure="yes" />
    <Property Id="INSTALL_CMS" Value="1" Secure="yes" />
    <Property Id="INSTALL_WORKERS" Value="1" Secure="yes" />
    <Property Id="IMPORT_DEMO_CONTENT" Value="0" Secure="yes" />
    <Property Id="INSTALL_MFES" Value="0" Secure="yes" />
    <Property Id="PROP_OPENEDX_THEME" Value="none" Secure="yes" />
    <Property Id="PROP_OPENEDX_THEME_REPO_URL" Secure="yes" />
    <Property Id="CREATE_SHORTCUT_LMS" Value="1" Secure="yes" />
    <Property Id="CREATE_SHORTCUT_CMS" Value="1" Secure="yes" />
    <Property Id="AGREE_ALL_LICENSES" Value="0" Secure="yes" />${MULTI_LICENSE_PROPS}

    <!-- Mask Sensitive Git Credentials and Passwords in Verbose Logs -->

    <!-- Target Directory Layout with CommonAppDataFolder for Mutable User Data -->
    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFiles64Folder">
        <Directory Id="INSTALLFOLDER" Name="OpenEdX">
          <Directory Id="LIBSCRIPT_FOLDER" Name="libscript" />
        </Directory>
      </Directory>
      <Directory Id="ProgramMenuFolder">
        <Directory Id="OpenEdXProgramMenuFolder" Name="Open edX" />
      </Directory>
      <Directory Id="DesktopFolder" Name="Desktop" />
      <Directory Id="CommonAppDataFolder">
        <Directory Id="COMPANYDATAFOLDER" Name="OpenEdX">
          <Directory Id="DATAFOLDER" Name="data" />
          <Directory Id="LOGSFOLDER" Name="logs" />
          <Directory Id="BACKUPFOLDER" Name="backups" />
        </Directory>
      </Directory>
    </Directory>

    <!-- Custom Actions -->
    <CustomAction Id="CA_CheckNetworkConnection" Directory="INSTALLFOLDER" ExeCommand="powershell.exe -NoProfile -Command &quot;try { (New-Object System.Net.Sockets.TcpClient('github.com', 443)).Close(); (New-Object System.Net.Sockets.TcpClient('pypi.org', 443)).Close(); } catch { exit 1 }&quot;" Execute="immediate" Return="ignore" />
    <CustomAction Id="CA_CheckPorts" Directory="INSTALLFOLDER" ExeCommand="powershell.exe -NoProfile -Command &quot;foreach (\$p in @(8000, 8001, 3306, 6379, 27017, 7700)) { try { \$s = [System.Net.Sockets.TcpClient]::new('127.0.0.1', \$p); \$s.Close(); Write-Warning &quot;Port \$p is currently occupied&quot; } catch {} }&quot;" Execute="immediate" Return="ignore" />
    <CustomAction Id="CA_DetectExistingRuntimes" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\_lib\web-apps\openedx\status_runtimes.cmd runtimes/python &amp; [INSTALLFOLDER]libscript\_lib\web-apps\openedx\status_runtimes.cmd runtimes/nodejs&quot;" Execute="deferred" Return="ignore" Impersonate="no" />
    <CustomAction Id="CA_DetectDatabases" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\_lib\web-apps\openedx\status_databases.cmd databases/mysql&quot;" Execute="deferred" Return="ignore" Impersonate="no" />
    <CustomAction Id="CA_LaunchBrowser" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\packaging\launch_browser.cmd&quot; http://[PROP_LMS_HOST]:[PROP_LMS_PORT] &quot;Open edX LMS&quot;" Return="asyncNoWait" />
    <CustomAction Id="CA_LaunchStudio" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\packaging\launch_browser.cmd&quot; http://[PROP_CMS_HOST]:[PROP_CMS_PORT] &quot;Open edX Studio&quot;" Return="asyncNoWait" />
    <CustomAction Id="InstallOpenEdXService" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c set PROP_OPENEDX_FAST_VERIFY=[PROP_OPENEDX_FAST_VERIFY]&amp; &quot;[INSTALLFOLDER]libscript\libscript.cmd&quot; install _lib/web-apps/openedx --offline=[PROP_OPENEDX_OFFLINE] --lms-port=[PROP_LMS_PORT] --cms-port=[PROP_CMS_PORT] --mysql-url=&quot;[PROP_MYSQL_REMOTE_URL]&quot; --redis-port=[PROP_REDIS_PORT] --redis-url=&quot;[PROP_REDIS_URL]&quot; --mongodb-uri=&quot;[PROP_MONGODB_URI]&quot; --repo=&quot;[PROP_OPENEDX_EDX_PLATFORM_REPOSITORY]&quot; --version=&quot;[PROP_OPENEDX_VERSION]&quot; --admin-user=&quot;[PROP_OPENEDX_ADMIN_USERNAME]&quot; --admin-password=&quot;[PROP_OPENEDX_ADMIN_PASSWORD]&quot; --admin-email=&quot;[PROP_OPENEDX_ADMIN_EMAIL]&quot; --theme=&quot;[PROP_OPENEDX_THEME]&quot; &gt;&gt; &quot;[LOGSFOLDER]install_openedx.log&quot; 2&gt;&amp;1" Execute="deferred" Return="ignore" Impersonate="no" />
    <CustomAction Id="InstallWorkersService" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\_lib\web-apps\openedx\workers.cmd&quot; start &gt;&gt; &quot;[LOGSFOLDER]install_workers.log&quot; 2&gt;&amp;1" Execute="deferred" Return="ignore" Impersonate="no" />
    <CustomAction Id="StopWorkersService" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\_lib\web-apps\openedx\workers.cmd&quot; stop" Execute="deferred" Return="ignore" Impersonate="no" />
    <CustomAction Id="ImportDemoContentAction" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\_lib\web-apps\openedx\import_demo.cmd&quot; course &gt;&gt; &quot;[LOGSFOLDER]install_demo.log&quot; 2&gt;&amp;1 &amp;&amp; &quot;[INSTALLFOLDER]libscript\_lib\web-apps\openedx\import_demo.cmd&quot; libraries &gt;&gt; &quot;[LOGSFOLDER]install_demo.log&quot; 2&gt;&amp;1" Execute="deferred" Return="ignore" Impersonate="no" />
    <CustomAction Id="BuildMFEsAction" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\_lib\web-apps\openedx\mfe.cmd&quot; build all &gt;&gt; &quot;[LOGSFOLDER]install_mfe.log&quot; 2&gt;&amp;1 &amp;&amp; &quot;[INSTALLFOLDER]libscript\_lib\web-apps\openedx\mfe.cmd&quot; deploy all &gt;&gt; &quot;[LOGSFOLDER]install_mfe.log&quot; 2&gt;&amp;1" Execute="deferred" Return="ignore" Impersonate="no" />
    <CustomAction Id="PostInstallHealthcheck" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\_lib\web-apps\openedx\healthcheck.cmd&quot; &gt;&gt; &quot;[LOGSFOLDER]install_health.log&quot; 2&gt;&amp;1" Execute="deferred" Return="ignore" Impersonate="no" />
    <CustomAction Id="InstallMySQLService" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\libscript.cmd&quot; install databases/mysql --port=[PROP_MYSQL_PORT] &gt;&gt; &quot;[LOGSFOLDER]install_mysql.log&quot; 2&gt;&amp;1" Execute="deferred" Return="ignore" Impersonate="no" />
    <CustomAction Id="InstallRedisService" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\libscript.cmd&quot; install caches/redis --port=[PROP_REDIS_PORT] &gt;&gt; &quot;[LOGSFOLDER]install_redis.log&quot; 2&gt;&amp;1" Execute="deferred" Return="ignore" Impersonate="no" />
    <CustomAction Id="UninstallOpenEdXService" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\libscript.cmd&quot; uninstall _lib/web-apps/openedx [PURGE_openedx]" Execute="deferred" Return="ignore" Impersonate="no" />
    <CustomAction Id="CA_AbortNoLicense" Error="Installation aborted: You must accept all bundled software licenses to proceed. Pass AGREE_ALL_LICENSES=1 for unattended installations." />

    <!-- UI Architecture Supporting Simple and Advanced Modes -->
    <UI Id="CustomUI">
      <Property Id="DefaultUIFont" Value="WixUI_Font_Normal" />

      <!-- Welcome Dialog -->
      <Dialog Id="Dlg_Welcome" Width="370" Height="270" Title="Welcome to [ProductName] Setup">
        <Control Id="Bitmap" Type="Bitmap" X="0" Y="0" Width="123" Height="234" Text="WixUIDialogBmp" />
        <Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" />
        <Control Id="Title" Type="Text" X="135" Y="20" Width="220" Height="50" Transparent="yes" NoPrefix="yes" Text="{\WixUI_Font_Bigger}Welcome to the [ProductName] Setup Wizard" />
        <Control Id="Description" Type="Text" X="135" Y="70" Width="220" Height="70" Transparent="yes" NoPrefix="yes" Text="$WELCOME_DESC" />
        <Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Disabled="yes" Text="Back" />
        <Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next">
          <Publish Event="NewDialog" Value="Dlg_License">1</Publish>
        </Control>
        <Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel">
          <Publish Event="EndDialog" Value="Exit">1</Publish>
        </Control>
      </Dialog>

      <!-- License Dialog -->
      <Dialog Id="Dlg_License" Width="370" Height="270" Title="[ProductName] Setup">
        <Control Id="BannerBitmap" Type="Bitmap" X="0" Y="0" Width="370" Height="44" Text="WixUIBannerBmp" />
        <Control Id="BannerLine" Type="Line" X="0" Y="44" Width="370" Height="0" />
        <Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" />
        <Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="{\WixUI_Font_Title}End-User License Agreement" />
        <Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Please read the following license agreement carefully." />
        <Control Id="AgreementText" Type="ScrollableText" X="20" Y="48" Width="330" Height="178" Sunken="yes" TabSkip="no">
          <Text SourceFile="${rtf_license_file:-license_placeholder.rtf}" />
        </Control>
        <Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back">
          <Publish Event="NewDialog" Value="Dlg_Welcome">1</Publish>
        </Control>
        <Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="I Agree">
          <Publish Property="LICENSE_ACCEPTED" Value="1">1</Publish>
          <Publish Property="AGREE_ALL_LICENSES" Value="1">1</Publish>
          <Publish Event="NewDialog" Value="Dlg_SetupType">1</Publish>
        </Control>
        <Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel">
          <Publish Event="EndDialog" Value="Exit">1</Publish>
        </Control>
      </Dialog>
${MULTI_LICENSE_XML}

      <!-- Setup Type Choice: Simple Mode vs Advanced Mode -->
      <Dialog Id="Dlg_SetupType" Width="370" Height="270" Title="Choose Installation Mode">
        <Control Id="BannerBitmap" Type="Bitmap" X="0" Y="0" Width="370" Height="44" Text="WixUIBannerBmp" />
        <Control Id="BannerLine" Type="Line" X="0" Y="44" Width="370" Height="0" />
        <Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" />
        <Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="{\\WixUI_Font_Title}Choose Setup Type" />
        <Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Select your preferred deployment method." />
        <Control Id="RadioGroup" Type="RadioButtonGroup" X="20" Y="60" Width="330" Height="120" Property="SETUP_MODE">
          <RadioButtonGroup Property="SETUP_MODE">
            <RadioButton Value="Simple" X="0" Y="0" Width="320" Height="30" Text="Simple Mode (Express Install) - Installs all components with recommended defaults" />
            <RadioButton Value="Advanced" X="0" Y="45" Width="320" Height="30" Text="Advanced Mode (Custom Configuration) - Customize component selection, DBaaS URLs, and ports" />
          </RadioButtonGroup>
        </Control>
        <Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back">
          <Publish Event="NewDialog" Value="Dlg_License">1</Publish>
        </Control>
        <Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next">
          <Publish Event="NewDialog" Value="Dlg_Features"><![CDATA[SETUP_MODE="Advanced"]]></Publish>
          <Publish Event="NewDialog" Value="Dlg_VerifyReady"><![CDATA[SETUP_MODE="Simple"]]></Publish>
        </Control>
        <Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel">
          <Publish Event="EndDialog" Value="Exit">1</Publish>
        </Control>
      </Dialog>

      <!-- Advanced Features Selection Dialog -->
      <Dialog Id="Dlg_Features" Width="370" Height="270" Title="Custom Component Selection">
        <Control Id="BannerBitmap" Type="Bitmap" X="0" Y="0" Width="370" Height="44" Text="WixUIBannerBmp" />
        <Control Id="BannerLine" Type="Line" X="0" Y="44" Width="370" Height="0" />
        <Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" />
        <Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="{\\WixUI_Font_Title}Component Selection &amp; Architecture" />
        <Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Review required runtimes and configure optional services." />
        <Control Id="Lbl_NonOptHeader" Type="Text" X="20" Y="48" Width="330" Height="14" NoPrefix="yes" Text="Non-Optional Components (always installed):" />
        <Control Id="Lbl_NonOptList" Type="Text" X="28" Y="63" Width="320" Height="50" NoPrefix="yes" Text="${NON_OPT_LIST}" />
        <Control Id="Lbl_OptHeader" Type="Text" X="20" Y="114" Width="330" Height="14" NoPrefix="yes" Text="Optional / Configurable Services:" />
        <Control Id="Chk_LMS" Type="CheckBox" X="28" Y="128" Width="320" Height="14" Property="INSTALL_LMS" CheckBoxValue="1" Text="${CHK_LMS_TEXT}" />
        <Control Id="Chk_CMS" Type="CheckBox" X="28" Y="142" Width="320" Height="14" Property="INSTALL_CMS" CheckBoxValue="1" Text="${CHK_CMS_TEXT}" />
        <Control Id="Chk_MySQL" Type="CheckBox" X="28" Y="156" Width="320" Height="14" Property="INSTALL_MYSQL" CheckBoxValue="1" Text="Install Local MySQL Service (uncheck if using DBaaS)" />
        <Control Id="Chk_Redis" Type="CheckBox" X="28" Y="170" Width="320" Height="14" Property="INSTALL_REDIS" CheckBoxValue="1" Text="Install Local Redis Service (uncheck if using Cloud Redis)" />
        <Control Id="Chk_Workers" Type="CheckBox" X="28" Y="184" Width="320" Height="14" Property="INSTALL_WORKERS" CheckBoxValue="1" Text="${CHK_WORKERS_TEXT}" />
        <Control Id="Chk_Demo" Type="CheckBox" X="28" Y="198" Width="320" Height="14" Property="IMPORT_DEMO_CONTENT" CheckBoxValue="1" Text="${CHK_DEMO_TEXT}" />
        <Control Id="Chk_MFEs" Type="CheckBox" X="28" Y="212" Width="320" Height="14" Property="INSTALL_MFES" CheckBoxValue="1" Text="${CHK_MFES_TEXT}" />
        <Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back">
          <Publish Event="NewDialog" Value="Dlg_SetupType">1</Publish>
        </Control>
        <Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next">
          <Publish Event="NewDialog" Value="Dlg_InstallLocation">1</Publish>
        </Control>
        <Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel">
          <Publish Event="EndDialog" Value="Exit">1</Publish>
        </Control>
      </Dialog>

      <!-- Advanced Destination Folders Dialog (Dlg_InstallLocation) -->
      <Dialog Id="Dlg_InstallLocation" Width="370" Height="270" Title="Destination Folders">
        <Control Id="BannerBitmap" Type="Bitmap" X="0" Y="0" Width="370" Height="44" Text="WixUIBannerBmp" />
        <Control Id="BannerLine" Type="Line" X="0" Y="44" Width="370" Height="0" />
        <Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" />

        <Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="{\\WixUI_Font_Title}Destination Folders" />
        <Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Select target locations for binaries, databases, logs, and backups." />

        <Control Id="Lbl_AppFolder" Type="Text" X="20" Y="48" Width="330" Height="13" NoPrefix="yes" Text="Application Installation Folder:" />
        <Control Id="Txt_AppFolder" Type="Edit" X="20" Y="61" Width="260" Height="17" Property="INSTALLFOLDER" />
        <Control Id="Btn_BrowseApp" Type="PushButton" X="285" Y="61" Width="65" Height="17" Text="Browse...">
          <Publish Property="_BrowseProperty" Value="INSTALLFOLDER">1</Publish>
          <Publish Event="SpawnDialog" Value="BrowseDlg">1</Publish>
        </Control>

        <Control Id="Lbl_DataFolder" Type="Text" X="20" Y="80" Width="330" Height="13" NoPrefix="yes" Text="Databases and Media Storage Folder:" />
        <Control Id="Txt_DataFolder" Type="Edit" X="20" Y="93" Width="260" Height="17" Property="DATAFOLDER" />
        <Control Id="Btn_BrowseData" Type="PushButton" X="285" Y="93" Width="65" Height="17" Text="Browse...">
          <Publish Property="_BrowseProperty" Value="DATAFOLDER">1</Publish>
          <Publish Event="SpawnDialog" Value="BrowseDlg">1</Publish>
        </Control>

        <Control Id="Lbl_LogsFolder" Type="Text" X="20" Y="112" Width="330" Height="13" NoPrefix="yes" Text="Log Files Folder:" />
        <Control Id="Txt_LogsFolder" Type="Edit" X="20" Y="125" Width="260" Height="17" Property="LOGSFOLDER" />
        <Control Id="Btn_BrowseLogs" Type="PushButton" X="285" Y="125" Width="65" Height="17" Text="Browse...">
          <Publish Property="_BrowseProperty" Value="LOGSFOLDER">1</Publish>
          <Publish Event="SpawnDialog" Value="BrowseDlg">1</Publish>
        </Control>

        <Control Id="Lbl_BackupFolder" Type="Text" X="20" Y="144" Width="330" Height="13" NoPrefix="yes" Text="Automated Snapshots &amp; Backups Folder:" />
        <Control Id="Txt_BackupFolder" Type="Edit" X="20" Y="157" Width="260" Height="17" Property="BACKUPFOLDER" />
        <Control Id="Btn_BrowseBackup" Type="PushButton" X="285" Y="157" Width="65" Height="17" Text="Browse...">
          <Publish Property="_BrowseProperty" Value="BACKUPFOLDER">1</Publish>
          <Publish Event="SpawnDialog" Value="BrowseDlg">1</Publish>
        </Control>

        <Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back">
          <Publish Event="NewDialog" Value="Dlg_Features">1</Publish>
        </Control>
        <Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next">
          <Publish Event="NewDialog" Value="Dlg_RuntimeSelection">1</Publish>
        </Control>
        <Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel">
          <Publish Event="EndDialog" Value="Exit">1</Publish>
        </Control>
      </Dialog>

      <!-- Advanced Runtime Selection Dialog (Dlg_RuntimeSelection) -->
      <Dialog Id="Dlg_RuntimeSelection" Width="370" Height="270" Title="Runtime Environment Selection">
        <Control Id="BannerBitmap" Type="Bitmap" X="0" Y="0" Width="370" Height="44" Text="WixUIBannerBmp" />
        <Control Id="BannerLine" Type="Line" X="0" Y="44" Width="370" Height="0" />
        <Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" />

        <Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="{\\WixUI_Font_Title}Runtime Environments" />
        <Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="${RT_DESC}" />

        <Control Id="Grp_Python" Type="GroupBox" X="20" Y="50" Width="330" Height="70" Text="${GRP_RT1_TEXT}" />
        <Control Id="Rad_PythonExisting" Type="RadioButtonGroup" X="28" Y="65" Width="310" Height="45" Property="USE_EXISTING_PYTHON">
          <RadioButtonGroup Property="USE_EXISTING_PYTHON">
            <RadioButton Value="1" X="0" Y="0" Width="310" Height="20" Text="${RAD_RT1_EX}" />
            <RadioButton Value="0" X="0" Y="22" Width="310" Height="20" Text="${RAD_RT1_ISO}" />
          </RadioButtonGroup>
        </Control>

        <Control Id="Grp_Node" Type="GroupBox" X="20" Y="125" Width="330" Height="70" Text="${GRP_RT2_TEXT}" />
        <Control Id="Rad_NodeExisting" Type="RadioButtonGroup" X="28" Y="140" Width="310" Height="45" Property="USE_EXISTING_NODE">
          <RadioButtonGroup Property="USE_EXISTING_NODE">
            <RadioButton Value="1" X="0" Y="0" Width="310" Height="20" Text="${RAD_RT2_EX}" />
            <RadioButton Value="0" X="0" Y="22" Width="310" Height="20" Text="${RAD_RT2_ISO}" />
          </RadioButtonGroup>
        </Control>

        <Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back">
          <Publish Event="NewDialog" Value="Dlg_InstallLocation">1</Publish>
        </Control>
        <Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next">
          <Publish Event="NewDialog" Value="Dlg_OpenEdX_SourceRepo">1</Publish>
        </Control>
        <Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel">
          <Publish Event="EndDialog" Value="Exit">1</Publish>
        </Control>
      </Dialog>

      <!-- Advanced Source Repository Dialog (Dlg_OpenEdX_SourceRepo) -->
      <Dialog Id="Dlg_OpenEdX_SourceRepo" Width="370" Height="270" Title="Source Repository &amp; Release Selection">
        <Control Id="BannerBitmap" Type="Bitmap" X="0" Y="0" Width="370" Height="44" Text="WixUIBannerBmp" />
        <Control Id="BannerLine" Type="Line" X="0" Y="44" Width="370" Height="0" />
        <Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" />

        <Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="{\\WixUI_Font_Title}Source Repository &amp; Release" />
        <Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Review the repository source and branch configured for this installer." />

        <Control Id="Lbl_Repo" Type="Text" X="20" Y="48" Width="330" Height="14" NoPrefix="yes" Text="Configured ${_esc_name} Repository Source (Read-Only):" />
        <Control Id="Txt_Repo" Type="Edit" X="20" Y="63" Width="330" Height="18" Property="PROP_OPENEDX_EDX_PLATFORM_REPOSITORY" Disabled="yes" />
        <Control Id="Hint_Repo" Type="Text" X="20" Y="83" Width="330" Height="22" Transparent="yes" NoPrefix="yes" Text="Source repository, local path, or fork configured during installer build." />

        <Control Id="Lbl_Branch" Type="Text" X="20" Y="110" Width="330" Height="14" NoPrefix="yes" Text="Configured Target Release, Branch, or Tag (Read-Only):" />
        <Control Id="Txt_Branch" Type="Edit" X="20" Y="125" Width="330" Height="18" Property="PROP_OPENEDX_VERSION" Disabled="yes" />
        <Control Id="Hint_Branch" Type="Text" X="20" Y="145" Width="330" Height="22" Transparent="yes" NoPrefix="yes" Text="Target branch, release tag, or commit SHA configured during installer build." />

        <Control Id="Lbl_Token" Type="Text" X="20" Y="175" Width="330" Height="14" NoPrefix="yes" Text="Private Repository Access Token (optional if private fork):" />
        <Control Id="Txt_Token" Type="Edit" X="20" Y="190" Width="330" Height="18" Property="PROP_OPENEDX_REPO_AUTH_TOKEN" Password="yes" />

        <Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back">
          <Publish Event="NewDialog" Value="Dlg_RuntimeSelection">1</Publish>
        </Control>
        <Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next">
          <Publish Event="NewDialog" Value="Dlg_OpenEdX_Config">1</Publish>
        </Control>
        <Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel">
          <Publish Event="EndDialog" Value="Exit">1</Publish>
        </Control>
      </Dialog>

      <!-- Advanced Configuration Dialog: Network and Superuser -->
      <Dialog Id="Dlg_OpenEdX_Config" Width="370" Height="270" Title="Network and Credentials Configuration">
        <Control Id="BannerBitmap" Type="Bitmap" X="0" Y="0" Width="370" Height="44" Text="WixUIBannerBmp" />
        <Control Id="BannerLine" Type="Line" X="0" Y="44" Width="370" Height="0" />
        <Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" />
        <Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="{\WixUI_Font_Title}Network &amp; Credentials" />
        <Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Set service ports and administrator credentials." />
        <Control Id="Lbl_LmsPort" Type="Text" X="20" Y="50" Width="150" Height="15" Text="${LBL_PORT1}" />
        <Control Id="Txt_LmsPort" Type="Edit" X="20" Y="65" Width="140" Height="18" Property="PROP_LMS_PORT" />
        <Control Id="Lbl_CmsPort" Type="Text" X="180" Y="50" Width="150" Height="15" Text="${LBL_PORT2}" />
        <Control Id="Txt_CmsPort" Type="Edit" X="180" Y="65" Width="140" Height="18" Property="PROP_CMS_PORT" />

        <Control Id="Lbl_AdminUser" Type="Text" X="20" Y="90" Width="150" Height="15" Text="Superuser Username:" />
        <Control Id="Txt_AdminUser" Type="Edit" X="20" Y="105" Width="140" Height="18" Property="PROP_OPENEDX_ADMIN_USERNAME" />
        <Control Id="Lbl_AdminPass" Type="Text" X="180" Y="90" Width="150" Height="15" Text="Superuser Password:" />
        <Control Id="Txt_AdminPass" Type="Edit" X="180" Y="105" Width="140" Height="18" Property="PROP_OPENEDX_ADMIN_PASSWORD" Password="yes" />

        <Control Id="Lbl_AdminEmail" Type="Text" X="20" Y="130" Width="300" Height="15" Text="Superuser Email Address:" />
        <Control Id="Txt_AdminEmail" Type="Edit" X="20" Y="145" Width="300" Height="18" Property="PROP_OPENEDX_ADMIN_EMAIL" />

        <Control Id="Lbl_Theme" Type="Text" X="20" Y="170" Width="150" Height="15" Text="Theme Name (or 'none'):" />
        <Control Id="Txt_Theme" Type="Edit" X="20" Y="185" Width="140" Height="18" Property="PROP_OPENEDX_THEME" />
        <Control Id="Lbl_ThemeUrl" Type="Text" X="180" Y="170" Width="150" Height="15" Text="Custom Theme Git URL:" />
        <Control Id="Txt_ThemeUrl" Type="Edit" X="180" Y="185" Width="170" Height="18" Property="PROP_OPENEDX_THEME_REPO_URL" />

        <Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back">
          <Publish Event="NewDialog" Value="Dlg_OpenEdX_SourceRepo">1</Publish>
        </Control>
        <Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next">
          <Publish Event="NewDialog" Value="Dlg_OpenEdX_DB">1</Publish>
        </Control>
        <Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel">
          <Publish Event="EndDialog" Value="Exit">1</Publish>
        </Control>
      </Dialog>

      <!-- Advanced Configuration Dialog: Relational Database / DBaaS -->
      <Dialog Id="Dlg_OpenEdX_DB" Width="370" Height="270" Title="Relational Database / DBaaS Configuration">
        <Control Id="BannerBitmap" Type="Bitmap" X="0" Y="0" Width="370" Height="44" Text="WixUIBannerBmp" />
        <Control Id="BannerLine" Type="Line" X="0" Y="44" Width="370" Height="0" />
        <Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" />
        <Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="{\WixUI_Font_Title}Database &amp; DBaaS Configuration" />
        <Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Configure MySQL or an External DBaaS Provider." />
        <Control Id="Lbl_LocalPort" Type="Text" X="20" Y="50" Width="300" Height="15" Text="Local MySQL Port (if self-hosted):" />
        <Control Id="Txt_LocalPort" Type="Edit" X="20" Y="65" Width="120" Height="18" Property="PROP_MYSQL_PORT" />

        <Control Id="Lbl_RemoteUrl" Type="Text" X="20" Y="90" Width="330" Height="15" Text="External DBaaS URL (e.g. AWS RDS / PlanetScale / Azure):" />
        <Control Id="Txt_RemoteUrl" Type="Edit" X="20" Y="105" Width="330" Height="18" Property="PROP_MYSQL_REMOTE_URL" />
        <Control Id="Hint_Remote" Type="Text" X="20" Y="125" Width="330" Height="25" Transparent="yes" Text="Format: mysql://user:password@host:port/database. Providing a remote DBaaS URL automatically bypasses local MySQL setup." />

        <Control Id="Lbl_RootPass" Type="Text" X="20" Y="155" Width="300" Height="15" Text="Local MySQL Root Password (ignored if DBaaS is used):" />
        <Control Id="Txt_RootPass" Type="Edit" X="20" Y="170" Width="200" Height="18" Property="PROP_MYSQL_ROOT_PASSWORD" Password="yes" />

        <Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back">
          <Publish Event="NewDialog" Value="Dlg_OpenEdX_Config">1</Publish>
        </Control>
        <Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next">
          <Publish Event="NewDialog" Value="Dlg_OpenEdX_CacheSearch">1</Publish>
        </Control>
        <Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel">
          <Publish Event="EndDialog" Value="Exit">1</Publish>
        </Control>
      </Dialog>

      <!-- Advanced Configuration Dialog: Cache (Redis), MongoDB & Search -->
      <Dialog Id="Dlg_OpenEdX_CacheSearch" Width="370" Height="270" Title="Cache, Document Store &amp; Search Configuration">
        <Control Id="BannerBitmap" Type="Bitmap" X="0" Y="0" Width="370" Height="44" Text="WixUIBannerBmp" />
        <Control Id="BannerLine" Type="Line" X="0" Y="44" Width="370" Height="0" />
        <Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" />
        <Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="{\WixUI_Font_Title}Cache, Document Store &amp; Search" />
        <Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Configure Redis, MongoDB Atlas, and Meilisearch." />

        <Control Id="Lbl_RedisPort" Type="Text" X="20" Y="50" Width="150" Height="15" Text="Redis Port (e.g. 6379, 6380):" />
        <Control Id="Txt_RedisPort" Type="Edit" X="20" Y="65" Width="120" Height="18" Property="PROP_REDIS_PORT" />
        <Control Id="Lbl_RedisUrl" Type="Text" X="160" Y="50" Width="190" Height="15" Text="Remote Redis DBaaS / URI:" />
        <Control Id="Txt_RedisUrl" Type="Edit" X="160" Y="65" Width="190" Height="18" Property="PROP_REDIS_URL" />

        <Control Id="Lbl_MongoUri" Type="Text" X="20" Y="95" Width="330" Height="15" Text="MongoDB Atlas URI / Connection String:" />
        <Control Id="Txt_MongoUri" Type="Edit" X="20" Y="110" Width="330" Height="18" Property="PROP_MONGODB_URI" />

        <Control Id="Lbl_MeiliUrl" Type="Text" X="20" Y="135" Width="330" Height="15" Text="Remote Meilisearch Cloud URL:" />
        <Control Id="Txt_MeiliUrl" Type="Edit" X="20" Y="150" Width="330" Height="18" Property="PROP_MEILISEARCH_CUSTOM_URL" />

        <Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back">
          <Publish Event="NewDialog" Value="Dlg_OpenEdX_DB">1</Publish>
        </Control>
        <Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next">
          <Publish Event="NewDialog" Value="Dlg_VerifyReady">1</Publish>
        </Control>
        <Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel">
          <Publish Event="EndDialog" Value="Exit">1</Publish>
        </Control>
      </Dialog>

      <!-- Verify Ready to Install Dialog -->
      <Dialog Id="Dlg_VerifyReady" Width="370" Height="270" Title="Ready to Install [ProductName]">
        <Control Id="BannerBitmap" Type="Bitmap" X="0" Y="0" Width="370" Height="44" Text="WixUIBannerBmp" />
        <Control Id="BannerLine" Type="Line" X="0" Y="44" Width="370" Height="0" />
        <Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" />
        <Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="{\WixUI_Font_Title}Ready to Install [ProductName]" />
        <Control Id="Description" Type="Text" X="25" Y="22" Width="280" Height="20" Transparent="yes" NoPrefix="yes" Text="Review the components being installed on your computer." />
        <Control Id="Summary" Type="Text" X="20" Y="48" Width="330" Height="14" NoPrefix="yes" Text="Non-optional components to be installed:" />
        <Control Id="CompPython" Type="Text" X="28" Y="64" Width="320" Height="13" NoPrefix="yes" Text="- python (Python 3.11+ runtime &amp; virtual environment)$COMP_TAG" />
        <Control Id="CompNode" Type="Text" X="28" Y="78" Width="320" Height="13" NoPrefix="yes" Text="- nodejs (Node.js &amp; npm asset compilation pipeline)$COMP_TAG" />
        <Control Id="CompMeili" Type="Text" X="28" Y="92" Width="320" Height="13" NoPrefix="yes" Text="- meilisearch (Course search and catalog discovery engine)$COMP_TAG" />
        <Control Id="CompMySQL" Type="Text" X="28" Y="106" Width="320" Height="13" NoPrefix="yes" Text="- mysql (Relational database for users and course metadata)$COMP_TAG" />
        <Control Id="CompRedis" Type="Text" X="28" Y="120" Width="320" Height="13" NoPrefix="yes" Text="- redis (In-memory caching and Celery asynchronous task broker)$COMP_TAG" />
        <Control Id="CompMongo" Type="Text" X="28" Y="134" Width="320" Height="13" NoPrefix="yes" Text="- mongodb (Document datastore for courseware modules)$COMP_TAG" />
        <Control Id="CompLMS" Type="Text" X="28" Y="148" Width="320" Height="13" NoPrefix="yes" Text="- openedx (Open edX LMS on port [PROP_LMS_PORT], Studio on port [PROP_CMS_PORT])$COMP_TAG" />
        <Control Id="CompWorkers" Type="Text" X="28" Y="162" Width="320" Height="13" NoPrefix="yes" Text="- workers (Celery asynchronous task workers &amp; beat scheduler)$COMP_TAG" />
        <Control Id="CompDemo" Type="Text" X="28" Y="176" Width="320" Height="13" NoPrefix="yes" Text="- content (Demo courseware and content libraries catalog)$COMP_TAG" />
        <Control Id="CompMFEs" Type="Text" X="28" Y="190" Width="320" Height="13" NoPrefix="yes" Text="- mfes (Micro-Frontends: Learning, Authn, Account)$COMP_TAG" />
        <Control Id="Instructions" Type="Text" X="20" Y="208" Width="330" Height="24" Text="Click Install to begin installation. If you want to review or change any settings, click Back." />
        <Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back">
          <Publish Event="NewDialog" Value="Dlg_SetupType"><![CDATA[SETUP_MODE="Simple"]]></Publish>
          <Publish Event="NewDialog" Value="Dlg_OpenEdX_CacheSearch"><![CDATA[SETUP_MODE="Advanced"]]></Publish>
        </Control>
        <Control Id="Install" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Install">
          <Publish Event="EndDialog" Value="Return">1</Publish>
        </Control>
        <Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel">
          <Publish Event="EndDialog" Value="Exit">1</Publish>
        </Control>
      </Dialog>

      <!-- Completion/Exit Dialog with Desktop Shortcuts and Launch Browser Checkboxes -->
      <Dialog Id="Dlg_Exit" Width="370" Height="270" Title="[ProductName] Setup Complete">
        <Control Id="Bitmap" Type="Bitmap" X="0" Y="0" Width="123" Height="234" Text="WixUIDialogBmp" />
        <Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" />
        <Control Id="Title" Type="Text" X="135" Y="20" Width="220" Height="50" Transparent="yes" NoPrefix="yes" Text="{\\WixUI_Font_Bigger}Completed [ProductName] Setup" />
        <Control Id="Desc" Type="Text" X="135" Y="70" Width="220" Height="35" Transparent="yes" NoPrefix="yes" Text="${EXIT_DESC}" />
        <Control Id="CreateLmsShortcutCheckBox" Type="CheckBox" X="135" Y="115" Width="230" Height="15" Property="CREATE_SHORTCUT_LMS" CheckBoxValue="1" Text="${SHORTCUT_1_TEXT}" />
        <Control Id="CreateCmsShortcutCheckBox" Type="CheckBox" X="135" Y="135" Width="230" Height="15" Property="CREATE_SHORTCUT_CMS" CheckBoxValue="1" Text="${SHORTCUT_2_TEXT}" />
        <Control Id="LaunchBrowserCheckBox" Type="CheckBox" X="135" Y="155" Width="230" Height="15" Property="LAUNCH_BROWSER" CheckBoxValue="1" Text="${LAUNCH_1_TEXT}" />
        <Control Id="LaunchStudioCheckBox" Type="CheckBox" X="135" Y="175" Width="230" Height="15" Property="LAUNCH_STUDIO" CheckBoxValue="1" Text="${LAUNCH_2_TEXT}" />
        <Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Disabled="yes" Text="Back" />
        <Control Id="Finish" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Finish">
          <Publish Event="DoAction" Value="CA_LaunchBrowser"><![CDATA[LAUNCH_BROWSER="1" AND NOT Installed]]></Publish>
          <Publish Event="DoAction" Value="CA_LaunchStudio"><![CDATA[LAUNCH_STUDIO="1" AND NOT Installed]]></Publish>
          <Publish Event="EndDialog" Value="Return">1</Publish>
        </Control>
        <Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Disabled="yes" Text="Cancel" />
      </Dialog>

      <!-- Sequential UI Navigation Routing -->
      <InstallUISequence>
        <CostInitialize Sequence="800" />
        <FileCost Sequence="900" />
        <CostFinalize Sequence="1000" />
        <Show Dialog="Dlg_Welcome" After="CostFinalize">NOT Installed</Show>
        <Show Dialog="Dlg_Exit" OnExit="success">NOT Installed</Show>
      </InstallUISequence>
    </UI>

    <!-- Execution Sequence for Service Orchestration -->
    <InstallExecuteSequence>
      <CostInitialize Sequence="800" />
      <FileCost Sequence="900" />
      <CostFinalize Sequence="1000" />
      <Custom Action="CA_AbortNoLicense" Before="InstallInitialize"><![CDATA[NOT Installed AND NOT (AGREE_ALL_LICENSES="1") AND NOT (LICENSE_ACCEPTED="1"${MULTI_LICENSE_EXEC_COND})]]></Custom>
      <Custom Action="InstallMySQLService" Before="InstallOpenEdXService"><![CDATA[NOT Installed AND INSTALL_MYSQL="1" AND NOT PROP_MYSQL_REMOTE_URL AND NOT PROP_OPENEDX_OFFLINE="1"]]></Custom>
      <Custom Action="InstallRedisService" Before="InstallOpenEdXService"><![CDATA[NOT Installed AND INSTALL_REDIS="1" AND NOT PROP_REDIS_URL AND NOT PROP_OPENEDX_OFFLINE="1"]]></Custom>
      <Custom Action="InstallOpenEdXService" Before="InstallFinalize"><![CDATA[NOT Installed AND INSTALL_LMS="1"]]></Custom>
      <Custom Action="InstallWorkersService" After="InstallOpenEdXService"><![CDATA[NOT Installed AND INSTALL_WORKERS="1"]]></Custom>
      <Custom Action="ImportDemoContentAction" After="InstallOpenEdXService"><![CDATA[NOT Installed AND IMPORT_DEMO_CONTENT="1"]]></Custom>
      <Custom Action="BuildMFEsAction" After="InstallOpenEdXService"><![CDATA[NOT Installed AND INSTALL_MFES="1"]]></Custom>
      <Custom Action="PostInstallHealthcheck" After="InstallOpenEdXService"><![CDATA[NOT Installed]]></Custom>
      <Custom Action="StopWorkersService" Before="UninstallOpenEdXService"><![CDATA[REMOVE="ALL"]]></Custom>
      <Custom Action="UninstallOpenEdXService" Before="RemoveFiles">REMOVE="ALL"</Custom>
    </InstallExecuteSequence>

    <Feature Id="ProductFeature" Title="$APP_NAME" Level="1">
      <ComponentGroupRef Id="LibscriptHarvestedComponents" />
$([ "$VARIANT" = "offline" ] && printf '      <ComponentGroupRef Id="LibscriptOfflineCacheComponents" />\n')      <ComponentRef Id="CoursewareDataStore" />
      <ComponentRef Id="CoursewareLogStore" />
      <ComponentRef Id="CoursewareBackupStore" />
      <ComponentRef Id="ApplicationShortcuts" />
      <ComponentRef Id="EnvironmentSettings" />
    </Feature>
  </Product>

  <Fragment>
    <!-- Environment Variable Registration -->
    <DirectoryRef Id="INSTALLFOLDER">
      <Component Id="EnvironmentSettings" Guid="7291A843-159A-46D8-92EF-891029384756">
        <Environment Id="EnvLibscriptRoot" Name="LIBSCRIPT_ROOT_DIR" Value="[INSTALLFOLDER]libscript" Permanent="no" Action="set" System="yes" />
        <Environment Id="EnvPathLibscript" Name="PATH" Value="[INSTALLFOLDER]libscript" Permanent="no" Action="set" Part="last" System="yes" />
        <Environment Id="EnvPathStack" Name="PATH" Value="[INSTALLFOLDER]libscript\_lib\web-apps\openedx" Permanent="no" Action="set" Part="last" System="yes" />
        <RegistryValue Root="HKCU" Key="Software\LibScript\OpenEdX" Name="env_configured" Type="integer" Value="1" KeyPath="yes" />
      </Component>
    </DirectoryRef>

    <!-- Permanent and NeverOverwrite User Data and Courseware Stores -->
    <DirectoryRef Id="DATAFOLDER">
      <Component Id="CoursewareDataStore" Guid="7F28A541-11C3-4E80-990A-46D91A883C12" Permanent="yes" NeverOverwrite="yes">
        <CreateFolder Directory="DATAFOLDER" />
      </Component>
    </DirectoryRef>

    <DirectoryRef Id="LOGSFOLDER">
      <Component Id="CoursewareLogStore" Guid="3E4A1521-884A-49A3-A65B-64771C5091E2" Permanent="yes" NeverOverwrite="yes">
        <CreateFolder Directory="LOGSFOLDER" />
      </Component>
    </DirectoryRef>

    <DirectoryRef Id="BACKUPFOLDER">
      <Component Id="CoursewareBackupStore" Guid="98127364-5A4B-4C3D-8E2F-1029384756BA" Permanent="yes" NeverOverwrite="yes">
        <CreateFolder Directory="BACKUPFOLDER" />
      </Component>
    </DirectoryRef>

    <!-- Administrative Shortcuts in Start Menu -->
    <DirectoryRef Id="OpenEdXProgramMenuFolder">
      <Component Id="ApplicationShortcuts" Guid="718293A4-B5C6-4D7E-8F90-123456789ABC">
        <Shortcut Id="ShortcutCli" Name="Open edX Management Console" Description="Open edX Management CLI" Target="[INSTALLFOLDER]libscript\_lib\web-apps\openedx\cli.cmd" WorkingDirectory="INSTALLFOLDER" />
        <Shortcut Id="ShortcutHealth" Name="Open edX Healthcheck" Description="Open edX Diagnostics Probe" Target="[INSTALLFOLDER]libscript\_lib\web-apps\openedx\healthcheck.cmd" WorkingDirectory="INSTALLFOLDER" />
        <Shortcut Id="ShortcutDbShell" Name="Open edX Database Console" Description="Open edX MySQL Database Shell" Target="[INSTALLFOLDER]libscript\_lib\web-apps\openedx\dbshell.cmd" Arguments="mysql" WorkingDirectory="INSTALLFOLDER" />
        <Shortcut Id="ShortcutBackup" Name="Open edX Backup and Restore" Description="Open edX Backup Tool" Target="[INSTALLFOLDER]libscript\_lib\web-apps\openedx\backup.cmd" WorkingDirectory="INSTALLFOLDER" $([ -n "$ICON_PATH" ] && [ -f "$ICON_PATH" ] && printf 'Icon="AppIcon.ico"') />
        <Shortcut Id="DesktopShortcutCli" Directory="DesktopFolder" Name="Open edX Management Console" Description="Open edX Management CLI" Target="[INSTALLFOLDER]libscript\_lib\web-apps\openedx\cli.cmd" WorkingDirectory="INSTALLFOLDER" $([ -n "$ICON_PATH" ] && [ -f "$ICON_PATH" ] && printf 'Icon="AppIcon.ico"') />
        <Shortcut Id="DesktopShortcutLms" Directory="DesktopFolder" Name="Open edX LMS" Description="Open edX Learning Management System" Target="[INSTALLFOLDER]libscript\_lib\web-apps\openedx\cli.cmd" Arguments="lms" WorkingDirectory="INSTALLFOLDER" $([ -n "$ICON_PATH" ] && [ -f "$ICON_PATH" ] && printf 'Icon="LmsIcon.ico"') />
        <Shortcut Id="DesktopShortcutStudio" Directory="DesktopFolder" Name="Open edX Studio" Description="Open edX Studio Course Authoring" Target="[INSTALLFOLDER]libscript\_lib\web-apps\openedx\cli.cmd" Arguments="studio" WorkingDirectory="INSTALLFOLDER" $([ -n "$ICON_PATH" ] && [ -f "$ICON_PATH" ] && printf 'Icon="StudioIcon.ico"') />
        <RemoveFolder Id="CleanUpShortCutDir" Directory="OpenEdXProgramMenuFolder" On="uninstall" />
        <RegistryValue Root="HKCU" Key="Software\LibScript\OpenEdX" Name="installed" Type="integer" Value="1" KeyPath="yes" />
      </Component>
    </DirectoryRef>
  </Fragment>
</Wix>
EOF_PROPS
}

generate_wxs
printf '[PASS] Successfully created WiX manifest: %s\n' "$WXS_FILE"

# ## harvest_engine_payload
# Performs the harvest_engine_payload operation and updates component state.
# ## Overview
# Performs the Overview operation and updates component state.
PAYLOAD_WXS="${OUT_FILE}_payload.wxs"
if [ "$VARIANT" = "offline" ]; then
  _bundle_manifest="${RESOLVED_TARGET_DIR}/offline_bundle.json"
  if [ -f "$_bundle_manifest" ]; then
    _cache_file_count=0
    if [ -d "$CACHE_DIR" ]; then
      _cache_file_count=$(find "$CACHE_DIR" -type f ! -name "manifest.json" ! -name "checksums.sha256" 2>/dev/null | wc -l | tr -d ' ')
    fi
    if [ "${_cache_file_count:-0}" -eq 0 ]; then
      printf '[INFO] Auto-hydrating offline cache for %s from %s...\n' "$APP_IDENTIFIER" "$_bundle_manifest"
      if [ "$APP_IDENTIFIER" = "openedx" ]; then
        "${SCRIPT_DIR}/hydrate_offline_cache.sh" --manifest "$_bundle_manifest" --cache-dir "$CACHE_DIR" --component python
      else
        "${SCRIPT_DIR}/hydrate_offline_cache.sh" --manifest "$_bundle_manifest" --cache-dir "$CACHE_DIR"
      fi
    fi
  fi
  "${SCRIPT_DIR}/harvest_payload.sh" \
    --wix-fragment "${PAYLOAD_WXS}" \
    --directory-id "LIBSCRIPT_FOLDER" \
    --component-group "LibscriptHarvestedComponents" \
    --include-cache "${CACHE_DIR}"
else
  "${SCRIPT_DIR}/harvest_payload.sh" \
    --wix-fragment "${PAYLOAD_WXS}" \
    --directory-id "LIBSCRIPT_FOLDER" \
    --component-group "LibscriptHarvestedComponents"
fi

# ## compile_msi
# Performs the compile_msi operation and updates component state.
# ## Overview
# Builds the .msi binary using cross-platform msi-rs, 
# ## Usage
#   Internal function.
# ## compile_msi
# Performs the compile_msi operation and updates component state.
compile_msi() {
  if [ "$USE_WIX" = "1" ]; then
    printf '[INFO] Using traditional WiX Toolset...\n'
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/wix/env.sh" ]; then
      # shellcheck disable=SC1090,SC1091
      _ls_src_this="${THIS_FILE:-}"; _ls_src_dir="${SCRIPT_DIR:-}"
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/wix/env.sh"
      export SCRIPT_NAME
      # shellcheck disable=SC1090,SC1091
      . "${SCRIPT_NAME}" >/dev/null 2>&1 || true
      unset SCRIPT_NAME || true
      [ -n "${_ls_src_this:-}" ] && THIS_FILE="$_ls_src_this"
      [ -n "${_ls_src_dir:-}" ] && SCRIPT_DIR="$_ls_src_dir"
    fi
  else
    if [ -d "${LIBSCRIPT_ROOT_DIR}/../msi-rs/target/release" ] && [ -x "${LIBSCRIPT_ROOT_DIR}/../msi-rs/target/release/candle" ]; then
      PATH="${LIBSCRIPT_ROOT_DIR}/../msi-rs/target/release:${PATH}"
      export PATH
    elif [ -d "${LIBSCRIPT_ROOT_DIR}/../msi-rs/target/debug" ] && [ -x "${LIBSCRIPT_ROOT_DIR}/../msi-rs/target/debug/candle" ]; then
      PATH="${LIBSCRIPT_ROOT_DIR}/../msi-rs/target/debug:${PATH}"
      export PATH
    elif [ -d "${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/default/bin" ]; then
      PATH="${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/default/bin:${PATH}"
      export PATH
    elif [ -d "${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/v0.0.1/bin" ]; then
      PATH="${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/v0.0.1/bin:${PATH}"
      export PATH
    fi

    if ! command -v candle >/dev/null 2>&1 && ! command -v candle.exe >/dev/null 2>&1; then
      if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/msi-rs/env.sh" ]; then
        # shellcheck disable=SC1090,SC1091
        _ls_src_this="${THIS_FILE:-}"; _ls_src_dir="${SCRIPT_DIR:-}"
        SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/msi-rs/env.sh"
        export SCRIPT_NAME
        # shellcheck disable=SC1090,SC1091
        . "${SCRIPT_NAME}" >/dev/null 2>&1 || true
        unset SCRIPT_NAME || true
        [ -n "${_ls_src_this:-}" ] && THIS_FILE="$_ls_src_this"
        [ -n "${_ls_src_dir:-}" ] && SCRIPT_DIR="$_ls_src_dir"
      fi
    fi

    if ! command -v candle >/dev/null 2>&1 && ! command -v candle.exe >/dev/null 2>&1; then
      if [ -x "${LIBSCRIPT_ROOT_DIR}/libscript.sh" ]; then
        "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install msi-rs v0.0.1 >/dev/null 2>&1 || true
        if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/msi-rs/env.sh" ]; then
          # shellcheck disable=SC1090,SC1091
          _ls_src_this="${THIS_FILE:-}"; _ls_src_dir="${SCRIPT_DIR:-}"
          SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/msi-rs/env.sh"
          export SCRIPT_NAME
          # shellcheck disable=SC1090,SC1091
          . "${SCRIPT_NAME}" >/dev/null 2>&1 || true
          unset SCRIPT_NAME || true
          [ -n "${_ls_src_this:-}" ] && THIS_FILE="$_ls_src_this"
          [ -n "${_ls_src_dir:-}" ] && SCRIPT_DIR="$_ls_src_dir"
        fi
      fi
    fi
  fi

  _candle_cmd='candle'
  _light_cmd='light'
  if [ "${OS:-}" = "Windows_NT" ]; then
    command -v candle.exe >/dev/null 2>&1 && _candle_cmd="candle.exe"
    command -v light.exe >/dev/null 2>&1 && _light_cmd="light.exe"
  fi


  if [ "$USE_WIX" = "1" ]; then
    printf "[INFO] Delegating MSI compilation to remote Windows VM via compile_msi_remote.sh...\n"
    if ! "${LIBSCRIPT_ROOT_DIR}/packaging/compile_msi_remote.sh" "${OUT_FILE}"; then
      printf "[ERROR] Remote compilation failed\n" >&2
      return 1
    fi
    return 0
  else
    printf "[INFO] Compiling MSI with pure-Rust msi-rs (%s / %s)...\n" "$_candle_cmd" "$_light_cmd"
  fi
  if ! "$_candle_cmd" -arch "${TARGET_ARCH}" -out "${OUT_FILE}.wixobj" "$WXS_FILE"; then
    printf '[ERROR] candle compilation failed on %s\n' "$WXS_FILE" >&2
    return 1
  fi

  if ! "$_candle_cmd" -arch "${TARGET_ARCH}" -out "${OUT_FILE}_payload.wixobj" "${PAYLOAD_WXS}"; then
    printf '[ERROR] candle compilation failed on %s\n' "${PAYLOAD_WXS}" >&2
    return 1
  fi

  if [ "$VARIANT" = "offline" ] && [ -d "$CACHE_DIR" ]; then
    if ! "$_light_cmd" -sval -ext WixUIExtension -b "${LIBSCRIPT_ROOT_DIR}" -b "$CACHE_DIR" -out "${OUT_FILE}.msi" "${OUT_FILE}.wixobj" "${OUT_FILE}_payload.wixobj"; then
      printf '[ERROR] light linker failed for %s.msi\n' "${OUT_FILE}" >&2
      return 1
    fi
  else
    if ! "$_light_cmd" -sval -ext WixUIExtension -b "${LIBSCRIPT_ROOT_DIR}" -out "${OUT_FILE}.msi" "${OUT_FILE}.wixobj" "${OUT_FILE}_payload.wixobj"; then
      printf '[ERROR] light linker failed for %s.msi\n' "${OUT_FILE}" >&2
      return 1
    fi
  fi

  _msi_tables=$(msiinfo tables "${OUT_FILE}.msi" 2>/dev/null || true)
  if ! printf '%s\n' "$_msi_tables" | grep "CustomAction" >/dev/null 2>&1; then
    printf "[ERROR] MSI validation failed. Missing CustomAction table.\n" >&2
    return 1
  fi
  if ! printf '%s\n' "$_msi_tables" | grep "Dialog" >/dev/null 2>&1; then
    printf "[ERROR] MSI validation failed. Missing Dialog table.\n" >&2
    return 1
  fi
  if ! printf '%s\n' "$_msi_tables" | grep "Property" >/dev/null 2>&1; then
    printf '[ERROR] msiinfo structural validation failed. Missing fundamental MSI tables.\n' >&2
    return 1
  fi
  
  _msi_size=$(wc -c < "${OUT_FILE}.msi" | tr -d ' ')
  if [ "$VARIANT" = "offline" ]; then
    if [ "$_msi_size" -lt 5242880 ]; then
      printf '[ERROR] Offline MSI validation failed. The generated MSI is abnormally small (%s bytes < 5242880 bytes).\n' "$_msi_size" >&2
      return 1
    fi
  else
    if [ "$_msi_size" -lt 100000 ]; then
      printf '[ERROR] Online MSI validation failed. The generated MSI is abnormally small (%s bytes < 100000 bytes).\n' "$_msi_size" >&2
      return 1
    fi
  fi

  printf '[PASS] Successfully built %s.msi\n' "${OUT_FILE}"
}

compile_msi || { exit 1; }
exit 0
