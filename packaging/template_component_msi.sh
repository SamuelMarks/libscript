#!/bin/sh
# ## Overview
# Generates a pure WiX XML (.wxs) manifest for a standalone LibScript component MSI.
# Utilizes deterministic GUIDs and reference-counted services from packaging/guid_registry.json.
# Supports 100% pure Windows Installer with zero external .exe dependencies.
#
# ## Usage
#   ./packaging/template_component_msi.sh [OPTIONS]
#
# ## Parameters
#   --component <name>    Component identifier (e.g. mysql, redis, mongodb, python, nodejs, meilisearch)
#   --version <version>   Component release version (e.g. 8.0.39, 20.17.0)
#   --out <file.wxs>      Output path for the generated WiX XML file
#   --source-dir <dir>    Directory containing component payload binaries to package
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

COMPONENT=""
VERSION="1.0.0"
OUT_FILE=""
SOURCE_DIR=""
SERVICE_GUID=""

# ## show_help
# Displays usage information and supported flags.
show_help() {
  cat << EOF_HELP
Standalone Component WiX Generator

Usage:
  ./packaging/template_component_msi.sh [OPTIONS]

Options:
  --component <name>   Component name (mysql, redis, mongodb, python, nodejs, meilisearch)
  --version <ver>      Version string (e.g. 8.0.39, default: 1.0.0)
  --out <file.wxs>     Output WiX file path
  --source-dir <dir>   Payload directory containing files to bundle
  --help, -h           Show this help text
EOF_HELP
}

while [ $# -gt 0 ]; do
  case "$1" in
    --component)
      COMPONENT="$2"
      shift 2
      ;;
    --version)
      VERSION="$2"
      shift 2
      ;;
    --out)
      OUT_FILE="$2"
      shift 2
      ;;
    --source-dir)
      SOURCE_DIR="$2"
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

if [ -z "$COMPONENT" ] || [ -z "$OUT_FILE" ]; then
  printf '[ERROR] --component and --out are mandatory parameters.
' >&2
  show_help
  exit 1
fi

REGISTRY_JSON="${LIBSCRIPT_ROOT_DIR}/packaging/guid_registry.json"
if [ ! -f "$REGISTRY_JSON" ]; then
  printf '[ERROR] Registry file not found: %s
' "$REGISTRY_JSON" >&2
  exit 1
fi

# Extract registry values via jq or awk
UPGRADE_CODE=$(jq -r --arg comp "$COMPONENT" '.components[$comp].upgrade_code // empty' "$REGISTRY_JSON")
COMPONENT_GUID=$(jq -r --arg comp "$COMPONENT" '.components[$comp].component_guid // empty' "$REGISTRY_JSON")
TITLE=$(jq -r --arg comp "$COMPONENT" '.components[$comp].title // $comp' "$REGISTRY_JSON")
TITLE=$(printf '%s\n' "$TITLE" | sed 's/&/\&amp;/g')
SERVICE_NAME=$(jq -r --arg comp "$COMPONENT" '.components[$comp].service_name // empty' "$REGISTRY_JSON")
DEFAULT_PORT=$(jq -r --arg comp "$COMPONENT" '.components[$comp].default_port // empty' "$REGISTRY_JSON")
SHARED_REF=$(jq -r --arg comp "$COMPONENT" '.components[$comp].shared_dll_ref_count // true' "$REGISTRY_JSON")

if [ -z "$UPGRADE_CODE" ]; then
  printf '[ERROR] Component %s is not registered in %s\n' "$COMPONENT" "$REGISTRY_JSON" >&2
  exit 1
fi

# Calculate deterministic ProductCode using uuid_gen.sh
PRODUCT_CODE=$("${LIBSCRIPT_ROOT_DIR}/_lib/_common/uuid_gen.sh" "6ba7b810-9dad-11d1-80b4-00c04fd430c8" "libscript.${COMPONENT}.${VERSION}")

# Map directory name for WiX
DIR_NAME="${COMPONENT}"
case "$COMPONENT" in
  mysql) DIR_NAME="MySQL" ;;
  redis) DIR_NAME="Redis" ;;
  mongodb) DIR_NAME="MongoDB" ;;
  python) DIR_NAME="Python311" ;;
  nodejs) DIR_NAME="Node20" ;;
  meilisearch) DIR_NAME="Meilisearch" ;;
esac

SHARED_ATTR=""
if [ "$SHARED_REF" = "true" ]; then
  SHARED_ATTR='SharedDllRefCount="yes"'
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

