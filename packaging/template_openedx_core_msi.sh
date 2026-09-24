#!/bin/sh
# ## Overview
# Generates a pure WiX XML (.wxs) manifest for openedx-core.msi.
# Packages the Open edX LMS/CMS codebase, scripts, configuration, and data folders.
# Expects third-party dependencies (MySQL, Redis, etc.) as standalone reference-counted MSIs.
#
# ## Usage
#   ./packaging/template_openedx_core_msi.sh [OPTIONS]
#
# ## Parameters
#   --version <version>   Package version (default: 22.1.0)
#   --out <file.wxs>      Output path for the generated WiX XML manifest
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

VERSION="22.1.0"
OUT_FILE=""

# ## show_help
# Displays usage documentation.
show_help() {
  cat << EOF_HELP
Open edX Core WiX Template Generator

Usage:
  ./packaging/template_openedx_core_msi.sh [OPTIONS]

Options:
  --version <ver>    Package version (default: 22.1.0)
  --out <file.wxs>   Output WiX manifest path
  --help, -h         Show this help text
EOF_HELP
}

while [ $# -gt 0 ]; do
  case "$1" in
    --version)
      VERSION="$2"
      shift 2
      ;;
    --out)
      OUT_FILE="$2"
      shift 2
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      printf '[ERROR] Unknown parameter: %s
' "$1" >&2
      exit 1
      ;;
  esac
done

if [ -z "$OUT_FILE" ]; then
  printf '[ERROR] --out is required.
' >&2
  show_help
  exit 1
fi

UPGRADE_CODE="B8C8E64E-9B5A-4B7C-A5D8-0F18B9918239"
PRODUCT_CODE=$("${LIBSCRIPT_ROOT_DIR}/_lib/_common/uuid_gen.sh" "6ba7b810-9dad-11d1-80b4-00c04fd430c8" "openedx.core.${VERSION}")

_p1="${VERSION%%.*}"
_rest1="${VERSION#*.}"
if [ "$_rest1" != "$VERSION" ]; then
  _p2="${_rest1%%.*}"
  _rest2="${_rest1#*.}"
  if [ "$_rest2" != "$_rest1" ]; then
    _p3="${_rest2%%.*}"
    _rest3="${_rest2#*.}"
    if [ "$_rest3" != "$_rest2" ]; then
      _p4="${_rest3%%.*}"
      WIX_VERSION="${_p1}.${_p2}.${_p3}.${_p4}"
    else
      WIX_VERSION="${_p1}.${_p2}.${_p3}.0"
    fi
  else
    WIX_VERSION="${_p1}.${_p2}.0.0"
  fi
else
  WIX_VERSION="${_p1}.0.0.0"
fi

