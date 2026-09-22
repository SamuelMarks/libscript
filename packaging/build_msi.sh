#!/bin/sh
# ## Overview
# Generic library engine for generating WiX Windows Installer (.msi) packages.
# Synthesizes WiX manifests from packaging.json and vars.schema.json, supporting
# Simple and Advanced setup modes, DBaaS offloading, custom directories,
# runtime auto-detection, and repository fork selection.
#
# ## Usage
# ./packaging/build_msi.sh [TARGET_DIR] [OPTIONS]
#
# Arguments:
#   TARGET_DIR            Component or stack path (e.g. stacks/cms/openedx)
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
#   --help, -h            Show this help text

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
# Prints script usage instructions and available command-line switches.
show_help() {
  printf '%s
' "Usage: $0 [TARGET_DIR] [OPTIONS]"
  printf '%s
' "Generates a generic WiX Windows Installer (.msi) package."
  printf '%s
' "Options:"
  printf '%s
' "  --out <name>          Output base file name"
  printf '%s
' "  --version <ver>       Package version"
  printf '%s
' "  --upgrade-code <guid> Upgrade code GUID"
  printf '%s
' "  --icon <path>         Path to .ico icon file"
  printf '%s
' "  --banner-top <path>   Path to 493x58 top banner BMP"
  printf '%s
' "  --banner-side <path>  Path to 164x312 side splash BMP"
  printf '%s
' "  --license <path>      Path to EULA (RTF or TXT)"
  printf '%s
' "  --install-dir <dir>   Default application installation folder"
  printf '%s
' "  --data-dir <dir>      Default mutable datastore folder"
  printf '%s
' "  --log-dir <dir>       Default logs folder"
  printf '%s
' "  --repo <url>          Source Git repository URL"
  printf '%s
' "  --branch <branch>     Target Git release branch or tag"
  printf '%s
' "  --auth-token <token>  Private repository authentication token"
  printf '%s
' "  --mode <mode>         Default setup mode (Simple or Advanced)"
  printf '%s
' "  --help, -h            Show this help text"
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
SETUP_MODE="Simple"

VARIANT="online"
[ "${LIBSCRIPT_OFFLINE:-0}" = "1" ] && VARIANT="offline"
CACHE_DIR="${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}"

while [ $# -gt 0 ]; do
  case "$1" in
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
      VARIANT="offline"
      shift
      ;;
    --online)
      VARIANT="online"
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
      REPO_AUTH_TOKEN="$2"
      shift 2
      ;;
    --mode)
      SETUP_MODE="$2"
      shift 2
      ;;
    -*)
      printf '[WARN] Unknown option: %s
' "$1" >&2
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
  TARGET_DIR="stacks/cms/openedx"
fi

# Resolve absolute path to TARGET_DIR
if [ -d "${LIBSCRIPT_ROOT_DIR}/${TARGET_DIR}" ]; then
  RESOLVED_TARGET_DIR="${LIBSCRIPT_ROOT_DIR}/${TARGET_DIR}"
elif [ -d "$TARGET_DIR" ]; then
  RESOLVED_TARGET_DIR="$(cd -- "$TARGET_DIR" && pwd)"
else
  printf '[FAIL] Target directory does not exist: %s
' "$TARGET_DIR" >&2
  exit 1
fi

PACKAGING_JSON="${RESOLVED_TARGET_DIR}/packaging.json"
VARS_SCHEMA="${RESOLVED_TARGET_DIR}/vars.schema.json"
MANIFEST_JSON="${RESOLVED_TARGET_DIR}/manifest.json"

# Extract metadata from packaging.json if present
APP_NAME="Open edX Platform"
APP_IDENTIFIER="openedx"
APP_PUBLISHER="LibScript Open Source Project"
APP_URL="https://openedx.org"
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
  [ -z "$ICON_PATH" ] && [ -n "$_pkg_icon" ] && ICON_PATH="${LIBSCRIPT_ROOT_DIR}/${_pkg_icon}"
  [ -z "$BANNER_TOP_PATH" ] && [ -n "$_pkg_btop" ] && BANNER_TOP_PATH="${LIBSCRIPT_ROOT_DIR}/${_pkg_btop}"
  [ -z "$BANNER_SIDE_PATH" ] && [ -n "$_pkg_bside" ] && BANNER_SIDE_PATH="${LIBSCRIPT_ROOT_DIR}/${_pkg_bside}"
  [ -z "$LICENSE_PATH" ] && [ -n "$_pkg_lic" ] && LICENSE_PATH="${LIBSCRIPT_ROOT_DIR}/${_pkg_lic}"
  [ -z "$INSTALL_DIR" ] && [ -n "$_pkg_appdir" ] && INSTALL_DIR="$_pkg_appdir"
  [ -z "$DATA_DIR" ] && [ -n "$_pkg_datadir" ] && DATA_DIR="$_pkg_datadir"
  [ -z "$LOGS_DIR" ] && [ -n "$_pkg_logsdir" ] && LOGS_DIR="$_pkg_logsdir"
  [ -z "$REPO_URL" ] && [ -n "$_pkg_repourl" ] && REPO_URL="$_pkg_repourl"
  [ -z "$REPO_BRANCH" ] && [ -n "$_pkg_repobranch" ] && REPO_BRANCH="$_pkg_repobranch"
fi

: "${APP_VERSION:=1.0.0.0}"
: "${UPGRADE_CODE:=B8C8E64E-9B5A-4B7C-A5D8-0F18B9918239}"
: "${INSTALL_DIR:=[ProgramFiles64Folder]OpenEdX}"
: "${DATA_DIR:=C:\ProgramData\OpenEdX\data}"
: "${LOGS_DIR:=C:\ProgramData\OpenEdX\logs}"
: "${REPO_URL:=https://github.com/openedx/edx-platform.git}"
: "${REPO_BRANCH:=open-release/quince.master}"

if [ "$VARIANT" = "offline" ]; then
  PROP_OPENEDX_OFFLINE="1"
  [ "$APP_NAME" = "Open edX Platform" ] && APP_NAME="Open edX Platform (Offline Air-Gapped)"
  : "${OUT_FILE:=openedx-offline-${APP_VERSION}}"
  WELCOME_DESC="The Setup Wizard will deploy Open edX LMS, Studio CMS, and pre-bundled air-gapped runtimes on your computer."
  COMP_TAG=" [Pre-bundled / Offline]"
else
  PROP_OPENEDX_OFFLINE="0"
  [ "$APP_NAME" = "Open edX Platform" ] && APP_NAME="Open edX Platform (Online)"
  : "${OUT_FILE:=openedx-${APP_VERSION}}"
  WELCOME_DESC="The Setup Wizard will download and install Open edX LMS, Studio CMS, and required runtimes on your computer."
  COMP_TAG=""
fi

TMP_WORK_DIR="${LIBSCRIPT_ROOT_DIR}/tmp/msi_build_$$"
mkdir -p "$TMP_WORK_DIR"

# ## cleanup_tmp
# Removes temporary build directory.
# shellcheck disable=SC2317,SC2329
cleanup_tmp() {
  rm -rf "$TMP_WORK_DIR"
}
trap cleanup_tmp EXIT INT TERM