cat << EOF_WXS > "$OUT_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="${PRODUCT_CODE}"
           Name="LibScript ${TITLE}"
           Language="1033"
           Version="${WIX_VERSION}"
           Manufacturer="LibScript"
           UpgradeCode="${UPGRADE_CODE}">

    <Package Id="*"
             InstallerVersion="405"
             Compressed="yes"
             InstallScope="perMachine"
             Description="LibScript ${TITLE} Standalone Installer" />

    <MajorUpgrade DowngradeErrorMessage="A newer version of [ProductName] is already installed." Schedule="afterInstallInitialize" />
    <Media Id="1" Cabinet="payload.cab" EmbedCab="yes" />
EOF_WXS

if [ -n "$DEFAULT_PORT" ]; then
  cat << EOF_PORT >> "$OUT_FILE"
    <Property Id="PORT" Value="${DEFAULT_PORT}" />
EOF_PORT
fi

if [ -n "$SERVICE_NAME" ]; then
  cat << EOF_SVC_PROP >> "$OUT_FILE"
    <Property Id="SERVICE_NAME" Value="${SERVICE_NAME}" />
EOF_SVC_PROP
fi

cat << EOF_DIR_TREE >> "$OUT_FILE"
    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFiles64Folder">
        <Directory Id="LibScriptRootFolder" Name="LibScript">
          <Directory Id="INSTALLFOLDER" Name="${DIR_NAME}">
            <Directory Id="BIN_DIR" Name="bin" />
          </Directory>
        </Directory>
      </Directory>
      <Directory Id="CommonAppDataFolder">
        <Directory Id="LibScriptDataRoot" Name="LibScript">
          <Directory Id="COMPONENT_DATA_DIR" Name="${DIR_NAME}">
            <Directory Id="DATA_DIR" Name="data" />
          </Directory>
        </Directory>
      </Directory>
    </Directory>

    <Feature Id="MainFeature" Title="${TITLE}" Level="1">
      <ComponentRef Id="ComponentIdentityRecord" />
EOF_DIR_TREE

if [ -n "$SERVICE_NAME" ]; then
  cat << EOF_SERVICE_WXS >> "$OUT_FILE"
      <ComponentRef Id="ServiceRegistrationComponent" />
EOF_SERVICE_WXS
fi

cat << EOF_FOOTER >> "$OUT_FILE"
      <ComponentGroupRef Id="PayloadComponents" />
    </Feature>

    <DirectoryRef Id="INSTALLFOLDER">
      <Component Id="ComponentIdentityRecord" Guid="${COMPONENT_GUID}" ${SHARED_ATTR}>
        <RegistryKey Root="HKLM" Key="Software\\LibScript\\$COMPONENT">
          <RegistryValue Name="Installed" Type="integer" Value="1" KeyPath="yes" />
          <RegistryValue Name="Version" Type="string" Value="${VERSION}" />
          <RegistryValue Name="InstallDir" Type="string" Value="[INSTALLFOLDER]" />
          <RegistryValue Name="Port" Type="string" Value="[PORT]" />
        </RegistryKey>
      </Component>
    </DirectoryRef>
EOF_FOOTER

if [ -n "$SERVICE_NAME" ]; then
  SERVICE_GUID=$("${LIBSCRIPT_ROOT_DIR}/_lib/_common/uuid_gen.sh" "6ba7b810-9dad-11d1-80b4-00c04fd430c8" "service.${COMPONENT}")
  cat << EOF_SVC_DEF >> "$OUT_FILE"
    <DirectoryRef Id="BIN_DIR">
      <Component Id="ServiceRegistrationComponent" Guid="${SERVICE_GUID}" ${SHARED_ATTR}>
        <RegistryValue Root="HKLM" Key="Software\\LibScript\\$COMPONENT\\Service" Name="ServiceName" Type="string" Value="[SERVICE_NAME]" KeyPath="yes" />
        <ServiceInstall Id="Install_${COMPONENT}_Service"
                        Name="${SERVICE_NAME}"
                        DisplayName="LibScript ${TITLE}"
                        Type="ownProcess"
                        Start="auto"
                        ErrorControl="normal"
                        Description="Managed service daemon for LibScript ${TITLE}." />
        <ServiceControl Id="Control_${COMPONENT}_Service"
                        Name="${SERVICE_NAME}"
                        Start="install"
                        Stop="both"
                        Remove="uninstall"
                        Wait="yes" />
      </Component>
    </DirectoryRef>
EOF_SVC_DEF
fi

cat << 'EOF_CLOSE' >> "$OUT_FILE"
  </Product>
</Wix>
EOF_CLOSE

printf '[INFO] Generated standalone WiX manifest: %s
' "$OUT_FILE"
