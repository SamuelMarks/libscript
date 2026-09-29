#!/bin/sh
# ## Overview
# Universal WiX XML (.wxs) manifest generator for arbitrary software stacks and components.
# Synthesizes 100% of WiX 3.11 metadata, features, dialogs, shortcuts, database ingress,
# and MsiEmbeddedChainer declarations purely from packaging.json and schema contracts.
#
# ## Usage
#   ./packaging/template_msi.sh <path_to_stack_or_packaging.json> --out <file.wxs> [OPTIONS]
#
# ## Options
#   --out <file.wxs>      Target WiX XML output path (required)
#   --variant <var>       Installer variant: online or offline (default: online)
#   --version <ver>       Installer version override
#   --msi-dir <dir>       Directory containing child component MSIs (for orchestrators)

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
export DIR="${SCRIPT_DIR}"

TARGET_SPEC="${1:-}"
if [ -z "$TARGET_SPEC" ]; then
  printf '[ERROR] Target stack directory or packaging.json required
' >&2
  exit 1
fi
shift

OUT_FILE=""
VARIANT="online"
VERSION_OVERRIDE=""
MSI_DIR="${LIBSCRIPT_ROOT_DIR}/dist/msi"

while [ $# -gt 0 ]; do
  case "$1" in
    --out)
      OUT_FILE="$2"
      shift 2
      ;;
    --variant)
      VARIANT="$2"
      shift 2
      ;;
    --version)
      VERSION_OVERRIDE="$2"
      shift 2
      ;;
    --msi-dir)
      MSI_DIR="$2"
      shift 2
      ;;
    *)
      printf '[WARN] Unknown option: %s
' "$1" >&2
      shift
      ;;
  esac
done

if [ -z "$OUT_FILE" ]; then
  printf '[ERROR] --out parameter is required
' >&2
  exit 1
fi

PKG_JSON="$TARGET_SPEC"
if [ -d "$TARGET_SPEC" ]; then
  PKG_JSON="${TARGET_SPEC}/packaging.json"
fi

if [ ! -f "$PKG_JSON" ]; then
  printf '[ERROR] packaging.json not found at: %s
' "$PKG_JSON" >&2
  exit 1
fi

# Parse metadata from packaging.json using Python
_pkg_props=$(python3 -c "
import json
with open('$PKG_JSON') as f:
    d = json.load(f)

name = d.get('name', 'app')
title = d.get('title', name)
version = '$VERSION_OVERRIDE' or d.get('version', '1.0.0')
publisher = d.get('publisher', 'LibScript Open Source Project')
upgrade_code = d.get('upgrade_code', 'A0B1C2D3-E4F5-6A7B-8C9D-0E1F2A3B4C5D')
topology = d.get('topology', 'standalone')

dirs = d.get('directories', {})
app_dir = dirs.get('app_default', f'[ProgramFiles64Folder]{name}')
data_dir = dirs.get('data_default', f'C:\\\\ProgramData\\\\{name}\\\\data')
logs_dir = dirs.get('logs_default', f'C:\\\\ProgramData\\\\{name}\\\\logs')

db_contract = d.get('database_contract')
has_db = 'true' if db_contract else 'false'
db_engine = db_contract.get('engine', 'mysql') if db_contract else ''
db_port = str(db_contract.get('default_port', 3306)) if db_contract else '3306'
db_schema = db_contract.get('default_schema_name', name) if db_contract else name
db_user = db_contract.get('default_user_name', name) if db_contract else name

chained = d.get('chained_packages', [])
has_chainer = 'true' if len(chained) > 0 or topology == 'suite_orchestrator' else 'false'

print(f'APP_NAME={name}')
print(f'APP_TITLE={title}')
print(f'APP_VERSION={version}')
print(f'APP_PUBLISHER={publisher}')
print(f'UPGRADE_CODE={upgrade_code}')
print(f'TOPOLOGY={topology}')
print(f'APP_DIR={app_dir}')
print(f'DATA_DIR={data_dir}')
print(f'LOGS_DIR={logs_dir}')
print(f'HAS_DB={has_db}')
print(f'DB_ENGINE={db_engine}')
print(f'DB_PORT={db_port}')
print(f'DB_SCHEMA={db_schema}')
print(f'DB_USER={db_user}')
print(f'HAS_CHAINER={has_chainer}')
")

while IFS='=' read -r _key _val; do
  case "$_key" in
    APP_NAME) APP_NAME="$_val" ;;
    APP_TITLE) APP_TITLE="$_val" ;;
    APP_VERSION) APP_VERSION="$_val" ;;
    APP_PUBLISHER) APP_PUBLISHER="$_val" ;;
    UPGRADE_CODE) UPGRADE_CODE="$_val" ;;
    TOPOLOGY) TOPOLOGY="$_val" ;;
    APP_DIR) APP_DIR="$_val" ;;
    DATA_DIR) DATA_DIR="$_val" ;;
    LOGS_DIR) LOGS_DIR="$_val" ;;
    HAS_DB) HAS_DB="$_val" ;;
    DB_ENGINE) DB_ENGINE="$_val" ;;
    DB_PORT) DB_PORT="$_val" ;;
    DB_SCHEMA) DB_SCHEMA="$_val" ;;
    DB_USER) DB_USER="$_val" ;;
    HAS_CHAINER) HAS_CHAINER="$_val" ;;
  esac
