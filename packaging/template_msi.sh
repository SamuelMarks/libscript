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
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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
export DIR="${SCRIPT_DIR}"

TARGET_SPEC="${1:-}"
if [ -z "$TARGET_SPEC" ]; then
  printf '[ERROR] Target stack directory or packaging.json required\n' >&2
  exit 1
fi
shift

OUT_FILE=""
VARIANT="online"
VERSION_OVERRIDE=""
TARGET_ARCH="${TARGET_ARCH:-x64}"
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
    --arch)
      TARGET_ARCH="$2"
      shift 2
      ;;
    --msi-dir)
      MSI_DIR="$2"
      shift 2
      ;;
    *)
      printf '[WARN] Unknown option: %s\n' "$1" >&2
      shift
      ;;
  esac
done

if [ -z "$OUT_FILE" ]; then
  printf '[ERROR] --out parameter is required\n' >&2
  exit 1
fi

PKG_JSON="$TARGET_SPEC"
if [ -d "$TARGET_SPEC" ]; then
  PKG_JSON="${TARGET_SPEC}/packaging.json"
fi

if [ ! -f "$PKG_JSON" ]; then
  printf '[ERROR] packaging.json not found at: %s\n' "$PKG_JSON" >&2
  exit 1
fi

# Parse metadata from packaging.json using jq
_pkg_props=$(jq -r --arg ver_ovr "$VERSION_OVERRIDE" '
  (.name // "app") as $name |
  (.title // $name) as $title |
  (if $ver_ovr != "" then $ver_ovr else (.version // "1.0.0") end) as $version |
  (.publisher // "LibScript Open Source Project") as $publisher |
  (.upgrade_code // "A0B1C2D3-E4F5-6A7B-8C9D-0E1F2A3B4C5D") as $upgrade_code |
  (.topology // "standalone") as $topology |
  (.directories // {}) as $dirs |
  ($dirs.app_default // ("[ProgramFiles64Folder]" + $name)) as $app_dir |
  ($dirs.data_default // ("C:\\ProgramData\\" + $name + "\\data")) as $data_dir |
  ($dirs.logs_default // ("C:\\ProgramData\\" + $name + "\\logs")) as $logs_dir |
  (.database_contract // null) as $dbc |
  (if $dbc != null then "true" else "false" end) as $has_db |
  (if $dbc != null then ($dbc.engine // "mysql") else "" end) as $db_engine |
  (if $dbc != null then (($dbc.default_port // 3306) | tostring) else "3306" end) as $db_port |
  (if $dbc != null then ($dbc.default_schema_name // $name) else $name end) as $db_schema |
  (if $dbc != null then ($dbc.default_user_name // $name) else $name end) as $db_user |
  ((.chained_packages // []) | length) as $chained_len |
  (if ($chained_len > 0 or $topology == "suite_orchestrator") then "true" else "false" end) as $has_chainer |
  "APP_NAME=\($name)\nAPP_TITLE=\($title)\nAPP_VERSION=\($version)\nAPP_PUBLISHER=\($publisher)\nUPGRADE_CODE=\($upgrade_code)\nTOPOLOGY=\($topology)\nAPP_DIR=\($app_dir)\nDATA_DIR=\($data_dir)\nLOGS_DIR=\($logs_dir)\nHAS_DB=\($has_db)\nDB_ENGINE=\($db_engine)\nDB_PORT=\($db_port)\nDB_SCHEMA=\($db_schema)\nDB_USER=\($db_user)\nHAS_CHAINER=\($has_chainer)"
' "$PKG_JSON")

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

    <Package Id="*" Platform="${TARGET_ARCH}"
             InstallerVersion="500"
             SummaryCodepage="1252"
             Compressed="yes"
             InstallScope="perMachine"
             Description="${APP_TITLE} Installer" />

    <MajorUpgrade DowngradeErrorMessage="A newer version of ${APP_TITLE} is already installed." Schedule="afterInstallInitialize" />
    <Media Id="1" Cabinet="payload.cab" EmbedCab="yes" />

    <Property Id="PROP_VARIANT" Value="${VARIANT}" Secure="yes" />
    <Property Id="PROP_APP_IDENTIFIER" Value="${APP_NAME}" Secure="yes" />
    <Property Id="PROP_TOPOLOGY" Value="${TOPOLOGY}" Secure="yes" />
    <!-- <Property Id="MsiHiddenProperties" Value="PROP_PROVISION_PASSWORD;PROP_MYSQL_ROOT_PASSWORD;PROP_MONGODB_ROOT_PASSWORD;PROP_REDIS_PASSWORD" /> -->
EOF_WXS

# Inject database contract properties if applicable
if [ "$HAS_DB" = "true" ]; then
  cat << EOF_DB_PROPS >> "$OUT_FILE"
    <!-- Universal Database Contract Properties -->
    <Property Id="PROP_DB_TYPE" Value="${DB_ENGINE}" Secure="yes" />
    <Property Id="USER_DB_HOST" Value="127.0.0.1" Secure="yes" />
    <Property Id="USER_DB_PORT" Value="${DB_PORT}" Secure="yes" />
    <Property Id="USER_DB_NAME" Value="${DB_SCHEMA}" Secure="yes" />
    <Property Id="PROP_PROVISION_USER" Value="${DB_USER}" Secure="yes" />
    <Property Id="PROP_PROVISION_PASSWORD" Value="${APP_NAME}123" Secure="yes" />
    <Property Id="PROP_MYSQL_ROOT_PASSWORD" Secure="yes" Hidden="yes" />
    <Property Id="PROP_MONGODB_ROOT_PASSWORD" Secure="yes" Hidden="yes" />
    <Property Id="PROP_PROVISION_CHARSET" Value="utf8mb4" Secure="yes" />
    <Property Id="PROP_PROVISION_COLLATION" Value="utf8mb4_unicode_ci" Secure="yes" />
    <Property Id="PURGE_DATA" Value="0" Secure="yes" />
    <Property Id="USER_DB_STRATEGY" Value="local" Secure="yes" />
    <Property Id="INSTALL_MYSQL" Value="1" Secure="yes" />

    <UI Id="DatabaseConfigUI">
      <Dialog Id="Dlg_DatabaseConfig" Width="370" Height="270" Title="Database Configuration">
        <Control Id="Title" Type="Text" X="15" Y="6" Width="260" Height="15" Transparent="yes" NoPrefix="yes" Text="Database Configuration" />
        <Control Id="Description" Type="Text" X="25" Y="22" Width="260" Height="20" Transparent="yes" NoPrefix="yes" Text="Select your database deployment strategy." />
        <Control Id="RadioGroup" Type="RadioButtonGroup" X="20" Y="60" Width="330" Height="50" Property="USER_DB_STRATEGY">
          <RadioButtonGroup Property="USER_DB_STRATEGY">
            <RadioButton Value="local" X="0" Y="0" Width="320" Height="20" Text="Install Local Database Component" />
            <RadioButton Value="remote" X="0" Y="25" Width="320" Height="20" Text="Connect to Existing/Remote Database" />
          </RadioButtonGroup>
        </Control>
        <Control Id="Lbl_DbHost" Type="Text" X="20" Y="120" Width="100" Height="15" Text="Database Host:" />
        <Control Id="Txt_DbHost" Type="Edit" X="120" Y="118" Width="200" Height="18" Property="USER_DB_HOST" />
        <Control Id="Lbl_DbName" Type="Text" X="20" Y="145" Width="100" Height="15" Text="Database Name:" />
        <Control Id="Txt_DbName" Type="Edit" X="120" Y="143" Width="200" Height="18" Property="USER_DB_NAME" />
      </Dialog>
    </UI>

    <CustomAction Id="SetInstallMySQL" Property="INSTALL_MYSQL" Value="0" />
    <CustomAction Id="ProvisionLogicalDB" Execute="deferred" Impersonate="no" Return="check" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]bundle\_lib\databases\provision_logical_db.cmd&quot; --host &quot;[USER_DB_HOST]&quot; --port &quot;[USER_DB_PORT]&quot; --db-name &quot;[USER_DB_NAME]&quot;" Directory="INSTALLFOLDER" />
    <CustomAction Id="RollbackLogicalDB" Execute="rollback" Impersonate="no" Return="ignore" ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]bundle\_lib\databases\provision_logical_db.cmd&quot; --rollback" Directory="INSTALLFOLDER" />
    
    <InstallExecuteSequence>
      <Custom Action="SetInstallMySQL" Before="ProvisionLogicalDB">USER_DB_STRATEGY="remote"</Custom>
      <Custom Action="ProvisionLogicalDB" Before="InstallFinalize">1</Custom>
      <Custom Action="RollbackLogicalDB" Before="ProvisionLogicalDB">1</Custom>
    </InstallExecuteSequence>
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

printf '[SUCCESS] Generated universal WiX XML manifest: %s\n' "$OUT_FILE"