cat << EOF_CORE_WXS > "$OUT_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="${PRODUCT_CODE}"
           Name="Open edX Platform Core"
           Language="1033"
           Version="${WIX_VERSION}"
           Manufacturer="The Axim Collaborative &amp; LibScript Contributors"
           UpgradeCode="${UPGRADE_CODE}">

    <Package Id="*"
             InstallerVersion="405"
             Compressed="yes"
             InstallScope="perMachine"
             Description="Open edX Platform Core LMS and Studio Services" />

    <MajorUpgrade DowngradeErrorMessage="A newer version of Open edX Platform Core is already installed." Schedule="afterInstallInitialize" />
    <Media Id="1" Cabinet="openedx_core.cab" EmbedCab="yes" />

    <Property Id="PROP_LMS_PORT" Value="8000" />
    <Property Id="PROP_CMS_PORT" Value="8001" />
    <Property Id="PROP_MYSQL_HOST" Value="127.0.0.1" />
    <Property Id="PROP_MYSQL_PORT" Value="3306" />
    <Property Id="PROP_REDIS_HOST" Value="127.0.0.1" />
    <Property Id="PROP_REDIS_PORT" Value="6379" />
    <Property Id="PROP_MONGODB_HOST" Value="127.0.0.1" />
    <Property Id="PROP_MONGODB_PORT" Value="27017" />
    <Property Id="PROP_MEILISEARCH_PORT" Value="7700" />

    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFiles64Folder">
        <Directory Id="INSTALLFOLDER" Name="OpenEdX">
          <Directory Id="SCRIPTS_DIR" Name="scripts" />
        </Directory>
      </Directory>
      <Directory Id="CommonAppDataFolder">
        <Directory Id="OPENEDX_DATA_ROOT" Name="OpenEdX">
          <Directory Id="DATA_DIR" Name="data" />
          <Directory Id="LOGS_DIR" Name="logs" />
          <Directory Id="BACKUPS_DIR" Name="backups" />
        </Directory>
      </Directory>
      <Directory Id="ProgramMenuFolder">
        <Directory Id="ApplicationProgramsFolder" Name="Open edX" />
      </Directory>
    </Directory>

    <Feature Id="OpenEdXCoreFeature" Title="Open edX Core" Level="1">
      <ComponentRef Id="CoreIdentityRecord" />
      <ComponentRef Id="CoursewareDataStore" />
      <ComponentRef Id="CoursewareLogStore" />
      <ComponentRef Id="CoursewareBackupStore" />
      <ComponentRef Id="ApplicationShortcuts" />
      <ComponentGroupRef Id="OpenEdXCorePayloadComponents" />
    </Feature>

    <DirectoryRef Id="INSTALLFOLDER">
      <Component Id="CoreIdentityRecord" Guid="E2A89C15-99BD-4720-A0E8-A97A2E504F63">
        <RegistryKey Root="HKLM" Key="Software\LibScript\OpenEdX">
          <RegistryValue Name="Installed" Type="integer" Value="1" KeyPath="yes" />
          <RegistryValue Name="Version" Type="string" Value="${VERSION}" />
          <RegistryValue Name="InstallDir" Type="string" Value="[INSTALLFOLDER]" />
          <RegistryValue Name="DataDir" Type="string" Value="[DATA_DIR]" />
          <RegistryValue Name="LogsDir" Type="string" Value="[LOGS_DIR]" />
        </RegistryKey>
      </Component>
    </DirectoryRef>

    <DirectoryRef Id="DATA_DIR">
      <Component Id="CoursewareDataStore" Guid="7F28A541-11C3-4E80-990A-46D91A883C12" Permanent="yes" NeverOverwrite="yes">
        <CreateFolder />
      </Component>
    </DirectoryRef>

    <DirectoryRef Id="LOGS_DIR">
      <Component Id="CoursewareLogStore" Guid="3E4A1521-884A-49A3-A65B-64771C5091E2" Permanent="yes" NeverOverwrite="yes">
        <CreateFolder />
      </Component>
    </DirectoryRef>

    <DirectoryRef Id="BACKUPS_DIR">
      <Component Id="CoursewareBackupStore" Guid="98127364-5A4B-4C3D-8E2F-1029384756BA" Permanent="yes" NeverOverwrite="yes">
        <CreateFolder />
      </Component>
    </DirectoryRef>

    <DirectoryRef Id="ApplicationProgramsFolder">
      <Component Id="ApplicationShortcuts" Guid="718293A4-B5C6-4D7E-8F90-123456789ABC">
        <Shortcut Id="ApplicationStartMenuShortcutCLI"
                  Name="Open edX Management Console"
                  Description="Open edX Command-Line Operations"
                  Target="[INSTALLFOLDER]cli.cmd"
                  WorkingDirectory="INSTALLFOLDER" />
        <Shortcut Id="ApplicationStartMenuShortcutHealth"
                  Name="Open edX Health Diagnostics"
                  Description="Full-stack health diagnostic probe"
                  Target="[INSTALLFOLDER]healthcheck.cmd"
                  WorkingDirectory="INSTALLFOLDER" />
        <Shortcut Id="ApplicationStartMenuShortcutDbShell"
                  Name="Open edX Database Console"
                  Description="Interactive SQL and Datastore Console"
                  Target="[INSTALLFOLDER]dbshell.cmd"
                  WorkingDirectory="INSTALLFOLDER" />
        <RemoveFolder Id="CleanUpShortCut" On="uninstall" />
        <RegistryValue Root="HKCU" Key="Software\LibScript\OpenEdX\Shortcuts" Name="Installed" Type="integer" Value="1" KeyPath="yes" />
      </Component>
    </DirectoryRef>
  </Product>
</Wix>
EOF_CORE_WXS

printf '[INFO] Generated Open edX Core WiX manifest: %s
' "$OUT_FILE"