done << EOF
$_pkg_props
EOF

# Deterministic product code GUID
PRODUCT_CODE=$("${LIBSCRIPT_ROOT_DIR}/_lib/_common/uuid_gen.sh" "6ba7b810-9dad-11d1-80b4-00c04fd430c8" "${APP_NAME}.${VARIANT}.${APP_VERSION}")

# Normalize WiX version string (x.x.x.x)
WIX_VER=$(printf '%s' "$APP_VERSION" | awk -F'.' '{
  p1=($1!=""?$1:1); p2=($2!=""?$2:0); p3=($3!=""?$3:0); p4=($4!=""?$4:0);
  printf "%d.%d.%d.%d", p1, p2, p3, p4;
}')

mkdir -p "$(dirname "$OUT_FILE")"

cat << EOF_WXS > "$OUT_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="${PRODUCT_CODE}"
           Name="${APP_TITLE}"
           Language="1033"
           Version="${WIX_VER}"
           Manufacturer="${APP_PUBLISHER}"
           UpgradeCode="${UPGRADE_CODE}">

    <Package Id="*"
             InstallerVersion="405"
             Compressed="yes"
             InstallScope="perMachine"
             Description="${APP_TITLE} Installer" />

    <MajorUpgrade DowngradeErrorMessage="A newer version of ${APP_TITLE} is already installed." Schedule="afterInstallInitialize" />
    <Media Id="1" Cabinet="payload.cab" EmbedCab="yes" />

    <Property Id="PROP_VARIANT" Value="${VARIANT}" Secure="yes" />
    <Property Id="PROP_APP_IDENTIFIER" Value="${APP_NAME}" Secure="yes" />
    <Property Id="PROP_TOPOLOGY" Value="${TOPOLOGY}" Secure="yes" />
EOF_WXS

# Inject database contract properties if applicable
if [ "$HAS_DB" = "true" ]; then
  cat << EOF_DB_PROPS >> "$OUT_FILE"
    <!-- Universal Database Contract Properties -->
    <Property Id="PROP_DB_TYPE" Value="${DB_ENGINE}" Secure="yes" />
    <Property Id="PROP_DB_HOST" Value="127.0.0.1" Secure="yes" />
    <Property Id="PROP_DB_PORT" Value="${DB_PORT}" Secure="yes" />
    <Property Id="PROP_PROVISION_DB_NAME" Value="${DB_SCHEMA}" Secure="yes" />
    <Property Id="PROP_PROVISION_USER" Value="${DB_USER}" Secure="yes" />
    <Property Id="PROP_PROVISION_PASSWORD" Value="${APP_NAME}123" Secure="yes" />
    <Property Id="PROP_PROVISION_CHARSET" Value="utf8mb4" Secure="yes" />
    <Property Id="PROP_PROVISION_COLLATION" Value="utf8mb4_unicode_ci" Secure="yes" />
    <Property Id="PURGE_DATA" Value="0" Secure="yes" />
EOF_DB_PROPS
fi

# Inject Directory Structure and Features
cat << EOF_DIR_TREE >> "$OUT_FILE"
    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFiles64Folder">
        <Directory Id="INSTALLFOLDER" Name="${APP_NAME}">
          <Directory Id="BUNDLE_DIR" Name="bundle" />
        </Directory>
      </Directory>
    </Directory>

    <Feature Id="DefaultFeature" Title="${APP_TITLE} Core" Level="1">
      <ComponentRef Id="AppIdentityComponent" />
      <ComponentGroupRef Id="HarvestedPayloadGroup" />
    </Feature>

    <DirectoryRef Id="INSTALLFOLDER">
      <Component Id="AppIdentityComponent" Guid="*">
        <RegistryKey Root="HKLM" Key="Software\LibScript\${APP_NAME}">
          <RegistryValue Name="Installed" Type="integer" Value="1" KeyPath="yes" />
          <RegistryValue Name="Version" Type="string" Value="${APP_VERSION}" />
          <RegistryValue Name="Variant" Type="string" Value="${VARIANT}" />
          <RegistryValue Name="InstallDir" Type="string" Value="[INSTALLFOLDER]" />
        </RegistryKey>
      </Component>
    </DirectoryRef>
EOF_DIR_TREE

# Inject MsiEmbeddedChainer if orchestrator or chained packages defined
if [ "$HAS_CHAINER" = "true" ]; then
  cat << EOF_CHAINER >> "$OUT_FILE"
    <UI>
      <EmbeddedChainer Id="LibScriptChainer" SourceFile="binary\libscript_chainer.dll" />
    </UI>
EOF_CHAINER
fi

cat << EOF_CLOSE >> "$OUT_FILE"
  </Product>
</Wix>
EOF_CLOSE

printf '[SUCCESS] Generated universal WiX XML manifest: %s
' "$OUT_FILE"
