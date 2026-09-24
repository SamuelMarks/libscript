#!/bin/sh
# ## Overview
# Generates a pure WiX XML (.wxs) manifest for the Open edX Master Orchestrator MSI.
# Chained via Windows Installer 4.5+ native MsiEmbeddedChainer without any setup.exe bootstrapper.
# Supports online and air-gapped offline variants.
#
# ## Usage
#   ./packaging/template_openedx_orchestrator.sh [OPTIONS]
#
# ## Parameters
#   --version <ver>      Open edX stack version (default: 22.1.0)
#   --variant <var>      Installer variant: online or offline (default: offline)
#   --msi-dir <dir>      Directory containing standalone component MSIs (default: dist/msi)
#   --out <file.wxs>     Target path for generated WiX XML manifest
#   --help, -h           Show this help text

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
VARIANT="offline"
MSI_DIR="${LIBSCRIPT_ROOT_DIR}/dist/msi"
OUT_FILE=""

# ## show_help
# Displays usage documentation.
show_help() {
  cat << EOF_HELP
Open edX Master Orchestrator WiX Generator

Usage:
  ./packaging/template_openedx_orchestrator.sh [OPTIONS]

Options:
  --version <ver>    Stack release version (default: 22.1.0)
  --variant <var>    Installer variant (online or offline, default: offline)
  --msi-dir <dir>    Directory containing child component MSIs
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
    --variant)
      VARIANT="$2"
      shift 2
      ;;
    --msi-dir)
      MSI_DIR="$2"
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

UPGRADE_CODE="C9D8E74F-0A6B-4C8D-B6E9-1F29C0029340"
PRODUCT_CODE=$("${LIBSCRIPT_ROOT_DIR}/_lib/_common/uuid_gen.sh" "6ba7b810-9dad-11d1-80b4-00c04fd430c8" "openedx.orchestrator.${VARIANT}.${VERSION}")

DISPLAY_NAME="Open edX Platform"
if [ "$VARIANT" = "offline" ]; then
  DISPLAY_NAME="Open edX Platform (Air-Gapped Offline)"
fi

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

cat << EOF_ORCH_WXS > "$OUT_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="${PRODUCT_CODE}"
           Name="${DISPLAY_NAME}"
           Language="1033"
           Version="${WIX_VERSION}"
           Manufacturer="The Axim Collaborative &amp; LibScript Contributors"
           UpgradeCode="${UPGRADE_CODE}">

    <Package Id="*"
             InstallerVersion="405"
             Compressed="yes"
             InstallScope="perMachine"
             Description="${DISPLAY_NAME} Unified Installer" />

    <MajorUpgrade DowngradeErrorMessage="A newer version of ${DISPLAY_NAME} is already installed." Schedule="afterInstallInitialize" />
    <Media Id="1" Cabinet="master_orch.cab" EmbedCab="yes" />

    <Property Id="INSTALL_MYSQL" Value="1" />
    <Property Id="PROP_MYSQL_PORT" Value="3306" />
    <Property Id="INSTALL_REDIS" Value="1" />
    <Property Id="PROP_REDIS_PORT" Value="6379" />
    <Property Id="INSTALL_MONGODB" Value="1" />
    <Property Id="PROP_MONGODB_PORT" Value="27017" />
    <Property Id="INSTALL_PYTHON" Value="1" />
    <Property Id="INSTALL_NODEJS" Value="1" />
    <Property Id="INSTALL_MEILISEARCH" Value="1" />
    <Property Id="PROP_MEILISEARCH_PORT" Value="7700" />
    <Property Id="INSTALL_CORE" Value="1" />

    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFiles64Folder">
        <Directory Id="INSTALLFOLDER" Name="OpenEdX">
          <Directory Id="BUNDLE_DIR" Name="bundle" />
        </Directory>
      </Directory>
    </Directory>

    <Feature Id="CompleteStack" Title="Open edX Complete Deployment" Level="1">
      <ComponentRef Id="MasterOrchestratorIdentity" />
      <ComponentGroupRef Id="ChainedMsiPayloads" />
    </Feature>

    <DirectoryRef Id="INSTALLFOLDER">
      <Component Id="MasterOrchestratorIdentity" Guid="A1B2C3D4-E5F6-4A5B-8C9D-0E1F2A3B4C5D">
        <RegistryKey Root="HKLM" Key="Software\LibScript\OpenEdX\Master">
          <RegistryValue Name="Installed" Type="integer" Value="1" KeyPath="yes" />
          <RegistryValue Name="Variant" Type="string" Value="${VARIANT}" />
          <RegistryValue Name="Version" Type="string" Value="${VERSION}" />
          <RegistryValue Name="InstallDir" Type="string" Value="[INSTALLFOLDER]" />
        </RegistryKey>
      </Component>
    </DirectoryRef>
  </Product>
</Wix>
EOF_ORCH_WXS

printf '[INFO] Generated Open edX Master Orchestrator WiX manifest: %s
' "$OUT_FILE"