# ## ensure_branding_assets
# Validates or synthesizes placeholder branding assets.
ensure_branding_assets() {
  local cc0_assets="${LIBSCRIPT_ROOT_DIR}/../cc0-assets/libscript/openedx/assets"
  if [ ! -d "$cc0_assets" ] && [ -d "${LIBSCRIPT_ROOT_DIR}/cc0-assets/libscript/openedx/assets" ]; then
    cc0_assets="${LIBSCRIPT_ROOT_DIR}/cc0-assets/libscript/openedx/assets"
  fi
  local gen_script="${LIBSCRIPT_ROOT_DIR}/packaging/generate_openedx_branding.sh"
  local gen_attempted=0

  # Check external cc0-assets repository first if not explicitly found
  if [ -z "$ICON_PATH" ] || [ ! -f "$ICON_PATH" ]; then
    if [ -f "$cc0_assets/openedx.ico" ]; then
      ICON_PATH="$cc0_assets/openedx.ico"
    elif [ -f "${LIBSCRIPT_ROOT_DIR}/packaging/assets/openedx.ico" ]; then
      ICON_PATH="${LIBSCRIPT_ROOT_DIR}/packaging/assets/openedx.ico"
    fi
  fi

  if [ -z "$BANNER_TOP_PATH" ] || [ ! -f "$BANNER_TOP_PATH" ]; then
    if [ -f "$cc0_assets/openedx_banner_top.bmp" ]; then
      BANNER_TOP_PATH="$cc0_assets/openedx_banner_top.bmp"
    elif [ -f "${LIBSCRIPT_ROOT_DIR}/packaging/assets/openedx_banner_top.bmp" ]; then
      BANNER_TOP_PATH="${LIBSCRIPT_ROOT_DIR}/packaging/assets/openedx_banner_top.bmp"
    fi
  fi

  if [ -z "$BANNER_SIDE_PATH" ] || [ ! -f "$BANNER_SIDE_PATH" ]; then
    if [ -f "$cc0_assets/openedx_banner_side.bmp" ]; then
      BANNER_SIDE_PATH="$cc0_assets/openedx_banner_side.bmp"
    elif [ -f "${LIBSCRIPT_ROOT_DIR}/packaging/assets/openedx_banner_side.bmp" ]; then
      BANNER_SIDE_PATH="${LIBSCRIPT_ROOT_DIR}/packaging/assets/openedx_banner_side.bmp"
    fi
  fi

  if [ -z "$LICENSE_PATH" ] || [ ! -f "$LICENSE_PATH" ]; then
    if [ -f "$cc0_assets/openedx_eula.rtf" ]; then
      LICENSE_PATH="$cc0_assets/openedx_eula.rtf"
    elif [ -f "${LIBSCRIPT_ROOT_DIR}/packaging/assets/openedx_eula.rtf" ]; then
      LICENSE_PATH="${LIBSCRIPT_ROOT_DIR}/packaging/assets/openedx_eula.rtf"
    fi
  fi

  # Synthesize assets dynamically on the fly if still missing
  if { [ -z "$ICON_PATH" ] || [ ! -f "$ICON_PATH" ]; } || \
     { [ -z "$BANNER_TOP_PATH" ] || [ ! -f "$BANNER_TOP_PATH" ]; } || \
     { [ -z "$BANNER_SIDE_PATH" ] || [ ! -f "$BANNER_SIDE_PATH" ]; } || \
     { [ -z "$LICENSE_PATH" ] || [ ! -f "$LICENSE_PATH" ]; }; then
    if [ -f "$gen_script" ]; then
      "$gen_script" --output-dir "$TMP_WORK_DIR" >/dev/null 2>&1 || true
      gen_attempted=1
    fi
  fi

  if [ -z "$ICON_PATH" ] || [ ! -f "$ICON_PATH" ]; then
    if [ -f "${TMP_WORK_DIR}/openedx.ico" ]; then
      ICON_PATH="${TMP_WORK_DIR}/openedx.ico"
    else
      ICON_PATH="${TMP_WORK_DIR}/app.ico"
      touch "$ICON_PATH"
    fi
  fi

  if [ -z "$BANNER_TOP_PATH" ] || [ ! -f "$BANNER_TOP_PATH" ]; then
    if [ -f "${TMP_WORK_DIR}/openedx_banner_top.bmp" ]; then
      BANNER_TOP_PATH="${TMP_WORK_DIR}/openedx_banner_top.bmp"
    else
      BANNER_TOP_PATH="${TMP_WORK_DIR}/banner_top.bmp"
      touch "$BANNER_TOP_PATH"
    fi
  fi

  if [ -z "$BANNER_SIDE_PATH" ] || [ ! -f "$BANNER_SIDE_PATH" ]; then
    if [ -f "${TMP_WORK_DIR}/openedx_banner_side.bmp" ]; then
      BANNER_SIDE_PATH="${TMP_WORK_DIR}/openedx_banner_side.bmp"
    else
      BANNER_SIDE_PATH="${TMP_WORK_DIR}/banner_side.bmp"
      touch "$BANNER_SIDE_PATH"
    fi
  fi

  if [ -z "$LICENSE_PATH" ] || [ ! -f "$LICENSE_PATH" ]; then
    if [ -f "${TMP_WORK_DIR}/openedx_eula.rtf" ]; then
      LICENSE_PATH="${TMP_WORK_DIR}/openedx_eula.rtf"
    else
      LICENSE_PATH="${TMP_WORK_DIR}/license.rtf"
      cat << 'EOF_EULA' > "$LICENSE_PATH"
{\rtf1\ansi\deff0 {\fonttbl {\f0 Courier;}}\fs20
Open edX Community License Agreement\par
This software is licensed under the AGPLv3 and respective dependency licenses.\par
By proceeding with the installation, you agree to comply with all applicable terms.\par
}
EOF_EULA
    fi
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
# Generates the WiX XML (.wxs) manifest synthesizing properties from schema and packaging config.
generate_wxs() {
  _esc_pub=$(printf '%s\n' "$APP_PUBLISHER" | sed 's/&/\&amp;/g')
  _esc_name=$(printf '%s\n' "$APP_NAME" | sed 's/&/\&amp;/g')
  cat << EOF_XML > "$WXS_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="$PRODUCT_CODE" Name="$_esc_name" Language="1033" Version="$APP_VERSION" Manufacturer="$_esc_pub" UpgradeCode="$UPGRADE_CODE">
    <Package InstallerVersion="200" Compressed="yes" InstallScope="perMachine" Description="$_esc_name Windows Installer" />
EOF_XML

  if [ "$VARIANT" = "offline" ]; then
    cat << EOF_MEDIA >> "$WXS_FILE"
    <!-- Offline Variant (Multi-cab partition) -->
    <Media Id="1" Cabinet="engine.cab" EmbedCab="yes" CompressionLevel="high" />
    <Media Id="2" Cabinet="runtimes.cab" EmbedCab="yes" CompressionLevel="medium" />
    <Media Id="3" Cabinet="databases.cab" EmbedCab="yes" CompressionLevel="medium" />
    <Media Id="4" Cabinet="codebase.cab" EmbedCab="yes" CompressionLevel="medium" />
EOF_MEDIA
  else
    cat << EOF_MEDIA >> "$WXS_FILE"
    <!-- Online Variant (Single compressed cab) -->
    <Media Id="1" Cabinet="engine.cab" EmbedCab="yes" CompressionLevel="high" />
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
    <Property Id="ARPPRODUCTICON" Value="AppIcon.ico" />
    <Property Id="ARPURLINFOABOUT" Value="$APP_URL" />
    <Property Id="PROP_OPENEDX_OFFLINE" Value="$PROP_OPENEDX_OFFLINE" Secure="yes" />
EOF_UPGRADE

  if [ -n "$BANNER_TOP_PATH" ] && [ -f "$BANNER_TOP_PATH" ]; then
    printf '    <WixVariable Id="WixUIBannerBmp" Value="%s" />
' "$BANNER_TOP_PATH" >> "$WXS_FILE"
  fi
  if [ -n "$BANNER_SIDE_PATH" ] && [ -f "$BANNER_SIDE_PATH" ]; then
    printf '    <WixVariable Id="WixUIDialogBmp" Value="%s" />
' "$BANNER_SIDE_PATH" >> "$WXS_FILE"
  fi
  if [ -n "$rtf_license_file" ] && [ -f "$rtf_license_file" ]; then
    printf '    <WixVariable Id="WixUILicenseRtf" Value="%s" />
' "$rtf_license_file" >> "$WXS_FILE"
  fi

  cat << EOF_PROPS >> "$WXS_FILE"
    <!-- Runtime Properties & Setup Mode Defaults -->
    <Property Id="SETUP_MODE" Value="$SETUP_MODE" Secure="yes" />
    <Property Id="LICENSE_ACCEPTED" Value="0" Secure="yes" />
    <Property Id="LAUNCH_BROWSER" Value="1" Secure="yes" />
    <Property Id="LAUNCH_STUDIO" Value="0" Secure="yes" />

    <!-- Directory Configuration Properties -->
    <Property Id="WIXUI_INSTALLDIR" Value="INSTALLFOLDER" />
    <Property Id="DATAFOLDER" Value="$DATA_DIR" Secure="yes" />
    <Property Id="LOGSFOLDER" Value="$LOGS_DIR" Secure="yes" />

    <!-- Runtime Auto-Detection Registry Searches -->
    <Property Id="FOUND_PYTHON_EXE">
      <RegistrySearch Id="SearchPython64" Root="HKLM" Key="SOFTWARE\Python\PythonCore\3.12\InstallPath" Type="raw" Win64="yes">
        <FileSearch Id="SearchPythonExe64" Name="python.exe" />
      </RegistrySearch>
      <RegistrySearch Id="SearchPython311" Root="HKLM" Key="SOFTWARE\Python\PythonCore\3.11\InstallPath" Type="raw" Win64="yes">
        <FileSearch Id="SearchPythonExe311" Name="python.exe" />
      </RegistrySearch>
    </Property>

    <Property Id="FOUND_NODE_EXE">
      <RegistrySearch Id="SearchNodeReg" Root="HKLM" Key="SOFTWARE\Node.js" Name="InstallPath" Type="raw">
        <FileSearch Id="SearchNodeExe" Name="node.exe" />
      </RegistrySearch>
    </Property>

    <Property Id="FOUND_MYSQL_EXE">
      <RegistrySearch Id="SearchMySQL8" Root="HKLM" Key="SOFTWARE\\MySQL AB\\MySQL Server 8.0" Name="Location" Type="raw">
        <FileSearch Id="SearchMySQLDaemon" Name="mysqld.exe" />
      </RegistrySearch>
    </Property>

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
    <Property Id="PROP_OPENEDX_BRANCH_PRESET" Value="Quince" Secure="yes" />

    <!-- Open edX Stack Properties Synthesized from vars.schema.json -->
    <Property Id="PROP_LMS_HOST" Value="localhost" Secure="yes" />
    <Property Id="PROP_LMS_PORT" Value="8000" Secure="yes" />
    <Property Id="PROP_CMS_HOST" Value="localhost" Secure="yes" />
    <Property Id="PROP_CMS_PORT" Value="8001" Secure="yes" />
    <Property Id="PROP_OPENEDX_ADMIN_EMAIL" Value="admin@openedx.local" Secure="yes" />
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
    <Property Id="BACKUPFOLDER" Value="C:\ProgramData\OpenEdX\backups" Secure="yes" />

    <!-- Mask Sensitive Git Credentials and Passwords in Verbose Logs -->
    <Property Id="MsiHiddenProperties" Value="PROP_OPENEDX_ADMIN_PASSWORD;PROP_OPENEDX_SECRET_KEY;PROP_MYSQL_ROOT_PASSWORD;PROP_MYSQL_REMOTE_URL;PROP_REDIS_PASSWORD;PROP_REDIS_URL;PROP_MONGODB_URI;PROP_MEILISEARCH_MASTER_KEY;PROP_OPENEDX_REPO_AUTH_TOKEN" />

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
    <CustomAction Id="CA_LaunchBrowser" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\packaging\launch_browser.cmd&quot; http://[PROP_LMS_HOST]:[PROP_LMS_PORT] &quot;Open edX LMS&quot;" Return="asyncNoWait" />
    <CustomAction Id="CA_LaunchStudio" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\packaging\launch_browser.cmd&quot; http://[PROP_CMS_HOST]:[PROP_CMS_PORT] &quot;Open edX Studio&quot;" Return="asyncNoWait" />
    <CustomAction Id="InstallOpenEdXService" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\libscript.cmd&quot; install stacks/cms/openedx --offline=[PROP_OPENEDX_OFFLINE] --lms-port=[PROP_LMS_PORT] --cms-port=[PROP_CMS_PORT] --mysql-url=&quot;[PROP_MYSQL_REMOTE_URL]&quot; --redis-port=[PROP_REDIS_PORT] --redis-url=&quot;[PROP_REDIS_URL]&quot; --mongodb-uri=&quot;[PROP_MONGODB_URI]&quot; --repo=&quot;[PROP_OPENEDX_EDX_PLATFORM_REPOSITORY]&quot; --version=&quot;[PROP_OPENEDX_VERSION]&quot; --admin-user=&quot;[PROP_OPENEDX_ADMIN_USERNAME]&quot; --admin-password=&quot;[PROP_OPENEDX_ADMIN_PASSWORD]&quot; --admin-email=&quot;[PROP_OPENEDX_ADMIN_EMAIL]&quot; --backup-dir=&quot;[BACKUPFOLDER]&quot; --theme=&quot;[PROP_OPENEDX_THEME]&quot;" Execute="deferred" Return="check" Impersonate="no" />
    <CustomAction Id="InstallWorkersService" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\stacks\cms\openedx\workers.cmd&quot; start" Execute="deferred" Return="ignore" Impersonate="no" />
    <CustomAction Id="StopWorkersService" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\stacks\cms\openedx\workers.cmd&quot; stop" Execute="deferred" Return="ignore" Impersonate="no" />
    <CustomAction Id="ImportDemoContentAction" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\stacks\cms\openedx\import_demo.cmd&quot; course &amp;&amp; &quot;[INSTALLFOLDER]libscript\stacks\cms\openedx\import_demo.cmd&quot; libraries" Execute="deferred" Return="ignore" Impersonate="no" />
    <CustomAction Id="BuildMFEsAction" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\stacks\cms\openedx\mfe.cmd&quot; build all &amp;&amp; &quot;[INSTALLFOLDER]libscript\stacks\cms\openedx\mfe.cmd&quot; deploy all" Execute="deferred" Return="ignore" Impersonate="no" />
    <CustomAction Id="PostInstallHealthcheck" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\stacks\cms\openedx\healthcheck.cmd&quot;" Execute="deferred" Return="ignore" Impersonate="no" />
    <CustomAction Id="InstallMySQLService" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\libscript.cmd&quot; install databases/mysql --port=[PROP_MYSQL_PORT]" Execute="deferred" Return="check" Impersonate="no" />
    <CustomAction Id="InstallRedisService" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\libscript.cmd&quot; install caches/redis --port=[PROP_REDIS_PORT]" Execute="deferred" Return="check" Impersonate="no" />
    <CustomAction Id="UninstallOpenEdXService" Directory="INSTALLFOLDER" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\libscript.cmd&quot; uninstall stacks/cms/openedx [PURGE_openedx]" Execute="deferred" Return="check" Impersonate="no" />

    <!-- UI Architecture Supporting Simple and Advanced Modes -->
    <UI Id="CustomUI">
      <Property Id="DefaultUIFont" Value="WixUI_Font_Normal" />

      <!-- Welcome Dialog -->
      <Dialog Id="Dlg_Welcome" Width="370" Height="270" Title="Welcome to [ProductName] Setup">
        <Control Id="Bitmap" Type="Bitmap" X="0" Y="0" Width="123" Height="234" Text="WixUIDialogBmp" />
        <Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" />
        <Control Id="Title" Type="Text" X="135" Y="20" Width="220" Height="50" Transparent="yes" NoPrefix="yes" Text="Welcome to the [ProductName] Setup Wizard" />
        <Control Id="Description" Type="Text" X="135" Y="70" Width="220" Height="70" Transparent="yes" NoPrefix="yes" Text="$WELCOME_DESC" />
        <Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Disabled="yes" Text="Back" />
        <Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next">
          <Publish Event="EndDialog" Value="Return">1</Publish>
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
        <Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="End-User License Agreement" />
        <Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Please read the following license agreement carefully." />
        <Control Id="AgreementText" Type="ScrollableText" X="20" Y="48" Width="330" Height="155" Sunken="yes" TabSkip="no">
          <Text SourceFile="license_placeholder.rtf" />
        </Control>
        <Control Id="LicenseAcceptedCheckBox" Type="CheckBox" X="20" Y="210" Width="330" Height="18" Property="LICENSE_ACCEPTED" CheckBoxValue="1" Text="I accept the terms in the License Agreement" />
        <Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back">
          <Publish Event="EndDialog" Value="Return">1</Publish>
        </Control>
        <Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="I Agree">
          <Publish Event="EndDialog" Value="Return"><![CDATA[LICENSE_ACCEPTED="1"]]></Publish>
          <Condition Action="disable"><![CDATA[LICENSE_ACCEPTED<>"1"]]></Condition>
          <Condition Action="enable"><![CDATA[LICENSE_ACCEPTED="1"]]></Condition>
        </Control>
        <Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel">
          <Publish Event="EndDialog" Value="Exit">1</Publish>
        </Control>
      </Dialog>

      <!-- Setup Type Choice: Simple Mode vs Advanced Mode -->
      <Dialog Id="Dlg_SetupType" Width="370" Height="270" Title="Choose Installation Mode">
        <Control Id="BannerBitmap" Type="Bitmap" X="0" Y="0" Width="370" Height="44" Text="WixUIBannerBmp" />
        <Control Id="BannerLine" Type="Line" X="0" Y="44" Width="370" Height="0" />
        <Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" />
        <Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="Choose Setup Type" />
        <Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Select your preferred deployment method." />
        <Control Id="RadioGroup" Type="RadioButtonGroup" X="20" Y="60" Width="330" Height="120" Property="SETUP_MODE">
          <RadioButtonGroup Property="SETUP_MODE">
            <RadioButton Value="Simple" X="0" Y="0" Width="320" Height="30" Text="Simple Mode (Express Install) - Installs all components with recommended defaults" />
            <RadioButton Value="Advanced" X="0" Y="45" Width="320" Height="30" Text="Advanced Mode (Custom Configuration) - Customize component selection, DBaaS URLs, and ports" />
          </RadioButtonGroup>
        </Control>
        <Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back">
          <Publish Event="EndDialog" Value="Return">1</Publish>
        </Control>
        <Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next">
          <Publish Event="EndDialog" Value="Return">1</Publish>
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
        <Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="Component Selection &amp; Architecture" />
        <Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Review required runtimes and configure optional services." />
        <Control Id="Lbl_NonOptHeader" Type="Text" X="20" Y="48" Width="330" Height="14" NoPrefix="yes" Text="Non-Optional Components (always installed):" />
        <Control Id="Lbl_NonOptList" Type="Text" X="28" Y="63" Width="320" Height="50" NoPrefix="yes" Text="- Python (Python 3.11+ runtime &amp; virtual environment)&#13;&#10;- Node.js (Node.js &amp; npm asset pipeline)&#13;&#10;- Meilisearch (Course search and catalog discovery engine)&#13;&#10;- MySQL (Relational database) &amp; Redis (Cache &amp; Celery broker)&#13;&#10;- MongoDB (Course document datastore)" />
        <Control Id="Lbl_OptHeader" Type="Text" X="20" Y="114" Width="330" Height="14" NoPrefix="yes" Text="Optional / Configurable Services:" />
        <Control Id="Chk_LMS" Type="CheckBox" X="28" Y="128" Width="320" Height="14" Property="INSTALL_LMS" CheckBoxValue="1" Text="Open edX LMS Core Service (Port 8000)" />
        <Control Id="Chk_CMS" Type="CheckBox" X="28" Y="142" Width="320" Height="14" Property="INSTALL_CMS" CheckBoxValue="1" Text="Open edX Studio / CMS Course Authoring (Port 8001)" />
        <Control Id="Chk_MySQL" Type="CheckBox" X="28" Y="156" Width="320" Height="14" Property="INSTALL_MYSQL" CheckBoxValue="1" Text="Install Local MySQL Service (uncheck if using DBaaS)" />
        <Control Id="Chk_Redis" Type="CheckBox" X="28" Y="170" Width="320" Height="14" Property="INSTALL_REDIS" CheckBoxValue="1" Text="Install Local Redis Service (uncheck if using Cloud Redis)" />
        <Control Id="Chk_Workers" Type="CheckBox" X="28" Y="184" Width="320" Height="14" Property="INSTALL_WORKERS" CheckBoxValue="1" Text="Launch Celery Background Workers &amp; Scheduler" />
        <Control Id="Chk_Demo" Type="CheckBox" X="28" Y="198" Width="320" Height="14" Property="IMPORT_DEMO_CONTENT" CheckBoxValue="1" Text="Import edX Demo Course &amp; Content Libraries" />
        <Control Id="Chk_MFEs" Type="CheckBox" X="28" Y="212" Width="320" Height="14" Property="INSTALL_MFES" CheckBoxValue="1" Text="Build and Deploy Micro-Frontends (Learning, Authn, Account)" />
        <Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back">
          <Publish Event="EndDialog" Value="Return">1</Publish>
        </Control>
        <Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next">
          <Publish Event="EndDialog" Value="Return">1</Publish>
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

        <Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="Destination Folders" />
        <Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Select target locations for binaries, databases, logs, and backups." />

        <Control Id="Lbl_AppFolder" Type="Text" X="20" Y="48" Width="330" Height="13" NoPrefix="yes" Text="Application Installation Folder:" />
        <Control Id="Txt_AppFolder" Type="PathEdit" X="20" Y="61" Width="260" Height="17" Property="INSTALLFOLDER" />
        <Control Id="Btn_BrowseApp" Type="PushButton" X="285" Y="61" Width="65" Height="17" Text="Browse...">
          <Publish Property="_BrowseProperty" Value="INSTALLFOLDER">1</Publish>
          <Publish Event="SpawnDialog" Value="BrowseDlg">1</Publish>
        </Control>

        <Control Id="Lbl_DataFolder" Type="Text" X="20" Y="80" Width="330" Height="13" NoPrefix="yes" Text="Databases and Media Storage Folder:" />
        <Control Id="Txt_DataFolder" Type="PathEdit" X="20" Y="93" Width="260" Height="17" Property="DATAFOLDER" />
        <Control Id="Btn_BrowseData" Type="PushButton" X="285" Y="93" Width="65" Height="17" Text="Browse...">
          <Publish Property="_BrowseProperty" Value="DATAFOLDER">1</Publish>
          <Publish Event="SpawnDialog" Value="BrowseDlg">1</Publish>
        </Control>

        <Control Id="Lbl_LogsFolder" Type="Text" X="20" Y="112" Width="330" Height="13" NoPrefix="yes" Text="Log Files Folder:" />
        <Control Id="Txt_LogsFolder" Type="PathEdit" X="20" Y="125" Width="260" Height="17" Property="LOGSFOLDER" />
        <Control Id="Btn_BrowseLogs" Type="PushButton" X="285" Y="125" Width="65" Height="17" Text="Browse...">
          <Publish Property="_BrowseProperty" Value="LOGSFOLDER">1</Publish>
          <Publish Event="SpawnDialog" Value="BrowseDlg">1</Publish>
        </Control>

        <Control Id="Lbl_BackupFolder" Type="Text" X="20" Y="144" Width="330" Height="13" NoPrefix="yes" Text="Automated Snapshots &amp; Backups Folder:" />
        <Control Id="Txt_BackupFolder" Type="PathEdit" X="20" Y="157" Width="260" Height="17" Property="BACKUPFOLDER" />
        <Control Id="Btn_BrowseBackup" Type="PushButton" X="285" Y="157" Width="65" Height="17" Text="Browse...">
          <Publish Property="_BrowseProperty" Value="BACKUPFOLDER">1</Publish>
          <Publish Event="SpawnDialog" Value="BrowseDlg">1</Publish>
        </Control>

        <Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back">
          <Publish Event="EndDialog" Value="Return">1</Publish>
        </Control>
        <Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next">
          <Publish Event="EndDialog" Value="Return">1</Publish>
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

        <Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="Runtime Environments" />
        <Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Configure Python and Node.js execution runtime providers." />

        <Control Id="Grp_Python" Type="GroupBox" X="20" Y="50" Width="330" Height="70" Text="Python 3.11+ Execution Runtime" />
        <Control Id="Rad_PythonExisting" Type="RadioButtonGroup" X="28" Y="65" Width="310" Height="45" Property="USE_EXISTING_PYTHON">
          <RadioButtonGroup Property="USE_EXISTING_PYTHON">
            <RadioButton Value="1" X="0" Y="0" Width="310" Height="20" Text="Reuse existing system Python: [FOUND_PYTHON_EXE]" />
            <RadioButton Value="0" X="0" Y="22" Width="310" Height="20" Text="Install isolated private Python runtime via LibScript" />
          </RadioButtonGroup>
        </Control>

        <Control Id="Grp_Node" Type="GroupBox" X="20" Y="125" Width="330" Height="70" Text="Node.js 18/20+ Asset Pipeline Runtime" />
        <Control Id="Rad_NodeExisting" Type="RadioButtonGroup" X="28" Y="140" Width="310" Height="45" Property="USE_EXISTING_NODE">
          <RadioButtonGroup Property="USE_EXISTING_NODE">
            <RadioButton Value="1" X="0" Y="0" Width="310" Height="20" Text="Reuse existing system Node.js: [FOUND_NODE_EXE]" />
            <RadioButton Value="0" X="0" Y="22" Width="310" Height="20" Text="Install isolated private Node.js runtime via LibScript" />
          </RadioButtonGroup>
        </Control>

        <Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back">
          <Publish Event="EndDialog" Value="Return">1</Publish>
        </Control>
        <Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next">
          <Publish Event="EndDialog" Value="Return">1</Publish>
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

        <Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="Source Repository &amp; Release" />
        <Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Review the repository source and branch configured for this installer." />

        <Control Id="Lbl_Repo" Type="Text" X="20" Y="48" Width="330" Height="14" NoPrefix="yes" Text="Configured edx-platform Repository Source (Read-Only):" />
        <Control Id="Txt_Repo" Type="Edit" X="20" Y="63" Width="330" Height="18" Property="PROP_OPENEDX_EDX_PLATFORM_REPOSITORY" Disabled="yes" />
        <Control Id="Hint_Repo" Type="Text" X="20" Y="83" Width="330" Height="22" Transparent="yes" NoPrefix="yes" Text="Source repository, local path, or fork configured during installer build." />

        <Control Id="Lbl_Branch" Type="Text" X="20" Y="110" Width="330" Height="14" NoPrefix="yes" Text="Configured Target Release, Branch, or Tag (Read-Only):" />
        <Control Id="Txt_Branch" Type="Edit" X="20" Y="125" Width="330" Height="18" Property="PROP_OPENEDX_VERSION" Disabled="yes" />
        <Control Id="Hint_Branch" Type="Text" X="20" Y="145" Width="330" Height="22" Transparent="yes" NoPrefix="yes" Text="Target branch, release tag, or commit SHA configured during installer build." />

        <Control Id="Lbl_Token" Type="Text" X="20" Y="175" Width="330" Height="14" NoPrefix="yes" Text="Private Repository Access Token (optional if private fork):" />
        <Control Id="Txt_Token" Type="Edit" X="20" Y="190" Width="330" Height="18" Property="PROP_OPENEDX_REPO_AUTH_TOKEN" Password="yes" />

        <Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back">
          <Publish Event="EndDialog" Value="Return">1</Publish>
        </Control>
        <Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next">
          <Publish Event="EndDialog" Value="Return">1</Publish>
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
        <Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="Network &amp; Credentials" />
        <Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Set service ports and administrator credentials." />
        <Control Id="Lbl_LmsPort" Type="Text" X="20" Y="50" Width="150" Height="15" Text="LMS Web Port:" />
        <Control Id="Txt_LmsPort" Type="Edit" X="20" Y="65" Width="140" Height="18" Property="PROP_LMS_PORT" />
        <Control Id="Lbl_CmsPort" Type="Text" X="180" Y="50" Width="150" Height="15" Text="Studio Web Port:" />
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
          <Publish Event="EndDialog" Value="Return">1</Publish>
        </Control>
        <Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next">
          <Publish Event="EndDialog" Value="Return">1</Publish>
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
        <Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="Database &amp; DBaaS Configuration" />
        <Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Configure MySQL or an External DBaaS Provider." />
        <Control Id="Lbl_LocalPort" Type="Text" X="20" Y="50" Width="300" Height="15" Text="Local MySQL Port (if self-hosted):" />
        <Control Id="Txt_LocalPort" Type="Edit" X="20" Y="65" Width="120" Height="18" Property="PROP_MYSQL_PORT" />

        <Control Id="Lbl_RemoteUrl" Type="Text" X="20" Y="90" Width="330" Height="15" Text="External DBaaS URL (e.g. AWS RDS / PlanetScale / Azure):" />
        <Control Id="Txt_RemoteUrl" Type="Edit" X="20" Y="105" Width="330" Height="18" Property="PROP_MYSQL_REMOTE_URL" Password="yes" />
        <Control Id="Hint_Remote" Type="Text" X="20" Y="125" Width="330" Height="25" Transparent="yes" Text="Format: mysql://user:password@host:port/database. Providing a remote DBaaS URL automatically bypasses local MySQL setup." />

        <Control Id="Lbl_RootPass" Type="Text" X="20" Y="155" Width="300" Height="15" Text="Local MySQL Root Password (ignored if DBaaS is used):" />
        <Control Id="Txt_RootPass" Type="Edit" X="20" Y="170" Width="200" Height="18" Property="PROP_MYSQL_ROOT_PASSWORD" Password="yes" />

        <Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back">
          <Publish Event="EndDialog" Value="Return">1</Publish>
        </Control>
        <Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next">
          <Publish Event="EndDialog" Value="Return">1</Publish>
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
        <Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="Cache, Document Store &amp; Search" />
        <Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Configure Redis, MongoDB Atlas, and Meilisearch." />

        <Control Id="Lbl_RedisPort" Type="Text" X="20" Y="50" Width="150" Height="15" Text="Redis Port (e.g. 6379, 6380):" />
        <Control Id="Txt_RedisPort" Type="Edit" X="20" Y="65" Width="120" Height="18" Property="PROP_REDIS_PORT" />
        <Control Id="Lbl_RedisUrl" Type="Text" X="160" Y="50" Width="190" Height="15" Text="Remote Redis DBaaS / URI:" />
        <Control Id="Txt_RedisUrl" Type="Edit" X="160" Y="65" Width="190" Height="18" Property="PROP_REDIS_URL" Password="yes" />

        <Control Id="Lbl_MongoUri" Type="Text" X="20" Y="95" Width="330" Height="15" Text="MongoDB Atlas URI / Connection String:" />
        <Control Id="Txt_MongoUri" Type="Edit" X="20" Y="110" Width="330" Height="18" Property="PROP_MONGODB_URI" Password="yes" />

        <Control Id="Lbl_MeiliUrl" Type="Text" X="20" Y="135" Width="330" Height="15" Text="Remote Meilisearch Cloud URL:" />
        <Control Id="Txt_MeiliUrl" Type="Edit" X="20" Y="150" Width="330" Height="18" Property="PROP_MEILISEARCH_CUSTOM_URL" />

        <Control Id="Back" Type="PushButton" X="180" Y="243" Width="56" Height="17" Text="Back">
          <Publish Event="EndDialog" Value="Return">1</Publish>
        </Control>
        <Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next">
          <Publish Event="EndDialog" Value="Return">1</Publish>
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
        <Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="Ready to Install [ProductName]" />
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
          <Publish Event="EndDialog" Value="Return">1</Publish>
        </Control>
        <Control Id="Install" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Install">
          <Publish Event="EndDialog" Value="Return">1</Publish>
        </Control>
        <Control Id="Cancel" Type="PushButton" X="304" Y="243" Width="56" Height="17" Cancel="yes" Text="Cancel">
          <Publish Event="EndDialog" Value="Exit">1</Publish>
        </Control>
      </Dialog>

      <!-- Completion/Exit Dialog with Launch Browser Checkbox -->
      <Dialog Id="Dlg_Exit" Width="370" Height="270" Title="[ProductName] Setup Complete">
        <Control Id="Bitmap" Type="Bitmap" X="0" Y="0" Width="123" Height="234" Text="WixUIDialogBmp" />
        <Control Id="BottomLine" Type="Line" X="0" Y="234" Width="370" Height="0" />
        <Control Id="Title" Type="Text" X="135" Y="20" Width="220" Height="50" Transparent="yes" NoPrefix="yes" Text="Completed [ProductName] Setup" />
        <Control Id="Desc" Type="Text" X="135" Y="70" Width="220" Height="50" Transparent="yes" NoPrefix="yes" Text="Open edX services have been successfully installed and started." />
        <Control Id="LaunchBrowserCheckBox" Type="CheckBox" X="135" Y="150" Width="220" Height="18" Property="LAUNCH_BROWSER" CheckBoxValue="1" Text="Launch Open edX LMS in Web Browser" />
        <Control Id="LaunchStudioCheckBox" Type="CheckBox" X="135" Y="172" Width="220" Height="18" Property="LAUNCH_STUDIO" CheckBoxValue="1" Text="Launch Open edX Studio in Web Browser" />
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
        <Custom Action="CA_CheckNetworkConnection" After="CostFinalize"><![CDATA[NOT Installed AND PROP_OPENEDX_OFFLINE="0"]]></Custom>
        <Show Dialog="Dlg_Welcome" After="CostFinalize">NOT Installed</Show>
        <Show Dialog="Dlg_License" After="Dlg_Welcome">NOT Installed</Show>
        <Show Dialog="Dlg_SetupType" After="Dlg_License">NOT Installed</Show>
        <!-- In Advanced Mode, route through customization dialogs -->
        <Show Dialog="Dlg_Features" After="Dlg_SetupType"><![CDATA[NOT Installed AND SETUP_MODE="Advanced"]]></Show>
        <Show Dialog="Dlg_InstallLocation" After="Dlg_Features"><![CDATA[NOT Installed AND SETUP_MODE="Advanced"]]></Show>
        <Show Dialog="Dlg_RuntimeSelection" After="Dlg_InstallLocation"><![CDATA[NOT Installed AND SETUP_MODE="Advanced"]]></Show>
        <Show Dialog="Dlg_OpenEdX_SourceRepo" After="Dlg_RuntimeSelection"><![CDATA[NOT Installed AND SETUP_MODE="Advanced"]]></Show>
        <Show Dialog="Dlg_OpenEdX_Config" After="Dlg_OpenEdX_SourceRepo"><![CDATA[NOT Installed AND SETUP_MODE="Advanced"]]></Show>
        <Show Dialog="Dlg_OpenEdX_DB" After="Dlg_OpenEdX_Config"><![CDATA[NOT Installed AND SETUP_MODE="Advanced"]]></Show>
        <Show Dialog="Dlg_OpenEdX_CacheSearch" After="Dlg_OpenEdX_DB"><![CDATA[NOT Installed AND SETUP_MODE="Advanced"]]></Show>
        <Show Dialog="Dlg_VerifyReady" After="Dlg_OpenEdX_CacheSearch"><![CDATA[NOT Installed AND SETUP_MODE="Advanced"]]></Show>
        <!-- In Simple Mode, skip directly to VerifyReady -->
        <Show Dialog="Dlg_VerifyReady" After="Dlg_SetupType"><![CDATA[NOT Installed AND SETUP_MODE="Simple"]]></Show>
        <Show Dialog="Dlg_Exit" OnExit="success">NOT Installed</Show>
      </InstallUISequence>
    </UI>

    <!-- Execution Sequence for Service Orchestration -->
    <InstallExecuteSequence>
      <CostInitialize Sequence="800" />
      <FileCost Sequence="900" />
      <CostFinalize Sequence="1000" />
      <Custom Action="InstallMySQLService" Before="InstallOpenEdXService"><![CDATA[NOT Installed AND INSTALL_MYSQL="1" AND NOT PROP_MYSQL_REMOTE_URL]]></Custom>
      <Custom Action="InstallRedisService" Before="InstallOpenEdXService"><![CDATA[NOT Installed AND INSTALL_REDIS="1" AND NOT PROP_REDIS_URL]]></Custom>
      <Custom Action="InstallOpenEdXService" Before="InstallFinalize"><![CDATA[NOT Installed AND INSTALL_LMS="1"]]></Custom>
      <Custom Action="InstallWorkersService" After="InstallOpenEdXService"><![CDATA[NOT Installed AND INSTALL_WORKERS="1"]]></Custom>
      <Custom Action="ImportDemoContentAction" After="InstallOpenEdXService"><![CDATA[NOT Installed AND IMPORT_DEMO_CONTENT="1"]]></Custom>
      <Custom Action="BuildMFEsAction" After="InstallOpenEdXService"><![CDATA[NOT Installed AND INSTALL_MFES="1"]]></Custom>
      <Custom Action="PostInstallHealthcheck" After="InstallOpenEdXService"><![CDATA[NOT Installed]]></Custom>
      <Custom Action="StopWorkersService" Before="UninstallOpenEdXService"><![CDATA[REMOVE="ALL"]]></Custom>
      <Custom Action="UninstallOpenEdXService" Before="RemoveFiles">REMOVE="ALL"</Custom>
    </InstallExecuteSequence>

    <Feature Id="ProductFeature" Title="$APP_NAME" Level="1">
      <ComponentGroupRef Id="ProductComponents" />
      <ComponentGroupRef Id="LibscriptHarvestedComponents" />
$([ "$VARIANT" = "offline" ] && printf '      <ComponentGroupRef Id="LibscriptOfflineCacheComponents" />\n')      <ComponentRef Id="CoursewareDataStore" />
      <ComponentRef Id="CoursewareLogStore" />
      <ComponentRef Id="CoursewareBackupStore" />
      <ComponentRef Id="ApplicationShortcuts" />
      <ComponentRef Id="EnvironmentSettings" />
    </Feature>
  </Product>

  <Fragment>
    <ComponentGroup Id="ProductComponents" Directory="INSTALLFOLDER">
      <Component Id="AppManifestComponent" Guid="E2A89C15-99BD-4720-A0E8-A97A2E504F63">
        <File Id="ManifestFile" Source="stacks/cms/openedx/manifest.json" KeyPath="yes" />
      </Component>
      <Component Id="VarsSchemaComponent" Guid="D1A72951-86E3-4E61-A79B-7D8C430931B5">
        <File Id="VarsSchemaFile" Source="stacks/cms/openedx/vars.schema.json" KeyPath="yes" />
      </Component>
      <Component Id="PackagingJsonComponent" Guid="C4A82110-5321-4FA6-9B3B-8D7E6512A098">
        <File Id="PackagingJsonFile" Source="stacks/cms/openedx/packaging.json" KeyPath="yes" />
      </Component>
      <Component Id="CliScriptComponent" Guid="B35F9271-2B4A-48DC-8812-3D7C51094E1A">
        <File Id="CliCmdFile" Source="stacks/cms/openedx/cli.cmd" KeyPath="yes" />
        <File Id="CliShFile" Source="stacks/cms/openedx/cli.sh" />
      </Component>
      <Component Id="UserScriptComponent" Guid="A91283F1-15D2-46A9-81FE-2B45CD98103F">
        <File Id="UserCmdFile" Source="stacks/cms/openedx/user.cmd" KeyPath="yes" />
        <File Id="UserShFile" Source="stacks/cms/openedx/user.sh" />
      </Component>
      <Component Id="ImportDemoScriptComponent" Guid="87123A0B-4321-48C1-871B-9430CD7812E5">
        <File Id="ImportDemoCmdFile" Source="stacks/cms/openedx/import_demo.cmd" KeyPath="yes" />
        <File Id="ImportDemoShFile" Source="stacks/cms/openedx/import_demo.sh" />
      </Component>
      <Component Id="DbShellScriptComponent" Guid="521A79B2-9F12-4C18-91AA-56193BF43109">
        <File Id="DbShellCmdFile" Source="stacks/cms/openedx/dbshell.cmd" KeyPath="yes" />
        <File Id="DbShellShFile" Source="stacks/cms/openedx/dbshell.sh" />
      </Component>
      <Component Id="HealthcheckScriptComponent" Guid="3190BCA1-71E5-4890-85A2-671239EF1045">
        <File Id="HealthcheckCmdFile" Source="stacks/cms/openedx/healthcheck.cmd" KeyPath="yes" />
        <File Id="HealthcheckShFile" Source="stacks/cms/openedx/healthcheck.sh" />
      </Component>
      <Component Id="ConfigScriptComponent" Guid="781A3290-E5A1-4F29-B109-873429185CA2">
        <File Id="ConfigCmdFile" Source="stacks/cms/openedx/config.cmd" KeyPath="yes" />
        <File Id="ConfigShFile" Source="stacks/cms/openedx/config.sh" />
      </Component>
      <Component Id="BackupScriptComponent" Guid="91823CA5-B410-4821-A951-871295A642B1">
        <File Id="BackupCmdFile" Source="stacks/cms/openedx/backup.cmd" KeyPath="yes" />
        <File Id="BackupShFile" Source="stacks/cms/openedx/backup.sh" />
      </Component>
      <Component Id="RestoreScriptComponent" Guid="65109AB3-7182-4C91-A281-541982736AE4">
        <File Id="RestoreCmdFile" Source="stacks/cms/openedx/restore.cmd" KeyPath="yes" />
        <File Id="RestoreShFile" Source="stacks/cms/openedx/restore.sh" />
      </Component>
      <Component Id="WorkersScriptComponent" Guid="418293B7-A619-4F52-8719-741982365BAC">
        <File Id="WorkersCmdFile" Source="stacks/cms/openedx/workers.cmd" KeyPath="yes" />
        <File Id="WorkersShFile" Source="stacks/cms/openedx/workers.sh" />
      </Component>
      <Component Id="ThemeScriptComponent" Guid="27189A45-C918-42A9-9812-651928473ACB">
        <File Id="ThemeCmdFile" Source="stacks/cms/openedx/theme.cmd" KeyPath="yes" />
        <File Id="ThemeShFile" Source="stacks/cms/openedx/theme.sh" />
      </Component>
      <Component Id="XBlockScriptComponent" Guid="19283746-5A6B-4C8D-9E0F-123456789ABC">
        <File Id="XBlockCmdFile" Source="stacks/cms/openedx/xblock.cmd" KeyPath="yes" />
        <File Id="XBlockShFile" Source="stacks/cms/openedx/xblock.sh" />
      </Component>
      <Component Id="UpgradeScriptComponent" Guid="38472910-B1C2-4D3E-8F4A-5678901234EF">
        <File Id="UpgradeCmdFile" Source="stacks/cms/openedx/upgrade.cmd" KeyPath="yes" />
        <File Id="UpgradeShFile" Source="stacks/cms/openedx/upgrade.sh" />
      </Component>
      <Component Id="MfeScriptComponent" Guid="59102837-A2B3-4C4D-8E5F-6789012345FA">
        <File Id="MfeCmdFile" Source="stacks/cms/openedx/mfe.cmd" KeyPath="yes" />
        <File Id="MfeShFile" Source="stacks/cms/openedx/mfe.sh" />
      </Component>
      <Component Id="MockServerComponent" Guid="6A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D">
        <File Id="MockServerPs1File" Source="stacks/cms/openedx/mock_server.ps1" KeyPath="yes" />
      </Component>
    </ComponentGroup>

    <!-- Environment Variable Registration -->
    <DirectoryRef Id="INSTALLFOLDER">
      <Component Id="EnvironmentSettings" Guid="7291A843-159A-46D8-92EF-891029384756">
        <Environment Id="EnvLibscriptRoot" Name="LIBSCRIPT_ROOT_DIR" Value="[INSTALLFOLDER]libscript" Permanent="no" Action="set" System="yes" />
        <Environment Id="EnvPathLibscript" Name="PATH" Value="[INSTALLFOLDER]libscript" Permanent="no" Action="set" Part="last" System="yes" />
        <Environment Id="EnvPathStack" Name="PATH" Value="[INSTALLFOLDER]libscript\stacks\cms\openedx" Permanent="no" Action="set" Part="last" System="yes" />
        <RegistryValue Root="HKCU" Key="Software\LibScript\OpenEdX" Name="env_configured" Type="integer" Value="1" KeyPath="yes" />
      </Component>
    </DirectoryRef>

    <!-- Permanent and NeverOverwrite User Data and Courseware Stores -->
    <DirectoryRef Id="DATAFOLDER">
      <Component Id="CoursewareDataStore" Guid="7F28A541-11C3-4E80-990A-46D91A883C12" Permanent="yes" NeverOverwrite="yes">
        <CreateFolder />
      </Component>
    </DirectoryRef>

    <DirectoryRef Id="LOGSFOLDER">
      <Component Id="CoursewareLogStore" Guid="3E4A1521-884A-49A3-A65B-64771C5091E2" Permanent="yes" NeverOverwrite="yes">
        <CreateFolder />
      </Component>
    </DirectoryRef>

    <DirectoryRef Id="BACKUPFOLDER">
      <Component Id="CoursewareBackupStore" Guid="98127364-5A4B-4C3D-8E2F-1029384756BA" Permanent="yes" NeverOverwrite="yes">
        <CreateFolder />
      </Component>
    </DirectoryRef>

    <!-- Administrative Shortcuts in Start Menu -->
    <DirectoryRef Id="OpenEdXProgramMenuFolder">
      <Component Id="ApplicationShortcuts" Guid="718293A4-B5C6-4D7E-8F90-123456789ABC">
        <Shortcut Id="ShortcutCli" Name="Open edX Management Console" Description="Open edX Management CLI" Target="[INSTALLFOLDER]libscript\stacks\cms\openedx\cli.cmd" WorkingDirectory="[INSTALLFOLDER]libscript\stacks\cms\openedx" />
        <Shortcut Id="ShortcutHealth" Name="Open edX Healthcheck" Description="Open edX Diagnostics Probe" Target="[INSTALLFOLDER]libscript\stacks\cms\openedx\healthcheck.cmd" WorkingDirectory="[INSTALLFOLDER]libscript\stacks\cms\openedx" />
        <Shortcut Id="ShortcutDbShell" Name="Open edX Database Console" Description="Open edX MySQL Database Shell" Target="[INSTALLFOLDER]libscript\stacks\cms\openedx\dbshell.cmd" Arguments="mysql" WorkingDirectory="[INSTALLFOLDER]libscript\stacks\cms\openedx" />
        <Shortcut Id="ShortcutBackup" Name="Open edX Backup and Restore" Description="Open edX Backup Tool" Target="[INSTALLFOLDER]libscript\stacks\cms\openedx\backup.cmd" WorkingDirectory="[INSTALLFOLDER]libscript\stacks\cms\openedx" $([ -n "$ICON_PATH" ] && [ -f "$ICON_PATH" ] && printf 'Icon="AppIcon.ico"') />
        <Shortcut Id="DesktopShortcutCli" Directory="DesktopFolder" Name="Open edX Management Console" Description="Open edX Management CLI" Target="[INSTALLFOLDER]libscript\stacks\cms\openedx\cli.cmd" WorkingDirectory="[INSTALLFOLDER]libscript\stacks\cms\openedx" $([ -n "$ICON_PATH" ] && [ -f "$ICON_PATH" ] && printf 'Icon="AppIcon.ico"') />
        <Shortcut Id="DesktopShortcutLms" Directory="DesktopFolder" Name="Open edX LMS" Description="Open edX Learning Management System" Target="[INSTALLFOLDER]libscript\stacks\cms\openedx\cli.cmd" Arguments="lms" WorkingDirectory="[INSTALLFOLDER]libscript\stacks\cms\openedx" $([ -n "$ICON_PATH" ] && [ -f "$ICON_PATH" ] && printf 'Icon="AppIcon.ico"') />
        <Shortcut Id="DesktopShortcutStudio" Directory="DesktopFolder" Name="Open edX Studio" Description="Open edX Studio Course Authoring" Target="[INSTALLFOLDER]libscript\stacks\cms\openedx\cli.cmd" Arguments="studio" WorkingDirectory="[INSTALLFOLDER]libscript\stacks\cms\openedx" $([ -n "$ICON_PATH" ] && [ -f "$ICON_PATH" ] && printf 'Icon="AppIcon.ico"') />
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
PAYLOAD_WXS="${OUT_FILE}_payload.wxs"
if [ "$VARIANT" = "offline" ]; then
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
# Builds the .msi binary using wixl on POSIX systems or WiX toolset on Windows.
compile_msi() {
  if [ "${OS:-}" = "Windows_NT" ] || command -v candle.exe >/dev/null 2>&1 || command -v wix.exe >/dev/null 2>&1; then
    if command -v wix.exe >/dev/null 2>&1; then
      wix.exe build -ext WixToolset.UI.wixext -o "${OUT_FILE}.msi" "$WXS_FILE" "${PAYLOAD_WXS}"
    else
      candle.exe "$WXS_FILE" "${PAYLOAD_WXS}"
      light.exe -ext WixUIExtension -out "${OUT_FILE}.msi" "${OUT_FILE}.wixobj" "${OUT_FILE}_payload.wixobj"
    fi
  elif command -v wixl >/dev/null 2>&1; then
    _wixl_manifest="${OUT_FILE}_wixl.wxs"
    _wixl_payload="${OUT_FILE}_payload_wixl.wxs"
    # Create wixl-compatible subset without vendor-specific UI extensions
    sed '/<WixVariable/d; /<UI Id="CustomUI">/,/<\/UI>/d; /<CustomAction/d; /<InstallExecuteSequence>/,/<\/InstallExecuteSequence>/d; /<MajorUpgrade/d; /<ComponentRef Id="Courseware/d; /<ComponentRef Id="ApplicationShortcuts/d; /<ComponentRef Id="EnvironmentSettings/d; /<Component Id="ApplicationShortcuts"/,/<\/Component>/d; /<Component Id="EnvironmentSettings"/,/<\/Component>/d; /<Directory Id="ProgramMenuFolder"/,/<\/Directory>/d; /<Property Id="FOUND_/,/<\/Property>/d; /Value=""/d; s/ Hidden="yes"//g; s/ CompressionLevel="[^"]*"//g; s/ NeverOverwrite="yes"//g; /<Media Id="[2-9]"/d' "$WXS_FILE" > "$_wixl_manifest"
    sed 's/ DiskId="[0-9]*"/ DiskId="1"/g' "${PAYLOAD_WXS}" > "$_wixl_payload"
    if wixl -a x64 -o "${OUT_FILE}.msi" "$_wixl_manifest" "$_wixl_payload"; then
      printf '[PASS] Successfully compiled binary MSI via wixl: %s.msi\n' "$OUT_FILE"
    else
      printf '[WARN] wixl compilation failed; keeping generated .wxs manifest\n' >&2
    fi
    rm -f "$_wixl_manifest" "$_wixl_payload"
  else
    printf '[INFO] Neither WiX toolset nor wixl is present in PATH. Generated XML manifest is ready for compilation.\n'
  fi
}

compile_msi
exit 0
